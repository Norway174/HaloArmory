
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



properties.Add( "presets_menu", {
    MenuLabel = "Presets...", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/disk.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( !ent.HALOARMORY_Ships_Presets ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        // Open the Presets GUI
        HALOARMORY.Ships.Presets.OpenGUI( ent )

    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        // Nothing
    end 
} )