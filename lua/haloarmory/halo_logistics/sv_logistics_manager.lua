HALOARMORY.MsgC("Server HALO SUPPLIES Manager Loading.")

HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Networks = HALOARMORY.Logistics.Networks or {}

local working_folder = "haloarmory/supplies/"
local global_folder = working_folder.."global/"
local map_folder = working_folder.."maps/"..game.GetMap().."/"

// Network Manager
util.AddNetworkString("HALOARMORY.Logistics.MANAGE.Manager")
util.AddNetworkString("HALOARMORY.Logistics.NETWORKS.GET")
util.AddNetworkString("HALOARMORY.Logistics.NETWORKS.ADD")
util.AddNetworkString("HALOARMORY.Logistics.NETWORKS.REMOVE")
util.AddNetworkString("HALOARMORY.Logistics.NETWORKS.EDIT")
util.AddNetworkString("HALOARMORY.Logistics.NETWORKS.EDIT.SAVE")

// User Access
util.AddNetworkString("HALOARMORY.Logistics.ACCESS.GetDevices")
util.AddNetworkString("HALOARMORY.Logistics.ACCESS.TakeSupplies")
util.AddNetworkString("HALOARMORY.Logistics.ACCESS.TransferSupplies")
util.AddNetworkString("HALOARMORY.Logistics.ACCESS.DeleteCargoBox")

--[[
                ################################
                ||                            ||
                ||       META FUNCTIONS       ||
                ||                            ||
                ################################
]]

local function GetSaveLocation( network )
    local save_location = global_folder
    if network.MapOnly then
        save_location = map_folder
    end
    return save_location
end

local function SaveNetworkToFile( name )

        // Convert the name to lowercase
        name = string.lower( name )

        // Replace spaces with _
        name = string.Replace( name, " ", "_" )

        local network = HALOARMORY.Logistics.Networks[name]

        // Create the folder
        print( "[SaveNetworkToFile] File:", GetSaveLocation( network ), file.IsDir( GetSaveLocation( network ), "DATA" ) )
        if not file.IsDir( GetSaveLocation( network ), "DATA" ) then
            file.CreateDir( GetSaveLocation( network ) )
            HALOARMORY.MsgC("[SaveNetworkToFile] HALO SUPPLIES: Created folder '"..GetSaveLocation( network ).."'.")
        end

        file.Write( GetSaveLocation( network )..name..".json", util.TableToJSON( network, true ) )
        HALOARMORY.MsgC("[SaveNetworkToFile] HALO SUPPLIES: Saved file '"..GetSaveLocation( network )..name..".json'.")


        return true, network

end

local function LoadNetworkFromFile( name )

    local network = HALOARMORY.Logistics.Networks[name]

    // Check if networks exists
    if not HALOARMORY.Logistics.Networks[name] then
        return false, "[LoadNetworkFromFile] Network '"..name.."' does not exist!"
    end

    // Check if the folder exists
    if not file.IsDir( GetSaveLocation( network ), "DATA" ) then
        HALOARMORY.MsgC("[LoadNetworkFromFile] HALO SUPPLIES: Folder '"..GetSaveLocation( network ).."' does not exist!")
        return false, "[LoadNetworkFromFile] Folder '"..GetSaveLocation( network ).."' does not exist!"
    end

    // Read the file into the network
    if file.Exists( GetSaveLocation( network )..name..".json", "DATA" ) then
        local data = util.JSONToTable( file.Read( GetSaveLocation( network )..name..".json", "DATA" ) )
        if data then
            data.Supplies = math.Round( data.Supplies )
            data.MaxSupplies = math.Round( data.MaxSupplies )

            HALOARMORY.Logistics.Networks[name] = data
        end
    end

    return true, HALOARMORY.Logistics.Networks[name]

end

--[[
                ################################
                ||                            ||
                ||      GLOBAL FUNCTIONS      ||
                ||          Networks          ||
                ||                            ||
                ################################
]]

