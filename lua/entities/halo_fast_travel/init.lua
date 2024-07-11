
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local CONSTS = {
    NETWORK = "HALOARMORY.FASTTRAVEL",
    ACTIONS = {
        TELEPORT = 1,
        SYNC = 2,
        SYNC_ALL = 3,
        REMOVE = 4,
    },
}

util.AddNetworkString( CONSTS.NETWORK )


local Destinations = {}


function ENT:PreInit()
    Destinations[ self:EntIndex() ] = self
    self:NetSync()
end

function ENT:OnRemove()
    Destinations[ self:EntIndex() ] = nil
    self:NetSync()
end

function ENT:TeleportPlayer( ply, destination )

    destination = destination or self

    if destination:GetEnabled() == false then return end
    if not ply:Alive() then return end
    if ply:InVehicle() then return end

    ply:ScreenFade( SCREENFADE.OUT, Color( 0, 0, 0 ), 1, 1 )

    timer.Simple( 1, function()

        if not IsValid( ply ) then return end

        // Find a suitable position to spawn the player, in front of the screen
        local spawn_pos = destination:GetPos() + (destination:GetForward() * -50) + (destination:GetUp() * 50)

        local tr = util.TraceLine( {
            start = spawn_pos,
            endpos = spawn_pos + Vector( 0, 0, -1000 ),
            filter = function( ent2 ) if ( ent2:GetClass() == "prop_physics" ) then return true end end
        } )

        if tr.Hit then
            spawn_pos = tr.HitPos + tr.HitNormal * 16
        end

        ply:SetPos( spawn_pos )

        // Face the player towards the screen, except for up and down.
        local ang = destination:GetAngles()
        ang.p = 0
        ang.r = 0
        ply:SetEyeAngles( ang )

        ply:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), 1, 1 )

    end )

end



function ENT:NetSync()
    net.Start( CONSTS.NETWORK )
    if Destinations[ self:EntIndex() ] == nil then
        // This is a removal
        net.WriteUInt( CONSTS.ACTIONS.REMOVE, 8 )
        net.WriteUInt( self:EntIndex(), 13 )
    else
        net.WriteUInt( CONSTS.ACTIONS.SYNC, 8 )
        self:NetBuilder()
    end

    net.Broadcast()
end

function ENT:NetSyncAll()
    net.Start( CONSTS.NETWORK )
    net.WriteUInt( CONSTS.ACTIONS.SYNC_ALL, 8 )
    
    local count = table.Count( Destinations )
    net.WriteUInt( count, 8 )

    for k, v in pairs( Destinations ) do
        v:NetBuilder()
    end

    net.Broadcast()
end

function ENT:NetBuilder()
    net.WriteUInt( self:EntIndex(), 13 ) //ID
    net.WriteString( self:GetDestination() ) //Destination
    net.WriteBool( self:GetEnabled() ) //Enabled
    net.WriteEntity( self ) //Entity
    net.WriteVector( self:GetPos() ) //Position
end


net.Receive( CONSTS.NETWORK, function( len, ply )

    local action = net.ReadUInt( 8 )


    if action == CONSTS.ACTIONS.TELEPORT then
        local ent_id = net.ReadUInt( 13 )

        if not Destinations[ent_id] and not IsValid(Destinations[ent_id]) then return end
        Destinations[ent_id]:TeleportPlayer( ply )

    elseif action == CONSTS.ACTIONS.SYNC_ALL then

        local dest_key = table.Random( Destinations )
        if dest_key and IsValid(dest_key) then
            dest_key:NetSyncAll()
        end
    end

end )

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end



// Handle auto-refreshing the destinations
local fast_travel_screens = ents.FindByClass( "halo_fast_travel" )

for k, v in pairs( fast_travel_screens ) do
    Destinations[ v:EntIndex() ] = v
end

if fast_travel_screens[1] and IsValid(fast_travel_screens[1]) then
    fast_travel_screens[1]:NetSyncAll()
end