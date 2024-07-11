HALOARMORY.MsgC("Client CONTROL PANEL GUI Loading.")

include('shared.lua')



ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )
ENT.Theme["icons"]["door"] = Material( ENT.Theme["icons"]["door"], "smooth" )
ENT.Theme["icons"]["doorbell"] = Material( ENT.Theme["icons"]["doorbell"], "smooth" )
ENT.Theme["icons"]["lock"] = Material( ENT.Theme["icons"]["lock"], "smooth" )
ENT.Theme["icons"]["noentry"] = Material( ENT.Theme["icons"]["noentry"], "smooth" )
ENT.Theme["icons"]["settings"] = Material( ENT.Theme["icons"]["settings"], "smooth" )
ENT.Theme["icons"]["attention"] = Material( ENT.Theme["icons"]["attention"], "smooth" )



function ENT:DrawTranslucent()
    self:DrawModel()

    --print("Drawing")

    local ang = self:GetAngles()

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:GetPos() + ang:Right() * self.PanelPos.x + ang:Forward() * self.PanelPos.y + ang:Up() * self.PanelPos.z, self:GetAngles() + self.PanelAng, .0264, self) then return end 

    --print("Drawing")

    surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( self.Theme["colors"]["background_color"] )
    surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )

    local succ, err = pcall(HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager, self)
    if not succ then
        print("Error from Door Control Panel Function related to button:", RoomName or self )
        print(err)
    end

    ui3d2d.endDraw() --Finish the UI render
end





-- if CLIENT then

--     local tr = util.TraceLine( util.GetPlayerTrace( LocalPlayer() ) )
--     if IsValid(tr.Entity) then
--         print(tr.Entity)

--         --PrintTable( list.Get( "simfphys_vehicles" ) )

--         --PrintTable( list.Get( "simfphys_vehicles" )[tr.Entity:GetSpawn_List()].name )

--         print( tr.Entity:GetSolid() )

--         --print( tr.Entity:GetSpawn_List() )
--     end

-- end