// Load all networks
function HALOARMORY.Logistics.InitiateNetworks()
    HALOARMORY.MsgC("[InitiateNetworks] HALO SUPPLIES: Loading networks...")

    HALOARMORY.Logistics.Networks = {}

    // Load global networks
    if file.IsDir( global_folder, "DATA" ) then

        local files, folders = file.Find( global_folder.."*.json", "DATA" )
        for k, v in pairs( files ) do
            local data = util.JSONToTable( file.Read( global_folder..v, "DATA" ) )
            v = string.Replace( v, ".json", "")
            if data then
                HALOARMORY.Logistics.Networks[v] = data
            end
        end
    end


    // Load map networks
    if file.IsDir( map_folder, "DATA" ) then

        local files, folders = file.Find( map_folder.."*.json", "DATA" )
        for k, v in pairs( files ) do
            local data = util.JSONToTable( file.Read( map_folder..v, "DATA" ) )
            v = string.Replace( v, ".json", "")
            if data then
                HALOARMORY.Logistics.Networks[v] = data
            end
        end
    end

    HALOARMORY.Logistics.SyncNetworks()

    HALOARMORY.MsgC("[InitiateNetworks] HALO SUPPLIES: Loaded "..table.Count( HALOARMORY.Logistics.Networks ).." networks.")
end

// Register a new network
function HALOARMORY.Logistics.RegisterNetwork( name )

    local network = {}
    network.Name = name
    network.MapOnly = true
    network.MaxSupplies = 10000
    network.Supplies = 0

    HALOARMORY.Logistics.Networks[name] = network
    HALOARMORY.MsgC("[RegisterNetwork] HALO SUPPLIES: Network '"..name.."' registered.")

    SaveNetworkToFile( name )

    HALOARMORY.Logistics.SyncNetworks()

    HALOARMORY.Logistics.UpdateNetworkDevices( name )

    return true, network
end


// Generate a random network UUID, make sure it's not already in use
function HALOARMORY.Logistics.GenerateNetworkUUID()
    local uuid = util.CRC( tostring( SysTime() ) .. tostring( math.random( 0, 100000 ) ) )
    if HALOARMORY.Logistics.Networks[uuid] then
        return HALOARMORY.Logistics.GenerateNetworkUUID()
    end
    HALOARMORY.MsgC("[GenerateNetworkUUID] HALO SUPPLIES: Generated network UUID '"..uuid.."'.")
    return uuid
end


