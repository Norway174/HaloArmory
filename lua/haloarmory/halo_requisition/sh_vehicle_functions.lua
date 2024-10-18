HALOARMORY.MsgC("Shared Vehicle Config Loaded!")

HALOARMORY.VEHICLES = HALOARMORY.VEHICLES or {}
HALOARMORY.Requisition = HALOARMORY.Requisition or {}

if SERVER then
    // Load vehicles server side
    HALOARMORY.VEHICLES.ADMIN = HALOARMORY.VEHICLES.ADMIN or {}
    HALOARMORY.VEHICLES.LIST = HALOARMORY.VEHICLES.LIST or {}

    function HALOARMORY.VEHICLES.INIT()
        HALOARMORY.MsgC("Loading Vehicles...")

        if isfunction( HALOARMORY.VEHICLES.ADMIN.LOADVEHICLES ) then
            HALOARMORY.VEHICLES.ADMIN.LOADVEHICLES()

            HALOARMORY.MsgC("Loaded Vehicles:", table.Count( HALOARMORY.VEHICLES.LIST ) )
        else
            HALOARMORY.MsgC("Too soon! Unable to load vehicles at this time." )
        end

    end

    hook.Add("InitPostEntity", "HALOARMORY.VEHICLES.INIT", HALOARMORY.VEHICLES.INIT)
    timer.Simple( 5, HALOARMORY.VEHICLES.INIT )
end


function HALOARMORY.Requisition.RefundAmount( vehicle )
    if not IsValid( vehicle ) then return 0 end

    local refund_amount = vehicle:GetNW2Int( "HALOARMORY_COST", 0 )

    --print( "fdgfhRefund Amount:", refund_amount )

    if refund_amount == 0 then return 0 end

    // Get the vehicle health in percentage. And refund that percentage of the cost.
    local health = vehicle:Health()
    --print( "Health:", health )
    // Check if the health is 0, and if the vehicle is a old? simfphys vehicle. If so, get the old? simfphys health.
    if health == 0 and vehicle.GetHP then
        health = vehicle:GetHP()
        --print( "Vehicle is old simfphys, getting simfphys health.", health )
    end
    // Check if the health is 0, and if the vehicle is a simfphys vehicle. If so, get the simfphys health.
    if health == 0 and vehicle.GetCurHealth then
        health = vehicle:GetCurHealth()
        --print( "Vehicle is new simfphys, getting simfphys health.", health )
    end

    local max_health = vehicle:GetMaxHealth()
    --print( "Max Health:", max_health )
    // Check if the max health is 0, and if the vehicle is a simfphys vehicle. If so, get the simfphys max health.
    if max_health == 0 and vehicle.GetMaxHP then
        max_health = vehicle:GetMaxHP()
        --print( "Vehicle is simfphys, getting simfphys max health.", max_health )
    end

    if max_health == 0 then return refund_amount end
    
    local health_percentage = health / max_health
    refund_amount = refund_amount * health_percentage

    --print( "Refund Amount:", refund_amount, "Health Percentage:", health_percentage, "Health:", health, "Max Health:", max_health)
    --PrintTable( vehicle:GetTable() )

    refund_amount = math.Round( refund_amount )

    return refund_amount
end


function HALOARMORY.Requisition.GetModelAndNameFromVehicle( VehicleClass )

    local Vehicle_Ent = scripted_ents.Get( VehicleClass )

    if Vehicle_Ent == nil then
        // Might be Simfphys
        Vehicle_Ent = list.Get("simfphys_vehicles")[VehicleClass]
    end

    if Vehicle_Ent == nil then
        local veh_list = list.Get( "Vehicles" )
        if istable( veh_list ) then
            Vehicle_Ent = veh_list[VehicleClass]
        end
    end

    if Vehicle_Ent == nil then
        return nil, "", ""
    end

    local VehiclePrintName = Vehicle_Ent.PrintName or Vehicle_Ent.Name
    local VehicleModel = Vehicle_Ent.Model or Vehicle_Ent.MDL

    return Vehicle_Ent, VehicleModel, VehiclePrintName

end
