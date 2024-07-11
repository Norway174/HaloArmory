
HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}
HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN = HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN or {}

local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )

local ply = LocalPlayer()



function HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.DrawScreen( ent )

    --surface.SetDrawColor( Color( 255, 0, 0) )
    --surface.DrawRect( 0, 0, ent.frameW, ent.frameH )

    surface.SetMaterial( unsc_logo )
    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawTexturedRect( (ent.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( ent:GetSignTitle(), "SP_QuanticoHeader", ent.frameW * .5, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, ent.frameW - 40, 2 )

    if not ply or not ply:IsPlayer() then ply = LocalPlayer() end
    if not ply or not ply:IsPlayer() then return end

    // Stop drawing if the player is too far away
    if ent:GetPos():Distance( ply:GetPos() ) >= 3000 then return end


    --Draw the text
    local pos = ent.frameW * .5
    local text_align = TEXT_ALIGN_CENTER
    if not ent:GetSignCentered() then
        text_align = TEXT_ALIGN_LEFT
        // Get the width of the text
        local w, h = surface.GetTextSize( ent:GetSignText() )

        // Offset the position by half the width
        pos = math.Clamp( pos - (w/2), 20, ent.frameW - 20 )
    end

    draw.DrawText( ent:GetSignText(), "SP_QuanticoNormal", pos, 120, ent:GetSignColor():ToColor(), text_align, TEXT_ALIGN_TOP )

end



function HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetText( ent )


    // Create a new VGUI Menu

    // Panels:
    // - Title
    // - Text
    // - Checkbox (Centered or left aligned)
    // - Color
    // - Submit button

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 500, 730 )
    frame:SetTitle( "Sign Editor" )
    frame:SetVisible( true )
    frame:SetDraggable( true )
    frame:ShowCloseButton( true )
    frame:Center()
    frame:MakePopup()

    local title = vgui.Create( "DTextEntry", frame )
    title:SetPos( 10, 30 )
    title:SetSize( 480, 20 )
    title:SetText( ent:GetSignTitle() )

    local text = vgui.Create( "DTextEntry", frame )
    text:SetPos( 10, 60 )
    text:SetSize( 480, 400 )
    text:SetText( ent:GetSignText() )
    text:SetMultiline( true )

    local centered = vgui.Create( "DCheckBoxLabel", frame )
    centered:SetPos( 10, 467 )
    centered:SetText( "Centered Text" )
    centered:SetValue( ent:GetSignCentered() )
    centered:SizeToContents()

    local color_selector = vgui.Create( "DColorMixer", frame )
    color_selector:SetPos( 10, 490 )
    color_selector:SetSize( 480, 200 )
    color_selector:SetPalette( true )
    color_selector:SetAlphaBar( false )
    color_selector:SetWangs( true )
    color_selector:SetColor( ent:GetSignColor():ToColor() )

    local submit = vgui.Create( "DButton", frame )
    submit:SetPos( 10, 700 )
    submit:SetSize( 480, 20 )
    submit:SetText( "Submit" )

    submit.DoClick = function()

        // Color fix. The color mixer returns the color as a table. We need to convert it to a Color.
        local color = Color(color_selector:GetColor().r, color_selector:GetColor().g, color_selector:GetColor().b, 255)

        net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetSign" )
            net.WriteEntity( ent )
            net.WriteString( title:GetValue() )
            net.WriteString( text:GetValue() )
            net.WriteBool( centered:GetChecked() )
            net.WriteVector( color:ToVector() )
        net.SendToServer()

        frame:Close()

    end

end