

HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR = HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR or {}


local function OpenDoorButton( self )

    local ParentEnt = self:GetDoorParent()

    local CanAccess, CanOverride = ParentEnt:CanPlyAcces(ply)
    if not (CanAccess or CanOverride) then return end

    local DoorOpen = not ParentEnt:GetDoorOpen()

    net.Start( ParentEnt.NETSTRING_DOOROPEN )
    net.WriteEntity( ParentEnt )
    net.WriteBool( DoorOpen )
    net.SendToServer()

end

local function RingDoorButton( self, ring )

    local ParentEnt = self:GetDoorParent()
    local DoorBell = ring or (not ParentEnt:GetDoorBellActive())

    net.Start( ParentEnt.NETSTRING_DOORBELL )
    net.WriteEntity( ParentEnt )
    net.WriteBool( DoorBell )
    net.SendToServer()

end

local function LockDoorButton( self )

    local ParentEnt = self:GetDoorParent()

    local CanAccess, CanOverride = ParentEnt:CanPlyAcces(ply)
    if not (CanAccess or CanOverride) then return end

    local DoorBell = not ParentEnt:GetDoorLocked()

    net.Start( ParentEnt.NETSTRING_DOORLOCK )
    net.WriteEntity( ParentEnt )
    net.WriteBool( DoorBell )
    net.SendToServer()

end

local function Scale(val, from, to)
    return (val - from[1]) * (to[2] - to[1]) / (from[2] - from[1]) + to[1]
end


local startTime = {}
local endTime = {}
local startValue = {}
local endValue = {}

local function DrawOpenDoorButtonTimer( xpos, ypos, width, height, theme, max, id )

    if startTime[id] == nil or startTime[id] >= CurTime() + .1 then
        startTime[id] = CurTime()
        startValue[id] = 0
        endValue[id] = width
    end

    endTime[id] = startTime[id] + max

    local progress = math.Clamp((CurTime() - startTime[id]) / (endTime[id] - startTime[id]), 0, 1)
    local currentValue = Lerp(progress, startValue[id], endValue[id])

    local btn_color = theme["btn_timed"] or Color( 255, 255, 255 )
    surface.SetDrawColor( btn_color )
    surface.DrawRect( xpos, ypos, width + ( 1 - currentValue), height )

    if currentValue >= width then
        endTime[id] = 0
        startTime[id] = nil
    end
end

local function DrawButton( ent, xpos, ypos, width, height, font, text, icon, theme, can_press, Timer_ID, Timer_Max, callback_function )

    if not theme then theme = ent.Theme["colors"]["buttons_default"] end

    local btn_color = theme["btn_normal"] 
    if ui3d2d.isHovering(xpos, ypos, width, height) and can_press then
        btn_color = theme["btn_hover"] 

        if ui3d2d.isPressed() then
            btn_color = theme["btn_click"]

            local succ, err = pcall(callback_function, ent)
            if not succ then
                print("Error from Door Control Panel Function related to button '".. text .."':")
                print(err)
            end
            
        end
    elseif not can_press then
        btn_color = theme["btn_normal"] 
    end

    // Button BG
    surface.SetDrawColor( btn_color )
    surface.DrawRect( xpos, ypos, width, height )

    local text_color = theme["text_color"] or ent.Theme["colors"]["text_color"]
    local icon_color = theme["icon_color"] or text_color

    // Button Timer
    if Timer_ID then
        DrawOpenDoorButtonTimer( xpos, ypos, width, height, theme, Timer_Max, Timer_ID )
    end
    

    // Button Icon
    local Icon_Scale = 15
    if icon then
        surface.SetMaterial( icon )
        surface.SetDrawColor( icon_color )
        Icon_Scale = Scale(height, {32, 43}, {18, 30})
        surface.DrawTexturedRect( xpos + (Icon_Scale - 10), ypos + 15 * .5, Icon_Scale, Icon_Scale )
    end

    // Button Text
    draw.DrawText( text, font or "QuanticoHeader", xpos + width * .5 + (Icon_Scale - 10), ypos + height * .13, text_color, TEXT_ALIGN_CENTER )

