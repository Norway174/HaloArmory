
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")



function ENT:PostInit()

    --HALOARMORY.Requisition.AddVehiclePad( self )

end

function ENT:OnRemove()

    --HALOARMORY.Requisition.RemoveVehiclePad( self )

end


function ENT:UpdateOnPad()

    local pos = self:GetPos() + self.VehicleSpawnPos
    // Check if there is a vehicle on the pad.
    local nearby_ent = {}

    // Remove self from the table.
    for k, v in pairs( ents.FindInSphere( pos, self.VehicleSpawnRadius ) ) do

        //print( "Found:", v:GetClass() )
        if v == self then continue end
        if v.HALOARMORY_Ships_Presets then continue end

        if v:IsPlayer() then
            continue
        end

        if v:IsNPC() then
            continue
        end

        // Check if v has a parent.
        if IsValid( v:GetParent() ) then
            continue
        end

        if v:IsWeapon() then
            continue
        end

        if v.LVS then
            table.insert( nearby_ent, v )
            continue
        end

        if v.LVSsimfphys then
            table.insert( nearby_ent, v )
            continue
        end

        if v.IsSimfphyscar then
            table.insert( nearby_ent, v )
            continue
        end

        if v:IsVehicle() then
            table.insert( nearby_ent, v )
            continue
        end

    end

    // Sort nearby entities by distance. And return the closest one.
    table.sort( nearby_ent, function( a, b )
        return a:GetPos():Distance( pos ) < b:GetPos():Distance( pos )
    end )

    local closest_ent = nil

    if IsValid(nearby_ent[1]) then closest_ent = nearby_ent[1] end

    if self:GetOnPad() ~= closest_ent then
        self:SetOnPad( closest_ent )
    end

    // Debug overlay
    debugoverlay.EntityTextAtPosition( pos, 0, tostring( table.Count( nearby_ent ) ) )
    local ind = 1
    for key, value in pairs(nearby_ent) do
        debugoverlay.EntityTextAtPosition( pos, ind, tostring( value ) )
        ind = ind + 1
    end

end

function ENT:AirPadThink()
end

function ENT:Think()

    self:NextThink( CurTime() + 1 )

    self:UpdateOnPad()

    self:AirPadThink()

end


