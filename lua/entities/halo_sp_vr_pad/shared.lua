ENT.Type = "anim"
ENT.Base = "halo_sp_base"

ENT.PrintName = "Vehicle Pad"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true
ENT.Editable = false
ENT.HALOARMORY_Device = true
ENT.AllowPadConfig = true

ENT.DeviceName = "Vehicle Requisition Pad"
ENT.DeviceType = "vehicle_requisition_pad"
ENT.DeviceIcon = "vgui/haloarmory/icons/anchor.png"
ENT.DeviceModel = HALOARMORY.Requisition and HALOARMORY.Requisition.GetDefaultPadModel and HALOARMORY.Requisition.GetDefaultPadModel() or "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc_small.mdl"

ENT.VehiclePad = true
ENT.RequiresSupplies = true
ENT.VehicleQueue = {}

ENT.LegacySpawnLights = false
ENT.LegacyPadCategory = "default"
ENT.LegacyLightDefaults = {
    Segments = 6,
    Radius = 370,
    LightAutoChange = true,
    LightOn = true,
    LightColor = Color( 0, 50, 0 ),
    LightBrightness = 2,
    LightSize = 256,
    LightWorld = true,
    LightModel = true,
}

function ENT:SetupModel()
end

local function schedule_light_refresh( ent )
    timer.Create( "HALOARMORY.VRPAD.RefreshLights." .. ent:EntIndex(), 0.1, 1, function()
        if not IsValid( ent ) then return end
        if not isfunction( ent.RefreshLights ) then return end

        ent:RefreshLights()
    end )
end

local function schedule_light_update( ent )
    timer.Create( "HALOARMORY.VRPAD.UpdateLights." .. ent:EntIndex(), 0.1, 1, function()
        if not IsValid( ent ) then return end
        if not isfunction( ent.UpdateLights ) then return end

        ent:UpdateLights()
    end )
end

local function normalize_model_path( value )
    return string.Trim( string.lower( tostring( value or "" ) ) )
end

local function get_model_config_for_entity( ent )
    local requisition = HALOARMORY and HALOARMORY.Requisition
    if not istable( requisition ) then
        return nil
    end

    local config = requisition.Config
    local pad_models = istable( config ) and config.PadModels or nil
    if not istable( pad_models ) then
        return nil
    end

    local current_model = normalize_model_path( IsValid( ent ) and ent:GetModel() or nil )
    if current_model == "" then
        return nil
    end

    for _, model_data in ipairs( pad_models ) do
        if not istable( model_data ) then continue end
        if normalize_model_path( model_data.model ) ~= current_model then continue end

        return model_data
    end

    return nil
end

local function get_model_config_value( ent, key, fallback )
    local model_data = get_model_config_for_entity( ent )
    if istable( model_data ) and model_data[key] ~= nil then
        return model_data[key]
    end

    return fallback
end

