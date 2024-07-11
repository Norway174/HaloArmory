HALOARMORY.MsgC("HALO LOGISTICS MAIN GUI Loading.")


HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Main_GUI = HALOARMORY.Logistics.Main_GUI or {}

local ScrWi, ScrHe = math.min(ScrW() - 10, 820), math.min(ScrH() - 10, 567)
--ScrWi, ScrHe = 800, 600

hook.Add( "OnScreenSizeChanged", "HALOARMORY.Logistics.Main_GUI.OnSizeChange", function( oldWidth, oldHeight )
    ScrWi, ScrHe = math.min(ScrW() - 10, 550), math.min(ScrH() - 10, 600)
end )


local controller_ent = controller_ent or nil
local controller_network = controller_network or {
    Name = "",
    Supplies = 0,
    MaxSupplies = 0,
    MapOnly = false,
}



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

local blur = Material("pp/blurscreen")

function HALOARMORY.Logistics.Main_GUI.RenderBlur(panel, inn, density, alpha)
	local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(blur)

	for i = 1, 3 do
		blur:SetFloat("$blur", (i / inn) * density)
		blur:Recompute()
	    render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function HALOARMORY.Logistics.Main_GUI.LerpColor(color1, color2, percent, threshold)
    percent = 1 - percent
    if percent <= 0 then
        return color1
    elseif percent >= 1 then
        return color2
    else
        local thresholdPercent = threshold or 0.5
        if percent < thresholdPercent then
            return color1
        else
            local lerpPercent = (percent - thresholdPercent) / (1 - thresholdPercent)
            return Color(
                Lerp(lerpPercent, color1.r, color2.r),
                Lerp(lerpPercent, color1.g, color2.g),
                Lerp(lerpPercent, color1.b, color2.b),
                Lerp(lerpPercent, color1.a, color2.a)
            )
        end
    end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function HALOARMORY.Logistics.Main_GUI.CreateOverlayPanel(parent)
    local overlayPanel = vgui.Create("DPanel", parent)
    overlayPanel:SetSize(ScrW(), ScrH())
    overlayPanel:SetPos(0, 0)
    overlayPanel:SetMouseInputEnabled(true)
    overlayPanel:SetKeyboardInputEnabled(false)

    function overlayPanel:OnMousePressed()
        parent:Close() -- Close the parent panel
        self:Remove() -- Remove the overlay panel
    end

    return overlayPanel
end


---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------


