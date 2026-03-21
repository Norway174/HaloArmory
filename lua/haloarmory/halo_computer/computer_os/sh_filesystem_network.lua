-- Shared Filesystem Network Messages
HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}
HALOARMORY.COMPUTER.INTERFACE.NETWORK = HALOARMORY.COMPUTER.INTERFACE.NETWORK or {}

local NET_NAME = "HALOARMORY.COMPUTER.FILESYSTEM"
local CanPlayerReachEntity
local CanPlayerUseEntity
local EnsureFilesystemReady
local ParseFileContent
local ReadVirtualFile
local BuildListEntry
local ListVirtualDirectory
local SendActionResponse
local SendPCFilesSync

local MAX_SYNC_CHUNK_SIZE = 60000

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

local function NormalizeSystemFolderKeys(files)
    if not istable(files) then
        return files
    end

    if istable(files.system) then
        if not istable(files[".system"]) then
            files[".system"] = files.system
        elseif files[".system"] ~= files.system then
            for name, value in pairs(files.system) do
                if files[".system"][name] == nil then
                    files[".system"][name] = value
                end
            end
        end
        files.system = nil
    end

    return files
end

if SERVER then
    util.AddNetworkString(NET_NAME)
end

-- Network action constants
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_SAVE_FILE = 1
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_READ_FILE = 2
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_LIST_DIR = 3
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_CREATE_DIR = 4
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_DELETE_FILE = 5
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_REQUEST_PC_FILES = 6
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_FILES_CHANGED = 7
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_SYNC_PC_FILES = 8
HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_RENAME_FILE = 9

