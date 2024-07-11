HALOARMORY.MsgC("Client HALOARMORY REQUISITION GUI loaded!")


HALOARMORY.Requisition = HALOARMORY.Requisition or {}
HALOARMORY.Requisition.Vehicles = HALOARMORY.Requisition.Vehicles or {}
HALOARMORY.Requisition.VehiclePads = {}
HALOARMORY.Requisition.GUI = HALOARMORY.Requisition.GUI or {}

HALOARMORY.Requisition.Theme = HALOARMORY.Requisition.Theme or {
    ["roundness"] = 0,
    ["background"] = Color(0,0,0,241),
    ["text"] = Color(255,255,255,255),
    ["header_color"] = Color(0,0,0),
    ["divider_color"] = Color(255,255,255,10),
    ["apply_btn"] = Color(52,107,149),
    ["cancel_btn"] = Color(97,0,0),
}


function HALOARMORY.Requisition.OpenPadSelector( callback )

    local MainWindow = vgui.Create( "DFrame" )
    MainWindow:SetSize( 576, 440 )
    MainWindow:SetTitle( "" )
    MainWindow:Center()
    MainWindow:MakePopup()
    MainWindow:ShowCloseButton( false )

    MainWindow.Paint = function( self, w, h )
        HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )

        draw.RoundedBox( HALOARMORY.Requisition.Theme["roundness"], 0, 0, w, h, HALOARMORY.Requisition.Theme["background"] )
        draw.RoundedBox( HALOARMORY.Requisition.Theme["roundness"], 0, 0, w, 40, HALOARMORY.Requisition.Theme["header_color"] )
        draw.SimpleText( "Select a vehicle pad", "QuanticoHeader", w/2, 20, HALOARMORY.Requisition.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    HALOARMORY.Requisition.GUI.PadSelector_Menu = MainWindow

    local CloseButton = vgui.Create( "DButton", MainWindow )
    CloseButton:SetSize( 40, 40 )
    CloseButton:SetPos( MainWindow:GetWide() - 40, 0 )
    CloseButton:SetText( "" )
    CloseButton.Paint = function( self, w, h )
        draw.RoundedBox( HALOARMORY.Requisition.Theme["roundness"], 0, 0, w, h, HALOARMORY.Requisition.Theme["cancel_btn"] )
        draw.SimpleText( "✕", "QuanticoHeader", w/2, h/2, HALOARMORY.Requisition.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    CloseButton.DoClick = function()
        MainWindow:Remove()
        HALOARMORY.Requisition.GUI.PadSelector_Menu = nil
    end

    local VehiclePadList = vgui.Create( "DScrollPanel", MainWindow )
    VehiclePadList:Dock( FILL )
    VehiclePadList:DockMargin( 0, 14, 0, 0 )

    VehiclePadList.VBar:SetHideButtons( true )


    VehiclePadList.Paint = function( self, w, h )
        --draw.RoundedBox( HALOARMORY.Requisition.Theme["roundness"], 0, 0, w, h, HALOARMORY.Requisition.Theme["background"] )
    end

    // Paint the scrollbar
    VehiclePadList.VBar.Paint = function( self, w, h )
        draw.RoundedBox( 10, 0, 0, w, h, HALOARMORY.Requisition.Theme["background"] )
    end

    // Paint the scrollbar grip
    VehiclePadList.VBar.btnGrip.Paint = function( self, w, h )
        draw.RoundedBox( 10, 0, 0, w, h, HALOARMORY.Requisition.Theme["apply_btn"] )
    end

    // Create a Loading Label
    local LoadingLabel = vgui.Create( "DLabel", VehiclePadList )
    LoadingLabel:Dock( TOP )
    LoadingLabel:DockMargin( 10, 5, 10, 5 )
    LoadingLabel:SetText( "Loading..." )
    LoadingLabel:SetFont( "QuanticoHeader" )
    LoadingLabel:SetTextColor( HALOARMORY.Requisition.Theme["text"] )
    LoadingLabel:SetContentAlignment( 5 )


    // Get the Vehicle Pads
    HALOARMORY.VEHICLES.NETWORK.RequestVehiclePads( function( pads )
        --if true then return end

        LoadingLabel:Remove()

        HALOARMORY.Requisition.VehiclePads = pads

        --print( "Got vehicle pads", pads, #pads )
        --if istable( pads ) then
        --    PrintTable( pads )
        --end

        for k, v in pairs( pads ) do
            local VehiclePad = vgui.Create( "DPanel", VehiclePadList )
            VehiclePad:SetTall( 64 )
            VehiclePad:Dock( TOP )
            VehiclePad:DockMargin( 10, 5, 10, 5 )

            VehiclePad.Paint = function( self, w, h )
                draw.RoundedBox( HALOARMORY.Requisition.Theme["roundness"], 0, 0, w, h, HALOARMORY.Requisition.Theme["background"] )
            end

            local VehiclePadIcon = vgui.Create( "DImage", VehiclePad )
            VehiclePadIcon:Dock( LEFT )

            local vehicle_icon = v.DeviceIcon or "vgui/haloarmory/icons/anchor.png"

            VehiclePadIcon:SetImage( vehicle_icon )

            local VehiclePadName = vgui.Create( "DLabel", VehiclePad )
            VehiclePadName:Dock( FILL )
            VehiclePadName:SetText( tostring( v:GetDeviceName() ) )
            VehiclePadName:SetFont( "QuanticoHeader" )
            VehiclePadName:SetTextColor( HALOARMORY.Requisition.Theme["text"] )
            VehiclePadName:SetContentAlignment( 5 )

            local VehiclePadButton = vgui.Create( "DButton", VehiclePad )
            VehiclePadButton:Dock( RIGHT )
            VehiclePadButton:SetWide( 128 )
            VehiclePadButton:SetText( "" )
            VehiclePadButton.Paint = function( self, w, h )
                draw.RoundedBox( 10, 10, 10, w - 20, h - 20, HALOARMORY.Requisition.Theme["apply_btn"] )
                draw.SimpleText( "Select", "QuanticoHeader", w/2, h/2, HALOARMORY.Requisition.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
            end

            VehiclePadButton.DoClick = function()
                --HALOARMORY.Requisition.OpenVehicleSelector( v )

                if callback and isfunction( callback ) then
                    callback( v )
                else
                    HALOARMORY.Requisition.OpenVehiclePad( v )
                end

                MainWindow:Remove()
            end
            
        end



    end )

end


concommand.Add("haloarmory_padselector", function() 
    HALOARMORY.Requisition.OpenPadSelector()
end)

if HALOARMORY.Requisition.GUI.PadSelector_Menu then
    HALOARMORY.Requisition.GUI.PadSelector_Menu:Remove()
    HALOARMORY.Requisition.GUI.PadSelector_Menu = nil

    HALOARMORY.Requisition.OpenPadSelector()
end