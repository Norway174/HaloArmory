
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Holotable"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Editable = true
ENT.IsHALOARMORY = true

ENT.TableMdl = "models/valk/halo3/unsc/props/military/monitor_med.mdl" -- Halo UNSC Prop Pack - Halo 3
ENT.TableLegsMdl = "models/hunter/blocks/cube075x2x075.mdl" -- Vanilla Gmod


ENT.CanDrag = false // Perfect Hands support to remove the hand icon over screens.


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

    local intIndex = 0 -- Separate index tracker for Int type
    local boolIndex = 1 -- Separate index tracker for Bool type
    local stringIndex = 0 -- Separate index tracker for String type

    for i = 1, 4 do
        local modelKey = "HoloModel" .. i

        -- Boolean variables
        self:NetworkVar("Bool", boolIndex, modelKey .. "_Enable", { 
            KeyName = modelKey .. "_Enable", 
            Edit = { type = "Boolean", order = i * 10, category = "Model " .. i } 
        })
        boolIndex = boolIndex + 1

        self:NetworkVar("Bool", boolIndex, modelKey .. "_Hologram", { 
            KeyName = modelKey .. "_Hologram", 
            Edit = { type = "Boolean", order = i * 10 + 7, category = "Model " .. i } 
        })
        boolIndex = boolIndex + 1

        -- String variables
        self:NetworkVar("String", stringIndex, modelKey .. "_Model", { 
            KeyName = modelKey .. "_Model", 
            Edit = { type = "String", order = i * 10 + 1, category = "Model " .. i } 
        })
        stringIndex = stringIndex + 1

        -- Integer variables for Position (Forward, Left, Up), Angle, and Scale
        self:NetworkVar("Int", intIndex, modelKey .. "_PosF", { 
            KeyName = modelKey .. "_PosF", 
            Edit = { type = "Int", order = i * 10 + 2, category = "Model " .. i, min = -100, max = 100 } 
        })
        intIndex = intIndex + 1

        self:NetworkVar("Int", intIndex, modelKey .. "_PosL", { 
            KeyName = modelKey .. "_PosL", 
            Edit = { type = "Int", order = i * 10 + 3, category = "Model " .. i, min = -100, max = 100 } 
        })
        intIndex = intIndex + 1

        self:NetworkVar("Int", intIndex, modelKey .. "_PosU", { 
            KeyName = modelKey .. "_PosU", 
            Edit = { type = "Int", order = i * 10 + 4, category = "Model " .. i, min = -100, max = 100 } 
        })
        intIndex = intIndex + 1

        self:NetworkVar("Int", intIndex, modelKey .. "_Ang", { 
            KeyName = modelKey .. "_Ang", 
            Edit = { type = "Int", order = i * 10 + 5, category = "Model " .. i, min = 0, max = 360 } 
        })
        intIndex = intIndex + 1

        self:NetworkVar("Int", intIndex, modelKey .. "_Scale", { 
            KeyName = modelKey .. "_Scale", 
            Edit = { type = "Int", order = i * 10 + 6, category = "Model " .. i, min = 1, max = 200 } 
        })
        intIndex = intIndex + 1
    end

    if SERVER then
        -- Initialize default values
        self:SetHoloModel1_Enable(true)
        self:SetHoloModel1_Model("models/impulse/halo/unsc/vehicles/unsc_fleet/stalwart_class_frigate/stalwart_class_frigate_small.mdl")
        self:SetHoloModel1_PosF(0)
        self:SetHoloModel1_PosL(0)
        self:SetHoloModel1_PosU(0)
        self:SetHoloModel1_Ang(0)
        self:SetHoloModel1_Scale(100)
        self:SetHoloModel1_Hologram(true)

        -- Disable and reset other holograms
        for i = 2, 4 do
            local modelKey = "HoloModel" .. i
            self["Set" .. modelKey .. "_Enable"](self, false)
            self["Set" .. modelKey .. "_Model"](self, "")
            self["Set" .. modelKey .. "_PosF"](self, 0)
            self["Set" .. modelKey .. "_PosL"](self, 0)
            self["Set" .. modelKey .. "_PosU"](self, 0)
            self["Set" .. modelKey .. "_Ang"](self, 0)
            self["Set" .. modelKey .. "_Scale"](self, 100)
            self["Set" .. modelKey .. "_Hologram"](self, true)
        end
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