end

local function DrawOpenDoorButton( ent, X, Y, W, H, Font, ThemeOverride )
    local DOOROPENCLOSE = "OPEN DOOR"
    local DOOROPENCLOSETHEME = ThemeOverride or ent.Theme["colors"]["buttons_default"]
    local DOORCANOPEN = true
    local DOORICON = ent.Theme["icons"]["door"]

    local DOORANIMID = nil

    if ent:GetDoorParent():GetDoorOpen() then
        DOOROPENCLOSE = "CLOSE DOOR"
        DOOROPENCLOSETHEME = ent.Theme["colors"]["buttons_toggled"]

        if ent:GetDoorParent():GetDoorAutoclose() then
            DOORANIMID = "door"
        end

    end

    local CanAccess, CanOverride = ent:GetDoorParent():CanPlyAcces( ply )
    --print( CanAccess, CanOverride)
    if not (CanAccess or CanOverride) then
        DOOROPENCLOSE = "NO ACCESS"
        DOORCANOPEN = false
        DOORICON = ent.Theme["icons"]["noentry"]
        DOOROPENCLOSETHEME = ent.Theme["colors"]["buttons_disabled"]
    end

    if ent:GetDoorParent():GetDoorLocked() and not ForceOverride then
        DOOROPENCLOSE = "DOOR LOCKED"
        DOORCANOPEN = false
        DOORICON = ent.Theme["icons"]["noentry"]
        DOOROPENCLOSETHEME = ent.Theme["colors"]["buttons_disabled"]
    end

    DrawButton( ent, X or 60, Y or 100, W or 250, H or 43, Font or "QuanticoHeader", DOOROPENCLOSE, DOORICON, DOOROPENCLOSETHEME, DOORCANOPEN, DOORANIMID, ent:GetDoorParent():GetDoorAutoclose_Timeout(), OpenDoorButton)

end

local function DrawDoorBellButton( ent, X, Y, W, H, Font, ThemeOverride )

    local DOORBELLTEXT = "RING DOORBELL"
    local DOORBELLTHEME = ent.Theme["icons"]["doorbell"]
    local DOORBELLBUTTONTHEME = ent.Theme["colors"]["buttons_default"]

    local DOORANIMID = nil

    if ent:GetDoorParent():GetDoorBellActive() then
        DOORBELLTEXT = "STOP RINGING"
        DOORBELLBUTTONTHEME = ent.Theme["colors"]["buttons_toggled"]
    end

    DrawButton( ent, 60, 155, 250, 43, "QuanticoHeader", DOORBELLTEXT, DOORBELLTHEME, DOORBELLBUTTONTHEME, true, DOORANIMID, 1, RingDoorButton)

end

local function DrawDoorLockButton( ent, X, Y, W, H, Font, ThemeOverride )

    local DOORBELLTEXT = "LOCK DOOR"
    local DOORBELLTHEME = ent.Theme["icons"]["lock"]
    local DOORBELLBUTTONTHEME = ThemeOverride or ent.Theme["colors"]["buttons_default"]
    local DOORCANOPEN = true

    local DOORANIMID = nil

    if ent:GetDoorParent():GetDoorLocked() then
        DOORBELLTEXT = "UNLOCK DOOR"
        --DOORBELLBUTTONTHEME = self.Theme["colors"]["buttons_toggled"]
    end

    local CanAccess, CanOverride = ent:GetDoorParent():CanPlyAcces( ply )
    --print( CanAccess, CanOverride)
    if not (CanAccess or CanOverride) then
        DOORBELLTEXT = "NO ACCESS"
        DOORCANOPEN = false
        DOORBELLTHEME = ent.Theme["icons"]["noentry"]
        DOORBELLBUTTONTHEME = ent.Theme["colors"]["buttons_disabled"]
    end

    DrawButton( ent, X or 60, Y or 155, W or 250, H or 43, Font or "QuanticoHeader", DOORBELLTEXT, DOORBELLTHEME, DOORBELLBUTTONTHEME, DOORCANOPEN, DOORANIMID, 1, LockDoorButton)

