HALOARMORY.MsgC("Server Vehicle Pickup loaded!")

HALOARMORY.Vehicles = HALOARMORY.Vehicles or {}


--[[ 
##============================##
||                            ||
||   Local Helper Functions   ||
||                            ||
##============================##

 ]]

local function getEntMass( ent )
    if not IsValid( ent ) then return 0 end

    local phys = ent:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        return phys:GetMass()
    else
        return 0
    end
end

local function setEntMass( ent, mass )
    if not IsValid( ent ) then return end
    mass = mass or 0

    local phys = ent:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:SetMass( mass )
    end
end

local function getEntMotion( ent )
    if not IsValid( ent ) then return nil end

    local phys = ent:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        return phys:IsMotionEnabled()
    else
        return nil
    end
end

local function setEntMotion( ent, enable )
    if not IsValid( ent ) then return end
    enable = not enable or false

    local phys = ent:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:EnableMotion( not enable )
    end
end



--[[ 
##============================##
||                            ||
||  Global Helper Functions   ||
||                            ||
##============================##
]]




--[[ 
##============================##
||                            ||
||    Global Main Function    ||
||            LOAD            ||
||                            ||
##============================##
 ]]

function HALOARMORY.Vehicles.LoadVehicle( vehicle )

    if not vehicle then
        --print( "Not a valid Vehicle", vehicle )
        HALOARMORY.MsgC( Color(255,0,0), "Not a valid Vehicle" )
        return
    end

    // Find the back position
    local pos = vehicle:GetPos()
    local offsets = HALOARMORY.Vehicles.allowedVehicles[vehicle.GetSpawn_List and vehicle:GetSpawn_List() or vehicle:GetClass()]

    if offsets.pos and offsets.rad then
        offsets = {
            {
                ["pos"] = offsets.pos,
                ["rad"] = offsets.rad,
            }
        }
    end

    local foundObjects = {}

    for k, v in pairs(offsets) do
        --print(k, v)
            
        local offset = v.pos
        pos = vehicle:LocalToWorld(offset)

        local radius = v.rad

        -- Draw the wireframe sphere!
        table.Add( foundObjects, ents.FindInSphere( pos, radius ) )
    end
    
    -- --local offset = Vector(-500, 0, 60)
    -- local offset = HALOARMORY.Vehicles.allowedVehicles[vehicle.GetSpawn_List and vehicle:GetSpawn_List() or vehicle:GetClass()].pos
    -- pos = vehicle:LocalToWorld(offset)

    -- local radius = HALOARMORY.Vehicles.allowedVehicles[vehicle.GetSpawn_List and vehicle:GetSpawn_List() or vehicle:GetClass()].rad

    -- // Find all the props in the position
    -- local foundObjects = ents.FindInSphere( pos, radius )
    local objectsToLoad = {}

    local ignoreObjects = {}

    local index_Num = 1

    for _, obj in pairs(foundObjects) do

        --print( obj )
        if not HALOARMORY.Vehicles.allowedObjectsToLoad[obj:GetClass()] then continue end
        if ignoreObjects[obj] then continue end
        if not IsValid(obj) then continue end
        if obj == vehicle then continue end
        --if not util.IsInWorld( obj:GetPos() ) then continue end
        if IsValid(vehicle.wheel_R) and obj == vehicle.wheel_R then continue end
        if IsValid(vehicle.wheel_L) and obj == vehicle.wheel_L then continue end
        if IsValid(vehicle.wheel_C) and obj == vehicle.wheel_C then continue end

        --if constraint.HasConstraints( obj ) then continue end

        if getEntMotion( obj ) == false then continue end

        if obj["MassOffset"] and IsValid(obj["MassOffset"]) then
            ignoreObjects[obj["MassOffset"]] = true
        end


        --print( "Object: ", obj )
        --PrintTable( obj:GetTable() )

        local alreadyLoaded = false
        for _, obj2 in pairs(vehicle.LoadedObjects or {}) do
            --print( "Checking: ", obj2["ent"], obj )
            if obj2["ent"] == obj then
                --print( "Already Loaded: ", obj )
                alreadyLoaded = true
                break
            end
        end

        if alreadyLoaded then
            index_Num = index_Num + 1
            continue
        end


        -- for k, v in pairs( vehicle:GetNW2VarTable() ) do

        --     // check if the var name starts with "HALOARMORY.Vehicles.LoadedObject_"
        --     if not string.StartWith( k, "HALOARMORY.Vehicles.LoadedObject_" ) then
        --         continue
        --     end

        --     if IsValid( vehicle:GetNW2Entity( k ) ) then
        --         index_Num = index_Num + 1
        --     end

        -- end

        // Special case for imp_halo_cov_shadow
        if vehicle:GetClass() == "imp_halo_cov_shadow" and obj:GetClass() == "imp_halo_shadowseats" then
            obj:SetPos( vehicle:LocalToWorld(Vector(0,0,0)) )
            obj:SetAngles( vehicle:GetAngles() )
        end


        theWeld = constraint.Weld( vehicle, obj, 0, 0, 0, false, false )

        if not IsValid(theWeld) then continue end

        local objectSave = {}
        objectSave["ent"] = obj
        objectSave["const"] = theWeld
        objectSave["custom"] = {}

        objectSave["custom"]["mass"] = getEntMass( obj )
        objectSave["custom"]["collision"] = obj:GetSolidFlags()

        setEntMass( obj, math.min(objectSave["custom"]["mass"], 50) )
        setEntMotion( obj, true )
        obj:SetSolidFlags( bit.bor( FSOLID_CUSTOMBOXTEST ) )

        --print( "Index: ", index_Num )

        vehicle:SetNW2Entity( "HALOARMORY.Vehicles.LoadedObject_"..index_Num, obj )

        

        vehicle.LoadedObjects = vehicle.LoadedObjects or {}
        vehicle.LoadedObjects[index_Num] = objectSave

        index_Num = index_Num + 1

    end

    --PrintTable( vehicle.LoadedObjects )

    --PrintTable( vehicle:GetNW2VarTable() )


    // Emit the unload sound
    vehicle:EmitSound( "buttons/button5.wav" )