if SERVER then
    local scriptPath = HALOARMORY.GetOwnScriptPath()
    local UTILS = HALOARMORY.COMPUTER.FILESYSTEM_UTILS or include(scriptPath .. "sh_filesystem_utils.lua")
    local MAX_COMPUTER_USE_DISTANCE_SQR = 400 * 400

    
    -- Track players with interface open for each entity
    HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers = HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers or {}

    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.IsPlayerRegistered(ent, ply)
        if not IsValid(ent) or not IsValid(ply) then return false end

        local entIndex = ent:EntIndex()
        local connectedPlayers = HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex]

        return connectedPlayers and connectedPlayers[ply] == true or false
    end

    CanPlayerReachEntity = function(ply, ent)
        if not IsValid(ply) or not ply:IsPlayer() or not IsValid(ent) then return false end

        if HALOARMORY.COMPUTER.INTERFACE.NETWORK.IsPlayerRegistered(ent, ply) then
            return true
        end

        return ent:GetPos():DistToSqr(ply:GetPos()) <= MAX_COMPUTER_USE_DISTANCE_SQR
    end

    CanPlayerUseEntity = function(ply, ent, requireRegistered)
        if not IsValid(ply) or not ply:IsPlayer() or not IsValid(ent) or not ent.IsHALOARMORY then
            return false
        end

        if requireRegistered then
            return HALOARMORY.COMPUTER.INTERFACE.NETWORK.IsPlayerRegistered(ent, ply)
        end

        return CanPlayerReachEntity(ply, ent)
    end

    EnsureFilesystemReady = function(ent)
        local pc_id = ent:GetPC_ID()
        if pc_id and pc_id ~= "" then
            if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
            end
        elseif not ent.PC_Files or table.Count(ent.PC_Files) == 0 then
            if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
                HALOARMORY.COMPUTER.InitializeFiles(ent)
            else
                ent.PC_Files = ent.PC_Files or {}
            end
        end

        ent.PC_Files = ent.PC_Files or {}

        if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.EnsureRequiredFolders then
            HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.EnsureRequiredFolders(ent.PC_Files)
        end

        return pc_id
    end

    ParseFileContent = function(content, filename)
        if not content or not filename or not UTILS.IsJSONFile(filename) then
            return nil
        end

        local success, data = pcall(util.JSONToTable, content)
        if success and istable(data) then
            return data
        end

        return nil
    end

    ReadVirtualFile = function(ent, path)
        local drive, filepath = UTILS.ParsePath(path)
        if not drive or (drive ~= "C" and drive ~= "C:") then
            return nil
        end

        local current = ent.PC_Files or {}
        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                current = current and current[part]
                if not current then
                    return nil
                end
            end
        end

        if istable(current) and current.type == "file" then
            return current.content
        end

        return nil
    end

    BuildListEntry = function(name, data)
        if not istable(data) then
            return nil
        end

        if data.type == "directory" then
            return {
                name = name,
                type = "directory",
                icon = (name == "trash") and utf8.char(0x1F5D1, 0xFE0F) or nil,
                readOnly = (name == "trash") and true or false,
                protected = (name == "trash") and true or false
            }
        end

        if data.type ~= "file" then
            return nil
        end

        local fileType = UTILS.GetFileType(name)
        local entry = {
            name = name,
            type = "file",
            fileType = fileType,
            displayName = UTILS.GetDisplayName(name),
            readOnly = data.readOnly or false,
            protected = data.protected or false
        }

        local fileData = ParseFileContent(data.content, name)
        if fileType == "shortcut" and fileData then
            entry.programId = fileData.program
            entry.folder = fileData.folder
            entry.icon = fileData.icon
            entry.isTrash = fileData.isTrash or false

            if fileData.filename then
                entry.displayName = fileData.filename
            end

            local normalizedFolder = string.lower(tostring(entry.folder or ""))
            local isExternalDriveShortcut = (entry.programId == "filebrowser" and normalizedFolder == "externaldrive:/") or
                (entry.programId == "externaldrive") or
                (string.lower(name) == "externaldrive.shortcut.dat")

            if isExternalDriveShortcut then
                entry.icon = "💽"
            end
        elseif fileType == "image" and fileData then
            if fileData.filename and fileData.filename ~= "" then
                entry.displayName = tostring(fileData.filename)
            end
        elseif fileType == "config" then
            entry.programId = "settings"
            entry.icon = utf8.char(0x2699, 0xFE0F)
        end

        return entry
    end

    ListVirtualDirectory = function(ent, path)
        local drive, filepath = UTILS.ParsePath(path)
        if not drive or (drive ~= "C" and drive ~= "C:") then
            return {}
        end

        local files = {}
        local current = ent.PC_Files or {}
        local parts = {}
        local navigateStart = 1

        for part in string.gmatch(filepath, "([^/]+)") do
            if part ~= "" then
                table.insert(parts, part)
            end
        end

        if (#parts == 2 and IsSystemFolderPart(parts[1]) and parts[2] == "programs") or
           (#parts == 1 and parts[1] == "programs") then
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
                        readOnly = true
                    })
                end
            end
            return files
        end

        if #parts == 1 and IsSystemFolderPart(parts[1]) then
            current = (ent.PC_Files and (ent.PC_Files[".system"] or ent.PC_Files.system)) or { type = "directory" }
            navigateStart = 2
        end

        for i = navigateStart, #parts do
            local part = parts[i]
            if part == "programs" then
                return files
            end

            current = current and current[part]
            if not current then
                return files
            end
        end

        local addedFolders = {}
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

        if #parts == 1 and IsSystemFolderPart(parts[1]) then
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
            if not addedFolders[name] then
                local entry = BuildListEntry(name, data)
                if entry then
                    table.insert(files, entry)
                end
            end
        end

        return files
    end

    SendActionResponse = function(ply, action, entIndex, requestId, payload)
        if not IsValid(ply) then return end

        local payloadJson = util.TableToJSON(payload or {}) or "{}"
        local compressed = util.Compress(payloadJson)
        if not compressed then return end

        net.Start(NET_NAME)
        net.WriteUInt(action, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(requestId or "")
        net.WriteUInt(#compressed, 32)
        net.WriteData(compressed, #compressed)
        net.Send(ply)
    end

    SendPCFilesSync = function(ply, entIndex, pcFiles)
        if not IsValid(ply) then return false end

        local pcFilesJson = util.TableToJSON(pcFiles or {}) or "{}"
        local compressed = util.Compress(pcFilesJson)
        if not compressed then return false end

        local totalLength = #compressed
        local totalChunks = math.max(1, math.ceil(totalLength / MAX_SYNC_CHUNK_SIZE))

        for chunkIndex = 1, totalChunks do
            local startPos = ((chunkIndex - 1) * MAX_SYNC_CHUNK_SIZE) + 1
            local chunkData = string.sub(compressed, startPos, math.min(startPos + MAX_SYNC_CHUNK_SIZE - 1, totalLength))

            net.Start(NET_NAME)
            net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_SYNC_PC_FILES, 8)
            net.WriteUInt(entIndex, 16)
            net.WriteUInt(totalChunks, 16)
            net.WriteUInt(chunkIndex, 16)
            net.WriteUInt(#chunkData, 32)
            net.WriteData(chunkData, #chunkData)
            net.Send(ply)
        end

        return true
    end
    
    -- Function to broadcast PC_Files updates to all connected players
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.BroadcastPCFilesUpdate(ent)
        if not IsValid(ent) then return end
        local entIndex = ent:EntIndex()
        local connectedPlayers = HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex]
        
        if not connectedPlayers or table.Count(connectedPlayers) == 0 then return end
        
        for ply, _ in pairs(connectedPlayers) do
            if IsValid(ply) then
                SendPCFilesSync(ply, entIndex, ent.PC_Files or {})
            end
        end
    end
    
    -- Function to register player as connected to entity
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.RegisterPlayer(ent, ply)
        if not IsValid(ent) or not IsValid(ply) then return end
        local entIndex = ent:EntIndex()
        
        if not HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex] then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex] = {}
        end
        
        HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex][ply] = true
    end
    
    -- Function to unregister player
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.UnregisterPlayer(ent, ply)
        if not IsValid(ent) or not IsValid(ply) then return end
        local entIndex = ent:EntIndex()
        
        if HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex] then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex][ply] = nil
            
            -- Clean up empty tables
            if table.Count(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex]) == 0 then
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex] = nil
            end
        end
    end
    
    -- Function to notify clients about folder changes (lightweight update)
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.NotifyFolderChanged(ent, folderPath)
        if not IsValid(ent) then return end
        local entIndex = ent:EntIndex()
        local connectedPlayers = HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex]
        
        if not connectedPlayers or table.Count(connectedPlayers) == 0 then return end
        
        -- Normalize folder path (ensure it starts with / and ends with /)
        if not string.match(folderPath, "^/") then
            folderPath = "/" .. folderPath
        end
        if not string.match(folderPath, "/$") then
            folderPath = folderPath .. "/"
        end
        
        -- Send lightweight notification
        for ply, _ in pairs(connectedPlayers) do
            if IsValid(ply) then
                net.Start(NET_NAME)
                net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_FILES_CHANGED, 8)
                net.WriteUInt(entIndex, 16)
                net.WriteString(folderPath)
                net.Send(ply)
            end
        end
    end
