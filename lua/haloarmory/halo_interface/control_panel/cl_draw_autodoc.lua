
// THIS FILE IS DEPERECATED!
// Will be deleted soon!

if true then return end


HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.AUTODOC = HALOARMORY.INTERFACE.CONTROL_PANEL.AUTODOC or {}

local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )

local function GetAutoDoc( ent )
    return ent:GetParent()
end

local function GetPatient( ent )

    local patient = GetAutoDoc( ent )
    if not IsValid( patient ) then return NULL end

    return patient:GetPatient()
end

local the_buttons = {}

the_buttons[1] = {
    ["name"] = "Scan",
    ["is_toggled"] = true,
    ["func_on_press"] = function( ent )
        --print( "Scan" )
        net.Start( "HALOARMORY.AUTODOC.SELECTMENU" )
            net.WriteEntity( ent )
            net.WriteString( "scan" )
        net.SendToServer()
    end,
}

the_buttons[2] = {
    ["name"] = "Operate",
    ["is_toggled"] = false,
    ["func_on_press"] = function( ent )
        --print( "Surgery" )
        net.Start( "HALOARMORY.AUTODOC.SELECTMENU" )
            net.WriteEntity( ent )
            net.WriteString( "operate" )
        net.SendToServer()
    end,
}

the_buttons[3] = {
    ["name"] = "Inject",
    ["is_toggled"] = false,
    ["func_on_press"] = function( ent )
        --print( "Inject" )
        net.Start( "HALOARMORY.AUTODOC.SELECTMENU" )
            net.WriteEntity( ent )
            net.WriteString( "inject" )
        net.SendToServer()
    end,
}

the_buttons[4] = {
    ["name"] = "Eject",
    ["is_toggled"] = false,
    ["func_on_press"] = function( ent )

        local patient = GetPatient( ent )
        if not IsValid( patient ) then return end

        net.Start( "HALOARMORY.AUTODOC.KICKPATIENT" )
            net.WriteEntity( ent )
        net.SendToServer()

    end,
}

