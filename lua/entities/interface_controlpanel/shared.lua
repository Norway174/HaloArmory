
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Frigate Door Control Panel"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.IsHALOARMORY = true

ENT.Editable = true


ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["icons"] = {
        ["door"] = "vgui/haloarmory/frigate_doors/control_panel/door_icon.png",
        ["doorbell"] = "vgui/haloarmory/frigate_doors/control_panel/doorbell_icon.png",
        ["lock"] = "vgui/haloarmory/frigate_doors/control_panel/lock_icon.png",
        ["noentry"] = "vgui/haloarmory/frigate_doors/control_panel/noentry_icon.png",
        ["settings"] = "vgui/haloarmory/frigate_doors/control_panel/settings_icon.png",
        ["attention"] = "vgui/haloarmory/frigate_doors/control_panel/attention_icon.png",
    },
    ["colors"] = {
        ["background_color"] = Color( 168, 168, 168 ),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(16, 51, 102),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_default_solid"] = {
            ["btn_normal"] = Color(16, 51, 102),
            ["btn_hover"] = Color(10, 33, 66),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_default_red"] = {
            ["btn_normal"] = Color(36, 6, 6, 128),
            ["btn_hover"] = Color(48, 8, 8),
            ["btn_click"] = Color(41, 7, 7),
        },
        ["buttons_disabled"] = {
            ["text_color"] = Color( 133, 107, 107, 80),
            ["btn_normal"] = Color(53, 0, 0, 128),
            ["btn_hover"] = Color(16, 51, 102),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_toggled"] = {
            ["btn_normal"] = Color(12, 78, 21, 128),
            ["btn_hover"] = Color(15, 87, 25),
            ["btn_click"] = Color(7, 41, 7),
            ["btn_timed"] = Color(0, 34, 2, 190),
        },
        ["buttons_override"] = {
            ["btn_normal"] = Color(110, 96, 18, 128),
            ["btn_hover"] = Color(16, 51, 102),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}

ENT.PanelPos = Vector(-3.5, -5.05, 1.2)
ENT.PanelAng = Angle(0, 0, 0)

ENT.frameW, ENT.frameH = 357, 265


function ENT:SetupDataTables()

    self:NetworkVar( "Entity", 0, "DoorParent" )
    self:NetworkVar( "String", 0, "PanelType", { KeyName = "PanelType", Edit = { type = "Combo", order = 1, text = "Select...", values = {
        ["Outside"] = "outside",
        ["Inside"] = "inside",
        --["test"] = "test",
    } } } )

end