// Get a network by name
function HALOARMORY.Logistics.GetNetwork( name )
    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[GetNetwork] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    if file.Exists( GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json", "DATA" ) then
        local data = util.JSONToTable( file.Read( GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json", "DATA" ) )
        if data then
            HALOARMORY.Logistics.Networks[name] = data
        end
    end

    return HALOARMORY.Logistics.Networks[name]
end

// Update a network
function HALOARMORY.Logistics.UpdateNetwork( old_network, new_network )
    if not HALOARMORY.Logistics.Networks[old_network.Name] then
        HALOARMORY.MsgC("[UpdateNetwork] HALO SUPPLIES: Network '"..old_network.Name.."' does not exist!")
        return false
    end

    HALOARMORY.Logistics.Networks[old_network.Name] = old_network

    print( old_network.Name, old_network )
    PrintTable( old_network )
    print( new_network.Name, new_network )
    PrintTable( new_network )

    HALOARMORY.Logistics.RemoveNetwork( old_network.Name )

    HALOARMORY.Logistics.Networks[new_network.Name] = new_network
    SaveNetworkToFile( new_network.Name )

    HALOARMORY.MsgC("[UpdateNetwork] HALO SUPPLIES: Network '"..new_network.Name.."' updated.")
    HALOARMORY.Logistics.SyncNetworks()

    HALOARMORY.Logistics.UpdateNetworkDevices( new_network.Name )

    return true
end


// Remove a network
function HALOARMORY.Logistics.RemoveNetwork( name )
    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[RemoveNetwork] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    // remove the file if it exists
    if file.Exists( GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json", "DATA" ) then
        file.Delete( GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json" )
        HALOARMORY.MsgC("[RemoveNetwork] HALO SUPPLIES: File '"..GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json".."' file was deleted.")
    end

    HALOARMORY.Logistics.Networks[name] = nil

    HALOARMORY.MsgC("[RemoveNetwork] HALO SUPPLIES: Network '"..name.."' removed.")

    HALOARMORY.Logistics.SyncNetworks()

    --HALOARMORY.Logistics.UpdateNetworkDevices( false )

    return true
end

// Get a table of all networks names as both keys and values
function HALOARMORY.Logistics.SyncNetworks()
    local networks = {}
    for k, v in pairs( HALOARMORY.Logistics.Networks ) do
        networks[k] = k
    end

    --HALOARMORY.MsgC("[SyncNetworks] HALO SUPPLIES: Synced networks. Chars:", string.len( util.TableToJSON( networks ) ))

    --SetGlobal2String( "HALOARMORY.Logistics.NETWORKS", util.TableToJSON( networks ) )

    return networks
end

--[[
                ################################
                ||                            ||
                ||      GLOBAL FUNCTIONS      ||
                ||          Supplies          ||
                ||                            ||
                ################################
]]

// Update the supplies of a network
function HALOARMORY.Logistics.SetNetworkSupplies( name, amount )
    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[UpdateNetworkSupplies] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    amount = math.Clamp( amount, 0, HALOARMORY.Logistics.Networks[name].MaxSupplies )

    HALOARMORY.Logistics.Networks[name].Supplies = amount

    // Save the network to file
    file.Write( GetSaveLocation( HALOARMORY.Logistics.Networks[name] )..name..".json", util.TableToJSON( HALOARMORY.Logistics.Networks[name], true ) )

    HALOARMORY.Logistics.UpdateNetworkDevices( name )

    --HALOARMORY.MsgC("[UpdateNetworkSupplies] HALO SUPPLIES: Network '"..name.."' supplies updated to '"..amount.."'.")
    return true, amount
end

// Get the supplies of a network
function HALOARMORY.Logistics.GetNetworksupplies( name )
    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[GetNetworksupplies] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    return HALOARMORY.Logistics.Networks[name].Supplies, HALOARMORY.Logistics.Networks[name].MaxSupplies
end

function HALOARMORY.Logistics.AddNetworkSupplies( name, amount )

    local current_supplies, max_supplies = HALOARMORY.Logistics.GetNetworksupplies( name )

    local success, new_total = HALOARMORY.Logistics.SetNetworkSupplies( name, current_supplies + amount )

    // Return how much was actually able to be added
    return success, new_total - current_supplies
end

--[[
                ################################
                ||                            ||
                ||      GLOBAL FUNCTIONS      ||
                ||          Devices           ||
                ||                            ||
                ################################
]]

// Get devices of a network
function HALOARMORY.Logistics.GetNetworkDevices( name )
    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[GetNetworkDevices] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    local devices = {}
    for k, v in pairs( ents.GetAll() ) do
        if v.HALOARMORY_Device and isfunction(v.GetNetworkID) then
            if v:GetNetworkID() == name then
                table.insert(devices, v)
            end
        end
    end

    return devices
end

// Update all the devices in a network
function HALOARMORY.Logistics.UpdateNetworkDevices( name )
    name = tostring(name)

    if not HALOARMORY.Logistics.Networks[name] then
        HALOARMORY.MsgC("[UpdateNetworkDevices] HALO SUPPLIES: Network '"..name.."' does not exist!")
        return false
    end

    local network = HALOARMORY.Logistics.Networks[name]

    for _, device in pairs(HALOARMORY.Logistics.GetNetworkDevices( name )) do
        device:OnNetworkUpdate( network )
    end

    --HALOARMORY.MsgC("[UpdateNetworkDevices] HALO SUPPLIES: Network '"..name.."' devices updated.")
    return true
end

--[[
                ################################
                ||                            ||
                ||         NETWORKING         ||
                ||                            ||
                ################################
]]

// Open the supplies manager
function HALOARMORY.Logistics.OpenManager( ply )
    local networks = HALOARMORY.Logistics.Networks

    print( "Sending network data to "..ply:Nick()..". Table:" )
    PrintTable( networks )

    net.Start("HALOARMORY.Logistics.MANAGE.Manager")
    net.WriteTable( networks )
    net.Send( ply )
end

// Recieve a network from the client to open the manager
net.Receive( "HALOARMORY.Logistics.MANAGE.Manager", function( len, ply )

    HALOARMORY.Logistics.OpenManager( ply )

end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.ADD", function( len, ply )
    if not ply:IsAdmin() then return end

    local name = net.ReadString()

    // Convert the name to lowercase
    name = string.lower( name )

    // Replace spaces with _
    name = string.Replace( name, " ", "_" )

    HALOARMORY.Logistics.RegisterNetwork( name )


    timer.Simple( 0.5, function()
        local the_network = HALOARMORY.Logistics.SyncNetworks()

        net.Start("HALOARMORY.Logistics.NETWORKS.ADD")
        net.WriteTable( the_network )
        net.Send( ply )
    end )
end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.REMOVE", function( len, ply )
    if not ply:IsAdmin() then return end

    local name = net.ReadString()

    HALOARMORY.Logistics.RemoveNetwork( name )

    timer.Simple( 0.5, function()
        local the_network = HALOARMORY.Logistics.SyncNetworks()

        net.Start("HALOARMORY.Logistics.NETWORKS.ADD")
        net.WriteTable( the_network )
        net.Send( ply )
    end )
end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.GET", function( len, ply )
    if not ply:IsAdmin() then return end

    local the_network = HALOARMORY.Logistics.SyncNetworks()

    net.Start("HALOARMORY.Logistics.NETWORKS.GET")
    net.WriteTable( the_network )
    net.Send( ply )

end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.EDIT", function( len, ply )
    if not ply:IsAdmin() then return end

    local name = net.ReadString()

    local the_network = HALOARMORY.Logistics.GetNetwork( name )

    net.Start("HALOARMORY.Logistics.NETWORKS.EDIT")
    net.WriteTable( the_network )
    net.Send( ply )

end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.EDIT.SAVE", function( len, ply )
    if not ply:IsAdmin() then return end

    local networks_to_save = net.ReadTable()

    local old_network = networks_to_save.old_network
    local new_network = networks_to_save.new_network

    HALOARMORY.Logistics.UpdateNetwork( old_network, new_network )

    local the_network = HALOARMORY.Logistics.SyncNetworks()

    timer.Simple( 0.5, function()
        net.Start("HALOARMORY.Logistics.NETWORKS.ADD")
        net.WriteTable( the_network )
        net.Send( ply )
    end )
end )

--[[
                ################################
                ||                            ||
                ||     ACCESS GUI HANDLER     ||
                ||                            ||
                ################################
]]

net.Receive( "HALOARMORY.Logistics.ACCESS.GetDevices", function( len, ply )

    local devices = HALOARMORY.Logistics.GetNetworkDevices( net.ReadString() )

    PrintTable( devices )

    net.Start("HALOARMORY.Logistics.ACCESS.GetDevices")
    net.WriteTable( devices or {} )
    net.Send( ply )

end )

net.Receive( "HALOARMORY.Logistics.ACCESS.TakeSupplies", function( len, ply )

    local device = net.ReadEntity()
    local cargoName = net.ReadString()
    local cargoModel = net.ReadString()
    local amount = net.ReadInt(32)

    if not device or not device:IsValid() then return end

    device:SpawnCargo( ply, amount, cargoName, cargoModel )

end )

net.Receive( "HALOARMORY.Logistics.ACCESS.TransferSupplies", function( len, ply )

    local device = net.ReadEntity()
    local cargo = net.ReadEntity()
    local amount = net.ReadInt(32)

    if not device or not device:IsValid() then return end
    if not cargo or not cargo:IsValid() then return end

    // Plus number to take from box and put in to network
    // Minus number to take from network and put in to box

    device:InsertCargo( ply, cargo, amount )

end )

net.Receive( "HALOARMORY.Logistics.ACCESS.DeleteCargoBox", function( len, ply )

    local cargo = net.ReadEntity()
    local force_delete = net.ReadBool()

    if not cargo or not cargo:IsValid() then return end
    if cargo:GetClass() != "halo_sp_crate" then return end

    if not force_delete and cargo:GetStored() > 0 then
        ply:ChatPrint( "You cannot delete a cargo box with supplies in it!" )
        return
    end

    cargo:Remove()

end )

--[[
                ################################
                ||                            ||
                ||         Initialize         ||
                ||                            ||
                ################################
]]
HALOARMORY.Logistics.InitiateNetworks()