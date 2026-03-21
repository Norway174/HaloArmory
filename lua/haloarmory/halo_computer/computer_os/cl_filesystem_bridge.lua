--[[
    File: cl_filesystem_bridge.lua
    Purpose: Client-side filesystem operations bridge
    Realm: Client Only
    
    Description:
        Handles all filesystem operations on the client side. Bridges between
        JavaScript (WebOS UI) and Lua (GMod filesystem). Manages both C:/ drive
        (entity/server storage) and ExternalDrive:/ (local player storage).
    
    Storage Locations:
        C:/ with PC_ID:      data/haloarmory/computer/computers/{pc_id}/     (Server persistent)
        C:/ without PC_ID:   Entity.PC_Files table                           (Non-persistent)
        ExternalDrive:/:     data/haloarmory/computer/local/                 (Client local, NO NETWORK)
    
    Key Functions:
        - WriteFile: Save files (plain text for .txt, JSON for .dat)
        - ReadFile: Read file content (returns raw content)
        - ListDirectory: List files/folders with metadata
        - CreateDirectory: Create new directory
        - DeleteFile: Delete file or directory
        - GetJavaScript: Generate window.filesystem bridge code
    
    Network Behavior:
        - C:/ operations: Always sync to server (persistent if PC_ID is set)
        - ExternalDrive:/ operations: Local only, NEVER use network
]]--

HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM or {}

-- Load shared utilities
local scriptPath = HALOARMORY.GetOwnScriptPath()
local UTILS = include(scriptPath .. "sh_filesystem_utils.lua")

local FILESYSTEM = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM

-- Helper function to escape JSON string for JavaScript string literal
local function EscapeJSONForJavaScript(jsonString)
    if not jsonString then return "null" end
    local escaped = jsonString
    escaped = string.gsub(escaped, "\\", "\\\\")  -- Escape backslashes first
    escaped = string.gsub(escaped, "\"", "\\\"")    -- Escape double quotes
    escaped = string.gsub(escaped, "\n", "\\n")     -- Escape newlines
    escaped = string.gsub(escaped, "\r", "\\r")     -- Escape carriage returns
    escaped = string.gsub(escaped, "'", "\\'")       -- Escape single quotes
    return escaped
end

-- Helper function to build JavaScript callback code
local function BuildJavaScriptCallback(luaResult, callbackId, fallbackResult)
    local resultJson = luaResult and util.TableToJSON(luaResult) or "null"
    local escapedJson = EscapeJSONForJavaScript(resultJson)
    local fallback = fallbackResult or "null"
    
    return string.format([[
        try {
            if (window.filesystemCallback) {
                var result = null;
                try {
                    var jsonStr = "%s";
                    result = JSON.parse(jsonStr);
                } catch(e) {
                    console.error("JSON parse error:", e, "jsonStr:", jsonStr);
                    result = %s;
                }
                window.filesystemCallback('%s', result);
            } else {
                console.error("window.filesystemCallback not found!");
            }
        } catch(e) {
            console.error("filesystem.callback JS error:", e);
        }
    ]], escapedJson, fallback, callbackId)
end

-- Use shared utility functions from UTILS
-- (ValidatePath and ParsePath are now in sh_filesystem_utils.lua)

-- Helper function to build Lua code string for filesystem operations
-- This generates the Lua code that will be executed by JavaScript via console.lua_exec
local function BuildFilesystemLuaCode(filesystemCall, callbackId, fallbackResult)
    local jsCallbackCode = BuildJavaScriptCallback({result = true}, callbackId, fallbackResult)
    -- Escape the JavaScript code for embedding in Lua string
    local escapedJsCode = string.gsub(jsCallbackCode, "\\", "\\\\")
    escapedJsCode = string.gsub(escapedJsCode, "\"", "\\\"")
    escapedJsCode = string.gsub(escapedJsCode, "\n", "\\n")
    escapedJsCode = string.gsub(escapedJsCode, "\r", "\\r")
    
    return string.format([[
        local result = %s;
        local resultJson = util.TableToJSON({result = result ~= false});
        if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then
            local jsCode = "%s";
            HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode);
        end
    ]], filesystemCall, escapedJsCode)
end

