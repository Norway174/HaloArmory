
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

function ENT:DrawTranslucent()
    self:DrawModel()



    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

    --print("Drawing")

    draw.RoundedBox( 32, 0, 0, self.frameW, self.frameH, self.Theme["colors"]["background_color"] )

    surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( self.Theme["colors"]["background_color"] )

    local imgW, imgH = 350, 450
    surface.DrawTexturedRect( (self.frameW / 2) - (imgW / 2), (self.frameH / 2) - (imgH / 2) - 10, imgW, imgH )

    local succ, err = pcall(HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager, self)
    if not succ then
        print("Error from Supply Point Base Function related to device:", self )
        print(err)
    end

    ui3d2d.endDraw() --Finish the UI render


    --render.DrawWireframeSphere( self:GetPos() + Vector(0,0,30), 50, 10, 10, Color( 255, 0, 0) , false)
end