
HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.SUPPLY = HALOARMORY.INTERFACE.CONTROL_PANEL.SUPPLY or {}

local function LerpColor(color1, color2, percent, threshold)
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

local function FormatTime(minutes)
    local days = math.floor(minutes / 1440)
    local hours = math.floor((minutes % 1440) / 60)
    minutes = math.floor(minutes % 60)

    local timeString = ""
    if days > 0 then
        timeString = timeString .. string.format("%d day%s ", days, days > 1 and "s" or "")
    end
    if hours > 0 then
        timeString = timeString .. string.format("%d hour%s ", hours, hours > 1 and "s" or "")
    end
    if minutes > 0 then
        timeString = timeString .. string.format("%d minute%s", minutes, minutes > 1 and "s" or "")
    end

    if timeString == "" then
        timeString = "0 minutes"
    end

    return timeString
end






local function DrawHeaderTitle( ent )
    local HeaderColor = ent:GetHeaderColor():ToColor() //or Color(18, 39, 133, 102)
    --print(HeaderColor:Unpack())
    HeaderColor.a = 102
    surface.SetDrawColor( HeaderColor:Unpack() )
    surface.DrawRect( 0, 0, ent.frameW, 105 )

    local RoomName = ent:GetDeviceName() or "ERR: No Name"

    draw.DrawText( RoomName, "SP_QuanticoHeader", ent.frameW / 2, 49 / 5, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )
end


local function DrawResources( ent, network )

    // Create a progress bar for the current resources
    local CurrentResource, MaxResource = network.Supplies, network.MaxSupplies

    local Progress = CurrentResource / MaxResource

    local BarX, BarY = 50, ent.frameH * .35
    local BarW, BarH = ent.frameW - (BarX * 2), 60

    // Progress Bar container
    surface.SetDrawColor( 0, 1, 2, 102)
    surface.DrawRect( BarX, BarY, BarW, BarH )

    // Progress Bar
    surface.SetDrawColor( LerpColor( Color(37, 133, 18, 102), Color(133, 18, 18, 102), Progress, .75 ) )
    surface.DrawRect( BarX, BarY, math.Clamp(BarW * Progress, 0, BarW), BarH )


    // Progress Bar Text
    draw.DrawText( "Supplies: " .. HALOARMORY.INTERFACE.PrettyFormatNumber(CurrentResource), "SP_QuanticoNormal", BarX, BarY - ( BarH * .6 ), ent.Theme["colors"]["text_color"], TEXT_ALIGN_LEFT )

    draw.DrawText( "Max Capacity: " .. HALOARMORY.INTERFACE.PrettyFormatNumber(MaxResource), "SP_QuanticoNormal", BarX + BarW, BarY + BarH, ent.Theme["colors"]["text_color"], TEXT_ALIGN_RIGHT )
end


local function DrawRate( ent, network )

    local rate = ent:GetRateM()

    if rate == 0 then return end

    local LocX, LocY = ent.frameW / 2, ent.frameH * .6

    local CurrentResource, MaxResource = network.Supplies, network.MaxSupplies

    local preText = ""
    local textColor = ent.Theme["colors"]["text_color"]
    local timeLeft = 0
    local timeText = ""

    if rate > 0 then
        // Filling
        preText = "Production Rate: +"
        textColor = Color( 37, 133, 18, 102)
        timeLeft = (MaxResource - CurrentResource) / rate
        if timeLeft > 0 then
            timeText = "Full in " .. FormatTime(timeLeft)
        else
            timeText = "At Capacity"
        end
    else
        // Emptying
        preText = "Consumption Rate: "
        textColor = Color( 133, 18, 18, 102)
        timeLeft = CurrentResource / rate * -1
        if timeLeft > 0 then
            timeText = "Depleted in " .. FormatTime(timeLeft)
        else
            timeText = "Fully Depleted"
        end
    end

    draw.DrawText( preText .. HALOARMORY.INTERFACE.PrettyFormatNumber(rate) .. "/m", "SP_QuanticoRate", LocX, LocY, textColor, TEXT_ALIGN_CENTER )
    if timeText != "" then
        draw.DrawText( timeText, "SP_QuanticoNormal", LocX, LocY + 50, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )
    end
end

local function DrawButton( ent, network )

    local ButtonW, ButtonH = 300, 75
    local ButtonX, ButtonY = (ent.frameW / 2) - (ButtonW / 2), (ent.frameH * .87) - (ButtonH / 2)

    local ButtonColor = ent.Theme["colors"]["buttons_default"]["btn_normal"]
    local ButtonTextColor = ent.Theme["colors"]["text_color"]

    if ui3d2d.isHovering(ButtonX, ButtonY, ButtonW, ButtonH) then
        ButtonColor = ent.Theme["colors"]["buttons_default"]["btn_hover"]
        if ui3d2d.isPressed() then
            ButtonColor = ent.Theme["colors"]["buttons_default"]["btn_click"]

            --Derma_Message("This feature is still a work in progress.\nSorry!", "W.I.P.", "OK")
            HALOARMORY.Logistics.Main_GUI.LoadAccessGUI( ent, network )
        end
    end


    surface.SetDrawColor( ButtonColor:Unpack() )
    surface.DrawRect( ButtonX, ButtonY, ButtonW, ButtonH )

    draw.DrawText( "Access", "SP_QuanticoRate", ButtonX + (ButtonW / 2), ButtonY + (ButtonH / 2) - 30, ButtonTextColor, TEXT_ALIGN_CENTER)
end


function HALOARMORY.INTERFACE.CONTROL_PANEL.SUPPLY.DrawControl( ent, hideButton )

    // Todo: Write a supply GUI Interface
    // To display:
    // - Device name (DONE!)
    // - Supplies Bar, current and max (DONE!)
    // - Consuption or Production rate (DONE!)
    // - Button to take out supplies

    --print("Draw Supply Control Panel")

    DrawHeaderTitle( ent )

    local network = ent:GetNetworkTable()
    network = util.JSONToTable( network )

    if( !network ) then
        draw.DrawText( "No Network ID", "SP_QuanticoNormal", ent.frameW / 2, ent.frameH / 2, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )
    else
        
        DrawResources( ent, network )

        DrawRate( ent, network )

        if !hideButton then
            DrawButton( ent, network )
        end

    end

    local networkID = "0"
    if ( ent.GetNetworkID and isfunction(ent.GetNetworkID) ) then
        networkID = ent:GetNetworkID()
    end

    // Draw ID
    draw.DrawText( "Network ID: " .. networkID, "SP_QuanticoNormal", ent.frameW - 15, ent.frameH - 30, Color( 173, 173, 173, 10), TEXT_ALIGN_RIGHT )

end