function ENT:CustomDataTables()
    self:NetworkVar( "Int", 2, "PadID", { KeyName = "PadID", Edit = { type = "Int", order = 1, min = 0, max = 999999 } } )
    self:NetworkVar( "String", 3, "PadCategory", {
        KeyName = "PadCategory",
        Edit = {
            type = "Combo",
            order = 2,
            values = HALOARMORY.Requisition.GetCategoryValues(),
        }
    } )

    self:NetworkVar( "Entity", 1, "OnPad" )
    self:NetworkVar( "Entity", 2, "Building" )

    self:NetworkVar( "Bool", 0, "RequiresSupplies", { KeyName = "RequiresSupplies", Edit = { type = "Boolean", order = 3 } } )
    self:NetworkVar( "Bool", 1, "SpawnLights", { KeyName = "SpawnLights", Edit = { type = "Boolean", order = 4, category = "Lights" } } )
    self:NetworkVar( "Bool", 2, "LightAutoChange", { KeyName = "LightAutoChange", Edit = { type = "Boolean", order = 5, category = "Lights" } } )
    self:NetworkVar( "Bool", 3, "LightOn", { KeyName = "LightOn", Edit = { type = "Boolean", order = 6, category = "Lights" } } )
    self:NetworkVar( "Bool", 4, "LightWorld", { KeyName = "LightWorld", Edit = { type = "Boolean", order = 7, category = "Lights" } } )
    self:NetworkVar( "Bool", 5, "LightModel", { KeyName = "LightModel", Edit = { type = "Boolean", order = 8, category = "Lights" } } )

    self:NetworkVar( "Int", 0, "Segments", { KeyName = "Segments", Edit = { type = "Int", order = 9, min = 0, max = 360, category = "Lights" } } )
    self:NetworkVar( "Int", 1, "Radius", { KeyName = "Radius", Edit = { type = "Int", order = 10, min = 0, max = 2048, category = "Lights" } } )

    self:NetworkVar( "Float", 0, "LightBrightness", { KeyName = "LightBrightness", Edit = { type = "Float", order = 11, min = 0, max = 8, category = "Lights" } } )
    self:NetworkVar( "Float", 1, "LightSize", { KeyName = "LightSize", Edit = { type = "Float", order = 12, min = 0, max = 2048, category = "Lights" } } )

    self:NetworkVar( "Vector", 0, "LightColor", { KeyName = "LightColor", Edit = { type = "VectorColor", order = 13, category = "Lights" } } )

    if SERVER then
        self:SetOnPad( NULL )
        self:SetPadCategory( HALOARMORY.Requisition.NormalizeCategory( self.LegacyPadCategory ) )
        self:SetRequiresSupplies( self.RequiresSupplies ~= false )
        self:SetSpawnLights( self.LegacySpawnLights == true )

        local defaults = self.LegacyLightDefaults or {}
        local default_color = defaults.LightColor or Color( 0, 50, 0 )

        self:SetSegments( defaults.Segments or 6 )
        self:SetRadius( defaults.Radius or 370 )
        self:SetLightAutoChange( defaults.LightAutoChange == true )
        self:SetLightOn( defaults.LightOn ~= false )
        self:SetLightColor( default_color:ToVector() )
        self:SetLightBrightness( defaults.LightBrightness or 2 )
        self:SetLightSize( defaults.LightSize or 256 )
        self:SetLightWorld( defaults.LightWorld ~= false )
        self:SetLightModel( defaults.LightModel ~= false )

        self:NetworkVarNotify( "SpawnLights", function( ent ) schedule_light_refresh( ent ) end )
        self:NetworkVarNotify( "Segments", function( ent ) schedule_light_refresh( ent ) end )
        self:NetworkVarNotify( "Radius", function( ent ) schedule_light_refresh( ent ) end )

        self:NetworkVarNotify( "LightAutoChange", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightOn", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightColor", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightBrightness", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightSize", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightWorld", function( ent ) schedule_light_update( ent ) end )
        self:NetworkVarNotify( "LightModel", function( ent ) schedule_light_update( ent ) end )
    end
end

function ENT:GetPadModelData()
    return get_model_config_for_entity( self )
end

function ENT:ShouldRenderHelipad()
    return get_model_config_value( self, "render_helipad", false )
end

function ENT:GetVehicleSpawnPos()
    return get_model_config_value( self, "spawn_pos", Vector( 0, 0, 10 ) )
end

function ENT:GetVehicleSpawnAng()
    return get_model_config_value( self, "spawn_ang", Angle( 0, -90, 0 ) )
end

function ENT:GetVehicleSpawnRadius()
    return get_model_config_value( self, "spawn_radius", 100 )
end

function ENT:ApplyPadModel( model_path )
    local model_data = HALOARMORY.Requisition.GetPadModelConfig( model_path )
    if not istable( model_data ) then
        model_data = HALOARMORY.Requisition.GetPadModelConfig( self.DeviceModel )
    end
    if not istable( model_data ) then
        model_data = HALOARMORY.Requisition.GetPadModelConfig( HALOARMORY.Requisition.GetDefaultPadModel() )
    end
    if not istable( model_data ) then return false end

    self:SetModel( model_data.model )
    self:SetupModel()

    if SERVER then
        local old_phys = self:GetPhysicsObject()
        local was_motion_enabled = true

        if IsValid( old_phys ) then
            was_motion_enabled = old_phys:IsMotionEnabled()
        end

        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS )

        local new_phys = self:GetPhysicsObject()
        if IsValid( new_phys ) then
            new_phys:EnableMotion( was_motion_enabled )

            if was_motion_enabled then
                new_phys:Wake()
            else
                new_phys:Sleep()
            end
        end
    end

    if isfunction( self.ApplyPadModelRuntimeFlags ) then
        self:ApplyPadModelRuntimeFlags()
    end

    return true