function HALOARMORY.Logistics.Main_GUI.LoadAccessGUI( ent, network )

    controller_ent = ent

    // Create a new VGUI element
    HALOARMORY.Logistics.Main_GUI.Menu = vgui.Create( "DFrame" )
    HALOARMORY.Logistics.Main_GUI.Menu:SetSize( ScrWi, ScrHe ) 
    HALOARMORY.Logistics.Main_GUI.Menu:Center()
    HALOARMORY.Logistics.Main_GUI.Menu:SetTitle( "" ) 
    HALOARMORY.Logistics.Main_GUI.Menu:SetVisible( true ) 
    HALOARMORY.Logistics.Main_GUI.Menu:SetDraggable( true ) 
    HALOARMORY.Logistics.Main_GUI.Menu:ShowCloseButton( true ) 
    HALOARMORY.Logistics.Main_GUI.Menu:MakePopup()

    local HeaderColor = ent:GetHeaderColor():ToColor()
    HeaderColor.a = 102
    HeaderColor = Color(HeaderColor:Unpack())

    local DeviceName = tostring(ent:GetDeviceName())

    print( "Opening Network: ", network, ent, HeaderColor )
    PrintTable( network )

    function HALOARMORY.Logistics.Main_GUI.Menu:Init()
        self.startTime = SysTime()
    end

    HALOARMORY.Logistics.Main_GUI.Menu.Paint = function(self, w, h)
        // Blur only behind the frame
        HALOARMORY.Logistics.Main_GUI.RenderBlur(self, 1, 3, 250)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

        draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )

        draw.SimpleText( "Network: "..tostring(network.Name), "default", 10, 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end


    HALOARMORY.Logistics.Main_GUI.Menu.Think_copy = HALOARMORY.Logistics.Main_GUI.Menu.Think
    HALOARMORY.Logistics.Main_GUI.Menu.Think = function(self)
        HALOARMORY.Logistics.Main_GUI.Menu.Think_copy(self)
        // Update the network table
        controller_network = util.JSONToTable( controller_ent:GetNetworkTable() )
    end



    // Create a panel for the device name
    HALOARMORY.Logistics.Main_GUI.DeviceName = vgui.Create( "DPanel", HALOARMORY.Logistics.Main_GUI.Menu )
    HALOARMORY.Logistics.Main_GUI.DeviceName:SetPos( 10, 35 )
    HALOARMORY.Logistics.Main_GUI.DeviceName:SetSize( ScrWi - 20, 50 )

    HALOARMORY.Logistics.Main_GUI.DeviceName.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, HeaderColor )

        draw.SimpleText( DeviceName, "SP_QuanticoNormal", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    // Create a panel for the supplies ammount, percentage bar, and max ammount
    HALOARMORY.Logistics.Main_GUI.Supplies = vgui.Create( "DPanel", HALOARMORY.Logistics.Main_GUI.Menu )
    HALOARMORY.Logistics.Main_GUI.Supplies:SetPos( 10, 110 )
    HALOARMORY.Logistics.Main_GUI.Supplies:SetSize( ScrWi - 20, 100 )

    HALOARMORY.Logistics.Main_GUI.Supplies.Paint = function(self, w, h)

        // Create a progress bar for the current resources
        local CurrentResource, MaxResource = controller_network.Supplies, controller_network.MaxSupplies

        local Progress = CurrentResource / MaxResource

        local BarX, BarY = 0, h * .35
        local BarW, BarH = w - (BarX * 2), h * .3

        // Progress Bar container
        surface.SetDrawColor( 54, 54, 54, 102)
        surface.DrawRect( BarX, BarY, BarW, BarH )

        // Progress Bar
        surface.SetDrawColor( HALOARMORY.Logistics.Main_GUI.LerpColor( Color(37, 133, 18, 210), Color(133, 18, 18, 210), Progress, .75 ) )
        surface.DrawRect( BarX, BarY, math.Clamp(BarW * Progress, 0, BarW), BarH )


        // Progress Bar Text
        draw.DrawText( "Supplies: " .. HALOARMORY.INTERFACE.PrettyFormatNumber(CurrentResource), "SP_QuanticoNormal", BarX, BarY - ( BarH * 1 ), ent.Theme["colors"]["text_color"], TEXT_ALIGN_LEFT )

        draw.DrawText( "Max Capacity: " .. HALOARMORY.INTERFACE.PrettyFormatNumber(MaxResource), "SP_QuanticoNormal", BarX + BarW, BarY + BarH, ent.Theme["colors"]["text_color"], TEXT_ALIGN_RIGHT )
        
    end


    // Create a button to create a new cargo box
    HALOARMORY.Logistics.Main_GUI.CreateCargo = vgui.Create( "DButton", HALOARMORY.Logistics.Main_GUI.Menu )
    HALOARMORY.Logistics.Main_GUI.CreateCargo:SetPos( ScrWi * .35, 250 )
    HALOARMORY.Logistics.Main_GUI.CreateCargo:SetSize( 250, 50 )
    HALOARMORY.Logistics.Main_GUI.CreateCargo:SetText( "Create New Shipment" )
    HALOARMORY.Logistics.Main_GUI.CreateCargo:SetFont( "SP_QuanticoNormal" )
    HALOARMORY.Logistics.Main_GUI.CreateCargo:SetTextColor( ent.Theme["colors"]["text_color"] )

    HALOARMORY.Logistics.Main_GUI.CreateCargo.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 85, 0, 0, 241) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 116, 0, 0, 241) )
        end
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargo.DoClick = function()
        HALOARMORY.Logistics.Main_GUI.NewShipment.SelectPallet( ent, network )
    end

    // Create a button to transfer supplies to and from the cargo box
    HALOARMORY.Logistics.Main_GUI.TransferSupplies = vgui.Create( "DButton", HALOARMORY.Logistics.Main_GUI.Menu )
    HALOARMORY.Logistics.Main_GUI.TransferSupplies:SetPos( ScrWi * .02, 250 )
    HALOARMORY.Logistics.Main_GUI.TransferSupplies:SetSize( 250, 50 )
    HALOARMORY.Logistics.Main_GUI.TransferSupplies:SetText( "Transfer Supplies" )
    HALOARMORY.Logistics.Main_GUI.TransferSupplies:SetFont( "SP_QuanticoNormal" )
    HALOARMORY.Logistics.Main_GUI.TransferSupplies:SetTextColor( ent.Theme["colors"]["text_color"] )

    HALOARMORY.Logistics.Main_GUI.TransferSupplies.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 35, 75, 241) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 241) )
        end
    end

    HALOARMORY.Logistics.Main_GUI.TransferSupplies.DoClick = function()
        HALOARMORY.Logistics.Main_GUI.Transfer.TransferGUI( ent, network )
    end

end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]
--  local function OpenDebugMenuByLooking()
--     if HALOARMORY.Logistics.Main_GUI.Menu then HALOARMORY.Logistics.Main_GUI.Menu:Remove() end
--     if HALOARMORY.Logistics.Main_GUI.CreateCargoMenu then HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Remove() end
--     if HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu then HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:Remove() end

--     local trace_ent = LocalPlayer():GetEyeTrace().Entity
--     if not IsValid( trace_ent ) then return end
--     --print( "Opening Debug Menu", trace_ent, trace_ent.DeviceType )
--     if trace_ent.DeviceType ~= "controller" then return end

--     --local network = trace_ent:GetNetworkTable()
--     --network = util.JSONToTable( network )

--     controller_network = util.JSONToTable( trace_ent:GetNetworkTable() )

--     HALOARMORY.Logistics.Main_GUI.LoadAccessGUI( trace_ent, controller_network )

--     --CreateANewShipmentGUI_SelectPallet( trace_ent, network )
--     --HALOARMORY.Logistics.Main_GUI.Transfer.TransferGUI( trace_ent )
-- end
-- OpenDebugMenuByLooking()