end

local function DrawDoorBellInside( ent )

    local X, Y, W, H = 20, 75, 320, 160

    // Background
    surface.SetDrawColor( Color(105, 0, 0, 166) )
    surface.DrawRect( X, Y, W, H )


    // Button Icon
    surface.SetMaterial( ent.Theme["icons"]["attention"] )
    surface.SetDrawColor( ent.Theme["colors"]["text_color"] )
    surface.DrawTexturedRect( X + 20, Y + 10, 30, 30 )
    surface.DrawTexturedRect( X + W - 30 - 20, Y + 10, 30, 30 )

    // Button Text
    local Att_Text = "// ATTENTION //"
    draw.DrawText( Att_Text, "QuanticoHeader", X + W * .5, Y + 10, text_color, TEXT_ALIGN_CENTER )

    // Button Text
    local PersonText = "UNIDENTIFIED"
    local ringer = ent:GetDoorParent():GetDoorBellPerson()
    if IsValid(ringer) and ringer:IsPlayer() then
        PersonText = ringer:Nick()
    end
    draw.DrawText( PersonText, "QuanticoNormal", X + W * .5, Y + 10 + 45, text_color, TEXT_ALIGN_CENTER )

    // Button Text
    local bottomText = "IS RINGING THE DOORBELL"
    draw.DrawText( bottomText, "QuanticoNormal", X + W * .5, Y + 10 + 70, text_color, TEXT_ALIGN_CENTER )

    // Door Button
    if ent:GetDoorParent():GetDoorLocked() then
        DrawDoorLockButton( ent, X + 8, Y + H - 32 - 10, 148, 32, "QuanticoNormal", ent.Theme["colors"]["buttons_default_solid"] )
    else 
        DrawOpenDoorButton( ent, X + 8, Y + H - 32 - 10, 148, 32, "QuanticoNormal", ent.Theme["colors"]["buttons_default_solid"] )
    end

    // Ignore button
    DrawButton( ent, X + W - 148 - 8, Y + H - 32 - 10, 148, 32, "QuanticoNormal", "Ignore", ent.Theme["icons"]["noentry"], ent.Theme["colors"]["buttons_default_red"], true, nil, nil, RingDoorButton)

end

local function DrawHeaderTitle( ent )
    surface.SetDrawColor( 7, 7, 7, 102)
    surface.DrawRect( 0, 0, ent.frameW, 49 )

    local RoomName = "ERR: No Name"
    RoomName = ent:GetDoorParent()
    if ent:GetDoorParent().GetRoomName then RoomName = ent:GetDoorParent():GetRoomName() end

    draw.DrawText( RoomName, "QuanticoHeader", ent.frameW / 2, 49 / 5, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )
end



function HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR.DrawOutside( ent )

    DrawHeaderTitle( ent )

    DrawOpenDoorButton( ent )
    DrawDoorBellButton( ent )

    if CanOverride then
        --ent:DrawButton( 60, 210, "OVERRIDE", self.Theme["icons"]["settings"], self.Theme["colors"]["buttons_override"], true)
    end

end

function HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR.DrawInside( ent )

    DrawHeaderTitle( ent )

    if ent:GetDoorParent():GetDoorBellActive() then
        DrawDoorBellInside( ent)

    else
        DrawOpenDoorButton( ent)
        DrawDoorLockButton( ent)

        if CanOverride then
            --ent:DrawButton( 60, 210, "OVERRIDE", self.Theme["icons"]["settings"], self.Theme["colors"]["buttons_override"], true)
        end

    end

end