
local function Scale(val, from, to)
    return (val - from[1]) * (to[2] - to[1]) / (from[2] - from[1]) + to[1]
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


local function DrawCallButton( ent )
	
	DrawButton( ent, 10, ent.frameH / 2 - 25, ent.frameW - 20, 75, "QuanticoHeader", "Call Elevator", nil, ent.Theme["colors"]["buttons_default"], true, nil, nil, function( _ent )
		print("Call Elevator")

		// Get the Door Parent, which is will be the main entity
		local doorParent = ent:GetDoorParent()
		if not IsValid(doorParent) then return end

		// Call the ToggleElevator function
		RunConsoleCommand("haloarmory_frigate_toggle_elevator", doorParent:EntIndex())
	end )

end


local function DrawHeaderTitle( ent )
    surface.SetDrawColor( 7, 7, 7, 102)
    surface.DrawRect( 0, 0, ent.frameW, 49 )

    draw.DrawText( "Elevator", "QuanticoHeader", ent.frameW / 2, 49 / 5, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )
end


function ENT:DrawCallButton( )

    DrawHeaderTitle( self )

	DrawCallButton( self )

end

function ENT:DrawFloors( )

    DrawHeaderTitle( self )

	DrawCallButton( self )

end

function ENT:DrawElevatorPanels()

    if self:GetPanelType() == "elevator_call" then
        self:DrawCallButton()
    elseif self:GetPanelType() == "elevator_floors" then
        self:DrawFloors()
    end

end