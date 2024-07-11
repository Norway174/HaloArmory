include('shared.lua')

surface.CreateFont( "QuanticoMedKitStation", {
    font = "Quantico",
    size = 32,
    weight = 400,
    antialias = false,
} )

--[[---------------------------------------------------------
   Name: Draw
   Purpose: Draw the model in-game.
   Remember, the things you render first will be underneath!
---------------------------------------------------------]]

local id = 1

ENT.startTime = {}
ENT.endTime = {}
ENT.startValue = {}
ENT.endValue = {}
function ENT:DrawTimerBar()

    if self.startTime[id] == nil or self.startTime[id] <= .01 then
        self.startTime[id] = CurTime()
        self.startValue[id] = 0
        self.endValue[id] = self.frameW
    end

    self.endTime[id] = self.startTime[id] + self:GetRespawnTime()

    -- In your draw function, use the following code to calculate the current progress of the animation
    local progress = math.Clamp((CurTime() - self.startTime[id]) / (self.endTime[id] - self.startTime[id]), 0, 1)
    local currentValue = Lerp(progress, self.startValue[id], self.endValue[id])

    --debugoverlay.EntityTextAtPosition( self:GetPos(), RealFrameTime(), currentValue, 1, Color( 255, 255, 255 ) )

    local btn_color = Color( 0, 0, 0, 190)
    surface.SetDrawColor( btn_color )
    surface.DrawRect( 0, 0, self.frameW + ( 1 - currentValue), self.frameH )

    if currentValue >= self.frameW  then
        self.endTime[id] = 0
        self.startTime[id] = nil
    end

end

function ENT:Draw()
    self:DrawModel()

    --self:SetColor( Color( 0, 189, 9) )
    --self:SetColor( Color( 189, 0, 0) )

    local ang = self:GetAngles()

    --Skip drawing if the player can't see the UI
    --if not ui3d2d.startDraw(self:GetPos() + ang:Right() * self.PanelPos.x + ang:Forward() * self.PanelPos.y + ang:Up() * self.PanelPos.z, self:GetAngles() + self.PanelAng, .0264, self) then return end 
    if not ui3d2d.startDraw(self:LocalToWorld( self.PanelPos ), self:LocalToWorldAngles( self.PanelAng ), .0264, self) then return end 

    surface.SetDrawColor( self.Theme["colors"]["background_color"] )
    surface.DrawRect( 0, 0, self.frameW, self.frameH )

    local State = self:GetState()

    if State == 1 then // Can Spawn
        local text = "// PRESS TO SPAWN //"

        draw.SimpleText( text, "QuanticoMedKitStation", self.frameW * 0.5, self.frameH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    elseif State == 2 then // Regenerating
        
        self:DrawTimerBar()

        local text = "// REGENERATING... //"

        draw.SimpleText( text, "QuanticoMedKitStation", self.frameW * 0.5, self.frameH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    ui3d2d.endDraw() --Finish the UI render
end