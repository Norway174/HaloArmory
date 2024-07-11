HALOARMORY.MsgC("Server HALO ARMORY Loadout Persistence Loading.")

HALOARMORY.ARMORY = HALOARMORY.ARMORY or {}
HALOARMORY.ARMORY.PERSISTENCE = HALOARMORY.ARMORY.PERSISTENCE or {}


function HALOARMORY.ARMORY.PERSISTENCE.GetSavedWeapons( ply )
    local playerID = ply:SteamID64()

    -- Read the file contents
    local fileContents = file.Read("haloarmory/armory/" .. playerID .. ".json", "DATA")
    if not fileContents then
        print("Error: Could not read file 'haloarmory/armory/" .. playerID .. ".json'")
        return {}
    end

    -- Parse the file contents as a JSON array
    local savedWeaponsTable = util.JSONToTable(fileContents)
    if not savedWeaponsTable then
        print("Error: Could not parse file contents as JSON array")
        return {}
    end

    return savedWeaponsTable
end


function HALOARMORY.ARMORY.PERSISTENCE.SaveWeapons( ply, listOfWeapons )
    

    local WeaponsToSave = {}

    WeaponsToSave = HALOARMORY.ARMORY.GetWeapons( ply )


    local characterID = ply:GetVar( "CharacterCreatorIdSaveLoad") or "default"

    WeaponsToSave[characterID] = listOfWeapons

    local playerID = ply:SteamID64()

    -- Create the folder if it doesn't exist
    if not file.IsDir("haloarmory/armory/", "DATA") then
        file.CreateDir("haloarmory/armory/")
    end

    file.Write("haloarmory/armory/" .. playerID .. ".json", util.TableToJSON(WeaponsToSave, true))
    print("Saved weapon data to 'haloarmory/armory/" .. playerID .. ".json'")
end


function HALOARMORY.ARMORY.PERSISTENCE.LoadWeapons( ply )

    local WeaponsToLoad = HALOARMORY.ARMORY.PERSISTENCE.GetSavedWeapons( ply )
    local characterID = ply:GetVar( "CharacterCreatorIdSaveLoad") or "default"

    WeaponsToLoad = WeaponsToLoad[characterID]

    if not WeaponsToLoad and not istable(WeaponsToLoad) then return end

    HALOARMORY.ARMORY.ApplyWeapons( ply, WeaponsToLoad, true )

end
hook.Add( "PlayerLoadout", "HALOARMORY.ARMORY.PERSISTENCE.LoadWeaponsHook", function( ply )
    timer.Simple(.1, function()
        HALOARMORY.ARMORY.PERSISTENCE.LoadWeapons( ply )
    end)
end)