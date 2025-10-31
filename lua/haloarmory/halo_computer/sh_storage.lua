HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.PersistentPC = HALOARMORY.COMPUTER.PersistentPC or {}

if SERVER then
    -- Create necessary directories
    if not file.Exists(HALOARMORY.COMPUTER.Directory, "DATA") then
        file.CreateDir(HALOARMORY.COMPUTER.Directory)
        file.CreateDir(HALOARMORY.COMPUTER.Directory .. "computers")
    end

    -- Load persistent computer config
    function HALOARMORY.COMPUTER.LoadPCConfig(pc_id)
        local basePath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        local configPath = basePath .. ".config"
        
        if file.Exists(configPath, "DATA") then
            local configData = file.Read(configPath, "DATA")
            return util.JSONToTable(configData) or {}
        end
        
        -- Return default config
        return {}
    end

    -- Save persistent computer config
    function HALOARMORY.COMPUTER.SavePCConfig(pc_id, config)
        local basePath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        local configPath = basePath .. ".config"
        
        if not file.Exists(basePath, "DATA") then
            file.CreateDir(basePath)
        end
        
        file.Write(configPath, util.TableToJSON(config, true))
    end

    -- Load persistent computer data
    -- This is called when a computer interface is opened
    -- New PCs (first time opened) will get welcome_note automatically
    function HALOARMORY.COMPUTER.LoadPersistentPC(pc_id)
        if not pc_id or pc_id == "" then
            return { notes = {} }
        end
        
        local basePath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        local notesPath = basePath .. "notes"
        
        -- Check if this is a new PC (notes folder doesn't exist)
        -- Only new PCs get default files like welcome_note
        if not file.Exists(notesPath, "DATA") then
            -- This is a new PC - create it with default files
            file.CreateDir(notesPath)
            
            -- Create default config if it doesn't exist
            if not file.Exists(basePath .. ".config", "DATA") then
                HALOARMORY.COMPUTER.SavePCConfig(pc_id, {})
            end
            
            -- Add default files (like welcome_note) for new computers only
            local notes = {}
            for fileId, fileInfo in pairs(HALOARMORY.COMPUTER.Files) do
                -- Use description as default content (same as non-persistent computers)
                local content = fileInfo.description or ""
                notes[fileId] = {
                    title = fileInfo.name,
                    content = content
                }
                HALOARMORY.COMPUTER.SavePersistentNote(pc_id, fileId, notes[fileId])
            end
            return { notes = notes }
        end
        
        -- Existing PC - load notes from storage (no welcome_note added)

        local notes = {}
        local files = file.Find(notesPath .. "/*.json", "DATA")
        
        for _, fname in ipairs(files) do
            local noteData = file.Read(notesPath .. "/" .. fname, "DATA")
            local noteId = string.match(fname, "(.+)%.json$")
            if noteData and noteId then
                notes[noteId] = util.JSONToTable(noteData) or {}
                
                -- Fix notes that were created with error content (from old code)
                if notes[noteId].content == "Error: Could not load file content" or not notes[noteId].content then
                    -- Try to get default content from config
                    local defaultFile = HALOARMORY.COMPUTER.Files[noteId]
                    if defaultFile then
                        notes[noteId].content = defaultFile.description or ""
                    else
                        notes[noteId].content = notes[noteId].content or ""
                    end
                    -- Save the fixed note back
                    HALOARMORY.COMPUTER.SavePersistentNote(pc_id, noteId, notes[noteId])
                end
            end
        end

        return { notes = notes }
    end

    -- Save persistent computer note
    function HALOARMORY.COMPUTER.SavePersistentNote(pc_id, noteId, noteData)
        local basePath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        local notesPath = basePath .. "notes"
        
        if not file.Exists(notesPath, "DATA") then
            file.CreateDir(notesPath)
        end
        file.Write(notesPath .. "/" .. noteId .. ".json", util.TableToJSON(noteData, true))
    end

    -- Delete persistent computer note
    function HALOARMORY.COMPUTER.DeletePersistentNote(pc_id, noteId)
        local basePath = string.gsub(HALOARMORY.COMPUTER.PersistentPC, "{pc_id}", pc_id)
        local notePath = basePath .. "notes/" .. noteId .. ".json"
        
        if file.Exists(notePath, "DATA") then
            file.Delete(notePath)
        end
    end

    -- Network computer data to clients
    util.AddNetworkString("HALOARMORY_SyncComputer")
    util.AddNetworkString("HALOARMORY_UpdateNote")
    util.AddNetworkString("HALOARMORY_DeleteNote")

    -- Handle client note updates
    net.Receive("HALOARMORY_UpdateNote", function(len, ply)
        local ent = net.ReadEntity()
        local pc_id = net.ReadString()
        local noteId = net.ReadString()
        local noteData = net.ReadTable()

        -- Validate the request
        if not IsValid(ent) or not ply:IsValid() then return end
        if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end -- 500 units squared

        -- Update data based on type
        if pc_id ~= "" then
            -- Persistent online computer
            HALOARMORY.COMPUTER.SavePersistentNote(pc_id, noteId, noteData)
        else
            -- Non-persistent computer
            HALOARMORY.COMPUTER.AddFile(ent, noteId, noteData.title, noteData.content)
        end

        -- Sync to all clients using this computer
        net.Start("HALOARMORY_SyncComputer")
        net.WriteEntity(ent)
        net.WriteTable({ notes = { [noteId] = noteData } })
        net.SendPVS(ent:GetPos())
    end)

    -- Handle note deletion
    net.Receive("HALOARMORY_DeleteNote", function(len, ply)
        local ent = net.ReadEntity()
        local pc_id = net.ReadString()
        local noteId = net.ReadString()

        -- Validate the request
        if not IsValid(ent) or not ply:IsValid() then return end
        if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end

        if pc_id ~= "" then
            HALOARMORY.COMPUTER.DeletePersistentNote(pc_id, noteId)
        else
            HALOARMORY.COMPUTER.RemoveFile(ent, noteId)
        end

        -- Notify all clients
        net.Start("HALOARMORY_DeleteNote")
        net.WriteEntity(ent)
        net.WriteString(noteId)
        net.SendPVS(ent:GetPos())
    end)
end

if CLIENT then
    -- Get ExternalDrive directory (local storage)
    function HALOARMORY.COMPUTER.GetExternalDrivePath()
        return HALOARMORY.COMPUTER.LocalPC
    end
    
    -- Initialize ExternalDrive directory when player spawns
    hook.Add("InitPostEntity", "HALOARMORY_InitExternalDrive", function()
        local drivePath = HALOARMORY.COMPUTER.GetExternalDrivePath()
        if drivePath and not file.Exists(drivePath .. "notes", "DATA") then
            file.CreateDir(drivePath)
            file.CreateDir(drivePath .. "notes")
        end
    end)

    -- Handle server sync
    net.Receive("HALOARMORY_SyncComputer", function()
        local ent = net.ReadEntity()
        local data = net.ReadTable()

        -- Update local data if we have the computer open
        if IsValid(HALOARMORY.COMPUTER.INTERFACE) and HALOARMORY.COMPUTER.INTERFACE.Entity == ent then
            HALOARMORY.COMPUTER.INTERFACE:UpdateData(data)
        end
    end)

    -- Handle note deletion sync
    net.Receive("HALOARMORY_DeleteNote", function()
        local ent = net.ReadEntity()
        local noteId = net.ReadString()

        if IsValid(HALOARMORY.COMPUTER.INTERFACE) and HALOARMORY.COMPUTER.INTERFACE.Entity == ent then
            HALOARMORY.COMPUTER.INTERFACE:DeleteNote(noteId)
        end
    end)

    -- ExternalDrive functions (local storage per player)
    function HALOARMORY.COMPUTER.SaveExternalNote(noteId, noteData)
        local drivePath = HALOARMORY.COMPUTER.GetExternalDrivePath()
        if not drivePath then return end
        
        local notePath = drivePath .. "notes/" .. noteId .. ".json"
        if not file.Exists(drivePath .. "notes", "DATA") then
            file.CreateDir(drivePath .. "notes")
        end
        file.Write(notePath, util.TableToJSON(noteData, true))
    end

    function HALOARMORY.COMPUTER.DeleteExternalNote(noteId)
        local drivePath = HALOARMORY.COMPUTER.GetExternalDrivePath()
        if not drivePath then return end
        
        local notePath = drivePath .. "notes/" .. noteId .. ".json"
        if file.Exists(notePath, "DATA") then
            file.Delete(notePath)
        end
    end

    function HALOARMORY.COMPUTER.LoadExternalDrive()
        local drivePath = HALOARMORY.COMPUTER.GetExternalDrivePath()
        if not drivePath then return { notes = {} } end
        
        local notes = {}
        local files = file.Find(drivePath .. "notes/*.json", "DATA")
        
        for _, fname in ipairs(files) do
            local noteData = file.Read(drivePath .. "notes/" .. fname, "DATA")
            local noteId = string.match(fname, "(.+)%.json$")
            if noteData and noteId then
                notes[noteId] = util.JSONToTable(noteData) or {}
            end
        end

        return { notes = notes }
    end

    -- Send note update to server
    function HALOARMORY.COMPUTER.UpdateServerNote(ent, pc_id, noteId, noteData)
        net.Start("HALOARMORY_UpdateNote")
        net.WriteEntity(ent)
        net.WriteString(pc_id or "")
        net.WriteString(noteId)
        net.WriteTable(noteData)
        net.SendToServer()
    end

    -- Send note deletion to server
    function HALOARMORY.COMPUTER.DeleteServerNote(ent, pc_id, noteId)
        net.Start("HALOARMORY_DeleteNote")
        net.WriteEntity(ent)
        net.WriteString(pc_id or "")
        net.WriteString(noteId)
        net.SendToServer()
    end

    -- Request note download for ExternalDrive
    function HALOARMORY.COMPUTER.DownloadNoteToExternal(ent, pc_id, noteId)
        net.Start("HALOARMORY_RequestFileContent")
        net.WriteEntity(ent)
        net.WriteString(noteId)
        net.SendToServer()
    end
end 