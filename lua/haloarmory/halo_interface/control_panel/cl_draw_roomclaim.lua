
HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM = HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM or {}

local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )


local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = math.floor(seconds % 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end




local function draw_button( ent )
    local ply = ply or LocalPlayer()
    if not IsValid( ply ) then return end

    if ent:GetPos():Distance( ply:GetPos() ) >= 150 then return end

    local claim_ply = ent:GetClaimedByPly()

    if claim_ply != NULL and claim_ply != LocalPlayer() then return end

    --Draw the button to claim the room
    local btn_w = 300
    local btn_h = 75

    local btn_x = (ent.frameW * .5) - (btn_w * .5)
    local btn_y = ent.frameH * .84

    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

                if claim_ply ~= NULL then
                    HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnclaimRoom( ent )
                else
                    HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.ClaimRoom( ent )
                end

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end

    local text = "Claim"

    if claim_ply != NULL then
        text = "Unclaim"
    end

    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    draw.SimpleText( text, "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

end


local function unclaimed_draw( ent )

    --Draw the room name
    draw.SimpleText( ent:GetRoomName(), "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .2, Color(0,255,64), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    --Draw the unclaimed text
    draw.SimpleText( ">// UNCLAIMED //", "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .41, Color(151,151,151), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    draw_button( ent )

end


local function claimed_draw( ent )

    --Draw the room name
    draw.SimpleText( ent:GetRoomName(), "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .2, Color( 255, 60, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    --Draw the unclaimed text
    local claim_name = ent:GetClaimedByName()
    draw.SimpleText( ">// CLAIMED: ".. claim_name .."//", "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .41, Color(151,151,151), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    local claim_time = ent:GetClaimTime()
    draw.SimpleText( FormatTime(claim_time), "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .7, Color(218,217,190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    draw_button( ent )

end

local function claimed_detailed_draw( ent )

    --Get Claim details
    local claim_ply = ent:GetClaimedByPly()
    local claim_name = ent:GetClaimedByName()
    local claim_reason = ent:GetClaimReason()
    local claim_time = ent:GetClaimTime()

    --Draw the room name
    draw.SimpleText( ent:GetRoomName(), "SP_QuanticoHeader", ent.frameW * .5, ent.frameH * .16, Color( 255, 60, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    // Draw a box
    local box_w = 500
    local box_h = 310

    local box_x = (ent.frameW * .5) - (box_w * .5)
    local box_y = ent.frameH * .3

    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawRect( box_x, box_y, box_w, box_h )

    --Draw the claimed text
    draw.SimpleText( "CLAIMED:", "SP_QuanticoNormal", box_x + 10, box_y + 20, Color(151,151,151), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    draw.SimpleText( claim_name, "SP_QuanticoRate", box_x + (box_w * .5), box_y + 50, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    draw.DrawText( claim_reason, "SP_QuanticoNormal", box_x + (box_w * .5), box_y + 70, Color(216,216,216), TEXT_ALIGN_CENTER )

    // Claimed by
    local team_color = team.GetColor( claim_ply:Team() )

    draw.SimpleText( "CLAIMED BY", "SP_QuanticoNormal", box_x + 10, box_y + box_h - 105, Color(151,151,151), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    draw.SimpleText( claim_ply:Nick(), "SP_QuanticoRate", box_x + (box_w * .5), box_y + box_h - 75, team_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )


    // Timer
    draw.SimpleText( "TIME LEFT", "SP_QuanticoNormal", box_x + 10, box_y + box_h - 30, Color(151,151,151), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

    draw.SimpleText( FormatTime(claim_time), "SP_QuanticoRate", box_x + (box_w * .5), box_y + box_h - 30, Color(218,217,190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )



    draw_button( ent )

end

function HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.DrawScreen( ent )

    surface.SetMaterial( unsc_logo )
    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawTexturedRect( (ent.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( "SIM-CLAIM", "SP_QuanticoHeader", ent.frameW * .5, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, ent.frameW - 40, 2 )


    --Get Claim details
    local claim_ply = ent:GetClaimedByPly()

    if claim_ply == NULL then
        unclaimed_draw( ent )
    else
        if ent:GetPos():Distance( ply:GetPos() ) >= 150 then 
            claimed_draw( ent )
        else
            claimed_detailed_draw( ent )
        end
    end

end


function HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnclaimRoom( ent )

    net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnClaimRoom" )
    net.WriteEntity( ent )
    net.SendToServer()

end



function HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.ClaimRoom( ent )

    if ent:GetPos():Distance( ply:GetPos() ) >= 250 then return end

    // Write a GUI to claim the room
    // The GUI should have the following:
    // 1. A text entry box to enter the claiming group's name
    // 2. A text entry box to enter the claiming reason
    // 3. Several number inputs to enter the hours, minutes, and seconds of the claim
    // 4. A button to submit the claim

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 300, 240 )
    frame:Center()
    frame:SetTitle( "Claim Room" )
    --frame:SetDraggable( false )
    frame:ShowCloseButton( true )
    frame:MakePopup()

    // Name
    local name_entry = vgui.Create( "DTextEntry", frame )
    name_entry:SetPos( 10, 40 )
    name_entry:SetSize( 280, 20 )
    --name_entry:SetText( "Claim Name" )
    name_entry:SetPlaceholderText( "Claimed For" )

    // Reason
    local reason_entry = vgui.Create( "DTextEntry", frame )
    reason_entry:SetPos( 10, 70 )
    reason_entry:SetSize( 280, 50 )
    --reason_entry:SetText( "Claim Reason" )
    reason_entry:SetPlaceholderText( "Claim Reason" )
    reason_entry:SetMultiline( true )

    // Time

    // Add a Label
    local time_label = vgui.Create( "DLabel", frame )
    time_label:SetPos( 10, 125 )
    time_label:SetSize( 280, 20 )
    time_label:SetText( "Claim Time (HH:MM:SS)" )

    // Hours
    local time_entry = vgui.Create( "DNumberWang", frame )
    time_entry:SetPos( 10, 145 )
    time_entry:SetSize( 40, 20 )
    time_entry:SetMinMax( 0, 99 )
    time_entry:SetDecimals( 0 )
    time_entry:SetValue( 0 )

    // Minutes
    local time_entry2 = vgui.Create( "DNumberWang", frame )
    time_entry2:SetPos( 55, 145 )
    time_entry2:SetSize( 40, 20 )
    time_entry2:SetMinMax( 0, 59 )
    time_entry2:SetDecimals( 0 )
    time_entry2:SetValue( 0 )

    // Seconds
    local time_entry3 = vgui.Create( "DNumberWang", frame )
    time_entry3:SetPos( 100, 145 )
    time_entry3:SetSize( 40, 20 )
    time_entry3:SetMinMax( 0, 59 )
    time_entry3:SetDecimals( 0 )
    time_entry3:SetValue( 0 )

    // Submit Button
    local submit_button = vgui.Create( "DButton", frame )
    submit_button:SetPos( 10, 180 )
    submit_button:SetSize( 120, 50 )
    submit_button:SetText( "Submit Claim" )

    submit_button.DoClick = function()

        local name = name_entry:GetValue()
        local reason = reason_entry:GetValue()
        local hours = time_entry:GetValue()
        local minutes = time_entry2:GetValue()
        local seconds = time_entry3:GetValue()

        local time = (hours * 3600) + (minutes * 60) + seconds

        if name == "" or reason == "" then return end

        net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.ClaimRoom" )
            net.WriteEntity( ent )
            net.WriteString( name )
            net.WriteString( reason )
            net.WriteInt( time, 32 )
        net.SendToServer()

        frame:Close()

    end

    submit_button.Think = function()

        if name_entry:GetValue() == "" or reason_entry:GetValue() == "" then
            submit_button:SetDisabled( true )
            return
        end

        local hours = time_entry:GetValue()
        local minutes = time_entry2:GetValue()
        local seconds = time_entry3:GetValue()

        local time = (hours * 3600) + (minutes * 60) + seconds

        if time <= 0 then
            submit_button:SetDisabled( true )
            return
        end

        submit_button:SetDisabled( false )
    end


end