HALOARMORY.MsgC("Shared HALOARMORY VEHICLES loaded!")


HALOARMORY.VEHICLES = HALOARMORY.VEHICLES or {}
HALOARMORY.VEHICLES.NETWORK = HALOARMORY.VEHICLES.NETWORK or {}


local NET_NAME = "HALOARMORY.VEHICLES.NETWORK"

local ACTION_REQUEST_VEHICLE_PADS = 1
local ACTION_REQUEST_VEHICLES = 2
local ACTION_SPAWN_VEHICLE = 3
local ACTION_REMOVE_VEHICLE = 4
local ACTION_REQUEST_PAD_CONFIG = 5
local ACTION_OPEN_PAD_CONFIG = 6
local ACTION_APPLY_PAD_CONFIG = 7
local ACTION_CREATE_PAD = 8
local ACTION_OPEN_NEW_PAD_CONFIG = 9
local ACTION_OPEN_CONSOLE_CONFIG = 10
local ACTION_APPLY_CONSOLE_CONFIG = 11
local ACTION_CREATE_CONSOLE = 12

if SERVER then
    util.AddNetworkString( NET_NAME )
end

local function get_sorted_networks()
    local networks = {}

    if SERVER and HALOARMORY.Logistics and isfunction( HALOARMORY.Logistics.SyncNetworks ) then
        networks = HALOARMORY.Logistics.SyncNetworks() or {}
    end

    local sorted = {}
    for network_id in pairs( networks ) do
        table.insert( sorted, tostring( network_id ) )
    end

    table.sort( sorted, function( a, b )
        return tostring( a ) < tostring( b )
    end )

    return sorted
end

