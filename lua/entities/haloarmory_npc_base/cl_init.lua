include('shared.lua')
 
--[[---------------------------------------------------------
   Name: Draw
   Purpose: Draw the model in-game.
   Remember, the things you render first will be underneath!
---------------------------------------------------------]]
function ENT:Draw()

   if LocalPlayer():IsAdmin() then
      self:DrawModel()
   end
   --self:DrawModel()

end
