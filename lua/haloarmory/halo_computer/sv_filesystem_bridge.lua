-- Server-side Filesystem Bridge
if SERVER then
    HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM or {}
    
    -- Load shared utilities
    local scriptPath = HALOARMORY.GetOwnScriptPath()
    local UTILS = include(scriptPath .. "sh_filesystem_utils.lua")
    
    local FILESYSTEM = HALOARMORY.COMPUTER.INTERFACE.FILESYSTEM

    local function EnsureDesktopFolder(files)
        files = files or {}
        if not istable(files.desktop) or files.desktop.type ~= "directory" then
            files.desktop = { type = "directory" }
        end
        return files.desktop
    end

    local function EnsureSystemFolder(files)
        files = files or {}
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
        if not istable(files[".system"]) or files[".system"].type ~= "directory" then
            files[".system"] = { type = "directory" }
        end
        return files[".system"]
    end

    local function EnsureTrashFolder(files)
        local systemFolder = EnsureSystemFolder(files)
        if not istable(systemFolder.trash) or systemFolder.trash.type ~= "directory" then
            systemFolder.trash = { type = "directory" }
        end
        return systemFolder.trash
    end

    local function PopulateDefaultDesktopShortcuts(targetFolder)
        if not istable(targetFolder) then
            return
        end

        local desktopFileCount = 0
        for name, item in pairs(targetFolder) do
            if name ~= "type" then
                desktopFileCount = desktopFileCount + 1
            end
        end

        if desktopFileCount > 0 then
            return
        end

        if HALOARMORY.COMPUTER.DefaultFiles and HALOARMORY.COMPUTER.DefaultFiles.desktop_shortcuts then
            for shortcutId, shortcutData in pairs(HALOARMORY.COMPUTER.DefaultFiles.desktop_shortcuts) do
                local shortcutName = shortcutId .. ".shortcut.dat"
                local shortcutContent = util.TableToJSON({
                    program = shortcutData.program or shortcutId,
                    filename = shortcutData.name or shortcutId,
                    folder = shortcutData.folder or nil,
                    icon = shortcutData.icon or nil,
                    isTrash = (shortcutId == "trash") or nil
                })
                targetFolder[shortcutName] = {
                    type = "file",
                    content = shortcutContent
                }
            end
        end
    end

    function FILESYSTEM.EnsureRequiredFolders(files)
        files = files or {}
        EnsureDesktopFolder(files)
        EnsureTrashFolder(files)
        return files
    end

    local function FindDirectoryEntries(dirPath)
        local normalized = string.match(dirPath or "", "/$") and dirPath or ((dirPath or "") .. "/")
        local files, dirs = file.Find(normalized .. "*", "DATA")
        files = files or {}
        dirs = dirs or {}

        if file.IsDir(normalized .. ".system", "DATA") then
            local found = false
            for _, dirName in ipairs(dirs) do
                if dirName == ".system" then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(dirs, ".system")
            end
        end

        return files, dirs
    end

    local function DeletePathRecursive(path)
        if not path or path == "" then
            return
        end

        if file.IsDir(path, "DATA") then
            local normalized = string.match(path, "/$") and path or (path .. "/")
            local files, dirs = FindDirectoryEntries(normalized)

            for _, fileName in ipairs(files or {}) do
                file.Delete(normalized .. fileName)
            end

            for _, dirName in ipairs(dirs or {}) do
                DeletePathRecursive(normalized .. dirName)
            end

            file.Delete(string.gsub(normalized, "/$", ""))
            return
        end

        if file.Exists(path, "DATA") then
            file.Delete(path)
        end
    end

    local function GetPersistentBasePath(pc_id)
        if not pc_id or pc_id == "" then
            return nil
        end

        return string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
    end

    local function GetPersistentPathFromVirtual(pc_id, virtualPath)
        if not pc_id or pc_id == "" or not virtualPath or virtualPath == "" then
            return nil
        end

        local drive, filepath = UTILS.ParsePath(virtualPath)
        if not drive or (drive ~= "C" and drive ~= "C:") then
            return nil
        end

        local basePath = GetPersistentBasePath(pc_id)
        if not basePath then
            return nil
        end

        return basePath .. string.gsub(filepath, "^/", "")
    end
    
    -- Load file from persistent storage
    function FILESYSTEM.LoadPersistentFile(pc_id, path)
        if not pc_id or pc_id == "" then return nil end
        
        local loadPath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        loadPath = loadPath .. string.gsub(path, "C:/", "")
        
        if file.Exists(loadPath, "DATA") then
            return file.Read(loadPath, "DATA")
        end
        
        return nil
    end
    
    -- Load filesystem from persistent storage recursively
    function FILESYSTEM.LoadFilesystemFromPersistentStorage(pc_id)
        if not pc_id or pc_id == "" then return nil end
        
        local persistentPath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        
        -- Check if persistent folder exists
        if not file.IsDir(persistentPath, "DATA") then
            return nil
        end
        
        -- Normalize persistentPath to always have trailing slash
        if not string.match(persistentPath, "/$") then
            persistentPath = persistentPath .. "/"
        end
        
        -- Recursive function to load directory structure
        local function LoadDirectory(dirPath, targetTable)
            -- Normalize dirPath to always have trailing slash
            if not string.match(dirPath, "/$") then
                dirPath = dirPath .. "/"
            end
            
            -- Find all files and directories
            -- file.Find returns TWO values: files and directories
            local files, dirs = FindDirectoryEntries(dirPath)
            
            if not files and not dirs then
                return
            end
            
            local totalItems = (files and #files or 0) + (dirs and #dirs or 0)
            
            if totalItems == 0 then
                return
            end
            
            -- Process directories first
            if dirs then
                for _, name in ipairs(dirs) do
                    -- Skip programs folder (virtual)
                    if name ~= "programs" then
                        local filePath = dirPath .. name
                        targetTable[name] = { type = "directory" }
                        -- Recursively load subdirectory
                        LoadDirectory(filePath .. "/", targetTable[name])
                    end
                end
            end
            
            -- Process files
            if files then
                for _, name in ipairs(files) do
                    local filePath = dirPath .. name
                    local content = file.Read(filePath, "DATA")
                    if content then
                        -- Preserve protected flag for config.dat files
                        local isProtected = (name == "config.dat")
                        targetTable[name] = {
                            type = "file",
                            content = content,
                            readOnly = isProtected,
                            protected = isProtected
                        }
                    end
                end
            end
        end
        
        -- Load fresh from disk - start with empty structure
        local loadedFiles = {}
        LoadDirectory(persistentPath, loadedFiles)
        
        FILESYSTEM.EnsureRequiredFolders(loadedFiles)

        -- Ensure config.dat exists in root
        if not loadedFiles["config.dat"] then
            local defaultConfig = util.TableToJSON({
                type = "color",
                value = "#1a1a1a"
            })
            loadedFiles["config.dat"] = {
                type = "file",
                content = defaultConfig,
                readOnly = true,
                protected = true
            }
        end
        
        return loadedFiles
    end
    
    -- Sync real filesystem to virtual filesystem (ent.PC_Files)
    -- If PC_ID is set, loads from persistent storage and replaces ent.PC_Files
    -- If PC_ID is not set, does nothing (virtual filesystem is already in use)
    function FILESYSTEM.SyncRealToVirtual(ent)
        if not IsValid(ent) then return false end
        
        local pc_id = ent:GetPC_ID()
        if not pc_id or pc_id == "" then
            -- No PC_ID set, virtual filesystem is already in use
            return false
        end
        
        -- Load from persistent storage
        local loadedFiles = FILESYSTEM.LoadFilesystemFromPersistentStorage(pc_id)
        
        if loadedFiles then
            -- Replace virtual filesystem with data from persistent storage
            ent.PC_Files = loadedFiles
            return true
        end

        -- Persistent PCs must treat disk as authoritative. If there is no saved
        -- filesystem yet, create a fresh default one instead of preserving any
        -- entity-side PC_Files state.
        ent.PC_Files = {}

        if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
            HALOARMORY.COMPUTER.InitializeFiles(ent)
        else
            ent.PC_Files = {}
        end

        -- Save the new persistent filesystem immediately so future loads come
        -- from disk rather than any transient entity state.
        FILESYSTEM.SaveFilesystemToPersistentStorage(pc_id, ent.PC_Files)
        return true
    end
    
    -- Save PC_Files structure to persistent storage recursively
    function FILESYSTEM.SaveFilesystemToPersistentStorage(pc_id, pcFiles)
        if not pc_id or pc_id == "" then return false end
        if not pcFiles or type(pcFiles) ~= "table" then return false end
        
        -- Create base directory if it doesn't exist
        local persistentPath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        if not file.IsDir(persistentPath, "DATA") then
            file.CreateDir(persistentPath)
        end
        
        -- Recursive function to save files and directories
        local function SaveRecursive(files, currentPath)
            for name, item in pairs(files) do
                -- Skip the "type" field and "programs" folder (virtual)
                if name ~= "type" and name ~= "programs" then
                    if type(item) == "table" then
                        if item.type == "directory" then
                            -- Create directory
                            local dirPath = currentPath .. name .. "/"
                            if not file.IsDir(dirPath, "DATA") then
                                file.CreateDir(dirPath)
                            end
                            -- Recursively save contents (skip programs folder)
                            SaveRecursive(item, dirPath)
                        elseif item.type == "file" and item.content then
                            -- Save file
                            local filePath = currentPath .. name
                            file.Write(filePath, item.content)
                        end
                    end
                end
            end
        end
        
        -- Start saving from base path
        SaveRecursive(pcFiles, persistentPath)
        return true
    end

    function FILESYSTEM.RebuildPersistentStorage(pc_id, pcFiles)
        if not pc_id or pc_id == "" then
            return false
        end

        local persistentPath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        if file.IsDir(persistentPath, "DATA") then
            DeletePathRecursive(string.gsub(persistentPath, "/$", ""))
        end

        return FILESYSTEM.SaveFilesystemToPersistentStorage(pc_id, pcFiles)
    end

    function FILESYSTEM.DeletePersistentPath(pc_id, virtualPath)
        local persistentPath = GetPersistentPathFromVirtual(pc_id, virtualPath)
        if not persistentPath then
            return false
        end

        if file.IsDir(persistentPath, "DATA") then
            DeletePathRecursive(string.gsub(persistentPath, "/$", ""))
            return true
        end

        if file.Exists(persistentPath, "DATA") then
            file.Delete(persistentPath)
            return true
        end

        return false
    end
    
    -- Initialize filesystem for entity
    function HALOARMORY.COMPUTER.InitializeFiles(ent)
        if not IsValid(ent) then 
            return 
        end
        
        ent.PC_Files = {}

        FILESYSTEM.EnsureRequiredFolders(ent.PC_Files)

        local desktopFolder = ent.PC_Files.desktop
        PopulateDefaultDesktopShortcuts(desktopFolder)

        -- Create config.dat file in root
        if not ent.PC_Files["config.dat"] then
            local defaultConfig = util.TableToJSON({
                type = "color",
                value = "#1a1a1a"
            })
            ent.PC_Files["config.dat"] = {
                type = "file",
                content = defaultConfig,
                readOnly = true,  -- Protected from deletion
                protected = true  -- Mark as protected file
            }
        end
        
        -- Save to persistent storage if PC_ID is set and folder doesn't exist
        local pc_id = ent:GetPC_ID()
        if pc_id and pc_id ~= "" then
            local persistentPath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
            
            -- Check if folder exists, if not, save the initialized files
            if not file.IsDir(persistentPath, "DATA") then
                FILESYSTEM.SaveFilesystemToPersistentStorage(pc_id, ent.PC_Files)
            end
        end
    end
end

