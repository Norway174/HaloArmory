
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "[SHIP] FRIGATE"
ENT.Category = "HALOARMORY - SHIPS"
ENT.Author = "Norway174"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.RenderGroup = RENDERGROUP_OPAQUE_HUGE

ENT.IsHALOARMORY = true

ENT.Model = "models/valk/halocustomedition/unsc/props/frigate/frigate.mdl"

ENT.HALOARMORY_Ships_Presets = true

// List of attached props
ENT.HALOARMORY_Attached = {}

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

