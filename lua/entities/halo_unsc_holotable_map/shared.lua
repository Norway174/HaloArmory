
ENT.Type = "anim"
ENT.Base = "halo_unsc_holotable"
 
ENT.PrintName = "Holotable Map"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Editable = true
ENT.IsHALOARMORY = true




// models/impulse/halo/unsc/vehicles/unsc_fleet/stalwart_class_frigate/stalwart_class_frigate_small.mdl // Halo - Fleets
--[[
[HALOARMORY] ------------------------------------------------------
[HALOARMORY] Relative Position: -60 0 0
[HALOARMORY] Relative Angle: 0 90 -90
 ]]

 function ENT:SetupDataTables()
    // Enable the map drawing bool
    self:NetworkVar("Bool", 0, "DrawMap", { KeyName = "DrawMap", Edit = { type = "Boolean", order = 1, category = "Map" } })

    if SERVER then
        self:SetDrawMap( true )
    end

    if CLIENT then

    end
end


local bg_scale = 400
local function ScreenDrawBG( self, background_img )
    surface.SetMaterial( background_img )
    surface.SetDrawColor( Color( 78, 87, 86, 79) )
    surface.DrawTexturedRect( (self.frameW/2)-((380+bg_scale)/2), (self.frameH / 2) - ((500+bg_scale) / 2), 380+bg_scale, 500+bg_scale )

    --surface.SetDrawColor( Color( 129, 21, 21, 79) )
    --surface.DrawRect( 0, 0, self.frameW, self.frameH )
end

ENT.ScreenModels = {
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_sm.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.5, 30.8, 21),
        ["ang"] = Angle(0, -90, 90),
        ["scale"] = .07,
        ["frameW"] = 946,
        ["frameH"] = 600,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = ScreenDrawBG,
    },
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_med.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.4, -64-2, 36.5),
        ["ang"] = Angle(90, -90, 90),
        ["scale"] = .100,
        ["frameW"] = 700,
        ["frameH"] = 1300,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = ScreenDrawBG,
    },
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_default.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.4, 131.8, 81),
        ["ang"] = Angle(0, -90, 90),
        ["scale"] = .279,
        ["frameW"] = 946,
        ["frameH"] = 600,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = ScreenDrawBG,
    }
}