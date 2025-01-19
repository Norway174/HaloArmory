
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "FOB Vehicle"
ENT.Category = "HALOARMORY - FOB"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.Deployed = false
ENT.HALOARMORY_Ships_Presets = true

// List of attached props
ENT.HALOARMORY_Attached = {}

ENT.VehiclePackagedModel = "models/props_junk/popcan01a.mdl" --Default Gmod

ENT.VehicleEnt = "sim_fphys_halo_militarytruck_Cargo" -- [Simfphys] Halo 5
--ENT.VehicleEnt = "sim_fphys_halorevamp_militarytruck_long_cargo" -- Halo Custom Edition

ENT.DeployedModel = "models/valk/haloreach/unsc/props/trailer/trailer.mdl" -- Halo UNSC Prop Pack - Halo Reach

ENT.CanDrag = false // Perfect Hands support to remove the hand icon over screens.

function ENT:SetupDataTables()

    self:NetworkVar( "String", 1, "AutoLoadPreset" )

    if SERVER then
        self:SetAutoLoadPreset( "" )
        self:NetworkVarNotify( "AutoLoadPreset", self.OnAutoLoadPresetChanged )
    end

end

function ENT:OnAutoLoadPresetChanged( name, old, new )

    if not SERVER then return end
    if ( new == "" ) then return end

    HALOARMORY.Ships.LoadShip( self, new )

end