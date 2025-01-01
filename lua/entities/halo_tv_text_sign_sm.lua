AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Text Screen - Small"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.DeviceType = "text_screen"

ENT.Editable = false

ENT.SelectedModel = 1

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "SignTitle" )
    self:NetworkVar( "String", 1, "SignText" )
    self:NetworkVar( "Bool", 0, "SignCentered" )
    self:NetworkVar( "Vector", 0, "SignColor" )

    if SERVER then
        self:SetSignTitle( "SIGN" )
        self:SetSignText( "Placeholder" )
        self:SetSignCentered( false )
        self:SetSignColor( Vector( 1, 1, 1 ) )
    end


end

if SERVER then


    util.AddNetworkString( "HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetSign" )

    --[[
        net.WriteString( title:GetValue() )
        net.WriteString( text:GetValue() )
        net.WriteBool( centered:GetChecked() )
        net.WriteColor( color:GetColor() )
    ]]
    net.Receive( "HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetSign", function( len, ply )
        if ( not ply:IsAdmin() ) then return false end

        local ent = net.ReadEntity()
        if not IsValid( ent ) then return end

        local title = net.ReadString()
        local text = net.ReadString()
        local centered = net.ReadBool()
        local color = net.ReadVector()

        ent:SetSignTitle( title )
        ent:SetSignText( text )
        ent:SetSignCentered( centered )
        ent:SetSignColor( color )

    end )

end


properties.Add( "set_sign", {
    MenuLabel = "Set Text", -- Name to display on the context menu
    Order = 99999, -- The order to display this property relative to other properties
    MenuIcon = "icon16/computer_edit.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end
        if ( ent.DeviceType != "text_screen" ) then return false end

        return true
    end,
    Action = function( self, ent )
        // Open GUI to set the text
        ent:SetText()
    end
} )



if not CLIENT then return end

--local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )

local ply = LocalPlayer()



function ENT:DrawScreen()

    local model_table = self.ScreenModels[self.Model]

    self.frameW = model_table["frameW"]
    self.frameH = model_table["frameH"]

    --surface.SetDrawColor( Color( 255, 0, 0) )
    --surface.DrawRect( 0, 0, self.frameW, self.frameH )

    --surface.SetMaterial( unsc_logo )
    --surface.SetDrawColor( Color( 0, 0, 0, 79) )
    --surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( self:GetSignTitle(), "SP_QuanticoHeader", self.frameW * .5, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, self.frameW - 40, 2 )

    if not ply or not ply:IsPlayer() then ply = LocalPlayer() end
    if not ply or not ply:IsPlayer() then return end

    // Stop drawing if the player is too far away
    if self:GetPos():Distance( ply:GetPos() ) >= 2000 then return end


    --Draw the text
    local pos = self.frameW * .5
    local text_align = TEXT_ALIGN_CENTER
    if not self:GetSignCentered() then
        text_align = TEXT_ALIGN_LEFT
        // Get the width of the text
        local w, h = surface.GetTextSize( self:GetSignText() )

        // Offset the position by half the width
        pos = math.Clamp( pos - (w/2), 20, self.frameW - 20 )
    end

    draw.DrawText( self:GetSignText(), "SP_QuanticoNormal", pos, 120, self:GetSignColor():ToColor(), text_align, TEXT_ALIGN_TOP )

end



function ENT:SetText()


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
    title:SetText( self:GetSignTitle() )

    local text = vgui.Create( "DTextEntry", frame )
    text:SetPos( 10, 60 )
    text:SetSize( 480, 400 )
    text:SetText( self:GetSignText() )
    text:SetMultiline( true )

    local centered = vgui.Create( "DCheckBoxLabel", frame )
    centered:SetPos( 10, 467 )
    centered:SetText( "Centered Text" )
    centered:SetValue( self:GetSignCentered() )
    centered:SizeToContents()

    local color_selector = vgui.Create( "DColorMixer", frame )
    color_selector:SetPos( 10, 490 )
    color_selector:SetSize( 480, 200 )
    color_selector:SetPalette( true )
    color_selector:SetAlphaBar( false )
    color_selector:SetWangs( true )
    color_selector:SetColor( self:GetSignColor():ToColor() )

    local submit = vgui.Create( "DButton", frame )
    submit:SetPos( 10, 700 )
    submit:SetSize( 480, 20 )
    submit:SetText( "Submit" )

    submit.DoClick = function()

        // Color fix. The color mixer returns the color as a table. We need to convert it to a Color.
        local color = Color(color_selector:GetColor().r, color_selector:GetColor().g, color_selector:GetColor().b, 255)

        net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetSign" )
            net.WriteEntity( self )
            net.WriteString( title:GetValue() )
            net.WriteString( text:GetValue() )
            net.WriteBool( centered:GetChecked() )
            net.WriteVector( color:ToVector() )
        net.SendToServer()

        frame:Close()

    end

end