
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

ENT.frameW, ENT.frameH = 400, 150

local rot = Angle(0, 0, 0)

function ENT:DrawTranslucent()
    self:DrawModel()

    local pla = LocalPlayer():GetAngles()
    rot = LerpAngle(FrameTime() * 7, rot, Angle(0, pla.y - 180, 0))

    local ang = Angle(0, rot.y, 0)
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 90)

    // Get the center of the model's bounding box
    local obbcenter = self:OBBCenter()
    obbcenter:Rotate(self:GetAngles())
    obbcenter = self:GetPos() + obbcenter

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(obbcenter + self.PanelPos, ang, self.PanelScale, self) then return end

        local succ, err = pcall(self.DrawLabel, self)
        if not succ then
            print("Error from Cargo Crate Draw related to device:", self )
            print(err)
        end

    ui3d2d.endDraw() --Finish the UI render
end


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

local function PrettyFormatNumber(number)
    if type(number) ~= "number" then return number end
    
    local integerPart = math.floor(number)
    local decimalPart = number - integerPart
    
    local formattedIntegerPart = string.format("%d", integerPart)
    formattedIntegerPart = string.reverse(formattedIntegerPart)
    formattedIntegerPart = string.gsub(formattedIntegerPart, "(%d%d%d)", "%1 ")
    formattedIntegerPart = string.reverse(formattedIntegerPart)
    
    if decimalPart > 0 then
        local formattedDecimalPart = string.format("%.3f", decimalPart)
        formattedDecimalPart = string.sub(formattedDecimalPart, 3)
        return formattedIntegerPart .. "." .. formattedDecimalPart
    else
        return formattedIntegerPart
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



local function PrettyName( ent )
    return (ent.GetBoxName and ent:GetBoxName() or ent.DeviceName) .. " [" .. ent:GetStored() .. "]"
end

local function DrawLabelFar( ent )

    //Get text width
    surface.SetFont( "SP_QuanticoCrate" )
    local textW, textH = surface.GetTextSize( PrettyName( ent ) )

    textW = textW + 175
    textH = textH + 10
    --surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( ent.Theme["colors"]["background_color"] )
    surface.DrawRect( -textW * .5, 0, textW, textH )

    local HeaderColor = ent:GetHeaderColor():ToColor() //or Color(18, 39, 133, 102)
    --print(HeaderColor:Unpack())
    HeaderColor.a = 102
    surface.SetDrawColor( HeaderColor:Unpack() )
    surface.DrawRect( -textW * .5, 0, textW, 5 )

    draw.DrawText( PrettyName( ent ), "SP_QuanticoCrate", 0, 0, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER)

end

local function DrawLabelNear( ent )

    //Get text width
    surface.SetFont( "SP_QuanticoCrate" )
    local textW, textH = surface.GetTextSize( PrettyName( ent ) )

    textW = textW + 200
    textH = textH + 30
    --surface.SetMaterial( self.Theme["background"] )
    surface.SetDrawColor( ent.Theme["colors"]["background_color"] )
    surface.DrawRect( -textW * .5, 0, textW, textH )

    local HeaderColor = ent:GetHeaderColor():ToColor() //or Color(18, 39, 133, 102)
    --print(HeaderColor:Unpack())
    HeaderColor.a = 102
    surface.SetDrawColor( HeaderColor:Unpack() )
    surface.DrawRect( -textW * .5, 0, textW, 5 )

    draw.DrawText( PrettyName( ent ), "SP_QuanticoCrate", 0, 0, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER)

    // Draw fill bar
    local fillBarWidth = textW - 20
    local fillBarHeight = 20
    local fillBarX = -fillBarWidth * .5
    local fillBarY = textH - fillBarHeight - 10

    local fillBarColor = Color(21, 255, 0)

    local fillBarPercent = ent:GetStored() / ent:GetMaxCapacity()

    local fillBarBackgroundColor = Color(0, 0, 0)

    surface.SetDrawColor(fillBarBackgroundColor)
    surface.DrawRect(fillBarX, fillBarY, fillBarWidth, fillBarHeight)

    surface.SetDrawColor(fillBarColor)
    surface.DrawRect(fillBarX + 1, fillBarY + 1, (fillBarWidth - 2) * fillBarPercent, fillBarHeight - 2)


end


function ENT:DrawLabel()
    local ply = ply or LocalPlayer()
    if not IsValid( ply ) then return end

    if self:GetPos():Distance( ply:GetPos() ) >= 100 then
        DrawLabelFar( self )
    else
        DrawLabelNear( self )
    end

end