end


--[[ 
##============================##
||                            ||
||    Global Main Function    ||
||           UNLOAD           ||
||                            ||
##============================##
 ]]

function HALOARMORY.Vehicles.UnLoadVehicle( vehicle )

    if not vehicle then
        --print( "Not a valid Vehicle", vehicle )
        HALOARMORY.MsgC( Color(255,0,0), "Not a valid Vehicle" )
        return
    end

    // Special case for imp_halo_cov_shadow
    if vehicle:GetClass() == "imp_halo_cov_shadow" then
        for k, v in pairs( constraint.FindConstraints( vehicle, "Weld" ) ) do
            if v.Ent1 == vehicle and v.Ent2:GetClass() == "imp_halo_shadowseats" then
                v.Constraint:Remove()
            end
        end
    end

    for NWindex, obj in pairs(vehicle.LoadedObjects or {}) do

        local Const = obj["const"]
        
        if IsValid( Const ) and Const:IsConstraint() then
            Const:Remove()
        end

        setEntMass( obj["ent"], obj["custom"]["mass"] )

        if IsValid( obj["ent"] ) and obj["custom"]["collision"] then
            obj["ent"]:SetSolidFlags( obj["custom"]["collision"] )
        end

        vehicle:SetNW2Entity( "HALOARMORY.Vehicles.LoadedObject_"..NWindex, NULL )

    end

    vehicle.LoadedObjects = nil

    // Emit the unload sound
    vehicle:EmitSound( "buttons/button6.wav" )

end


--[[ 
##============================##
||                            ||
||      Console Commands      ||
||                            ||
##============================##
 ]]

concommand.Add( "VEHICLE.Load", function( ply, cmd, args )
    local veh = HALOARMORY.Vehicles.GetFromTraceVehicle( ply )
    HALOARMORY.Vehicles.LoadVehicle( veh )
end )

concommand.Add( "VEHICLE.Unload", function( ply, cmd, args )
    local veh = HALOARMORY.Vehicles.GetFromTraceVehicle( ply )
    HALOARMORY.Vehicles.UnLoadVehicle( veh )
end )

concommand.Add( "VEHICLE.ToggleLoad", function( ply, cmd, args )
    local veh = HALOARMORY.Vehicles.GetFromTraceVehicle( ply )

    if veh.LoadedObjects then
        HALOARMORY.Vehicles.UnLoadVehicle( veh )
    else
        HALOARMORY.Vehicles.LoadVehicle( veh )
    end
    
end )


-- concommand.Add( "VEHICLE.DebugSV", function( ply, cmd, args )
--     local veh = HALOARMORY.Vehicles.GetFromTraceVehicle( ply )
    
--     --PrintTable( veh:GetNW2VarTable() )

--     PrintTable( veh.LoadedObjects or {} )
-- end )


--[[ 
##============================##
||                            ||
||      Network Commands      ||
||                            ||
##============================##
 ]]





-- if CLIENT then

--     local tr = util.TraceLine( util.GetPlayerTrace( LocalPlayer() ) )
--     if IsValid(tr.Entity) then
--         print(tr.Entity)

--         --PrintTable( list.Get( "simfphys_vehicles" ) )

--         --PrintTable( list.Get( "simfphys_vehicles" )[tr.Entity:GetSpawn_List()].name )

--         print( tr.Entity:GetClass():lower() == "gmod_sent_vehicle_fphysics_base" )

--         --print( tr.Entity:GetSpawn_List() )
--     end

-- end

-- print( list.Get( "simfphys_vehicles" )[tr.Entity:GetSpawn_List()]["Name"] )