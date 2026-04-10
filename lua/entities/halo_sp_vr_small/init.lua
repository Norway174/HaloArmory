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
    new_pad:SetModel( self.DeviceModel or "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc_small.mdl" )

    -- Spawn and activate
    new_pad:Spawn()
    new_pad:Activate()

    -- Transfer ownership if CPPI exists
    if new_pad.CPPISetOwner and self:CPPIGetOwner() then
        new_pad:CPPISetOwner( self:CPPIGetOwner() )
    end

    -- Apply configuration
    local config_data = {
        device_name = self.DeviceName or "Vehicle Requisition Small",
        spawn_lights = self.LegacySpawnLights == true,
        category = self.LegacyPadCategory or "default",
        pad_id = self:GetPadID(),
        network_id = self:GetNetworkID(),
    }

    if isfunction( new_pad.ApplyPadConfig ) then
        new_pad:ApplyPadConfig( config_data )
    end

    -- Remove the old entity
    self:Remove()
end