local function DrawPatientInfo( ent, x, y, w, h )

    local patient = GetPatient( ent )

    local name = patient.Nick and patient:Nick() or "- N/A -"

    // Limit length of name
    if string.len(name) > 26 then
        name = string.sub(name, 1, 24) .. "..."
    end

    local health = "- N/A -"
    local health_percent = 0

    if IsValid( patient ) and patient.Health then
        health_percent = math.Round( (patient:Health() / patient:GetMaxHealth()) * 100 )
        health = string.format( "%s / %s (%s%%)", patient:Health(), patient:GetMaxHealth(), health_percent)
        --health = math.Round( (patient:Health() / patient:GetMaxHealth()) * 100 )
    end

    local armor = "- N/A -"
    local armor_percent = 0
    if IsValid( patient ) and patient.Armor then
        armor_percent = math.Round( (patient:Armor() / patient:GetMaxArmor()) * 100 )
        armor = string.format( "%s / %s (%s%%)", patient:Armor(), patient:GetMaxArmor(), armor_percent)
        --armor = math.Round( (patient:Armor() / patient:GetMaxArmor()) * 100 )
    end


    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x, y, w, h )

    // Name
    draw.SimpleText( "PATIENT NAME", "SP_QuanticoNormal", x + 10, y + 10, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( name, "SP_QuanticoRate", x + 10, y + 35, Color(0,255,64), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Health
    draw.SimpleText( "HEALTH", "SP_QuanticoNormal", x + 10, y + 115, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( health, "SP_QuanticoRate", x + 10, y + 140, Color(255, 60, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Health Bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 10, y + 195, w - 20, 20 )

    surface.SetDrawColor( Color( 255, 60, 0) )
    surface.DrawRect( x + 10, y + 195, (w - 20) * math.Clamp(health_percent / 100, 0, 1), 20 )

    // Armor
    draw.SimpleText( "ARMOR", "SP_QuanticoNormal", x + 10, y + 240, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( armor, "SP_QuanticoRate", x + 10, y + 265, Color(0,162,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Armor Bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 10, y + 320, w - 20, 20 )

    surface.SetDrawColor( Color( 0,162,255) )
    surface.DrawRect( x + 10, y + 320, (w - 20) * math.Clamp(armor_percent / 100, 0, 1), 20 )
    
end

local function DrawRightMenu( ent, x, y, w, h )

    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x, y, w, h )

    // Draw the title
    draw.SimpleText( "ACTIONS", "SP_QuanticoRate", x + (w/2), y + 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )


    // Draw the buttons
    for indx, btn in pairs(the_buttons) do
            
            local btn_x = x + 10
            local btn_y = y + 10 + (indx * 70)
    
            local btn_w = w - 20
            local btn_h = 60
    
            --surface.SetDrawColor( Color( 0, 0, 0, 99) )

            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
            if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) and GetAutoDoc(ent):GetSelectedMenu() == "" then --Check if the box is being hovered
                if ui3d2d.isPressed() then --Check if input is being held
                    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

                    if btn.func_on_press then
                        btn.func_on_press( GetAutoDoc( ent ) )
                    end

                else
                    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
                end
            end


            surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    
            draw.SimpleText( btn.name, "SP_QuanticoRate", btn_x + (btn_w/2), btn_y + 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
    
        
    end

end

local function DrawWindowBox( ent, x, y, w, h, title )

    surface.SetDrawColor( Color( 24, 24, 24, 254) )
    surface.DrawRect( x, y, w, h )

    // Draw the title
    draw.SimpleText( title, "SP_QuanticoRate", x + (w/2), y + 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    // Draw the exit button top right corner
    local btn_x = x + w - 65
    local btn_y = y + 10

    local btn_w = 55
    local btn_h = 55

    surface.SetDrawColor( Color( 255, 0, 0, 99) )

    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then
        if ui3d2d.isPressed() then
            surface.SetDrawColor( Color( 255, 0, 0, 255) )
            net.Start( "HALOARMORY.AUTODOC.SELECTMENU" )
                net.WriteEntity( GetAutoDoc( ent ) )
                net.WriteString( "" )
            net.SendToServer()
        else
            surface.SetDrawColor( Color( 255, 0, 0, 155) )
        end
    end

    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )

    draw.SimpleText( "☓", "SP_QuanticoRate", btn_x + (btn_w/2), btn_y - 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    // Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( x + 10, y + 75, w - 20, 2 )

end

function HALOARMORY.INTERFACE.CONTROL_PANEL.AUTODOC.DrawScreen( ent )

    surface.SetMaterial( unsc_logo )
    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawTexturedRect( (ent.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( "AUTO-DOC", "SP_QuanticoHeader", ent.frameW/2, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    local ply = ply or LocalPlayer()
    if not IsValid( ply ) then return end

    if ent:GetPos():Distance( ply:GetPos() ) >= 250 then return end

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, ent.frameW - 40, 2 )

    --Draw the patient info
    DrawPatientInfo( ent, 20, 120, ent.frameW * .60, ent.frameH * .60 )

    --Draw the right side menu
    DrawRightMenu( ent, ent.frameW * .60 + 40, 120, ent.frameW * .40 - 60, ent.frameH * .60 )


    if GetAutoDoc(ent):GetSelectedMenu() == "scan" then
        local w, h = 600, 300
        // Center the box
        DrawWindowBox( ent, (ent.frameW/2) - (w/2), (ent.frameH/2) - (h/2), w, h, "SCAN" )

    elseif GetAutoDoc(ent):GetSelectedMenu() == "operate" then
        local w, h = 600, 300
        // Center the box
        DrawWindowBox( ent, (ent.frameW/2) - (w/2), (ent.frameH/2) - (h/2), w, h, "OPERATE" )

    elseif GetAutoDoc(ent):GetSelectedMenu() == "inject" then
        local w, h = 600, 300
        // Center the box
        DrawWindowBox( ent, (ent.frameW/2) - (w/2), (ent.frameH/2) - (h/2), w, h, "INJECT" )
    end

end