-- Generate JavaScript filesystem bridge
function FILESYSTEM.GetJavaScript()
    return [[
// Helper function to escape strings for Lua
function escapeLuaString(str) {
    if (!str) return "''";
    // Use JSON.stringify which properly escapes the string, then remove quotes and escape for Lua
    var json = JSON.stringify(str);
    // Replace JSON quotes with Lua quotes and escape any existing quotes
    return json;
}

// Filesystem bridge using DHTML Lua bridge
window.filesystemCallbacks = window.filesystemCallbacks || {};
window.filesystemPendingOps = window.filesystemPendingOps || {};

window.notifyLocalFilesystemChange = function(path) {
    var targetPath = String(path || '');
    if (!targetPath) {
        return;
    }

    var folderPath = targetPath;
    if (!/\/$/i.test(folderPath)) {
        var slashIndex = folderPath.lastIndexOf('/');
        folderPath = slashIndex >= 0 ? folderPath.substring(0, slashIndex + 1) : folderPath;
    }

    if (window.osFileItemRenderer && window.osFileItemRenderer.invalidatePreviewCache) {
        window.osFileItemRenderer.invalidatePreviewCache(targetPath);
        window.osFileItemRenderer.invalidatePreviewCache(folderPath);
    }

    if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
        window.fileBrowserApp.refreshPath(folderPath);
    }

    if (window._saveDialogCurrentFolder) {
        var normalizedDialogPath = String(window._saveDialogCurrentFolder || '');
        if (normalizedDialogPath && !normalizedDialogPath.endsWith('/')) {
            normalizedDialogPath += '/';
        }
        if (folderPath && !folderPath.endsWith('/')) {
            folderPath += '/';
        }

        if (normalizedDialogPath === folderPath && window._saveDialogLoadFolder) {
            window._saveDialogLoadFolder(folderPath);
        }
    }
};

// Register callback function that Lua can call
window.filesystemCallback = function(callbackId, result, extra) {
    var pendingOp = window.filesystemPendingOps ? window.filesystemPendingOps[callbackId] : null;
    if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
        var callback = window.filesystemCallbacks[callbackId];
        // If result is an object with a result property, extract it
        var finalResult = result;
        if (result && typeof result === 'object' && result.result !== undefined) {
            finalResult = result.result;
        }
        callback(finalResult, extra, result);
        delete window.filesystemCallbacks[callbackId];
    }
    if (pendingOp) {
        var succeeded = false;
        if (result && typeof result === 'object' && result.result !== undefined) {
            succeeded = !!result.result;
        } else {
            succeeded = !!result;
        }

        if (succeeded && pendingOp.path && pendingOp.path.indexOf('ExternalDrive:/') === 0) {
            window.notifyLocalFilesystemChange(pendingOp.path);
        }

        if (succeeded && pendingOp.newPath && pendingOp.newPath.indexOf('ExternalDrive:/') === 0) {
            window.notifyLocalFilesystemChange(pendingOp.newPath);
        }

        delete window.filesystemPendingOps[callbackId];
    }
};

// Function to request fresh PC_Files sync from server
window.requestPCFilesSync = function(callback) {
    var callbackId = 'sync_' + Date.now();
    if (callback) {
        window.filesystemCallbacks[callbackId] = callback;
        window._pendingSyncCallback = callbackId;
    }
    
    var luaCode = 'if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.entity and IsValid(HALOARMORY.COMPUTER.INTERFACE.entity) and HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.RequestPCFiles then HALOARMORY.COMPUTER.INTERFACE.NETWORK.RequestPCFiles(HALOARMORY.COMPUTER.INTERFACE.entity:EntIndex()); end';
    
    if (typeof console !== 'undefined' && console.lua_exec) {
        console.lua_exec(luaCode);
    }
    
    // Callback will be triggered by the network receive handler after sync completes
    // Use a longer timeout as fallback
    if (callback) {
        setTimeout(function() {
            if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                window.filesystemCallbacks[callbackId](true);
                delete window.filesystemCallbacks[callbackId];
            }
            if (window._pendingSyncCallback === callbackId) {
                window._pendingSyncCallback = null;
            }
        }, 2000);
    }
};

// Store callback ID for sync completion
window._pendingSyncCallback = null;

