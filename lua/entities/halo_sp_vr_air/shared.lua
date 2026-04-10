ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Air Pad (Deprecated)"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.IsHALOARMORY = true

ENT.DeviceName = "Vehicle Requisition Air"
ENT.DeviceType = "vehicle_requisition_air"
ENT.DeviceIcon = "vgui/haloarmory/icons/airpad.png"
ENT.DeviceModel = "models/hunter/plates/plate2x2.mdl"

ENT.LegacySpawnLights = true
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

-- Minimal placeholder NetworkVars for PermaProps compatibility
-- These accept the old saved data types so PermaProps doesn't error
function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "NetworkID" )
    self:NetworkVar( "String", 1, "DeviceName" )
    self:NetworkVar( "String", 2, "NetworkTable" )
    self:NetworkVar( "String", 3, "PadID" )
    self:NetworkVar( "Entity", 1, "OnPad" )
    self:NetworkVar( "Entity", 2, "Building" )
    self:NetworkVar( "Bool", 0, "RequiresSupplies" )
    -- Light properties (old air pad had these)
    self:NetworkVar( "Int", 0, "Segments" )
    self:NetworkVar( "Int", 1, "Radius" )
    self:NetworkVar( "Bool", 1, "LightAutoChange" )
    self:NetworkVar( "Bool", 2, "LightOn" )
    self:NetworkVar( "Vector", 0, "LightColor" )
    self:NetworkVar( "Float", 0, "LightBrightness" )
    self:NetworkVar( "Float", 1, "LightSize" )
    self:NetworkVar( "Bool", 3, "LightWorld" )
    self:NetworkVar( "Bool", 4, "LightModel" )
end
