AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- This entity is deprecated. Spawn a halo_sp_vr_pad in its place and remove itself.
function ENT:Initialize()
    -- Create the new pad entity
    local new_pad = ents.Create( "halo_sp_vr_pad" )
    if not IsValid( new_pad ) then
        self:Remove()
        return
    end

    -- Transfer position and angles
    new_pad:SetPos( self:GetPos() )
    new_pad:SetAngles( self:GetAngles() )

    -- Apply the model for this pad type
    new_pad:SetModel( self.DeviceModel or "models/hunter/plates/plate2x2.mdl" )

    -- Spawn and activate
    new_pad:Spawn()
    new_pad:Activate()

    -- Transfer ownership if CPPI exists
    if new_pad.CPPISetOwner and self:CPPIGetOwner() then
        new_pad:CPPISetOwner( self:CPPIGetOwner() )
    end

    -- Apply configuration including light settings
    local light_defaults = self.LegacyLightDefaults or {}
    local config_data = {
        device_name = self.DeviceName or "Vehicle Requisition Air",
        spawn_lights = self.LegacySpawnLights == true,
        category = self.LegacyPadCategory or "default",
        pad_id = self:GetPadID(),
        network_id = self:GetNetworkID(),
        segments = light_defaults.Segments,
        radius = light_defaults.Radius,
        light_auto_change = light_defaults.LightAutoChange,
        light_on = light_defaults.LightOn,
        light_color = light_defaults.LightColor,
        light_brightness = light_defaults.LightBrightness,
        light_size = light_defaults.LightSize,
        light_world = light_defaults.LightWorld,
        light_model = light_defaults.LightModel,
    }

    if isfunction( new_pad.ApplyPadConfig ) then
        new_pad:ApplyPadConfig( config_data )
    end

    -- Remove the old entity
    self:Remove()
end
