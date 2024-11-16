HALOARMORY.MsgC("Client CONTROL PANEL GUI Loading.")

include('shared.lua')



ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )
ENT.Theme["icons"]["door"] = Material( ENT.Theme["icons"]["door"], "smooth" )
ENT.Theme["icons"]["doorbell"] = Material( ENT.Theme["icons"]["doorbell"], "smooth" )
ENT.Theme["icons"]["lock"] = Material( ENT.Theme["icons"]["lock"], "smooth" )
ENT.Theme["icons"]["noentry"] = Material( ENT.Theme["icons"]["noentry"], "smooth" )
ENT.Theme["icons"]["settings"] = Material( ENT.Theme["icons"]["settings"], "smooth" )
ENT.Theme["icons"]["attention"] = Material( ENT.Theme["icons"]["attention"], "smooth" )


local RoomName = "ERR: No Name"

local ply = LocalPlayer()



include("cl_doorpanel.lua")
include("cl_elevatorpanel.lua")


function ENT:DrawTranslucent()
    self:DrawModel()

    if not IsValid(ply) then ply = LocalPlayer() end

    local ang = self:GetAngles()

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:GetPos() + ang:Right() * self.PanelPos.x + ang:Forward() * self.PanelPos.y + ang:Up() * self.PanelPos.z, self:GetAngles() + self.PanelAng, .0264, self) then return end 

    --print("Drawing")

    surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( self.Theme["colors"]["background_color"] )
    surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )

    RoomName = self:GetDoorParent()
    if self:GetDoorParent().GetRoomName then RoomName = self:GetDoorParent():GetRoomName() end

    if self:GetPanelType() == "outside" or self:GetPanelType() == "inside" then
        self:DrawDoorPanels()
    elseif self:GetPanelType() == "elevator_call" or self:GetPanelType() == "elevator_floors" then
        self:DrawElevatorPanels()
    end

    ui3d2d.endDraw() --Finish the UI render
end

