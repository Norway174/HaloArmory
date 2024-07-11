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
        HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.SetText( ent )
    end
} )