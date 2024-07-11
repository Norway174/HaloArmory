HALOARMORY.MsgC("Server HALO SHIP Presets Manager Loading.")


HALOARMORY.Ships = HALOARMORY.Ships or {}
HALOARMORY.Ships.Presets = HALOARMORY.Ships.Presets or {}


// Create a new network string for the ship presets
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.PresetsList")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.SavePreset")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.LoadPreset")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.DeletePreset")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.RenamePreset")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.WipeShip")
util.AddNetworkString("HALOARMORY.SHIPS.PRESETS.SetAutoLoadPreset")


// SEND THE PRESETS LIST TO THE CLIENT
net.Receive( "HALOARMORY.SHIPS.PRESETS.PresetsList", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    // Get the ship type
    local shipType = net.ReadEntity()

    // Get a list of all the files from the folder
    local files = file.Find( "haloarmory/ships/" .. shipType:GetClass() .. "/*.json", "DATA" )

    --print("HALOARMORY.SHIPS.PRESETS.PresetsList", shipType, files)
    --PrintTable(files)

    // Loop through all the files and remove .json from the end
    for k, v in pairs( files ) do
        files[k] = string.Replace( v, ".json", "" )
    end

    // Efficiently send the list of files to the client
    net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
        net.WriteEntity( shipType )
        net.WriteTable( files )
        net.WriteString( HALOARMORY.Ships.Autoload:GetString() )
    net.Send( ply )
    
end )

// SAVE SHIP
net.Receive( "HALOARMORY.SHIPS.PRESETS.SavePreset", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    local shipType = net.ReadEntity()
    local presetName = net.ReadString()

    HALOARMORY.Ships.SaveShip(shipType, presetName)

    if IsValid( shipType ) then
        shipType:SetAutoLoadPreset( presetName )
    end

end )

// LOAD SHIP
net.Receive( "HALOARMORY.SHIPS.PRESETS.LoadPreset", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    local shipType = net.ReadEntity()
    local presetName = net.ReadString()

    --HALOARMORY.Ships.LoadShip(shipType, presetName)

    if IsValid( shipType ) then
        shipType:SetAutoLoadPreset( presetName )
    end

end )


// DELETE SHIP
net.Receive( "HALOARMORY.SHIPS.PRESETS.DeletePreset", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    local shipType = net.ReadEntity()
    local presetName = net.ReadString()

    HALOARMORY.Ships.DeleteShip(shipType, presetName)

end )

// RENAME SHIP
net.Receive( "HALOARMORY.SHIPS.PRESETS.RenamePreset", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    local shipType = net.ReadEntity()
    local presetName = net.ReadString()
    local newPresetName = net.ReadString()

    HALOARMORY.Ships.RenameShip(shipType, presetName, newPresetName)

end )

// WIPE SHIP
net.Receive( "HALOARMORY.SHIPS.PRESETS.WipeShip", function( len, ply )

    // Check if the player is valid and an admin
    if not IsValid( ply ) or not ply:IsAdmin() then return end

    local shipType = net.ReadEntity()

    HALOARMORY.Ships.WipeProps(shipType)

end )

// SET AUTOLOAD SHIP
-- net.Receive( "HALOARMORY.SHIPS.PRESETS.SetAutoLoadPreset", function( len, ply )

--     // Check if the player is valid and an admin
--     if not IsValid( ply ) or not ply:IsAdmin() then return end

--     local shipType = net.ReadEntity()
--     local presetName = net.ReadString()

--     HALOARMORY.Ships.Autoload:SetString( presetName )

-- end )