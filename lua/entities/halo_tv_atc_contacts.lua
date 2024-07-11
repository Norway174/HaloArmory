AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Contacts Screen"
ENT.Category = "HALOARMORY - ATC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.DeviceType = "atc_contacts_screen"


ENT.Contacts = {}


if SERVER then
    util.AddNetworkString("HALO.ATC.Contacts.Update")
    util.AddNetworkString("HALOARMORY.ATC.CONTACTS.SCREEN")

    net.Receive( "HALOARMORY.ATC.CONTACTS.SCREEN", function( len, ply )
        local action = net.ReadString()
        local ent = net.ReadEntity()

        if not IsValid( ent ) then return end

        if action == "scroll" then
            local scrollBar = net.ReadInt( 8 )
            ent:SetScreenScrollBar( scrollBar )
        elseif action == "select" then
            local contact = net.ReadEntity()
            ent:SetScreenSelectedContact( contact )
        end
    end )
end

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "RadarNetwork", { KeyName = "RadarNetwork",	Edit = { type = "Generic", order = 1 } } )
    self:NetworkVar( "Int", 0, "ScreenScrollBar" )
    self:NetworkVar( "Entity", 0, "ScreenSelectedContact" )

    if SERVER then
        self:SetRadarNetwork( "network_1" )
        self:SetScreenScrollBar( 0 )
        self:SetScreenSelectedContact( NULL )
    end

end

if CLIENT then

    net.Receive( "HALO.ATC.Contacts.Update", function( len, ply )

        --if not IsValid( self ) then return end

        local ent = net.ReadEntity()
        local contacts = net.ReadTable()

        if not IsValid( ent ) then return end

        for key, value in pairs( ents.GetAll() ) do
            if not IsValid( value ) then continue end
            if value.DeviceType ~= "atc_contacts_screen" then continue end
            if ent:GetRadarNetwork() ~= value:GetRadarNetwork() then continue end

            value.Contacts = contacts

            --PrintTable( value.Contacts )
        end

        

    end )

end