window.filesystem = {
    writeFile: function(path, content, callback) {
        var pathJson = JSON.stringify(path);
        var contentJson = JSON.stringify(content);
        var callbackId = 'write_' + Date.now() + '_' + Math.random();
        window.filesystemPendingOps[callbackId] = {
            type: 'write',
            path: path
        };
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        var luaCode = 'local success = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.WriteFile(' + pathJson + ', ' + contentJson + '); local resultJson = util.TableToJSON({result=success ~= false}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:true};}window.filesystemCallback(\'' + callbackId + '\',result);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        }
        
        // Fallback timeout - call callback if no response
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId](true);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 1500);
        }
    },
    
    readFile: function(path, callback) {
        var pathJson = JSON.stringify(path);
        var callbackId = 'read_' + Date.now() + '_' + Math.random();
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        var luaCode = 'local content = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.ReadFile(' + pathJson + '); local resultJson = content and util.TableToJSON({result=content}) or util.TableToJSON({result=nil}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:null};}window.filesystemCallback(\'' + callbackId + '\',result);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        }
        
        // Fallback timeout
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId](null);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 2000);
        }
    },
    
    listDirectory: function(path, callback) {
        var pathJson = JSON.stringify(path);
        var callbackId = 'list_' + Date.now() + '_' + Math.random();
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        // Use the registered filesystem.callback function - must call through html:RunJavascript
        var luaCode = 'local files = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.ListDirectory(' + pathJson + '); local resultJson = util.TableToJSON({result=files}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:[]};}window.filesystemCallback(\'' + callbackId + '\',result);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        } else {
            console.error('[FileBrowser] listDirectory: console.lua_exec not available!');
            if (callback) {
                callback([]);
            }
            return;
        }
        
        // Fallback timeout - return empty array if no response
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId]([]);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 3000);
        }
    },
    
    createDirectory: function(path, callback) {
        var pathJson = JSON.stringify(path);
        var callbackId = 'mkdir_' + Date.now() + '_' + Math.random();
        window.filesystemPendingOps[callbackId] = {
            type: 'mkdir',
            path: path
        };
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        var luaCode = 'local success = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.CreateDirectory(' + pathJson + '); local resultJson = util.TableToJSON({result=success ~= false}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:true};}window.filesystemCallback(\'' + callbackId + '\',result);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        }
        
        // Fallback timeout - call callback if no response
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId](true);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 1500);
        }
    },
    
    deleteFile: function(path, callback) {
        var pathJson = JSON.stringify(path);
        var callbackId = 'delete_' + Date.now() + '_' + Math.random();
        window.filesystemPendingOps[callbackId] = {
            type: 'delete',
            path: path
        };
        
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        var luaCode = 'local success = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.DeleteFile(' + pathJson + '); local resultJson = util.TableToJSON({result=success ~= false}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:false};}window.filesystemCallback(\'' + callbackId + '\',result);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        } else {
            if (callback) callback(false);
            return;
        }
        
        // Fallback timeout - call callback if no response
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId](false);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 1500);
        }
    },
    
    renameFile: function(oldPath, newName, callback) {
        var oldPathJson = JSON.stringify(oldPath);
        var newNameJson = JSON.stringify(newName);
        var callbackId = 'rename_' + Date.now() + '_' + Math.random();
        var normalizedOldPath = String(oldPath || '');
        var renamedPath = normalizedOldPath;
        var renameSlashIndex = normalizedOldPath.lastIndexOf('/');
        if (renameSlashIndex >= 0) {
            renamedPath = normalizedOldPath.substring(0, renameSlashIndex + 1) + String(newName || '');
        }
        window.filesystemPendingOps[callbackId] = {
            type: 'rename',
            path: oldPath,
            newPath: renamedPath
        };
        
        if (callback) {
            window.filesystemCallbacks[callbackId] = callback;
        }
        
        var luaCode = 'local success, newPath = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RenameFile(' + oldPathJson + ', ' + newNameJson + '); local resultJson = util.TableToJSON({result=success ~= false, newPath=newPath}); if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then local escapedJson = resultJson or "null"; escapedJson = string.gsub(escapedJson, "\\\\", "\\\\\\\\"); escapedJson = string.gsub(escapedJson, "\\"", "\\\\\\""); escapedJson = string.gsub(escapedJson, "\\n", "\\\\n"); escapedJson = string.gsub(escapedJson, "\\r", "\\\\r"); escapedJson = string.gsub(escapedJson, "\'", "\\\\\'"); local jsCode = "try{if(window.filesystemCallback){var result=null;try{var jsonStr=\\"" .. escapedJson .. "\\";result=JSON.parse(jsonStr);}catch(e){console.error(\\"JSON parse error:\\",e);result={result:false,newPath:null};}window.filesystemCallback(\'' + callbackId + '\',result.result,result.newPath);}else{console.error(\\"window.filesystemCallback not found!\\");}}catch(e){console.error(\\"filesystem.callback JS error:\\",e);}"; HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode); end';
        
        if (typeof console !== 'undefined' && console.lua_exec) {
            console.lua_exec(luaCode);
        } else {
            if (callback) callback(false, null);
            return;
        }
        
        // Fallback timeout - call callback if no response
        if (callback) {
            setTimeout(function() {
                if (window.filesystemCallbacks && window.filesystemCallbacks[callbackId]) {
                    window.filesystemCallbacks[callbackId](false, null);
                    delete window.filesystemCallbacks[callbackId];
                }
            }, 1500);
        }
    }
};

]]
end

-- Helper: Sanitize filename using shared utilities
-- New system: .txt for plain text, .shortcut.dat for shortcuts, .dat for config
local function sanitizeFilename(name, fileType, content)
    if not name then
        name = "untitled"
        fileType = fileType or "text"
    end
    
    -- Special handling for config
    if name == "config" or name == ".config" or name == "config.dat" then
        return UTILS.SanitizeFilename("config", "config")
    end
    
    -- Detect file type if not provided
    if not fileType then
        local lowerName = string.lower(name)
        if string.match(lowerName, "%.image%.dat$") or string.match(lowerName, "%.image$") then
            fileType = "image"
        elseif (string.match(lowerName, "%.png$") or string.match(lowerName, "%.jpg$") or string.match(lowerName, "%.jpeg$")) and string.StartWith(tostring(content or ""), "data:image/") then
            fileType = "image"
        elseif string.match(name, "%.shortcut") or string.match(name, "_shortcut") then
            fileType = "shortcut"
        elseif UTILS.ALLOWED_EXTENSIONS[string.match(string.lower(name), "(%.[a-z0-9]+)$") or ""] then
            fileType = "passthrough"
        else
            fileType = "text"
        end
    end
    
    return UTILS.SanitizeFilename(name, fileType)
end

-- Helper: Parse file content - only parse JSON for .dat files (shortcuts, config)
-- For .txt files, return content as-is (plain text)
local function parseFileContent(content, filename)
    if not content or content == "" then
        return ""
    end
    
    -- Determine if this is a JSON file based on filename
    if filename and UTILS.IsJSONFile(filename) then
        -- This is a .dat file (shortcut or config), parse as JSON
        local success, data = pcall(util.JSONToTable, content)
        if success and data then
            return data
        else
            -- JSON parse failed
            print("[Filesystem] Failed to parse JSON for: " .. tostring(filename))
            return {}
        end
    else
        -- This is a .txt file, return plain text content
        return content
    end
end

