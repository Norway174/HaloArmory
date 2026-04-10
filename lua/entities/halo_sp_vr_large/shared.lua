ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Large Pad (Deprecated)"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.IsHALOARMORY = true

ENT.DeviceName = "Vehicle Requisition Large"
ENT.DeviceType = "vehicle_requisition_large"
ENT.DeviceIcon = "vgui/haloarmory/icons/largepad.png"
ENT.DeviceModel = "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc.mdl"

ENT.LegacySpawnLights = false
ENT.LegacyPadCategory = "default"

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
end
