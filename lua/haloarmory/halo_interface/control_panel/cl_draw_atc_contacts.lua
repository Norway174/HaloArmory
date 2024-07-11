
HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.ATC_CONTACTS = HALOARMORY.INTERFACE.CONTROL_PANEL.ATC_CONTACTS or {}

local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )

--[[
    valid teams are:
    0 = FRIENDLY TO EVERYONE
    1 = FRIENDLY TO TEAM 1 and 0
    2 = FRIENDLY TO TEAM 2 and 0
    3 = HOSTILE TO EVERYONE
]]
local function get_aiteam_color_relative_to_ply( ai_team, ply_team )

    if ply_team == 0 then
        return Color( 255, 255, 255 )
    elseif ply_team == 1 then
        if ai_team == 0 then
            return Color(255,255,255)
        elseif ai_team == 1 then
            return Color(60,255,0)
        elseif ai_team == 2 then
            return Color(153,0,255)
        elseif ai_team == 3 then
            return Color(255,0,0)
        end
    elseif ply_team == 2 then
        if ai_team == 0 then
            return Color(255,255,255)
        elseif ai_team == 1 then
            return Color(153,0,255)
        elseif ai_team == 2 then
            return Color(60,255,0)
        elseif ai_team == 3 then
            return Color(255,0,0)
        end
    elseif ply_team == 3 then
        return Color( 255, 0, 0)
    end

end