-- Helper: Create file content based on file type
-- .txt files: plain text (no JSON wrapper)
-- .dat files: JSON
local function createFileContent(name, content, fileType)
    if fileType == "shortcut" then
        -- Shortcuts are always JSON
        if type(content) == "string" then
            -- Content from JavaScript is already a JSON string
            -- When JavaScript does JSON.stringify on a JSON string, it double-encodes it
            -- But when received by Lua via the bridge, it's already the correct JSON string
            return content
        else
            -- If it's a table (from Lua), convert to JSON
            return util.TableToJSON(content)
        end
    elseif fileType == "config" then
        -- Config is always JSON
        if type(content) == "string" then
            -- Content from JavaScript is already a JSON string
            return content
        else
            -- If it's a table (from Lua), convert to JSON
            return util.TableToJSON(content)
        end
    elseif fileType == "image" then
        local displayName = tostring(name or "image")
        displayName = string.gsub(displayName, "%.image%.dat$", "")
        displayName = string.gsub(displayName, "%.image$", "")
        displayName = string.gsub(displayName, "%.(png|jpg|jpeg)$", "")
        displayName = displayName .. ".image"

        if type(content) == "string" then
            local parsed = util.JSONToTable(content)
            if istable(parsed) and parsed.content then
                parsed.filename = displayName
                return util.TableToJSON(parsed)
            end

            return util.TableToJSON({
                filename = displayName,
                content = content
            })
        else
            if istable(content) and not content.filename then
                content.filename = displayName
            end
            return util.TableToJSON(content)
        end
    else
        -- Text files are plain text (no wrapper)
        return content
    end
end

local function IsSystemFolderPart(part)
    return part == ".system" or part == "system"
end

local function IsTrashPathParts(parts)
    return istable(parts) and #parts >= 2 and IsSystemFolderPart(parts[1]) and parts[2] == "trash"
end