function ENT:SpawnVehicle( ply, vehicle_key, vehicle_options )

    print( "Adding to queue", ply, vehicle_key, vehicle_options )

    local VehicleTable = self:GetVehicles( ply )[vehicle_key]

    if not VehicleTable then
        print( "Vehicle table is invalid" )
        return
    end

    print( "Vehicle is valid" )



    print( "Loadout and skin are valid" )

    local VehicleInQueue = {
        vehicle_key = vehicle_key,
        vehicle_table = VehicleTable,
        options = vehicle_options,
        authorization = {
            requester = ply,
            authorized = false,
            authorized_by = nil,
            authorized_at = nil,
            requested_at = CurTime(),
        }
    }

    --table.insert( self.VehicleQueue, VehicleInQueue )

    HALOARMORY.Requisition.AuthorizeVehicle( self, ply, VehicleInQueue, function( Auth, MsgBack )
    
        --print( "Authed:", Auth, MsgBack )

        if Auth then
            
            --print( "Spawn:", VehicleInQueue )
            --PrintTable( VehicleInQueue )

            local network_name = self:GetNetworkID()

            if not network_name then
                --print( "Network name is invalid" )
                return
            end

            if not self:CanAfford( VehicleTable ) then
                --print( "Not enough supplies" )
                return
            end

            local vehicle_ent = VehicleTable.entity

            local Pos = self:GetPos() + self.VehicleSpawnPos
            local Ang = self:GetAngles() + self.VehicleSpawnAng

            local Vehicle = nil

            --print( "Spawning vehicle", vehicle_ent)

            if simfphys and list.Get( "simfphys_vehicles" )[ vehicle_ent ] then
                --print( "Spawning simfphys vehicle" )
                Vehicle = simfphys.SpawnVehicleSimple( vehicle_ent, Pos, Ang )


            elseif list.Get("Vehicles")[vehicle_ent] then
                local engineVeh = list.Get("Vehicles")[vehicle_ent]
                --print( "Spawning engine vehicle", engineVeh )

                --PrintTable( engineVeh )

                if not engineVeh.Class or not engineVeh.Model then return end

                --print( "Spawning engine vehicle", engineVeh.Class, engineVeh.Model, engineVeh.KeyValues.vehiclescript )

                Vehicle = ents.Create( engineVeh.Class )
                Vehicle:SetModel( engineVeh.Model )


                // Set the vehicle position
                Vehicle:SetPos( Pos )
                Vehicle:SetAngles( self:GetAngles() + Angle( 0, 180, 0 ) )

                Vehicle:SetKeyValue( "vehiclescript", engineVeh.KeyValues.vehiclescript ) 

                Vehicle:Spawn()
                Vehicle:Activate()


            else
                --print( "Spawning normal vehicle" )
                Vehicle = ents.Create( vehicle_ent )

                Vehicle:SetPos( Pos )
                Vehicle:SetAngles( self:GetAngles() + Angle( 0, -90, 0 ) )

                Vehicle:Spawn()

            end

            // Set the options here
            if VehicleInQueue.options.color then
                local selectedColor = VehicleTable.colors[VehicleInQueue.options.color]
                if IsColor(selectedColor) then
                    Vehicle:SetColor( selectedColor )
                end
            end

            if VehicleInQueue.options.skin then
                local selectedSkin = VehicleTable.skins[VehicleInQueue.options.skin]
                if isnumber(selectedSkin) then
                    Vehicle:SetSkin( selectedSkin )
                end
            end

            if VehicleInQueue.options.bodygroups then
                local selectedBodygroups = VehicleInQueue.options.bodygroups
                if istable(selectedBodygroups) then
                    for k, v in pairs(selectedBodygroups) do
                        local BodygroupVal = VehicleTable.bodygroups[k][v]
                        Vehicle:SetBodygroup( Vehicle:FindBodygroupByName( k ), BodygroupVal )
                    end
                end
            end

            timer.Simple( 0.5, function()
                // If vehicle is frozen, unfreeze it
                local physVeh = Vehicle:GetPhysicsObject()
                if IsValid( physVeh ) then
                    --print( "Unfreezing vehicle", not physVeh:IsMotionEnabled() )
                    if not physVeh:IsMotionEnabled() then
                        physVeh:EnableMotion( true )
                    end
                end

                // Set the AI Team of the vehicle to the player's AI Team
                if Vehicle.SetAITEAM then
                    local plyAITeam = ply:lfsGetAITeam()
                    Vehicle:SetAITEAM( plyAITeam )
                end

            end )




            // Set the owner of the vehicle
            Vehicle:CPPISetOwner(ply)

            // Remove the supplies from the network
            if IsValid( Vehicle ) and self:GetRequiresSupplies() then
                
                local success, new_supplies = HALOARMORY.Logistics.AddNetworkSupplies( network_name, -VehicleTable.cost )

                // If the supplies were not removed, remove the vehicle.
                if not success then
                    Vehicle:Remove()
                    return
                end

                
                --Vehicle.HALOARMORY_COST = VehicleTable.cost
                Vehicle:SetNW2Int( "HALOARMORY_COST", VehicleTable.cost )
                
            end

        end
    
    end)

    return true

end


function ENT:ReclaimVehicle( ply, vehicle )

    if not self:GetRequiresSupplies() then
        vehicle:Remove()
        return true
    end

    local network_name = self:GetNetworkID()

    if not network_name then
        print( "Network name is invalid" )
        return
    end

    if not IsValid( vehicle ) then
        print( "Vehicle is invalid" )
        return
    end

    local refund_amount = HALOARMORY.Requisition.RefundAmount( vehicle )

    print( "Refund amount:", refund_amount )

    HALOARMORY.Logistics.AddNetworkSupplies( network_name, refund_amount )

    vehicle:Remove()

    return true

end


function ENT:GetVehicles( ply )
    // Global vehicle table: HALOARMORY.VEHICLES.LIST
    // Check the table for any vehicles that match any of the options in self.VehicleSize

    local vehicles = HALOARMORY.VEHICLES.LIST

    // TODO: Complete this function

    return vehicles
end