if CLIENT then
    local Callbacks = {}
    local function run_callback( action, ... )
        if not Callbacks[action] then return end

        Callbacks[action]( ... )
        Callbacks[action] = nil
    end

    local function open_pad_config_gui_later( pad_ent, networks, spawn_request, categories )
        timer.Simple( 0, function()
            if not isfunction( HALOARMORY.Requisition.OpenPadConfigGUI ) then return end

            HALOARMORY.Requisition.OpenPadConfigGUI( pad_ent, networks, spawn_request, categories )
        end )
    end

    net.Receive( NET_NAME, function()
        local action = net.ReadUInt( 8 )

        if action == ACTION_REQUEST_VEHICLE_PADS then
            local count = net.ReadUInt( 13 )
            local pads = {}

            for i = 1, count do
                table.insert( pads, net.ReadEntity() )
            end

            run_callback( ACTION_REQUEST_VEHICLE_PADS, pads )

        elseif action == ACTION_REQUEST_VEHICLES then
            local count = net.ReadUInt( 32 )
            local vehicles = {}

            for i = 1, count do
                local vehicle_key = net.ReadString()
                local data_len = net.ReadUInt( 32 )
                local data = net.ReadData( data_len )
                local vehicle = util.JSONToTable( util.Decompress( data ) )

                vehicles[vehicle_key] = vehicle
            end

            run_callback( ACTION_REQUEST_VEHICLES, vehicles )

        elseif action == ACTION_SPAWN_VEHICLE then
            local success = net.ReadBool()

            run_callback( ACTION_SPAWN_VEHICLE, success )

        elseif action == ACTION_REMOVE_VEHICLE then
            local success = net.ReadBool()

            run_callback( ACTION_REMOVE_VEHICLE, success )

        elseif action == ACTION_OPEN_PAD_CONFIG then
            local pad_ent = net.ReadEntity()
            local networks = net.ReadTable()
            local categories = net.ReadTable()

            open_pad_config_gui_later( pad_ent, networks, nil, categories )

        elseif action == ACTION_APPLY_PAD_CONFIG then
            local success = net.ReadBool()

            run_callback( ACTION_APPLY_PAD_CONFIG, success )

        elseif action == ACTION_CREATE_PAD then
            local success = net.ReadBool()

            run_callback( ACTION_CREATE_PAD, success )

        elseif action == ACTION_OPEN_CONSOLE_CONFIG then
            local console_ent = net.ReadEntity()

            timer.Simple( 0, function()
                if not isfunction( HALOARMORY.Requisition.OpenConsoleConfigGUI ) then return end

                HALOARMORY.Requisition.OpenConsoleConfigGUI( IsValid( console_ent ) and console_ent or nil )
            end )

        elseif action == ACTION_APPLY_CONSOLE_CONFIG then
            local success = net.ReadBool()

            run_callback( ACTION_APPLY_CONSOLE_CONFIG, success )

        elseif action == ACTION_CREATE_CONSOLE then
            local success = net.ReadBool()

            run_callback( ACTION_CREATE_CONSOLE, success )
        end
    end )

    function HALOARMORY.VEHICLES.NETWORK.RequestVehiclePads( callback, source_ent )
        Callbacks[ACTION_REQUEST_VEHICLE_PADS] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_REQUEST_VEHICLE_PADS, 8 )
            net.WriteEntity( IsValid( source_ent ) and source_ent or NULL )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.RequestVehicles( pad_ent, callback )
        Callbacks[ACTION_REQUEST_VEHICLES] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_REQUEST_VEHICLES, 8 )
            net.WriteEntity( pad_ent )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.SpawnVehicle( pad_ent, vehicle_key, vehicle_options, callback )
        Callbacks[ACTION_SPAWN_VEHICLE] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_SPAWN_VEHICLE, 8 )
            net.WriteEntity( pad_ent )
            net.WriteString( vehicle_key )
            net.WriteTable( vehicle_options )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.RemoveVehicle( pad_ent, vehicle, callback )
        Callbacks[ACTION_REMOVE_VEHICLE] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_REMOVE_VEHICLE, 8 )
            net.WriteEntity( pad_ent )
            net.WriteEntity( vehicle )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.RequestPadConfig( pad_ent )
        net.Start( NET_NAME )
            net.WriteUInt( ACTION_REQUEST_PAD_CONFIG, 8 )
            net.WriteEntity( pad_ent )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.OpenNewPadConfig()
        net.Start( NET_NAME )
            net.WriteUInt( ACTION_OPEN_NEW_PAD_CONFIG, 8 )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.ApplyPadConfig( pad_ent, data, callback )
        Callbacks[ACTION_APPLY_PAD_CONFIG] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_APPLY_PAD_CONFIG, 8 )
            net.WriteEntity( pad_ent )
            net.WriteTable( data or {} )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.CreatePad( class_name, spawn_data, data, callback )
        Callbacks[ACTION_CREATE_PAD] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_CREATE_PAD, 8 )
            net.WriteString( tostring( class_name or "halo_sp_vr_pad" ) )
            net.WriteVector( isvector( spawn_data and spawn_data.spawn_pos ) and spawn_data.spawn_pos or vector_origin )
            net.WriteAngle( isangle( spawn_data and spawn_data.spawn_ang ) and spawn_data.spawn_ang or angle_zero )
            net.WriteTable( data or {} )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.OpenConsoleConfig( console_ent )
        net.Start( NET_NAME )
            net.WriteUInt( ACTION_OPEN_CONSOLE_CONFIG, 8 )
            net.WriteEntity( IsValid( console_ent ) and console_ent or NULL )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.ApplyConsoleConfig( console_ent, data, callback )
        Callbacks[ACTION_APPLY_CONSOLE_CONFIG] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_APPLY_CONSOLE_CONFIG, 8 )
            net.WriteEntity( console_ent )
            net.WriteTable( data or {} )
        net.SendToServer()
    end

    function HALOARMORY.VEHICLES.NETWORK.CreateConsole( spawn_pos, spawn_ang, data, callback )
        Callbacks[ACTION_CREATE_CONSOLE] = callback

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_CREATE_CONSOLE, 8 )
            net.WriteVector( isvector( spawn_pos ) and spawn_pos or vector_origin )
            net.WriteAngle( isangle( spawn_ang ) and spawn_ang or angle_zero )
            net.WriteTable( data or {} )
        net.SendToServer()
    end
end