local function SplitFilenameForCollision(name)
    local filename = tostring(name or "untitled")

    if string.match(string.lower(filename), "%.shortcut%.dat$") then
        return string.gsub(filename, "%.shortcut%.dat$", ""), ".shortcut.dat"
    end

    local extension = string.match(filename, "(%.[^%.]+)$")
    if extension then
        return string.sub(filename, 1, #filename - #extension), extension
    end

    return filename, ""
end

local function ResolveTrashFilenameCollision(current, filename)
    if not istable(current) or not current[filename] then
        return filename
    end

    local baseName, extension = SplitFilenameForCollision(filename)
    local index = 1
    local candidate = filename

    while current[candidate] do
        candidate = string.format("%s_%d%s", baseName, index, extension)
        index = index + 1
    end

    return candidate
end

local function IsProgramsPathParts(parts)
    return istable(parts) and #parts >= 2 and IsSystemFolderPart(parts[1]) and parts[2] == "programs"
end

local function GetSystemFolderTable(files)
    if not istable(files) then
        return nil
    end

    return files[".system"] or files.system
end

-- Handle filesystem operations (called from HTML via Lua bridge)
function FILESYSTEM.WriteFile(path, content)
    if not IsValid(HALOARMORY.COMPUTER.INTERFACE.entity) then 
        return false
    end
    
    -- Use shared utility to parse and validate path
    local drive, filepath, err = UTILS.ParsePath(path)
    if not drive then 
        print("[Filesystem] WriteFile failed: " .. (err or "Invalid path"))
        return false
    end
    
    if drive == "C" or drive == "C:" then
        -- Save to entity filesystem (C:/ drive)
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not ent.PC_Files then
            ent.PC_Files = {}
        end
        
        -- Parse path into parts
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        if #parts == 0 then
            print("[Filesystem] WriteFile failed: Empty filepath")
            return false
        end

        if IsSystemFolderPart(parts[1]) and not IsTrashPathParts(parts) then
            print("[Filesystem] WriteFile failed: Cannot write to protected system folders")
            return false
        end

        local current = ent.PC_Files
        
        -- Create parent directories
        for i = 1, #parts - 1 do
            local part = parts[i]
            if part ~= "" then
                if not current[part] then
                    current[part] = { type = "directory" }
                end
                current = current[part]
            end
        end
        
        -- Determine file type from original name
        local originalName = parts[#parts] or "untitled"
        local fileType = "text" -- Default to text
        
        local lowerOriginalName = string.lower(originalName)

        if string.match(lowerOriginalName, "%.image%.dat$") or string.match(lowerOriginalName, "%.image$") then
            fileType = "image"
        elseif (string.match(lowerOriginalName, "%.png$") or string.match(lowerOriginalName, "%.jpg$") or string.match(lowerOriginalName, "%.jpeg$")) and string.StartWith(tostring(content or ""), "data:image/") then
            fileType = "image"
        elseif string.match(originalName, "%.shortcut") or string.match(originalName, "_shortcut") then
            fileType = "shortcut"
        elseif originalName == "config" or originalName == ".config" or originalName == "config.dat" then
            fileType = "config"
        elseif UTILS.ALLOWED_EXTENSIONS[string.match(lowerOriginalName, "(%.[a-z0-9]+)$") or ""] then
            fileType = "passthrough"
        end
        
        -- Sanitize filename with correct extension
        local filename = sanitizeFilename(originalName, fileType, content)

        if IsTrashPathParts(parts) and current[filename] then
            filename = ResolveTrashFilenameCollision(current, filename)
        end
        
        -- Create file content based on type
        -- .txt files: plain text (no JSON wrapper)
        -- .dat files (shortcuts, config): JSON
        local fileContent = createFileContent(originalName, content, fileType)
        
        -- Mark config.dat as protected
        local isProtected = (fileType == "config")
        
        -- Store in entity filesystem
        current[filename] = {
            type = "file",
            content = fileContent,
            readOnly = isProtected,
            protected = isProtected
        }
        
        -- Rebuild full path with sanitized filename for network sync
        local sanitizedPath = drive .. ":"
        for i = 1, #parts - 1 do
            if parts[i] ~= "" then
                sanitizedPath = sanitizedPath .. "/" .. parts[i]
            end
        end
        sanitizedPath = sanitizedPath .. "/" .. filename
        
        -- Send to server to update server's virtual filesystem and persistent storage
        -- Only if PC_ID is set will it persist to disk on server
        if HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.SaveFileToServer then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.SaveFileToServer(ent:EntIndex(), sanitizedPath, fileContent)
        end
    elseif drive == "ExternalDrive" then
        -- Save to local player storage (CLIENT-SIDE ONLY, NO NETWORK)
        local localPath = string.gsub(filepath, "^/", "")
        
        -- Determine file type and sanitize filename
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            table.insert(parts, part)
        end
        
        if #parts == 0 then
            print("[Filesystem] WriteFile failed: Empty filepath for ExternalDrive")
            return false
        end
        
        local originalName = parts[#parts]
        local fileType = "text"
        
        local lowerOriginalName = string.lower(originalName)

        if string.match(lowerOriginalName, "%.image%.dat$") or string.match(lowerOriginalName, "%.image$") then
            fileType = "image"
        elseif (string.match(lowerOriginalName, "%.png$") or string.match(lowerOriginalName, "%.jpg$") or string.match(lowerOriginalName, "%.jpeg$")) and string.StartWith(tostring(content or ""), "data:image/") then
            fileType = "image"
        elseif string.match(originalName, "%.shortcut") then
            fileType = "shortcut"
        elseif originalName == "config" or originalName == ".config" then
            fileType = "config"
        elseif UTILS.ALLOWED_EXTENSIONS[string.match(lowerOriginalName, "(%.[a-z0-9]+)$") or ""] then
            fileType = "passthrough"
        end
        
        -- Sanitize filename
        local filename = sanitizeFilename(originalName, fileType, content)
        
        -- Rebuild path with sanitized filename
        local sanitizedLocalPath = ""
        for i = 1, #parts - 1 do
            sanitizedLocalPath = sanitizedLocalPath .. parts[i] .. "/"
        end
        sanitizedLocalPath = sanitizedLocalPath .. filename
        
        local fullPath = HALOARMORY.COMPUTER.LocalPC .. sanitizedLocalPath
        
        -- Create directory if needed
        local dirPath = string.match(fullPath, "(.+)/")
        if dirPath and not file.IsDir(dirPath, "DATA") then
            file.CreateDir(dirPath)
        end
        
        -- Create content based on file type
        local fileContent = createFileContent(originalName, content, fileType)
        
        -- Write to local storage (NO NETWORK - stays on client)
        file.Write(fullPath, fileContent)
        return true
    end
    
    return true
end

function FILESYSTEM.ReadFile(path)
    -- Use shared utility to parse and validate path
    local drive, filepath, err = UTILS.ParsePath(path)
    if not drive then 
        print("[Filesystem] ReadFile failed: " .. (err or "Invalid path"))
        return nil 
    end
    
    if drive == "C" or drive == "C:" then
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not IsValid(ent) then 
            return nil 
        end
        
        -- Initialize PC_Files if it doesn't exist (client-side fallback)
        if not ent.PC_Files then
            ent.PC_Files = {}
        end
        
        -- Parse path
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        local current = ent.PC_Files
        
        for i = 1, #parts do
            local part = parts[i]
            if part ~= "" then
                if not current or not current[part] then 
                    return nil 
                end
                current = current[part]
            end
        end
        
        if current.type == "file" then
            local content = current.content or ""
            -- Return raw content (plain text for .txt, JSON for .dat)
            -- Programs are responsible for parsing JSON if needed
            return content
        end
        return nil
    elseif drive == "ExternalDrive" then
        -- Read from local player storage (CLIENT-SIDE ONLY, NO NETWORK)
        local localPath = string.gsub(filepath, "^/", "")
        local fullPath = HALOARMORY.COMPUTER.LocalPC .. localPath
        
        if file.Exists(fullPath, "DATA") then
            return file.Read(fullPath, "DATA")
        end
        return nil
    end
    
    return nil
end

function FILESYSTEM.ListDirectory(path)
    -- Use shared utility to parse and validate path
    local drive, filepath, err = UTILS.ParsePath(path)
    if not drive then 
        print("[Filesystem] ListDirectory failed: " .. (err or "Invalid path"))
        return {} 
    end
    
    local files = {}
    local current = nil
    
    -- Check for C: drive (drive will be "C" from the pattern match)
    if drive == "C" or drive == "C:" then
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not IsValid(ent) then 
            return files 
        end
        
        local entIndex = ent:EntIndex()
        
        -- Fallback: if interface entity doesn't have PC_Files, try getting it from Entity() lookup
        if not ent.PC_Files then
            local fallbackEnt = Entity(entIndex)
            if IsValid(fallbackEnt) and fallbackEnt.PC_Files then
                ent.PC_Files = fallbackEnt.PC_Files
                HALOARMORY.COMPUTER.INTERFACE.entity.PC_Files = fallbackEnt.PC_Files
            end
        end
        
        -- PC_Files should be synced from server, but initialize empty if not available yet
        if not ent.PC_Files then
            ent.PC_Files = {}
        end
        
        -- Parse path
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        current = ent.PC_Files
        local navigateStart = 1
        
        -- Virtual .system root
        if #parts == 1 and parts[1] == ".system" then
            current = GetSystemFolderTable(ent.PC_Files) or { type = "directory" }
            navigateStart = 2
        end

        -- Check if navigating into .system/programs folder (virtual)
        if (#parts == 2 and parts[1] == ".system" and parts[2] == "programs") or
           (#parts == 1 and parts[1] == "programs") then
            -- We're in the programs folder - show virtual programs
            local PROGRAMS = HALOARMORY.COMPUTER.INTERFACE.PROGRAMS
            if PROGRAMS and PROGRAMS.GetAll then
                for programId, program in pairs(PROGRAMS.GetAll()) do
                    table.insert(files, {
                        name = programId .. ".exe",
                        type = "file",
                        fileType = "program",
                        programId = programId,
                        folder = (programId == "externaldrive") and "ExternalDrive:/" or nil,
                        displayName = program.title or programId,
                        icon = program.icon or "📄",
                        readOnly = true
                    })
                end
            end
            return files
        end
        
        for i = navigateStart, #parts do
            local part = parts[i]
            if part ~= "" then
                -- Skip programs folder in navigation (it's virtual, inside system folder)
                if part == "programs" then
                    -- This shouldn't happen if we handled it above, but handle it anyway
                    return files
                end
                if IsSystemFolderPart(part) then
                    current = GetSystemFolderTable(current)
                else
                    current = current and current[part]
                end
                if not current then return files end
            end
        end
        
        -- Normal directory listing
        -- Track manually added folders to prevent duplicates
        local addedFolders = {}
        
        -- Add virtual .system folder at root
        if #parts == 0 then
            table.insert(files, {
                name = ".system",
                type = "directory",
                virtual = true,
                readOnly = true,
                protected = true
            })
            addedFolders[".system"] = true
        end

        -- Only add virtual "programs" folder if we're inside .system folder
        if #parts == 1 and parts[1] == ".system" then
            table.insert(files, {
                name = "programs",
                type = "directory",
                virtual = true,
                readOnly = true,
                protected = true
            })
            addedFolders["programs"] = true
        end
        
        for name, data in pairs(current) do
            -- Skip if we already manually added this folder
            if addedFolders[name] then
            elseif data.type == "directory" then
                table.insert(files, {
                    name = name,
                    type = "directory",
                    icon = (name == "trash") and utf8.char(0x1F5D1, 0xFE0F) or nil,
                    readOnly = (name == "trash") and true or false,
                    protected = (name == "trash") and true or false
                })
            elseif data.type == "file" then
                -- NEW SYSTEM: Detect file type by extension
                -- .txt = plain text (no JSON), .shortcut.dat = shortcut (JSON), config.dat = config (JSON)
                local isShortcut = string.match(name, "%.shortcut%.dat$")
                local isConfig = (name == "config.dat")
                local fileData = nil
                local fileType = UTILS.GetFileType(name)
                
                -- Get display name using shared utility
                local displayName = UTILS.GetDisplayName(name)
                
                -- Parse JSON content only for .dat files (shortcuts, config)
                if UTILS.IsJSONFile(name) then
                    fileData = parseFileContent(data.content or "", name)
                end
                
                -- For shortcuts, get program info from JSON
                local programId = nil
                local folder = nil
                local icon = nil
                local isTrash = false
                
                if fileType == "shortcut" and fileData then
                    -- Extract shortcut metadata from JSON
                    programId = fileData.program
                    folder = fileData.folder
                    icon = fileData.icon
                    isTrash = fileData.isTrash or false
                    
                    -- Override display name if shortcut has a custom name
                    if fileData.filename then
                        displayName = fileData.filename
                    end

                    local normalizedFolder = string.lower(tostring(folder or ""))
                    local isExternalDriveShortcut = (programId == "filebrowser" and normalizedFolder == "externaldrive:/") or
                        (programId == "externaldrive") or
                        (string.lower(name) == "externaldrive.shortcut.dat")

                    if isExternalDriveShortcut then
                        icon = "💽"
                    end
                    
                    -- If no icon specified, try to get it from the program registry
                    if not icon and programId then
                        local PROGRAMS = HALOARMORY.COMPUTER.INTERFACE.PROGRAMS
                        if PROGRAMS and PROGRAMS.GetAll then
                            local program = PROGRAMS.GetAll()[programId]
                            if program and program.icon then
                                icon = program.icon
                            end
                        end
                    end
                elseif fileType == "image" and fileData then
                    if fileData.filename then
                        displayName = fileData.filename
                    end
                elseif fileType == "config" then
                    -- config.dat file opens Settings when double-clicked
                    programId = "settings"
                    icon = utf8.char(0x2699, 0xFE0F)
                end
                
                table.insert(files, {
                    name = name,
                    type = "file",
                    fileType = fileType,
                    displayName = displayName,
                    programId = programId,
                    folder = folder,
                    icon = icon or (isConfig and utf8.char(0x2699, 0xFE0F) or (isTrash and utf8.char(0x1F5D1, 0xFE0F) or (fileType == "shortcut" and utf8.char(0x1F517) or (fileType == "program" and utf8.char(0x2699, 0xFE0F) or utf8.char(0x1F4C4))))),
                    isTrash = isTrash,
                    readOnly = data.readOnly or false,
                    protected = data.protected or false
                })
            end
        end
    elseif drive == "ExternalDrive" then
        local localPath = string.gsub(filepath, "^/", "")
        local fullPath = HALOARMORY.COMPUTER.LocalPC .. localPath
        
        if file.IsDir(fullPath, "DATA") then
            local fileList, dirList = file.Find(fullPath .. "*", "DATA")

            for _, name in ipairs(fileList or {}) do
                local filePath = fullPath .. name
                local isDir = file.IsDir(filePath, "DATA")
                
                if not isDir then
                    -- Get file type and display name for files
                    local fileType = UTILS.GetFileType(name)
                    local displayName = UTILS.GetDisplayName(name)

                    if fileType == "image" then
                        local fileContent = file.Read(filePath, "DATA")
                        local fileData = parseFileContent(fileContent or "", name)
                        if istable(fileData) and fileData.filename and fileData.filename ~= "" then
                            displayName = tostring(fileData.filename)
                        end
                    end
                    
                    table.insert(files, {
                        name = name,
                        type = "file",
                        fileType = fileType,
                        displayName = displayName
                    })
                end
            end

            for _, name in ipairs(dirList or {}) do
                table.insert(files, {
                    name = name,
                    type = "directory"
                })
            end
        end
    end
    
    return files
end

local function DeleteLocalPathRecursive(path)
    if not path or path == "" then
        return false
    end

    if file.IsDir(path, "DATA") then
        local normalized = string.match(path, "/$") and path or (path .. "/")
        local files, dirs = file.Find(normalized .. "*", "DATA")

        for _, fileName in ipairs(files or {}) do
            file.Delete(normalized .. fileName)
        end

        for _, dirName in ipairs(dirs or {}) do
            DeleteLocalPathRecursive(normalized .. dirName)
        end

        file.Delete(string.gsub(normalized, "/$", ""))
        return true
    end

    if not file.Exists(path, "DATA") then
        return false
    end

    file.Delete(path)
    return true
end

local function CopyLocalPathRecursive(sourcePath, targetPath)
    if file.Exists(sourcePath, "DATA") then
        local content = file.Read(sourcePath, "DATA")
        if content == nil then
            return false
        end
        file.Write(targetPath, content)
        return true
    end

    if not file.IsDir(sourcePath, "DATA") then
        return false
    end

    file.CreateDir(targetPath)

    local normalizedSource = string.match(sourcePath, "/$") and sourcePath or (sourcePath .. "/")
    local normalizedTarget = string.match(targetPath, "/$") and targetPath or (targetPath .. "/")
    local files, dirs = file.Find(normalizedSource .. "*", "DATA")

    for _, fileName in ipairs(files or {}) do
        local content = file.Read(normalizedSource .. fileName, "DATA")
        if content ~= nil then
            file.Write(normalizedTarget .. fileName, content)
        end
    end

    for _, dirName in ipairs(dirs or {}) do
        CopyLocalPathRecursive(normalizedSource .. dirName, normalizedTarget .. dirName)
    end

    return true
end

function FILESYSTEM.CreateDirectory(path)
    local drive, filepath, err = UTILS.ParsePath(path)
    if not drive then
        print("[Filesystem] CreateDirectory failed: " .. (err or "Invalid path"))
        return false
    end

    filepath = string.gsub(filepath, "/+$", "")
    local parts = {}
    for part in string.gmatch(filepath, "([^/]+)") do
        if part ~= "" then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return false
    end

    if IsSystemFolderPart(parts[1]) and not IsTrashPathParts(parts) then
        return false
    end

    if drive == "C" or drive == "C:" then
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not IsValid(ent) then
            return false
        end

        if not ent.PC_Files then
            ent.PC_Files = {}
        end

        local current = ent.PC_Files
        for i = 1, #parts do
            local part = parts[i]
            if not current[part] then
                current[part] = { type = "directory" }
            end
            current = current[part]
        end

        if HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.CreateDirectoryOnServer then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.CreateDirectoryOnServer(ent:EntIndex(), drive .. ":" .. filepath)
        end
        return true
    elseif drive == "ExternalDrive" then
        local localPath = HALOARMORY.COMPUTER.LocalPC .. string.gsub(filepath, "^/", "")
        if not file.IsDir(localPath, "DATA") then
            file.CreateDir(localPath)
        end
        return true
    end

    return false
end

function FILESYSTEM.DeleteFile(path)
    -- Use shared utility to parse and validate path
    local drive, filepath, err = UTILS.ParsePath(path)
    if not drive then 
        print("[Filesystem] DeleteFile failed: " .. (err or "Invalid path"))
        return false 
    end
    
    if drive == "C" or drive == "C:" then
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not IsValid(ent) or not ent.PC_Files then 
            return false 
        end
        
        -- Remove trailing slash if present (for directories)
        filepath = string.gsub(filepath, "/+$", "")
        
        -- Parse path
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        -- Cannot delete from reserved virtual folders
        if (#parts > 0 and parts[1] == "programs") or IsProgramsPathParts(parts) then
            return false
        end
        
        -- Cannot delete desktop or .system folder itself
        if (#parts == 1 and (parts[1] == "desktop" or IsSystemFolderPart(parts[1]))) then
            return false
        end
        if (#parts == 2 and IsSystemFolderPart(parts[1]) and (parts[2] == "programs" or parts[2] == "trash")) then
            return false
        end
        
        local current = ent.PC_Files
        local parent = nil
        local targetName = parts[#parts]
        
        -- Cannot delete config.dat file (protected)
        if targetName == "config.dat" then
            return false
        end
        
        for i = 1, #parts - 1 do
            local part = parts[i]
            if part ~= "" then
                parent = current
                if not current or not current[part] then
                    return false
                end
                current = current[part]
            end
        end
        
        if current and current[targetName] then
            local isShortcut = string.match(targetName, "%.shortcut%.dat$") ~= nil
            -- Check if it's read-only (programs) or protected (config.dat)
            if not isShortcut and (current[targetName].readOnly or current[targetName].protected) then
                return false
            end
            current[targetName] = nil
            
            -- Always send to server to update server's virtual filesystem
            -- Server will handle saving to persistent storage if PC_ID is set
            if HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.DeleteFileOnServer then
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.DeleteFileOnServer(ent:EntIndex(), path)
            end
            
            return true
        end
        return false
    elseif drive == "ExternalDrive" then
        local localPath = string.gsub(filepath, "^/", "")
        local fullPath = HALOARMORY.COMPUTER.LocalPC .. localPath
        
        return DeleteLocalPathRecursive(fullPath)
    end
    
    return false
end

--- Rename a file or directory
-- @param oldPath string The current full path of the item
-- @param newName string The new name (not full path, just the name)
-- @return boolean success True if renamed successfully
-- @return string|nil newPath The new full path if successful
function FILESYSTEM.RenameFile(oldPath, newName)
    -- Use shared utility to parse and validate path
    local drive, filepath, err = UTILS.ParsePath(oldPath)
    if not drive then 
        print("[Filesystem] RenameFile failed: " .. (err or "Invalid path"))
        return false, nil
    end
    
    if not newName or newName == "" then
        print("[Filesystem] RenameFile failed: empty new name")
        return false, nil
    end
    
    local isDirectoryPath = string.match(filepath, "/$") ~= nil
    -- Sanitize new name
    local fileType = isDirectoryPath and "directory" or UTILS.GetFileType(oldPath)
    newName = UTILS.SanitizeFilename(newName, fileType)
    
    if drive == "C" or drive == "C:" then
        local ent = HALOARMORY.COMPUTER.INTERFACE.entity
        if not IsValid(ent) or not ent.PC_Files then 
            return false, nil
        end
        
        -- Parse path
        filepath = string.gsub(filepath, "/+$", "")
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        -- Get current name and check if it's the same
        local oldName = parts[#parts]
        if #parts == 0 then
            return false, nil
        end

        if #parts == 1 and (oldName == "desktop" or IsSystemFolderPart(oldName)) then
            return false, nil
        end

        if IsSystemFolderPart(parts[1]) then
            return false, nil
        end

        if oldName == newName then
            -- No change needed
            return true, oldPath
        end
        
        -- Navigate to parent
        local current = ent.PC_Files
        local parent = nil
        
        for i = 1, #parts - 1 do
            local part = parts[i]
            if part ~= "" then
                parent = current
                if not current or not current[part] then
                    return false, nil
                end
                current = current[part]
            end
        end
        
        -- Check if item exists
        if not current or not current[oldName] then
            return false, nil
        end
        
        -- Check if protected
        local isShortcut = string.match(oldName, "%.shortcut%.dat$") ~= nil
        if not isShortcut and (current[oldName].readOnly or current[oldName].protected) then
            print("[Filesystem] Cannot rename protected item")
            return false, nil
        end
        
        -- Check if new name already exists
        if current[newName] then
            print("[Filesystem] Item with new name already exists")
            return false, nil
        end
        
        -- Perform rename
        current[newName] = current[oldName]
        current[oldName] = nil
        
        -- Build new path
        parts[#parts] = newName
        local newFilepath = "/" .. table.concat(parts, "/")
        local newPath = drive .. ":" .. newFilepath
        
        -- Add trailing slash if it's a directory
        if current[newName].type == "directory" then
            newPath = newPath .. "/"
        end
        
        -- Always send to server to update server's virtual filesystem
        if HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.RenameFileOnServer then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.RenameFileOnServer(ent:EntIndex(), oldPath, newName)
        end
        
        return true, newPath
    elseif drive == "ExternalDrive" then
        -- Remove trailing slash if present
        filepath = string.gsub(filepath, "/+$", "")
        
        -- Parse path to get parent directory and old filename
        local parts = {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end
        
        if #parts == 0 then
            print("[Filesystem] RenameFile failed: Empty filepath for ExternalDrive")
            return false, nil
        end
        
        local oldName = parts[#parts]
        
        -- Check if old name matches new name (already sanitized)
        if oldName == newName then
            -- No change needed
            return true, oldPath
        end
        
        -- Build parent directory path
        local parentParts = {}
        for i = 1, #parts - 1 do
            table.insert(parentParts, parts[i])
        end
        
        local parentPath = ""
        if #parentParts > 0 then
            parentPath = table.concat(parentParts, "/") .. "/"
        end
        
        -- Build full paths
        local oldFullPath = HALOARMORY.COMPUTER.LocalPC .. parentPath .. oldName
        local newFullPath = HALOARMORY.COMPUTER.LocalPC .. parentPath .. newName
        
        if file.IsDir(oldFullPath, "DATA") then
            if file.IsDir(newFullPath, "DATA") or file.Exists(newFullPath, "DATA") then
                return false, nil
            end
            if not CopyLocalPathRecursive(oldFullPath, newFullPath) then
                return false, nil
            end
            DeleteLocalPathRecursive(oldFullPath)
        else
            -- Check if old file exists
            if not file.Exists(oldFullPath, "DATA") then
                print("[Filesystem] RenameFile failed: Old file does not exist: " .. oldFullPath)
                return false, nil
            end

            -- Check if new file already exists
            if file.Exists(newFullPath, "DATA") then
                print("[Filesystem] RenameFile failed: New file already exists: " .. newFullPath)
                return false, nil
            end

            -- Read old file content
            local content = file.Read(oldFullPath, "DATA")
            if not content then
                print("[Filesystem] RenameFile failed: Could not read old file")
                return false, nil
            end

            -- Write to new path
            file.Write(newFullPath, content)

            -- Delete old file
            file.Delete(oldFullPath)
        end
        
        -- Build new path
        local newFilepath = "/" .. parentPath .. newName
        local newPath = drive .. ":" .. newFilepath
        
        return true, newPath
    end
    
    return false, nil
end

return FILESYSTEM