local function draw_scroll_buttons( ent, x, y, w, h )

    // Button one
    local btn1_x = x
    local btn1_y = y
    local btn1_w = w
    local btn1_h = h * .5

    // Draw the up button
    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn1_x, btn1_y, btn1_w, btn1_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

            local selectedIndex = ent:GetScreenScrollBar()
            selectedIndex = math.Clamp(selectedIndex - 1, 0, math.max(#ent.Contacts - 7, 0))
            ent:SetScreenScrollBar( selectedIndex )

            net.Start("HALOARMORY.ATC.CONTACTS.SCREEN")
                net.WriteString("scroll")
                net.WriteEntity(ent)
                net.WriteInt(selectedIndex, 8)
            net.SendToServer()

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end


    surface.DrawRect( btn1_x, btn1_y, btn1_w, btn1_h )

    draw.SimpleText( "▲", "SP_QuanticoRate", btn1_x + (btn1_w/2) - 3, btn1_y + -4, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    // Button two
    local btn2_x = x
    local btn2_y = btn1_y + btn1_h + 15
    local btn2_w = w
    local btn2_h = h * .5

    // Draw the down button
    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn2_x, btn2_y, btn2_w, btn2_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

            local selectedIndex = ent:GetScreenScrollBar()
            selectedIndex = math.Clamp(selectedIndex + 1, 0, math.max(#ent.Contacts - 7, 0))
            ent:SetScreenScrollBar( selectedIndex )

            net.Start("HALOARMORY.ATC.CONTACTS.SCREEN")
                net.WriteString("scroll")
                net.WriteEntity(ent)
                net.WriteInt(selectedIndex, 8)
            net.SendToServer()

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end


    surface.DrawRect( btn2_x, btn2_y, btn2_w, btn2_h )

    draw.SimpleText( "▼", "SP_QuanticoRate", btn2_x + (btn2_w/2) - 3, btn2_y + -4, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

end



local function draw_contact_details( ent, x, y, w, h )

    local ent_lfs = ent:GetScreenSelectedContact()
    local aircraft_name = tostring(ent_lfs.PrintName)
    // Limit length of name, cut off the end
    if string.len(aircraft_name) > 20 then
        aircraft_name = string.sub(aircraft_name, 1, 20) .. "..."
    end

    local aircraft_name_color = get_aiteam_color_relative_to_ply( ent_lfs:GetAITEAM(), LocalPlayer():lfsGetAITeam() )

    local aircraft_pilot = ent_lfs:GetDriver()

    local aircraft_pilot_name = "None"
    local aircraft_pilot_name_color = Color(202,202,202)

    if IsValid(aircraft_pilot) and aircraft_pilot:IsPlayer() then
        aircraft_pilot_name = aircraft_pilot:Nick()
        aircraft_pilot_name_color = team.GetColor( aircraft_pilot:Team() )

        // Limit length of name
        if string.len(aircraft_pilot_name) > 35 then
            aircraft_pilot_name = "..." .. string.sub(aircraft_pilot_name, 20)
        end
    elseif ent_lfs:GetAI() then
        aircraft_pilot_name = "Unknown (AI)"
        aircraft_pilot_name_color = Color(165,59,59)
    end

    // Health
    local health = math.Round(ent_lfs:GetHP())
    local health_max = math.Round(ent_lfs:GetMaxHP())

    local health_percent = math.Round( (health / health_max) * 100 )

    // Shield
    local shield = math.Round(ent_lfs:GetShield())
    local shield_max = math.Round(ent_lfs:GetMaxShield())

    local shield_percent = math.Clamp(math.Round( (shield / shield_max) * 100 ), 0, 100)

    // Ammo Primary
    local primary_ammo = ent_lfs:GetAmmoPrimary()
    local primary_ammo_max = ent_lfs:GetMaxAmmoPrimary()

    local primary_ammo_percent = math.Round( (primary_ammo / primary_ammo_max) * 100 )

    // Ammo Secondary
    local secondary_ammo = ent_lfs:GetAmmoSecondary()
    local secondary_ammo_max = ent_lfs:GetMaxAmmoSecondary()

    local secondary_ammo_percent = math.Round( (secondary_ammo / secondary_ammo_max) * 100 )

    // Get Aircraft Passengers
    local passengers = ent_lfs:GetPassengerSeats()

    --print("Passengers: " .. #passengers)
    --PrintTable(passengers)

    // Check each passenger seat for a player
    local passenger_count = 0
    for k, v in pairs(passengers) do
        if IsValid(v:GetDriver()) and v:GetDriver():IsPlayer() then
            passenger_count = passenger_count + 1
        end
    end



    // Get Aircraft Load
    local IsLoaded, TheLoad = HALOARMORY.Vehicles.IsLoadedVehicle( ent_lfs )

    if IsLoaded then
        TheLoad = math.Round(#TheLoad)
    else
        TheLoad = "Unladen"
    end


    // Draw the aircraft name
    draw.SimpleText( aircraft_name, "SP_QuanticoNormal", x + 4, y + 4, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Draw the LFS Aircraft team
    draw.SimpleText( "Team:", "SP_QuanticoNormal", x + w - 25, y + 35, Color(139,139,139), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
    draw.SimpleText( ent_lfs:GetAITEAM(), "SP_QuanticoNormal", x + w - 10, y + 35, aircraft_name_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )


    // Draw the aircraft pilot name
    draw.SimpleText( "Pilot:", "SP_QuanticoNormal", x + 4, y + 35, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( aircraft_pilot_name, "SP_QuanticoNormal", x + 4, y + 60, aircraft_pilot_name_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    // Draw the health bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 4, y + 130, w - 8, 20 )

    surface.SetDrawColor( Color( 255, 0, 0, 99) )
    surface.DrawRect( x + 4, y + 130, (w - 8) * (health_percent / 100), 20 )

    // Draw the aircraft health
    draw.SimpleText( "HP:", "SP_QuanticoNormal", x + 4, y + 100, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( health .. " / " .. health_max .. " (" .. health_percent .. "%)", "SP_QuanticoNormal", x + 5, y + 123, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    // Draw the shield bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 4, y + 185, w - 8, 20 )

    surface.SetDrawColor( Color( 0, 0, 255, 99) )
    surface.DrawRect( x + 4, y + 185, (w - 8) * (shield_percent / 100), 20 )

    // Draw the aircraft shield
    draw.SimpleText( "SHD:", "SP_QuanticoNormal", x + 4, y + 155, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( shield .. " / " .. shield_max .. " (" .. shield_percent .. "%)", "SP_QuanticoNormal", x + 5, y + 178, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    // Draw the primary ammo bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 4, y + 240, w - 8, 20 )

    surface.SetDrawColor( Color( 189, 189, 3, 99) )
    surface.DrawRect( x + 4, y + 240, (w - 8) * (primary_ammo_percent / 100), 20 )

    // Draw the aircraft primary ammo
    draw.SimpleText( "PRM:", "SP_QuanticoNormal", x + 4, y + 210, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( primary_ammo .. " / " .. primary_ammo_max .. " (" .. primary_ammo_percent .. "%)", "SP_QuanticoNormal", x + 5, y + 233, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Draw the secondary ammo bar
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x + 4, y + 295, w - 8, 20 )

    surface.SetDrawColor( Color( 189, 189, 3, 99) )
    surface.DrawRect( x + 4, y + 295, (w - 8) * (secondary_ammo_percent / 100), 20 )

    // Draw the aircraft secondary ammo
    draw.SimpleText( "SEC:", "SP_QuanticoNormal", x + 4, y + 265, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( secondary_ammo .. " / " .. secondary_ammo_max .. " (" .. secondary_ammo_percent .. "%)", "SP_QuanticoNormal", x + 5, y + 288, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    // Draw the aircraft passengers
    draw.SimpleText( "Passengers:", "SP_QuanticoNormal", x + 4, y + 325, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText(  passenger_count.. " / ".. tostring(#passengers), "SP_QuanticoNormal", x + 140, y + 325, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Draw the aircraft load
    draw.SimpleText( "Cargo:", "SP_QuanticoNormal", x + 4, y + 360, Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
    draw.SimpleText( tostring(TheLoad), "SP_QuanticoNormal", x + 80, y + 360, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    // Draw the close button
    local btn1_x = x - 108
    local btn1_y = y
    local btn1_w = 100
    local btn1_h = 50

    // Draw the up button
    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn1_x, btn1_y, btn1_w, btn1_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

            // Mark the selected aircraft
            ent:SetScreenSelectedContact( nil )

            net.Start("HALOARMORY.ATC.CONTACTS.SCREEN")
                net.WriteString("select")
                net.WriteEntity(ent)
                net.WriteEntity(nil)
            net.SendToServer()
        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end

    surface.DrawRect( btn1_x, btn1_y, btn1_w, btn1_h )
    draw.SimpleText( "☓", "SP_QuanticoRate", btn1_x + (btn1_w/2) - 3, btn1_y + -4, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )


end


local function draw_contact_list( ent, x, y, w, h )

    //ent.Contacts

    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( x, y, w, h )


    // Draw alternating rows
    local row_height = h * .143
    
    for index = 0, math.floor(h / row_height) do
        local SetIndex = 1 + index + ent:GetScreenScrollBar()
        if index % 2 == 0 then
            surface.SetDrawColor( Color( 0, 0, 0, 99) )
            surface.DrawRect( x, y + (index * row_height), w, row_height )
        end
    end

    // Draw the contacts
    for index = 0, math.floor(h / row_height) do
        local SetIndex = 1 + index + ent:GetScreenScrollBar()

        if not ent.Contacts[SetIndex] then continue end

        if not IsValid( ent.Contacts[SetIndex] ) then continue end


        draw.SimpleText( SetIndex .. "", "SP_QuanticoNormal", x + 4, y + (index * row_height) + (row_height / 2), Color(88,88,88), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

        local ent_lfs = ent.Contacts[SetIndex]
        local aircraft_name = tostring(ent_lfs.PrintName)
        local aircraft_name_color = get_aiteam_color_relative_to_ply( ent_lfs:GetAITEAM(), LocalPlayer():lfsGetAITeam() )


        local aircraft_pilot = ent_lfs:GetDriver()

        local aircraft_pilot_name = "None"
        local aircraft_pilot_name_color = Color(202,202,202)

        if IsValid(aircraft_pilot) and aircraft_pilot:IsPlayer() then
            aircraft_pilot_name = aircraft_pilot:Nick()
            aircraft_pilot_name_color = team.GetColor( aircraft_pilot:Team() )

            // Limit length of name
            if string.len(aircraft_pilot_name) > 35 then
                aircraft_pilot_name = "..." .. string.sub(aircraft_pilot_name, 20)
            end
        elseif ent_lfs:GetAI() then
            aircraft_pilot_name = "Unknown (AI)"
            aircraft_pilot_name_color = Color(165,59,59)
        end

        local aircraft_distance = math.Round(ent:GetPos():Distance(ent_lfs:GetPos()) / 52.49, 0)

        // Get the compass number to the aircraft
        // North is 0, East is 90, South is 180, West is 270
        local aircraft_compass = math.Round((math.atan2(ent_lfs:GetPos().y - ent:GetPos().y, ent_lfs:GetPos().x - ent:GetPos().x) * (180 / -math.pi)) - 0)
        if aircraft_compass < 0 then
            aircraft_compass = aircraft_compass + 360
        end

        // Make the buttons
        if ui3d2d.isHovering(x, y + (index * row_height), w, row_height) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])
    
                // Mark the selected aircraft
                ent:SetScreenSelectedContact( ent_lfs )

                net.Start("HALOARMORY.ATC.CONTACTS.SCREEN")
                    net.WriteString("select")
                    net.WriteEntity(ent)
                    net.WriteEntity(ent_lfs)
                net.SendToServer()
    
            else
                surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
            end

            surface.DrawRect( x, y + (index * row_height), w, row_height )
        end

        // Aircraft name
        draw.SimpleText( aircraft_name, "SP_QuanticoNormal", x + 40, y + (index * row_height) + (row_height * .28), aircraft_name_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

        // Pilot name
        draw.SimpleText( "P: ", "SP_QuanticoNormal", x + 40, y + (index * row_height) + (row_height * .7), Color(139,139,139), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

        draw.SimpleText( aircraft_pilot_name, "SP_QuanticoNormal", x + 67, y + (index * row_height) + (row_height * .7), aircraft_pilot_name_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

        // Distance
        draw.SimpleText( "D: ", "SP_QuanticoNormal", w - 67, y + (index * row_height) + (row_height * .28), Color(139,139,139), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

        draw.SimpleText( aircraft_distance .. "m", "SP_QuanticoNormal", w, y + (index * row_height) + (row_height * .28), Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

        // Angle
        draw.SimpleText( "A: ", "SP_QuanticoNormal", w - 67, y + (index * row_height) + (row_height * .7), Color(139,139,139), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

        draw.SimpleText( math.Round(aircraft_compass, 2) .. "°", "SP_QuanticoNormal", w, y + (index * row_height) + (row_height * .7), Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

    end

end


function HALOARMORY.INTERFACE.CONTROL_PANEL.ATC_CONTACTS.DrawScreen( ent )

    surface.SetMaterial( unsc_logo )
    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawTexturedRect( (ent.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( "RADAR", "SP_QuanticoHeader", ent.frameW/2, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    if ent:GetPos():Distance( ply:GetPos() ) >= 250 then return end

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, ent.frameW - 40, 2 )

    // Draw the header
    draw.SimpleText( #ent.Contacts .. " CONTACTS", "SP_QuanticoNormal", 20, ent.frameH * .1, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )


    --Draw the contacts list
    draw_contact_list( ent, 20, ent.frameH * .2, ent.frameW * .55, ent.frameH * .70 )
    --Draw the scroll buttons
    draw_scroll_buttons( ent, ent.frameW * .58, ent.frameH * .71, 100, 100 )

    --Draw the contact details
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    surface.DrawRect( ent.frameW * .694, ent.frameH * .2, ent.frameW * .287, ent.frameH * .70 )
    if IsValid(ent:GetScreenSelectedContact()) then
        draw_contact_details( ent, ent.frameW * .694, ent.frameH * .2, ent.frameW * .287, ent.frameH * .70 )
    else
        draw.DrawText( "No contact\nselected", "SP_QuanticoNormal", ent.frameW * .84, ent.frameH * .45, Color(255,255,255), TEXT_ALIGN_CENTER )
    end
    

    draw.SimpleText( "YOUR LFS TEAM: ".. LocalPlayer():lfsGetAITeam(), "SP_QuanticoNormal", ent.frameW - 20, ent.frameH * .1, Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )

end