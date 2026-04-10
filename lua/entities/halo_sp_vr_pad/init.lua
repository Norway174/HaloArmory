AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )


ENT.lights = ENT.lights or {}

function ENT:SpawnFunction( ply, tr, class_name )
    if not tr.Hit then return end

    if not IsValid( ply ) then return end

    ply:ConCommand( "haloarmory_open_pad_menu" )
end

function ENT:PostInit()
    timer.Simple( 0, function()
        if not IsValid( self ) then return end

        self:ApplyPadModel( self:GetModel() )
        self:RefreshLights()
    end )
end

function ENT:ApplyPadModelRuntimeFlags()
    local render_helipad = self:ShouldRenderHelipad()
    local phys = self:GetPhysicsObject()
    local collision_group = render_helipad and COLLISION_GROUP_PASSABLE_DOOR or COLLISION_GROUP_NONE

    self:DrawShadow( not render_helipad )
    self:SetNotSolid( false )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( collision_group )

    if IsValid( phys ) then
        phys:EnableCollisions( true )
    end

    self:CollisionRulesChanged()
end

function ENT:ClearLights()
    for index, light in pairs( self.lights ) do
        if IsValid( light ) then
            light:Remove()
        end

        self.lights[index] = nil
    end
end

function ENT:CreateLights()
    self:ClearLights()

    if not self:GetSpawnLights() then return end

    local segments = self:GetSegments()
    if segments <= 0 then return end

    local radius = self:GetRadius()

    for i = 1, segments do
        local light = ents.Create( "gmod_light" )
        if not IsValid( light ) then continue end

        local angle = ( i - 1 ) * ( 360 / segments )
        local x = radius * math.cos( math.rad( angle ) )
        local y = radius * math.sin( math.rad( angle ) )

        light:SetPos( self:GetPos() + Vector( x, y, 0 ) )
        light:SetParent( self )
        light:Spawn()
        light:SetRenderMode( RENDERMODE_TRANSCOLOR )
        light:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

        self:DeleteOnRemove( light )
        self.lights[i] = light
    end

    self:UpdateLights()
end

function ENT:RefreshLights()
    if not self:GetSpawnLights() then
        self:ClearLights()
        return
    end

    self:CreateLights()
end

function ENT:UpdateLights()
    if not self:GetSpawnLights() then
        self:ClearLights()
        return
    end

    for index, light in pairs( self.lights ) do
        if not IsValid( light ) then
            self.lights[index] = nil
            continue
        end

        local light_color = self:GetLightColor():ToColor()
        light_color.a = 1

        light:SetColor( light_color )
        light:SetBrightness( self:GetLightBrightness() )
        light:SetLightSize( self:GetLightSize() )
        light:SetLightWorld( not self:GetLightWorld() )
        light:SetLightModels( not self:GetLightModel() )
        light:SetOn( self:GetLightOn() )
    end
end

function ENT:UpdateOnPad()
    local pos = self:GetPos() + self:GetVehicleSpawnPos()
    local closest_ent = nil
    local closest_distance = math.huge

    for _, ent in pairs( ents.FindInSphere( pos, self:GetVehicleSpawnRadius() ) ) do
        if ent == self then continue end
        if ent.HALOARMORY_Ships_Presets then continue end
        if ent:IsPlayer() or ent:IsNPC() or ent:IsWeapon() then continue end
        if IsValid( ent:GetParent() ) then continue end

        if ent.LVS or ent.LVSsimfphys or ent.IsSimfphyscar or ent:IsVehicle() then
            local distance = ent:GetPos():Distance( pos )
            if distance < closest_distance then
                closest_distance = distance
                closest_ent = ent
            end
        end
    end

    self:SetOnPad( IsValid( closest_ent ) and closest_ent or NULL )
end

function ENT:PadThink()
    if not self:GetSpawnLights() then return end
    if not self:GetLightAutoChange() then return end

    if IsValid( self:GetOnPad() ) then
        self:SetLightColor( Color( 255, 0, 0 ):ToVector() )
    else
        self:SetLightColor( Color( 0, 255, 0 ):ToVector() )
    end
end

function ENT:Think()
    self:NextThink( CurTime() + 1 )

    self:UpdateOnPad()
    self:PadThink()

    return true
end

