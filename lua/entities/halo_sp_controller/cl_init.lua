
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

function ENT:DrawTranslucent()
    self:DrawModel()

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

    --print("Drawing")

    surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( self.Theme["colors"]["background_color"] )
    surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )

    local succ, err = pcall(HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager, self)
    if not succ then
        print("Error from Supply Point Base Function related to device:", self )
        print(err)
    end

    ui3d2d.endDraw() --Finish the UI render
end