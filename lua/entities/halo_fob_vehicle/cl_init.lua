
include('shared.lua')


function ENT:DrawTranslucent( flags )

    -- This is here just to make it backwards compatible.
    -- You shouldn't really be drawing your model here unless it's translucent


    if self:GetModel() ~= self.VehiclePackagedModel then
        self:Draw( flags )
    end

    --self:DrawDeployScreen()

end




hook.Add( "OnContextMenuOpen", "HALOARMORY_FOBVehicleContextMenu", function()
    print( "Context menu opened" )

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
        RunConsoleCommand( "halo_fob_vehicle_toggle_deploy", fob:EntIndex() )
    end


    hook.Add( "OnContextMenuClose", "HALOARMORY_FOBVehicleContextMenu", function()
        if IsValid( DeployMenu ) then
            DeployMenu:Remove()
        end

        hook.Remove( "OnContextMenuClose", "HALOARMORY_FOBVehicleContextMenu" )
    end )


end )
