
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

ENT.frameW, ENT.frameH = 400, 150

local rot = Angle(0, 0, 0)

function ENT:DrawTranslucent()
    self:DrawModel()

    local pla = LocalPlayer():GetAngles()
    rot = LerpAngle(FrameTime() * 7, rot, Angle(0, pla.y - 180, 0))

    local ang = Angle(0, rot.y, 0)
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 90)

    // Get the center of the model's bounding box
    local obbcenter = self:OBBCenter()
    obbcenter:Rotate(self:GetAngles())
    obbcenter = self:GetPos() + obbcenter

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(obbcenter + self.PanelPos, ang, self.PanelScale, self) then return end

        local succ, err = pcall(HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager, self)
        if not succ then
            print("Error from Cargo Crate Draw related to device:", self )
            print(err)
        end

    ui3d2d.endDraw() --Finish the UI render
end