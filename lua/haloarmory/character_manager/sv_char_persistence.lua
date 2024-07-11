HALOARMORY.MsgC("Server CHARACTHER PERSISTENCE Loading.")

HALOARMORY = HALOARMORY or {}
HALOARMORY.Character = HALOARMORY.Character or {}


HALOARMORY.Character.Directory = "haloarmory/characters/"

local EnableCharacterCreator = CreateConVar("HALOARMORY.PERSISTENCE.CHAR_CREATOR", "0", FCVAR_ARCHIVE, "Enable the character creator?")

function HALOARMORY.Character.GetCharacter( ply, foldername, fileName )
    if not fileName then fileName = "default" end
    if not foldername then foldername = ply:SteamID64() end

    if not file.IsDir(HALOARMORY.Character.Directory..foldername, "DATA") then
        print("No character data found for '" .. foldername .. "'")
        return false
    end

    -- Load the character data
    return util.JSONToTable(file.Read(HALOARMORY.Character.Directory .. foldername .. "/" .. fileName .. ".json", "DATA"))
end


function HALOARMORY.Character.SaveCharacter( ply, fileName )
    if not fileName then fileName = "default" end
    local foldername = ply:SteamID64()

    local CharTable = HALOARMORY.Character.GetCharacter( ply, foldername, fileName )

    if CharTable == false then CharTable = {} end

    // Call a hook to allow other addons to add their own data to the character table
    hook.Call( "HALOARMORY.SaveCharacter", nil, ply, CharTable )

    // Print Table
    --PrintTable(CharTable)

    
    -- Create the folder if it doesn't exist
    if not file.IsDir(HALOARMORY.Character.Directory..foldername, "DATA") then
        file.CreateDir(HALOARMORY.Character.Directory..foldername)
    end

    -- Save the character data
    file.Write(HALOARMORY.Character.Directory .. foldername .. "/" .. fileName .. ".json", util.TableToJSON(CharTable, true))
    --print("Saved character data to '" .. HALOARMORY.Character.Directory .. foldername .. "/" .. fileName .. ".json'")
    --ply:PrintMessage( HUD_PRINTCONSOLE, "[HALOARMORY] Character saved to server." )
    ply:SendLua( 'HALOARMORY.MsgC("Character saved to server.")' )
    return true

end


function HALOARMORY.Character.LoadCharacter( ply, fileName )
    if not fileName then fileName = "default" end
    local foldername = ply:SteamID64()

    local CharTable = HALOARMORY.Character.GetCharacter( ply, foldername, fileName )
    if not istable(CharTable) then return false end

    --print("Loaded character data from '" .. HALOARMORY.Character.Directory .. foldername .. "/" .. fileName .. ".json'")
    --ply:PrintMessage( HUD_PRINTCONSOLE, "[HALOARMORY] Character loaded from the server." )
    ply:SendLua( 'HALOARMORY.MsgC("Character loaded from the server.")' )

    // Call a hook to allow other addons to load their own data from the character table
    --hook.Call( "HALOARMORY.LoadCharacter", nil, ply, CharTable )

    for key, value in pairs(CharTable) do

        local load_func = hook.GetTable()["HALOARMORY.LoadCharacter"][key]
        if not isfunction(load_func) then continue end

        local succ, err = pcall(load_func, ply, value)
        if not succ then
            print("Error loading character data: '" .. key .. "'\n" .. err)
            --ply:PrintMessage( HUD_PRINTCONSOLE, "[HALOARMORY] Error loading character. See server console for details." )
            ply:SendLua( 'HALOARMORY.MsgC("Error loading character. See server console for details.")' )
        end
        
    end

    // Print Table
    --PrintTable(CharTable)

    return true

end


// LOADING
// Load on player spawn
local load_queue = {}

hook.Add("PlayerInitialSpawn", "HALOARMORY.Character.SVLOAD", function(ply)
    load_queue[ply] = true
end)

hook.Add("SetupMove", "HALOARMORY.Character.SVLOAD", function(ply, _, cmd)
    if load_queue[ply] and not cmd:IsForced() then
        load_queue[ply] = nil

        // Check if the player has a character saved
        timer.Simple(0.4, function()
            if HALOARMORY.Character.LoadCharacter( ply ) then
                HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE LOADED FOR " .. ply:Nick() .. ".")
            else
                // If not, open the character creator
                if EnableCharacterCreator:GetBool() then
                    HALOARMORY.Character.OpenCreator( ply )
                    HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE NOT FOUND FOR " .. ply:Nick() .. ". OPENED CREATOR.")
                else 
                    HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE NOT FOUND FOR " .. ply:Nick() .. ". CREATOR DISABLED.")
                end
            end
            ply.HALOARMORY_CanSave = true
        end)

    end
end)


// SAVING
hook.Add("PlayerDisconnected", "HALOARMORY.Character.SVSAVE", function(ply)
    HALOARMORY.Character.SaveCharacter( ply )
    HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE SAVED FOR " .. ply:Nick() .. " ON DISCONNECT.")
end)

hook.Add("ShutDown", "HALOARMORY.Character.SVSAVE", function()
    for _, ply in pairs(player.GetAll()) do
        if ply.HALOARMORY_CanSave then
            HALOARMORY.Character.SaveCharacter( ply )
        end
    end
    HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE SAVED FOR " .. #player.GetAll() .. " PLAYERS BEFORE SHUTDOWN.")
end)

local function SaveCharTimer()
    HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE TIMER INITIALIZED.")
    timer.Create( "SaveCharTimer", 60 * 2, 0, function( )
        for _, ply in pairs(player.GetAll()) do
            if ply.HALOARMORY_CanSave then
                HALOARMORY.Character.SaveCharacter( ply )
            end
        end
        HALOARMORY.MsgC("[CHARACTER] CHARACTHER PERSISTENCE SAVED FOR " .. #player.GetAll() .. " PLAYERS.")
    end )
end
hook.Add( "Initialize", "HALOARMORY.Character.TimerInit", SaveCharTimer )
// If timer exists, call the function again
if timer.Exists( "SaveCharTimer" ) then
    SaveCharTimer()
end