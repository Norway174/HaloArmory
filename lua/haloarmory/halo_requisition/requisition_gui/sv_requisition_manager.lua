HALOARMORY.MsgC("Server HALOARMORY REQUISITION MANAGER loaded!")


HALOARMORY.Requisition = HALOARMORY.Requisition or {}
HALOARMORY.Requisition.Vehicles = HALOARMORY.Requisition.Vehicles or {}
--HALOARMORY.Requisition.VehiclePads = HALOARMORY.Requisition.VehiclePads or {}

HALOARMORY.Requisition.Menu_Users = {}


-- util.AddNetworkString("HALOARMORY.Requisition")


-- function HALOARMORY.Requisition.AddVehiclePad( ent )
--     if not IsValid( ent ) then return end

--     table.insert( HALOARMORY.Requisition.VehiclePads, ent )
-- end

-- function HALOARMORY.Requisition.RemoveVehiclePad( ent )
--     if not IsValid( ent ) then return end

--     if not table.HasValue( HALOARMORY.Requisition.VehiclePads, ent ) then return end

--     table.RemoveByValue( HALOARMORY.Requisition.VehiclePads, ent )
-- end


// How to get the MRS rank of a player: MRS.GetNWdata(ply, "Rank")

local AuthList = AuthList or {}
// self, ply, VehicleInQueue, function( Auth, MsgBack )
function HALOARMORY.Requisition.AuthorizeVehicle( vehiclePad, ply, vehicle, callback )

    if not IsValid( ply ) then callback(false, "Invalid Player") return end
    if not istable( vehicle ) then callback(false, "Invalid Vehicle") return end

    if DarkRP then

        return callback( true, "DarkRP" )

    end

end


-- net.Receive( "HALOARMORY.Requisition", function( len, ply )
--     local Action = net.ReadString()

--     if Action == "Register-User" then
--         HALOARMORY.Requisition.Menu_Users[ ply ] = true

--         net.Start( "HALOARMORY.Requisition" )
--             net.WriteString( "Menu-Init" )
--             --print( "Sending Menu-Init", tonumber(#HALOARMORY.Requisition.VehiclePads), type( #HALOARMORY.Requisition.VehiclePads ) )

--             local VehiclePads = HALOARMORY.Requisition.VehiclePads

--             // Sort the VehiclePads by distance to the ply
--             table.sort( VehiclePads, function( a, b )
--                 return a:GetPos():Distance( ply:GetPos() ) < b:GetPos():Distance( ply:GetPos() )
--             end )
            
--             net.WriteInt( tonumber(#VehiclePads), 14 )

--             for k, v in pairs( VehiclePads ) do
--                 net.WriteEntity( v )
--             end

--         net.Send( ply )

--     elseif Action == "Un-Register-User" then
--         HALOARMORY.Requisition.Menu_Users[ ply ] = nil

--     elseif Action == "Request-Vehicle" then
--         local VehiclePad = net.ReadEntity()
--         if not IsValid( VehiclePad ) then return end

--         local Vehicle = net.ReadString()
--         local Vehicle_Skin = net.ReadString()
--         local Vehicle_Loadout = net.ReadString()

--         print( "Requesting Vehicle", Vehicle, Vehicle_Skin, Vehicle_Loadout )

--         VehiclePad:SpawnVehicle( ply, Vehicle, Vehicle_Skin, Vehicle_Loadout )

--     end

-- end )