function ENT:SpawnVehicle( ply, vehicle_key, vehicle_options )
    local vehicle_table = self:GetVehicles( ply )[vehicle_key]
    if not vehicle_table then
        return false
    end

    local vehicle_in_queue = {
        vehicle_key = vehicle_key,
        vehicle_table = vehicle_table,
        options = vehicle_options or {},
        authorization = {
            requester = ply,
            authorized = false,
            authorized_by = nil,
            authorized_at = nil,
            requested_at = CurTime(),
        }
    }

    HALOARMORY.Requisition.AuthorizeVehicle( self, ply, vehicle_in_queue, function( auth )
        if not auth then return end

        local network_name = self:GetNetworkID()
        if not network_name then return end
        if not self:CanAfford( vehicle_table ) then return end

        local vehicle_ent = vehicle_table.entity
        local pos = self:GetPos() + self:GetVehicleSpawnPos()
        local ang = self:GetAngles() + self:GetVehicleSpawnAng()

        local vehicle = nil

        if simfphys and list.Get( "simfphys_vehicles" )[vehicle_ent] then
            vehicle = simfphys.SpawnVehicleSimple( vehicle_ent, pos, ang )

        elseif list.Get( "Vehicles" )[vehicle_ent] then
            local engine_veh = list.Get( "Vehicles" )[vehicle_ent]
            if not engine_veh.Class or not engine_veh.Model then return end

            vehicle = ents.Create( engine_veh.Class )
            vehicle:SetModel( engine_veh.Model )
            vehicle:SetPos( pos )
            vehicle:SetAngles( self:GetAngles() + Angle( 0, 180, 0 ) )
            vehicle:SetKeyValue( "vehiclescript", engine_veh.KeyValues.vehiclescript )
            vehicle:Spawn()
            vehicle:Activate()

        else
            vehicle = ents.Create( vehicle_ent )
            vehicle:SetPos( pos )
            vehicle:SetAngles( ang )
            vehicle:Spawn()
        end

        timer.Simple( 0.1, function()
            if not IsValid( vehicle ) then return end

            if vehicle_in_queue.options.color then
                local selected_color = vehicle_table.colors[vehicle_in_queue.options.color]
                if IsColor( selected_color ) then
                    vehicle:SetColor( selected_color )
                end
            end

            if vehicle_in_queue.options.skin then
                local selected_skin = vehicle_table.skins[vehicle_in_queue.options.skin]
                if isnumber( selected_skin ) then
                    vehicle:SetSkin( selected_skin )
                end
            end

            if istable( vehicle_in_queue.options.bodygroups ) then
                for bodygroup_name, bodygroup_value in pairs( vehicle_in_queue.options.bodygroups ) do
                    vehicle:SetBodygroup( vehicle:FindBodygroupByName( bodygroup_name ), bodygroup_value )
                end
            end
        end )

        timer.Simple( 0.5, function()
            if not IsValid( vehicle ) then return end

            local phys_veh = vehicle:GetPhysicsObject()
            if IsValid( phys_veh ) and not phys_veh:IsMotionEnabled() then
                phys_veh:EnableMotion( true )
            end

            if vehicle.SetAITEAM then
                vehicle:SetAITEAM( ply:lfsGetAITeam() )
            end
        end )

        if not IsValid( vehicle ) then
            return
        end

        if vehicle.CPPISetOwner then
            vehicle:CPPISetOwner( ply )
        end

        if IsValid( vehicle ) and self:GetRequiresSupplies() then
            local success = HALOARMORY.Logistics.AddNetworkSupplies( network_name, -vehicle_table.cost )

            if not success then
                vehicle:Remove()
                return
            end

            vehicle:SetNW2Int( "HALOARMORY_COST", vehicle_table.cost )
        end
    end )

    return true
end

function ENT:ReclaimVehicle( _, vehicle )
    if not self:GetRequiresSupplies() then
        vehicle:Remove()
        return true
    end

    local network_name = self:GetNetworkID()
    if not network_name or not HALOARMORY.Logistics.Networks[network_name] then
        return false
    end

    if not IsValid( vehicle ) then
        return false
    end

    local refund_amount = HALOARMORY.Requisition.RefundAmount( vehicle )
    HALOARMORY.Logistics.AddNetworkSupplies( network_name, refund_amount )
    vehicle:Remove()

    return true
end

function ENT:GetVehicles( _ )
    local vehicles = {}

    for vehicle_key, vehicle_data in pairs( HALOARMORY.VEHICLES.LIST or {} ) do
        local normalized = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_data ) )

        if HALOARMORY.Requisition.VehicleHasCategory( normalized, self:GetPadCategory() ) then
            vehicles[vehicle_key] = normalized
        end
    end

    return vehicles
end
