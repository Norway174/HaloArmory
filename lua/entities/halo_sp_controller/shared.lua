
ENT.Type = "anim"
ENT.Base = "halo_sp_base"
 
ENT.PrintName = "Controller"
ENT.Category = "HALOARMORY - Logistics"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true


ENT.DeviceName = "Controller Node"
ENT.DeviceType = "controller"
ENT.RateM = 0 // Positive number to add resources, negative to take away, 0 to disable. Resources are updates every minute.

ENT.CanDrag = false // Perfect Hands support to remove the hand icon over screens.

ENT.DeviceModel = "models/valk/h4/unsc/props/terminal/terminal_small.mdl"
function ENT:SetupModel()
    -- Set the sub material to the model
    self:SetSubMaterial( 3, "phoenix_storms/black_chrome" )
end

ENT.PanelPos = Vector(-4.2, 23, 62)
ENT.PanelAng = Angle(0, -90, 67.8)
ENT.PanelScale = .0664

ENT.frameW, ENT.frameH = 694, 532


ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 168, 168, 168 ),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}


function ENT:CustomDataTables()

    self:NetworkVar( "Vector", 0, "HeaderColor", { KeyName = "HeaderColor",	Edit = { type = "VectorColor", order = 3 } } )
    self:NetworkVar( "Int", 2, "RateM", { KeyName = "RateM",	Edit = { title = "Rate / min", type = "Int", order = 6, min = -9999, max = 9999 } } )

    if SERVER then
        self:SetHeaderColor( Color(18, 39, 133, 102):ToVector() )
        self:SetRateM( self.RateM )
    end

end