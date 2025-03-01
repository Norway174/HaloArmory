
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

function ENT:DrawTranslucent()
    self:DrawModel()



    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

    --print("Drawing")

    draw.RoundedBox( 32, 0, 0, self.frameW, self.frameH, self.Theme["colors"]["background_color"] )

    if isstring(self.Theme["background"]) then
        self.Theme["background"] = Material( self.Theme["background"], "smooth" )
    end

    surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( self.Theme["colors"]["background_color"] )

    local imgW, imgH = 350, 450
    surface.DrawTexturedRect( (self.frameW / 2) - (imgW / 2), (self.frameH / 2) - (imgH / 2) - 10, imgW, imgH )

    local succ, err = pcall(self.DrawScreen, self)
    if not succ then
        print("Error from Supply Point Base Function related to device:", self )
        print(err)
    end

    ui3d2d.endDraw() --Finish the UI render


    --render.DrawWireframeSphere( self:GetPos() + Vector(0,0,30), 50, 10, 10, Color( 255, 0, 0) , false)
end


function ENT:DrawScreen()
    local ent = self

    local RoomName = ent:GetDeviceName() or "ERR: No Name"

    draw.DrawText( RoomName, "SP_QuanticoHeader", ent.frameW / 2, 49 / 5, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )

    local network = ent:GetNetworkTable()
    network = util.JSONToTable( network )

    if( !network ) then
        draw.DrawText( "Invalid Network ID", "SP_QuanticoRate", ent.frameW / 2, ent.frameH - 90, Color( 255, 0, 0, 96), TEXT_ALIGN_CENTER )

    end

    local networkID = "0"
    if ( ent.GetNetworkID and isfunction(ent.GetNetworkID) ) then
        networkID = ent:GetNetworkID()
    end

    // Draw ID
    draw.DrawText( "Network ID: " .. networkID, "SP_QuanticoNormal", ent.frameW / 2, ent.frameH - 35, Color( 173, 173, 173, 33), TEXT_ALIGN_CENTER )

end