end

if CLIENT then
    HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_FILES_CHANGED = 7
end

if SERVER then
    -- Receive file save request from client
    net.Receive(NET_NAME, function(len, ply)
        local action = net.ReadUInt(8)
        local entIndex = net.ReadUInt(16)
        local ent = Entity(entIndex)
        
        if not IsValid(ent) or not ent.IsHALOARMORY then return end

        if action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_REQUEST_PC_FILES then
            if not CanPlayerUseEntity(ply, ent, false) then
                return
            end
        elseif not CanPlayerUseEntity(ply, ent, true) then
            return
        end
        
        if action == 1 then -- ACTION_SAVE_FILE
            -- Sync from real filesystem to virtual if PC_ID is set
            local pc_id = ent:GetPC_ID()
            if pc_id and pc_id ~= "" then
                if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
                end
            else
                -- Ensure virtual filesystem is initialized when PC_ID is not set
                if not ent.PC_Files or table.Count(ent.PC_Files) == 0 then
                    if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
                        HALOARMORY.COMPUTER.InitializeFiles(ent)
                    else
                        if not ent.PC_Files then
                            ent.PC_Files = {}
                        end
                    end
                end
            end
            
            local path = net.ReadString()
            local contentLen = net.ReadUInt(32)
            local compressedData = net.ReadData(contentLen)
            
            -- Decompress the content
            local content = util.Decompress(compressedData)
            if not content then
                return
            end
            
            -- Update entity filesystem first
            if not ent.PC_Files then
                ent.PC_Files = {}
            end
            
            -- Parse path and save to entity
            local _, filepath = string.match(path, "^([^:]+):(.+)$")
            
            -- Store original filepath for notification (before processing)
            local originalFilepath = filepath or ""
            if filepath then
                local parts = {}
                for part in string.gmatch(filepath, "([^/]+)") do
                    if part ~= "" then
                        table.insert(parts, part)
                    end
                end

                if IsSystemFolderPart(parts[1]) and not IsTrashPathParts(parts) then
                    return
                end
                
                local current = ent.PC_Files
                -- Navigate through path parts
                for i = 1, #parts - 1 do
                    local part = parts[i]
                    if part ~= "" then
                        if not current[part] then
                            current[part] = { type = "directory" }
                        end
                        current = current[part]
                    end
                end
                
                local filename = parts[#parts] or "untitled"
                if IsTrashPathParts(parts) and current[filename] then
                    filename = ResolveTrashFilenameCollision(current, filename)
                end
                -- Preserve protected flag for config.dat files
                local isProtected = (filename == "config.dat")
                current[filename] = {
                    type = "file",
                    content = content,
                    readOnly = isProtected,
                    protected = isProtected
                }
            end
            
            -- Save to persistent storage if PC_ID is set
            if pc_id and pc_id ~= "" and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage then
                HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage(pc_id, ent.PC_Files)
            end
            
            -- Broadcast update to all connected players
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.BroadcastPCFilesUpdate(ent)
            
            -- Also send a lightweight folder change notification
            -- Extract parent folder from originalFilepath
            if originalFilepath and originalFilepath ~= "" then
                local parts = {}
                for part in string.gmatch(originalFilepath, "([^/]+)") do
                    if part ~= "" then
                        table.insert(parts, part)
                    end
                end
                
                -- Remove the last part (filename) to get parent directory
                local parentPath = "/"
                if #parts > 1 then
                    table.remove(parts)  -- Remove filename
                    parentPath = "/" .. table.concat(parts, "/")
                elseif #parts == 1 then
                    -- Only one part, means file is at root (like "/filename.txt")
                    parentPath = "/"
                end
                
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.NotifyFolderChanged(ent, parentPath)
            end
            
        elseif action == 2 then -- ACTION_READ_FILE
            local requestId = net.ReadString()
            local path = net.ReadString()

            EnsureFilesystemReady(ent)

            local content = ReadVirtualFile(ent, path)
            SendActionResponse(ply, HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_READ_FILE, entIndex, requestId, {
                success = content ~= nil,
                content = content
            })
        elseif action == 3 then -- ACTION_LIST_DIR
            local requestId = net.ReadString()
            local path = net.ReadString()

            EnsureFilesystemReady(ent)

            SendActionResponse(ply, HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_LIST_DIR, entIndex, requestId, {
                success = true,
                files = ListVirtualDirectory(ent, path)
            })
        elseif action == 4 then -- ACTION_CREATE_DIR
            -- Sync from real filesystem to virtual if PC_ID is set
            local pc_id = ent:GetPC_ID()
            if pc_id and pc_id ~= "" then
                if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
                end
            else
                -- Ensure virtual filesystem is initialized when PC_ID is not set
                if not ent.PC_Files or table.Count(ent.PC_Files) == 0 then
                    if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
                        HALOARMORY.COMPUTER.InitializeFiles(ent)
                    else
                        if not ent.PC_Files then
                            ent.PC_Files = {}
                        end
                    end
                end
            end
            
            local path = net.ReadString()
            
            -- Parse path
            local _, filepath = string.match(path, "^([^:]+):(.+)$")
            if not filepath then return end
            
            if not ent.PC_Files then
                ent.PC_Files = {}
            end
            
            -- Parse and create directory structure
            local parts = {}
            for part in string.gmatch(filepath, "([^/]+)") do
                table.insert(parts, part)
            end
            
            -- Prevent creating reserved virtual folders
            if ((#parts > 0 and IsSystemFolderPart(parts[1])) and not IsTrashPathParts(parts)) or
               (#parts > 0 and parts[1] == "programs") or
               IsProgramsPathParts(parts) then
                return
            end
            
            local current = ent.PC_Files
            for i = 1, #parts do
                local part = parts[i]
                if part ~= "" then
                    if not current[part] then
                        current[part] = { type = "directory" }
                    end
                    current = current[part]
                end
            end
            
            -- Save to persistent storage if PC_ID is set
            if pc_id and pc_id ~= "" and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage then
                HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage(pc_id, ent.PC_Files)
            end
            
            -- Broadcast update to all connected players
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.BroadcastPCFilesUpdate(ent)
            
            -- Also send a lightweight folder change notification
            local parentPath = "/"
            if #parts > 1 then
                local parentParts = {}
                for i = 1, #parts - 1 do
                    table.insert(parentParts, parts[i])
                end
                parentPath = "/" .. table.concat(parentParts, "/")
            end
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.NotifyFolderChanged(ent, parentPath)
            
        elseif action == 5 then -- ACTION_DELETE_FILE
            -- Sync from real filesystem to virtual if PC_ID is set
            local pc_id = ent:GetPC_ID()
            if pc_id and pc_id ~= "" then
                if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
                end
            end
            
            local path = net.ReadString()
            
            -- Parse path
            local _, filepath = string.match(path, "^([^:]+):(.+)$")
            if not filepath or not ent.PC_Files then return end
            
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
                return
            end
            
            -- Cannot delete desktop or virtual system folders themselves
            if (#parts == 1 and (parts[1] == "desktop" or IsSystemFolderPart(parts[1]))) then
                return
            end
            if (#parts == 2 and IsSystemFolderPart(parts[1]) and (parts[2] == "programs" or parts[2] == "trash")) then
                return
            end
            
            local current = ent.PC_Files
            local targetName = parts[#parts]
            
            -- Cannot delete config.dat file (protected)
            if targetName == "config.dat" then
                return
            end
            
            for i = 1, #parts - 1 do
                local part = parts[i]
                if part ~= "" then
                    if not current[part] then return end
                    current = current[part]
                end
            end
            
            if current and current[targetName] then
                local isShortcut = string.match(targetName, "%.shortcut%.dat$") ~= nil
                -- Check if it's read-only or protected
                if not isShortcut and (current[targetName].readOnly or current[targetName].protected) then
                    return
                end
                
                -- Delete from entity filesystem
                current[targetName] = nil
                
                -- Delete only the target path from persistent storage if PC_ID is set.
                -- This is safer than rebuilding the whole tree for a single delete.
                if pc_id and pc_id ~= "" and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.DeletePersistentPath then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.DeletePersistentPath(pc_id, path)
                end
                
                -- Broadcast update to all connected players
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.BroadcastPCFilesUpdate(ent)
                
                -- Also send a lightweight folder change notification
                -- Extract parent folder from filepath
                local parentParts = {}
                for part in string.gmatch(filepath, "([^/]+)") do
                    if part ~= "" then
                        table.insert(parentParts, part)
                    end
                end
                
                -- Remove the last part (filename) to get parent directory
                local parentPathForNotify = "/"
                if #parentParts > 1 then
                    table.remove(parentParts)  -- Remove filename
                    parentPathForNotify = "/" .. table.concat(parentParts, "/")
                elseif #parentParts == 1 then
                    -- Only one part, means file is at root (like "/filename.txt")
                    parentPathForNotify = "/"
                end
                
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.NotifyFolderChanged(ent, parentPathForNotify)
            end
        elseif action == 9 then -- ACTION_RENAME_FILE
            -- Sync from real filesystem to virtual if PC_ID is set
            local pc_id = ent:GetPC_ID()
            if pc_id and pc_id ~= "" then
                if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
                end
            end
            
            local oldPath = net.ReadString()
            local newName = net.ReadString()
            
            -- Parse old path
            local _, filepath = string.match(oldPath, "^([^:]+):(.+)$")
            if not filepath or not ent.PC_Files then return end
            
            -- Remove trailing slash if present
            filepath = string.gsub(filepath, "/+$", "")
            
            -- Parse path
            local parts = {}
            for part in string.gmatch(filepath, "([^/]+)") do
                if part ~= "" then
                    table.insert(parts, part)
                end
            end
            
            if #parts == 0 then return end

            if IsSystemFolderPart(parts[1]) then
                return
            end
            
            -- Navigate to parent
            local current = ent.PC_Files
            for i = 1, #parts - 1 do
                local part = parts[i]
                if part ~= "" then
                    if not current or not current[part] then
                        return
                    end
                    current = current[part]
                end
            end
            
            local oldName = parts[#parts]
            
            -- Check if item exists
            if not current or not current[oldName] then
                return
            end
            
            -- Check if protected
            local isShortcut = string.match(oldName, "%.shortcut%.dat$") ~= nil
            if not isShortcut and (current[oldName].readOnly or current[oldName].protected) then
                return
            end
            
            -- Check if new name already exists
            if current[newName] then
                return
            end
            
            -- Perform rename in entity filesystem
            current[newName] = current[oldName]
            current[oldName] = nil
            
            -- Rename in persistent storage if PC_ID is set
            if pc_id and pc_id ~= "" and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage then
                HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.RebuildPersistentStorage(pc_id, ent.PC_Files)
            end
            
            -- Broadcast update to all connected players
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.BroadcastPCFilesUpdate(ent)
            
            -- Send folder change notification
            local parentParts = {}
            for i = 1, #parts - 1 do
                table.insert(parentParts, parts[i])
            end
            
            local parentPathForNotify = "/"
            if #parentParts > 0 then
                parentPathForNotify = "/" .. table.concat(parentParts, "/")
            end
            
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.NotifyFolderChanged(ent, parentPathForNotify)
        elseif action == 6 then -- ACTION_REQUEST_PC_FILES
            -- Initialize PC_Files if it doesn't exist
            if not ent.PC_Files then
                ent.PC_Files = {}
            end
            
            local pc_id = ent:GetPC_ID()
            
            -- If PC_ID is set, always sync from real filesystem to virtual
            if pc_id and pc_id ~= "" then
                -- Sync from persistent storage to virtual filesystem
                if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual then
                    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.SyncRealToVirtual(ent)
                end
            else
                -- No PC_ID set - preserve existing files and only ensure default structure exists
                if not ent.PC_Files or table.Count(ent.PC_Files) == 0 then
                    -- Filesystem is completely empty, initialize it
                    if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
                        HALOARMORY.COMPUTER.InitializeFiles(ent)
                    else
                        ent.PC_Files = {}
                    end
                else
                    -- Filesystem has content - ensure config.dat exists in root
                    if not ent.PC_Files["config.dat"] then
                        local defaultConfig = util.TableToJSON({
                            type = "color",
                            value = "#1a1a1a"
                        })
                        ent.PC_Files["config.dat"] = {
                            type = "file",
                            content = defaultConfig,
                            readOnly = true,
                            protected = true
                        }
                    end
                    
                    if not ent.PC_Files["desktop"] then
                        ent.PC_Files["desktop"] = { type = "directory" }
                    end
                end
            end

            if HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM and HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.EnsureRequiredFolders then
                HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM.EnsureRequiredFolders(ent.PC_Files)
            end
            
            SendPCFilesSync(ply, entIndex, ent.PC_Files or {})
            
            -- Register player as connected
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.RegisterPlayer(ent, ply)
        end
    end)
    
    -- Clean up disconnected players periodically
    if not timer.Exists("HALOARMORY.COMPUTER.CleanupDisconnected") then
        timer.Create("HALOARMORY.COMPUTER.CleanupDisconnected", 5, 0, function()
            for entIndex, players in pairs(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers) do
                local ent = Entity(entIndex)
                if not IsValid(ent) then
                    HALOARMORY.COMPUTER.INTERFACE.NETWORK.ConnectedPlayers[entIndex] = nil
                else
                    for ply, _ in pairs(players) do
                        if not IsValid(ply) then
                            players[ply] = nil
                        end
                    end
                end
            end
        end)
    end
end

if CLIENT then
    HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses = HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses or {}
    HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingSyncChunks = HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingSyncChunks or {}

    local function CreateRequestId(prefix)
        return string.format("%s_%d_%d", prefix, math.floor(SysTime() * 1000), math.random(1000, 9999))
    end

    local function FinalizePCFilesSync(entIndex, ent, compressedData)
        local decompressed = util.Decompress(compressedData)
        if not decompressed or not IsValid(ent) then
            return
        end

        local success, pcFiles = pcall(util.JSONToTable, decompressed)
        if success and pcFiles then
            NormalizeSystemFolderKeys(pcFiles)

            ent.PC_Files = pcFiles

            if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.entity then
                local interfaceEnt = HALOARMORY.COMPUTER.INTERFACE.entity
                if interfaceEnt:EntIndex() == entIndex then
                    interfaceEnt.PC_Files = pcFiles
                end
            end

            if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.entity == ent then
                timer.Simple(0.1, function()
                    if HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and HALOARMORY.COMPUTER.INTERFACE.frame.html then
                        HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript([[
                            try {
                                if (window._pendingSyncCallback && window.filesystemCallbacks &&
                                    window.filesystemCallbacks[window._pendingSyncCallback]) {
                                    var callbackId = window._pendingSyncCallback;
                                    window._pendingSyncCallback = null;
                                    window.filesystemCallbacks[callbackId](true);
                                    delete window.filesystemCallbacks[callbackId];
                                } else {
                                    window._pendingSyncCallback = null;
                                }

                                if (typeof window.osShellFilesSynced === 'function') {
                                    window.osShellFilesSynced();
                                }
                            } catch(e) {
                                console.error("Error notifying boot sequence:", e);
                            }
                        ]])
                    end
                end)
            end
        else
            ent.PC_Files = {}
        end
    end

    -- Request PC_Files sync from server
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.RequestPCFiles(entIndex)
        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_REQUEST_PC_FILES, 8)
        net.WriteUInt(entIndex, 16)
        net.SendToServer()
    end

    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.ReadFileFromServer(entIndex, path, callback)
        local requestId = CreateRequestId("read")
        if callback then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses[requestId] = callback
        end

        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_READ_FILE, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(requestId)
        net.WriteString(path)
        net.SendToServer()

        return requestId
    end

    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.ListDirectoryFromServer(entIndex, path, callback)
        local requestId = CreateRequestId("list")
        if callback then
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses[requestId] = callback
        end

        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_LIST_DIR, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(requestId)
        net.WriteString(path)
        net.SendToServer()

        return requestId
    end
    
    -- Send file save request to server
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.SaveFileToServer(entIndex, path, content)
        local compressed = util.Compress(content)
        if not compressed then
            return false
        end
        
        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_SAVE_FILE, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(path)
        net.WriteUInt(#compressed, 32)
        net.WriteData(compressed, #compressed)
        net.SendToServer()
        
        return true
    end
    
    -- Send create directory request to server
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.CreateDirectoryOnServer(entIndex, path)
        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_CREATE_DIR, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(path)
        net.SendToServer()
        
        return true
    end
    
    -- Send delete file request to server
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.DeleteFileOnServer(entIndex, path)
        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_DELETE_FILE, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(path)
        net.SendToServer()
        
        return true
    end
    
    -- Send rename file request to server
    function HALOARMORY.COMPUTER.INTERFACE.NETWORK.RenameFileOnServer(entIndex, oldPath, newName)
        net.Start(NET_NAME)
        net.WriteUInt(HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_RENAME_FILE, 8)
        net.WriteUInt(entIndex, 16)
        net.WriteString(oldPath)
        net.WriteString(newName)
        net.SendToServer()
        
        return true
    end
    
    -- Receive PC_Files sync from server
    net.Receive(NET_NAME, function()
        local action = net.ReadUInt(8)
        local entIndex = net.ReadUInt(16)
        local ent = Entity(entIndex)
        
        if action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_READ_FILE or
           action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_LIST_DIR then
            local requestId = net.ReadString()
            local dataLen = net.ReadUInt(32)
            local compressedData = net.ReadData(dataLen)
            local decompressed = util.Decompress(compressedData)
            local payload = {}

            if decompressed then
                local success, parsed = pcall(util.JSONToTable, decompressed)
                if success and istable(parsed) then
                    payload = parsed
                end
            end

            local callback = HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses[requestId]
            HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingResponses[requestId] = nil

            if callback then
                if action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_READ_FILE then
                    callback(payload.success and payload.content or nil, payload)
                else
                    callback(payload.files or {}, payload)
                end
            end
        elseif action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_FILES_CHANGED then
            local folderPath = net.ReadString()
            
            if IsValid(ent) then
                -- Notify JavaScript about the folder change
                if HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.entity and 
                   HALOARMORY.COMPUTER.INTERFACE.entity:EntIndex() == entIndex then
                    if HALOARMORY.COMPUTER.INTERFACE.frame and IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) and 
                       HALOARMORY.COMPUTER.INTERFACE.frame.html then
                        -- Escape folder path for safe JavaScript injection
                        local escapedPath = string.gsub(folderPath, "\\", "\\\\")
                        escapedPath = string.gsub(escapedPath, '"', '\\"')
                        escapedPath = string.gsub(escapedPath, "'", "\\'")
                        escapedPath = string.gsub(escapedPath, "\n", "\\n")
                        escapedPath = string.gsub(escapedPath, "\r", "\\r")
                        
                        local jsCode = string.format([[
                            try {
                                var folderPath = "%s";

                                if (typeof window.handleFolderChange === 'function') {
                                    window.handleFolderChange(folderPath);
                                } else {
                                    if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
                                        window.fileBrowserApp.refreshPath('C:' + folderPath);
                                    }

                                    if (folderPath === '/desktop/' || folderPath === '/desktop') {
                                        if (window.osShell && window.osShell.loadDesktopIcons) {
                                            window.osShell.loadDesktopIcons(true);
                                        }
                                    }

                                    if (window._saveDialogCurrentFolder) {
                                        var saveDialogPath = window._saveDialogCurrentFolder;
                                        if (!saveDialogPath.endsWith('/')) {
                                            saveDialogPath = saveDialogPath + '/';
                                        }

                                        var normalizedPath = 'C:' + folderPath;
                                        if (!normalizedPath.endsWith('/')) {
                                            normalizedPath = normalizedPath + '/';
                                        }

                                        if (saveDialogPath === normalizedPath && window._saveDialogLoadFolder) {
                                            window._saveDialogLoadFolder(normalizedPath);
                                        }
                                    }
                                }
                            } catch(e) {}
                        ]], escapedPath)
                        
                        HALOARMORY.COMPUTER.INTERFACE.frame.html:RunJavascript(jsCode)
                    end
                end
            end
            
        elseif action == HALOARMORY.COMPUTER.INTERFACE.NETWORK.ACTION_SYNC_PC_FILES then
            local totalChunks = net.ReadUInt(16)
            local chunkIndex = net.ReadUInt(16)
            local dataLen = net.ReadUInt(32)
            local chunkData = net.ReadData(dataLen)

            if not IsValid(ent) then
                return
            end

            local pendingKey = tostring(entIndex)
            local pending = HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingSyncChunks[pendingKey]
            if not pending or pending.totalChunks ~= totalChunks then
                pending = {
                    totalChunks = totalChunks,
                    received = 0,
                    chunks = {}
                }
                HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingSyncChunks[pendingKey] = pending
            end

            if not pending.chunks[chunkIndex] then
                pending.chunks[chunkIndex] = chunkData
                pending.received = pending.received + 1
            end

            if pending.received >= pending.totalChunks then
                local combined = {}
                for i = 1, pending.totalChunks do
                    combined[#combined + 1] = pending.chunks[i] or ""
                end

                HALOARMORY.COMPUTER.INTERFACE.NETWORK.PendingSyncChunks[pendingKey] = nil
                FinalizePCFilesSync(entIndex, ent, table.concat(combined))
            end
        end
    end)
end

return HALOARMORY.COMPUTER.INTERFACE.NETWORK

