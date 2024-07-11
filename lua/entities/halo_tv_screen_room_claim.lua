AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Room Claim Screen"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.DeviceType = "room_claim_screen"

ENT.Editable = true


function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "RoomName", { KeyName = "RoomName",	Edit = { type = "Generic", order = 1 } } )
    self:NetworkVar( "Entity", 0, "ClaimedByPly" )
    self:NetworkVar( "Int", 0, "ClaimTime" )
    self:NetworkVar( "String", 1, "ClaimedByName" )
    self:NetworkVar( "String", 2, "ClaimReason" )

    if SERVER then
        self:SetRoomName( "Room Name" )
        self:SetClaimedByPly( NULL )
        self:SetClaimTime( 0 )
        self:SetClaimedByName( "No one" )
        self:SetClaimReason( "No reason" )
    end

end

if SERVER then

    ENT.ProcessClaimTimer = CurTime() + 1
    function ENT:Think()
        // Every minute, increase or decrease the Supplies based on the RateM.
        if ( CurTime() > self.ProcessClaimTimer ) then
            self.ProcessClaimTimer = CurTime() + 1
    
            if self:GetClaimTime() == 0 then return end

            self:SetClaimTime( math.max(self:GetClaimTime() - 1, 0) )
    
            if self:GetClaimTime() <= 0 then
                self:SetClaimedByPly( NULL )
                --self:SetClaimTime( 0 )
                self:SetClaimedByName( "No one" )
                self:SetClaimReason( "No reason" )

                timer.Simple( 0.1, function()
                    net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.Anounce" )
                        net.WriteEntity( self )
                    net.Broadcast()
                end )
            end
        end
    end

    
    util.AddNetworkString( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.ClaimRoom" )
    util.AddNetworkString( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnClaimRoom" )
    util.AddNetworkString( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.Anounce" )

    --[[
        net.WriteEntity( ent )
        net.WriteString( name )
        net.WriteString( reason )
        net.WriteInt( time, 32 )
    ]]
    net.Receive( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.ClaimRoom", function( len, ply )

        local ent = net.ReadEntity()
        local name = net.ReadString()
        local reason = net.ReadString()
        local time = net.ReadInt( 32 )

        --time = SysTime() + time

        if not IsValid( ent ) then return end

        ent:SetClaimedByPly( ply )
        ent:SetClaimTime( time )
        ent:SetClaimedByName( name )
        ent:SetClaimReason( reason )

        timer.Simple( 0.1, function()
            net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.Anounce" )
                net.WriteEntity( ent )
            net.Broadcast()
        end )

    end )

    net.Receive( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnClaimRoom", function( len, ply )

        local ent = net.ReadEntity()

        if not IsValid( ent ) then return end

        ent:SetClaimedByPly( NULL )
        ent:SetClaimTime( 0 )
        ent:SetClaimedByName( "No one" )
        ent:SetClaimReason( "No reason" )

        timer.Simple( 0.1, function()
            net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.Anounce" )
                net.WriteEntity( ent )
            net.Broadcast()
        end )

    end )

end

if CLIENT then
    
    net.Receive( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.Anounce", function( len, ply )

        local ent = net.ReadEntity()

        if not IsValid( ent ) then return end

        local claimedBy = ent:GetClaimedByPly()

        if claimedBy == NULL then
            // For Unclaimed
            chat.AddText(
                Color( 255, 0, 0 ), "[", "SIM-ROOM", "] ",
                Color( 207, 209, 106), ent:GetRoomName(), Color( 255, 255, 255 )," is now unclaimed.")
        
        else
            // For Claimed
            local team_color = team.GetColor( claimedBy:Team() )

            chat.AddText(
                Color( 255, 0, 0 ), "[", "SIM-ROOM", "] ",
                team_color, claimedBy:Nick(), Color( 255, 255, 255 ), " has claimed ", Color( 207, 209, 106), ent:GetRoomName(),
                Color( 255, 255, 255 ), " for ", Color( 80, 192, 52), ent:GetClaimedByName(), Color( 255, 255, 255 ), ".")

        end
        
        

    end )


end


properties.Add( "reset_claim", {
    MenuLabel = "Reset Claim", -- Name to display on the context menu
    Order = 90006, -- The order to display this property relative to other properties
    MenuIcon = "icon16/exclamation.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end
        if ( ent.DeviceType != "room_claim_screen" ) then return false end

        return true
    end,
    Action = function( self, ent )
        net.Start( "HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.UnClaimRoom" )
        net.WriteEntity( ent )
        net.SendToServer()
    end
} )