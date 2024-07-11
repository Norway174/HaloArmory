
ENT.Type = "anim"
ENT.Base = "halo_sp_vr_small"
 
ENT.PrintName = "Air Pad"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true


ENT.DeviceName = "Vehicle Requisition Air"
ENT.DeviceType = "vehicle_requisition_air"

ENT.DeviceIcon = "vgui/haloarmory/icons/airpad.png"

ENT.VehicleSize = { "air", }

ENT.DeviceModel = "models/hunter/plates/plate2x2.mdl"

ENT.VehicleSpawnPos = Vector( 0, 0, 65 )
ENT.VehicleSpawnAng = Angle( 0, -90, 0 )
ENT.VehicleSpawnRadius = 300


local function ReplaceLights( ent, name, old, new )

    timer.Create( "ReplaceLights"..ent:EntIndex(), 0.1, 1, function()
        if not IsValid( ent ) then return end
        print("ReplaceLights")
        ent:CreateLights()
    end )
end


local function UpdateLights( ent, name, old, new )

    timer.Simple( 0.1, function()
        if not IsValid( ent ) then return end
        ent:UpdateLights()
    end )

end

function ENT:CustomDataTablesAirPads()


    self:NetworkVar( "Int", 3, "Segments", { KeyName = "Segments",	Edit = { title = "Segments / Num Lights", type = "Int", order = 6, min = 0, max = 360, category = "Lights" } } )
    self:NetworkVar( "Int", 4, "Radius", { KeyName = "Radius",	Edit = { title = "Radius", type = "Int", order = 7, min = 0, max = 1000, category = "Lights" } } )

    self:NetworkVar( "Bool", 0, "LightAutoChange", { KeyName = "LightAutoChange",	Edit = { title = "Light AutoChange", type = "Boolean", order = 18, category = "Lights" } } )

    self:NetworkVar( "Bool", 1, "LightOn", { KeyName = "LightOn",	Edit = { title = "Light On", type = "Boolean", order = 19, category = "Lights" } } )

    self:NetworkVar( "Vector", 0, "LightColor", { KeyName = "LightColor",	Edit = { type = "VectorColor", order = 20, category = "Lights" } } )
    self:NetworkVar( "Float", 1, "LightBrightness", { KeyName = "LightBrightness",	Edit = { title = "Brightness", type = "Int", order = 21, min = 0, max = 6, category = "Lights" } } )
    self:NetworkVar( "Float", 2, "LightSize", { KeyName = "LightSize",	Edit = { title = "Size", type = "Int", order = 22, min = 0, max = 1024, category = "Lights" } } )

    self:NetworkVar( "Bool", 2, "LightWorld", { KeyName = "LightWorld",	Edit = { title = "Light World", type = "Boolean", order = 23, category = "Lights" } } )
    self:NetworkVar( "Bool", 3, "LightModel", { KeyName = "LightModel",	Edit = { title = "Light Model", type = "Boolean", order = 24, category = "Lights" } } )

    if SERVER then
        self:SetSegments( 6 )
        self:SetRadius( 370 )

        self:SetLightAutoChange( true )

        self:SetLightOn( true )

        self:SetLightColor( Color(0, 50, 0):ToVector() )
        self:SetLightBrightness( 2 )
        self:SetLightSize( 256 )

        self:SetLightWorld( true )
        self:SetLightModel( true )

        // Replace lights
        self:NetworkVarNotify( "Segments", ReplaceLights )
        self:NetworkVarNotify( "Radius", ReplaceLights )

        // Update lights
        self:NetworkVarNotify( "LightOn", UpdateLights )
        self:NetworkVarNotify( "LightColor", UpdateLights )
        self:NetworkVarNotify( "LightBrightness", UpdateLights )
        self:NetworkVarNotify( "LightSize", UpdateLights )
        self:NetworkVarNotify( "LightWorld", UpdateLights )
        self:NetworkVarNotify( "LightModel", UpdateLights )

    end
end