if SERVER then
    local function can_configure_pad( ply, ent )
        if not IsValid( ply ) or not IsValid( ent ) then return false end

        if not ply:IsAdmin() then
            return false
        end

        return true
    end

    function HALOARMORY.VEHICLES.NETWORK.OpenPadConfig( pad_ent, ply )
        if not IsValid( pad_ent ) or not IsValid( ply ) then return end

        net.Start( NET_NAME )
            net.WriteUInt( ACTION_OPEN_PAD_CONFIG, 8 )
            net.WriteEntity( pad_ent )
            net.WriteTable( get_sorted_networks() )
            net.WriteTable( HALOARMORY.Requisition.GetCategories() )
        net.Send( ply )
    end

    net.Receive( NET_NAME, function( _, ply )
        local action = net.ReadUInt( 8 )

        if action == ACTION_REQUEST_VEHICLE_PADS then
            local source_ent = net.ReadEntity()
            local pads = {}

            local function add_pad( ent )
                if not IsValid( ent ) or not ent.VehiclePad then return end

                if IsValid( source_ent ) and isfunction( source_ent.GetConsoleCategory ) then
                    if not HALOARMORY.Requisition.IsPadCompatibleWithConsole( ent, source_ent ) then
                        return
                    end
                end

                table.insert( pads, ent )
            end

            if ents.Iterator then
                for _, ent in ents.Iterator() do
                    add_pad( ent )
                end
            else
                for _, ent in pairs( ents.GetAll() ) do
                    add_pad( ent )
                end
            end

            table.sort( pads, function( a, b )
                return a:GetPos():Distance( ply:GetPos() ) < b:GetPos():Distance( ply:GetPos() )
            end )

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_REQUEST_VEHICLE_PADS, 8 )
                net.WriteUInt( #pads, 13 )

                for _, pad in ipairs( pads ) do
                    net.WriteEntity( pad )
                end
            net.Send( ply )

        elseif action == ACTION_REQUEST_VEHICLES then
            local pad_ent = net.ReadEntity()

            if not IsValid( pad_ent ) or not pad_ent.VehiclePad then return end

            local vehicles = pad_ent:GetVehicles( ply )

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_REQUEST_VEHICLES, 8 )
                net.WriteUInt( table.Count( vehicles ), 32 )

                for vehicle_key, vehicle in pairs( vehicles ) do
                    net.WriteString( vehicle_key )

                    local data = util.Compress( util.TableToJSON( vehicle ) )
                    local data_len = #data
                    net.WriteUInt( data_len, 32 )
                    net.WriteData( data, data_len )
                end
            net.Send( ply )

        elseif action == ACTION_SPAWN_VEHICLE then
            local pad_ent = net.ReadEntity()
            local vehicle_key = net.ReadString()
            local vehicle_options = net.ReadTable()

            if not IsValid( pad_ent ) or not pad_ent.VehiclePad then return end

            local success = pad_ent:SpawnVehicle( ply, vehicle_key, vehicle_options )

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_SPAWN_VEHICLE, 8 )
                net.WriteBool( success )
            net.Send( ply )

        elseif action == ACTION_REMOVE_VEHICLE then
            local pad_ent = net.ReadEntity()
            local vehicle = net.ReadEntity()

            if not IsValid( pad_ent ) or not pad_ent.VehiclePad then return end
            if not IsValid( vehicle ) then return end

            local success = pad_ent:ReclaimVehicle( ply, vehicle )

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_REMOVE_VEHICLE, 8 )
                net.WriteBool( success )
            net.Send( ply )

        elseif action == ACTION_REQUEST_PAD_CONFIG then
            local pad_ent = net.ReadEntity()

            if not IsValid( pad_ent ) or not pad_ent.VehiclePad then return end
            if not can_configure_pad( ply, pad_ent ) then return end

            HALOARMORY.VEHICLES.NETWORK.OpenPadConfig( pad_ent, ply )

        elseif action == ACTION_OPEN_NEW_PAD_CONFIG then
            -- Open pad config for creating a new pad
            net.Start( NET_NAME )
                net.WriteUInt( ACTION_OPEN_PAD_CONFIG, 8 )
                net.WriteEntity( NULL )
                net.WriteTable( get_sorted_networks() )
                net.WriteTable( HALOARMORY.Requisition.GetCategories() )
            net.Send( ply )

        elseif action == ACTION_APPLY_PAD_CONFIG then
            local pad_ent = net.ReadEntity()
            local config_data = net.ReadTable()
            local success = false

            if IsValid( pad_ent ) and pad_ent.VehiclePad and can_configure_pad( ply, pad_ent ) and isfunction( pad_ent.ApplyPadConfig ) then
                success = pad_ent:ApplyPadConfig( config_data ) == true
            end

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_APPLY_PAD_CONFIG, 8 )
                net.WriteBool( success )
            net.Send( ply )

        elseif action == ACTION_CREATE_PAD then
            local class_name = net.ReadString()
            local spawn_pos = net.ReadVector()
            local spawn_ang = net.ReadAngle()
            local config_data = net.ReadTable()
            local success = false

            class_name = tostring( class_name or "halo_sp_vr_pad" )

            local ent_data = scripted_ents.GetStored( class_name )
            if istable( ent_data ) and istable( ent_data.t ) and ent_data.t.VehiclePad then
                local ent = ents.Create( class_name )
                if IsValid( ent ) then
                    ent:SetPos( spawn_pos )
                    ent:SetAngles( spawn_ang )
                    ent:Spawn()
                    ent:Activate()

                    if ent.CPPISetOwner then
                        ent:CPPISetOwner( ply )
                    end

                    if isfunction( ent.ApplyPadConfig ) then
                        success = ent:ApplyPadConfig( config_data ) == true
                    end

                    if success then
                        undo.Create( "Vehicle Pad" )
                            undo.AddEntity( ent )
                            undo.SetPlayer( ply )
                        undo.Finish()

                        cleanup.Add( ply, "sents", ent )
                        ply:AddCleanup( "sents", ent )
                    else
                        ent:Remove()
                    end
                end
            end

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_CREATE_PAD, 8 )
                net.WriteBool( success )
            net.Send( ply )

        elseif action == ACTION_OPEN_CONSOLE_CONFIG then
            local console_ent = net.ReadEntity()

            if not ply:IsAdmin() then return end

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_OPEN_CONSOLE_CONFIG, 8 )
                net.WriteEntity( IsValid( console_ent ) and console_ent or NULL )
            net.Send( ply )

        elseif action == ACTION_APPLY_CONSOLE_CONFIG then
            local console_ent = net.ReadEntity()
            local config_data = net.ReadTable()
            local success = false

            if IsValid( console_ent ) and ply:IsAdmin() and isfunction( console_ent.ApplyConsoleConfig ) then
                success = console_ent:ApplyConsoleConfig( config_data ) == true
            end

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_APPLY_CONSOLE_CONFIG, 8 )
                net.WriteBool( success )
            net.Send( ply )

        elseif action == ACTION_CREATE_CONSOLE then
            local spawn_pos = net.ReadVector()
            local spawn_ang = net.ReadAngle()
            local config_data = net.ReadTable()
            local success = false

            if not ply:IsAdmin() then return end

            local ent = ents.Create( "halo_sp_vr_console" )
            if IsValid( ent ) then
                ent:SetPos( spawn_pos )
                ent:SetAngles( spawn_ang )
                ent:Spawn()
                ent:Activate()

                if ent.CPPISetOwner then
                    ent:CPPISetOwner( ply )
                end

                if isfunction( ent.ApplyConsoleConfig ) then
                    success = ent:ApplyConsoleConfig( config_data ) == true
                end

                if success then
                    undo.Create( "Requisition Console" )
                        undo.AddEntity( ent )
                        undo.SetPlayer( ply )
                    undo.Finish()

                    cleanup.Add( ply, "sents", ent )
                    ply:AddCleanup( "sents", ent )
                else
                    ent:Remove()
                end
            end

            net.Start( NET_NAME )
                net.WriteUInt( ACTION_CREATE_CONSOLE, 8 )
                net.WriteBool( success )
            net.Send( ply )
        end
    end )
end
