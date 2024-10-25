AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "PC Base"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

--ENT.DeviceType = "generic_screen"

ENT.PanelPos = Vector(-1, -10.5, 26.8)
ENT.PanelAng = Angle(0, 90, 80)
ENT.PanelScale = .0103

ENT.frameW, ENT.frameH = 2048, 2048

ENT.Model = "models/ishi/halo_rebirth/props/human/tech_console_b.mdl"

ENT.Theme = {
    ["background"] = "vgui/haloarmory/pc/pc_bg.png",
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
end

function ENT:SetupDataTables()

    self:CustomDataTables()

end


if CLIENT then

    function ENT:Initialize()
        self.Theme.background = Material( self.Theme.background, "smooth" )
    end

    local function Draw3D2D( ent )
        // Custom draw function here
    end


    function ENT:Draw()
        --render.SuppressEngineLighting(true)
        self:DrawModel()
        --render.SuppressEngineLighting(false)

        // Check if ent.Theme.background is a material, if not, make it one
        if isstring(self.Theme.background) then
            self.Theme.background = Material( self.Theme.background, "smooth" )
        end

        if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end

            //draw.RoundedBox( 0, 0, 0, self.frameW, self.frameH, Color( 219, 23, 23) )

            // Draw the background
            surface.SetMaterial( self.Theme.background )
            surface.SetDrawColor( Color( 255, 255, 255) )
            surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )

            local succ, err = pcall(self.Draw3D2D, self)
            if not succ then
                print("Error from Supply Point Base Function related to device:", self )
                print(err)
            end

        ui3d2d.endDraw() --Finish the UI render
    end

end