end

local function as_bool( value )
    return value == true or value == 1 or value == "1"
end

local function as_vector_color( value, fallback )
    fallback = fallback or Vector( 0, 1, 0 )

    if isvector( value ) then
        return value
    end

    if IsColor( value ) then
        return value:ToVector()
    end

    if istable( value ) then
        return Color( tonumber( value.r ) or 0, tonumber( value.g ) or 0, tonumber( value.b ) or 0 ):ToVector()
    end

    return fallback
end

function ENT:ApplyPadConfig( data )
    if not istable( data ) then return false end

    local target_model = data.model or self:GetModel()
    if not self:ApplyPadModel( target_model ) then
        return false
    end

    local pad_id = tonumber( data.pad_id )
    if pad_id and pad_id > 0 then
        self:SetPadID( pad_id )
    end

    if isstring( data.device_name ) and data.device_name ~= "" then
        self:SetDeviceName( data.device_name )
    end

    if isstring( data.network_id ) and data.network_id ~= "" then
        self:SetNetworkID( data.network_id )
    end

    self:SetPadCategory( HALOARMORY.Requisition.NormalizeCategory( data.category or self:GetPadCategory() ) )
    self:SetRequiresSupplies( as_bool( data.requires_supplies ) )

    self:SetSpawnLights( as_bool( data.spawn_lights ) )
    self:SetSegments( math.Clamp( math.Round( tonumber( data.segments ) or self:GetSegments() ), 0, 360 ) )
    self:SetRadius( math.Clamp( math.Round( tonumber( data.radius ) or self:GetRadius() ), 0, 2048 ) )
    self:SetLightAutoChange( as_bool( data.light_auto_change ) )
    self:SetLightOn( as_bool( data.light_on ) )
    self:SetLightWorld( as_bool( data.light_world ) )
    self:SetLightModel( as_bool( data.light_model ) )
    self:SetLightBrightness( math.Clamp( tonumber( data.light_brightness ) or self:GetLightBrightness(), 0, 8 ) )
    self:SetLightSize( math.Clamp( tonumber( data.light_size ) or self:GetLightSize(), 0, 2048 ) )
    self:SetLightColor( as_vector_color( data.light_color, self:GetLightColor() ) )

    if isfunction( self.RefreshLights ) then
        self:RefreshLights()
        self:UpdateLights()
    end

    return true
end

function ENT:CanAfford( selected_vehicle )
    if not self:GetRequiresSupplies() then
        return true
    end

    local controller_network = util.JSONToTable( self:GetNetworkTable() )
    if not istable( controller_network ) then return false end

    local current_resource = controller_network.Supplies
    local cost = istable( selected_vehicle ) and tonumber( selected_vehicle.cost ) or 0

    return cost <= current_resource
end

properties.Add( "haloarmory_vehicle_pad_config", {
    MenuLabel = "Configure Vehicle Pad",
    Order = 99998,
    MenuIcon = "icon16/wrench.png",
    PrependSpacer = true,

    Filter = function( _, ent, ply )
        if not IsValid( ent ) then return false end
        if ent:IsPlayer() then return false end
        if not ent.VehiclePad then return false end
        if not ent.AllowPadConfig then return false end
        if not ply:IsAdmin() then return false end

        return true
    end,

    Action = function( _, ent )
        HALOARMORY.VEHICLES.NETWORK.RequestPadConfig( ent )
    end,
} )
