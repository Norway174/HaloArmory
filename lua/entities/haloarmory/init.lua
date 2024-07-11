
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:Initialize()
    -- Sets what model to use
    self:SetModel( self.Model )

    self:SetSkin( self.Skin )

    if istable(self.Bodygroups) and #self.Bodygroups <= 1 then
        for key, value in pairs(self.Bodygroups) do
            if isnumber(key) and isnumber(value) then
                self:SetBodygroup(key, value)
            end
        end
    end

    -- Sets what color to use
    --self:SetColor( Color( 200, 255, 200 ) )

    -- Physics stuff
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    -- Init physics only on server, so it doesn't mess up physgun beam
    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end

    local phys = self:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:Wake()
        --phys:Sleep()

        phys:EnableMotion( false )
    end

end


function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end

    local SpawnPos = tr.HitPos + tr.HitNormal
    local SpawnAng = ply:EyeAngles()

    local ent = ents.Create( ClassName )

    local SpawnOff = ent.SpawnAngles
    SpawnAng.p = 0
    SpawnAng.p = SpawnAng.p + SpawnOff.p
    SpawnAng.y = SpawnAng.y + SpawnOff.y
    SpawnAng.z = SpawnAng.z + SpawnOff.z

    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end