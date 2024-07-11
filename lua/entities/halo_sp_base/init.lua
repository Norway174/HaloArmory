
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Sets what model to use
    self:SetModel( self.DeviceModel )
    self:SetupModel()

    -- Physics stuff
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    -- Init physics only on server, so it doesn't mess up physgun beam
    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end

    -- Make prop to fall on spawn
    self:PhysWake()

    -- Delay ENT:UpdateGlobalNetworks() by 1 second to allow the entity to spawn
    timer.Simple( 1, function()
        if not IsValid( self ) then return end
        self:SetNetworkID( self:GetNetworkID() )
    end )

    self:PostInit()

end

function ENT:PostInit()

end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end

    local SpawnPos = tr.HitPos + tr.HitNormal * 10
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0
    SpawnAng.y = SpawnAng.y + 0

    local ent = ents.Create( ClassName )
    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )

    ent:Spawn()
    ent:Activate()

    return ent

end
