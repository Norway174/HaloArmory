
include('shared.lua')


function ENT:DrawTranslucent( flags )

    -- This is here just to make it backwards compatible.
    -- You shouldn't really be drawing your model here unless it's translucent


    if self:GetModel() ~= self.VehiclePackagedModel then
        self:Draw( flags )
        self:DrawDeployedScreen()
    else
    end

    --self:DrawDeployScreen()

end

ENT.Theme = {
    panel = Color(0,0,0,200),
    titleText = Color(255,255,255,255),
    btnColor = Color(14,14,14),
    btnHover = Color(29,29,29),
    btnClick = Color(38,73,5,200),
    btnDisabled = Color(53,53,53),
}


ENT.PanelPos = Vector(-65, -148, 140)
ENT.PanelAng = Angle(0, 180, 90)
ENT.PanelScale = .1

ENT.frameW, ENT.frameH = 500, 350

function ENT:DrawDeployedScreen()

    --print("Drawing deployed screen")

    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

    surface.SetDrawColor( self.Theme["panel"] )
    surface.DrawRect(0, 0, self.frameW, self.frameH)

    draw.SimpleText( "FOB Controls", "SP_QuanticoHeader", self.frameW * .5, self.frameH * .0, self.Theme["titleText"], TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )


    surface.SetDrawColor(self.Theme.btnColor)
        if ui3d2d.isHovering(50, 140, self.frameW - 50 * 2, self.frameH - 210) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(self.Theme.btnClick)
                surface.PlaySound( "garrysmod/ui_click.wav" )
                RunConsoleCommand( "halo_fob_vehicle_undeploy", self:EntIndex() )
            else
                surface.SetDrawColor(self.Theme.btnHover)
            end

        end

        surface.DrawRect(50, 140, self.frameW - 50 * 2, self.frameH - 210)

        // Draw an outline around the rect
        surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
        surface.DrawOutlinedRect( 50, 140, self.frameW - 50 * 2, self.frameH - 210, 4 )

        draw.SimpleText("Pack up FOB", "SP_QuanticoRate", self.frameW * .5, self.frameH * .5, self.Theme["titleText"], TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    ui3d2d.endDraw() --Finish the UI render

end


hook.Add( "OnContextMenuOpen", "HALOARMORY_FOBVehicleContextMenu", function()
    --print( "Context menu opened" )

    local ply = LocalPlayer()
    if not IsValid( ply ) then return end

    // Check if ply is in a vehicle.
    local veh = ply:GetVehicle()
    if not IsValid( veh ) then return end

    veh = veh["vehiclebase"]
    if not IsValid( veh ) then return end

    local fob = veh:GetNW2Entity( "FOB" )
    if not IsValid( fob ) then return end

    if fob:GetParent() ~= veh then return end

    // CREATE THE MENU

    local DeployMenu = vgui.Create( "DPanel" )
    DeployMenu:SetSize( 400, 150 )

    DeployMenu:DockPadding( 50, 50, 50, 50 )

    DeployMenu:MakePopup()

    // Set the menu to center top of the screen.
    DeployMenu:SetPos( ScrW() * .5 - 200, 75 )

    DeployMenu.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    local DeployButton = vgui.Create( "DButton", DeployMenu )
    DeployButton:SetText( "Deploy" )
    DeployButton:Dock( FILL )

    DeployButton.DoClick = function()
        RunConsoleCommand( "halo_fob_vehicle_deploy", fob:EntIndex() )
    end


    hook.Add( "OnContextMenuClose", "HALOARMORY_FOBVehicleContextMenu", function()
        if IsValid( DeployMenu ) then
            DeployMenu:Remove()
        end

        hook.Remove( "OnContextMenuClose", "HALOARMORY_FOBVehicleContextMenu" )
    end )


end )
