HALOARMORY.MsgC("Server HALO Computer Operating System Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}

-- Network strings for file content requests
util.AddNetworkString("HALOARMORY_RequestFileContent")
util.AddNetworkString("HALOARMORY_ReceiveFileContent")
util.AddNetworkString("HALOARMORY_RequestComputer")
util.AddNetworkString("HALOARMORY_SyncComputer")

-- Initialize default files for a computer
function HALOARMORY.COMPUTER.InitializeFiles(ent)
    if not IsValid(ent) then return end
    
    print("[HALOARMORY] Initializing files for computer", ent)
    ent.PC_Files = {}
    
    -- Add default files from shared config
    for fileId, fileInfo in pairs(HALOARMORY.COMPUTER.Files) do
        print("[HALOARMORY] Adding default file:", fileId, fileInfo.name)
        HALOARMORY.COMPUTER.AddFile(ent, fileId, fileInfo.name, fileInfo.description)
    end
end

-- Add a file to a computer
function HALOARMORY.COMPUTER.AddFile(ent, fileId, name, content)
    if not IsValid(ent) then return end
    
    ent.PC_Files = ent.PC_Files or {}
    ent.PC_Files[fileId] = {
        name = name,
        content = content
    }
end

-- Remove a file from a computer
function HALOARMORY.COMPUTER.RemoveFile(ent, fileId)
    if not IsValid(ent) then return end
    
    if not ent.PC_Files then return end
    ent.PC_Files[fileId] = nil
end

-- Get all files for a computer (names only)
function HALOARMORY.COMPUTER.GetFiles(ent)
    if not IsValid(ent) then return {} end
    
    local files = {}
    for fileId, fileInfo in pairs(ent.PC_Files or {}) do
        files[fileId] = {
            name = fileInfo.name
        }
    end
    return files
end

-- Get a specific file's content
function HALOARMORY.COMPUTER.GetFileContent(ent, fileId)
    if not IsValid(ent) or not ent.PC_Files or not ent.PC_Files[fileId] then return nil end
    return ent.PC_Files[fileId].content
end

-- Handle computer data requests from clients
net.Receive("HALOARMORY_RequestComputer", function(len, ply)
    local pc_id = net.ReadString()
    local ent = net.ReadEntity()
    
    if not IsValid(ent) or not ent.IsHALOARMORY then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end -- 500 units squared
    
    -- Send data based on computer type
    local data = {}
    if pc_id ~= "" then
        -- Persistent computer - load from storage
        data = HALOARMORY.COMPUTER.LoadPersistentPC(pc_id)
    else
        -- Non-persistent computer - get from entity
        -- Make sure files are initialized
        if not ent.PC_Files then
            HALOARMORY.COMPUTER.InitializeFiles(ent)
        end
        
        local files = HALOARMORY.COMPUTER.GetFiles(ent)
        local notes = {}
        for fileId, fileInfo in pairs(files) do
            notes[fileId] = {
                title = fileInfo.name
            }
        end
        data = { notes = notes }
    end
    
    -- Send complete data table
    net.Start("HALOARMORY_SyncComputer")
    net.WriteEntity(ent)
    net.WriteTable(data)
    net.Send(ply)
end)

-- Handle file content requests
net.Receive("HALOARMORY_RequestFileContent", function(len, ply)
    local ent = net.ReadEntity()
    local fileId = net.ReadString()
    
    if not IsValid(ent) or not ent.IsHALOARMORY then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end -- 500 units squared
    
    local content
    if ent:GetPC_ID() ~= "" then
        -- Persistent computer - load from storage
        local data = HALOARMORY.COMPUTER.LoadPersistentPC(ent:GetPC_ID())
        if data and data.notes and data.notes[fileId] then
            content = data.notes[fileId].content
        end
    else
        -- Non-persistent computer - get from entity
        -- Make sure files are initialized
        if not ent.PC_Files then
            HALOARMORY.COMPUTER.InitializeFiles(ent)
        end
        content = HALOARMORY.COMPUTER.GetFileContent(ent, fileId)
    end
    
    if content then
        net.Start("HALOARMORY_ReceiveFileContent")
        net.WriteEntity(ent)
        net.WriteString(fileId)
        net.WriteString(content)
        net.Send(ply)
    end
end)