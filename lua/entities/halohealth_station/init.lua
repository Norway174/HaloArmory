
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:PreInit()
    self:SetSubMaterial( 2, "models/props_lab/security_screens2" )
	self:UpdateVisuals( false)
end

function ENT:UpdateVisuals( IsSpawned )
    local color = Color( 0, 110, 0)
    if IsSpawned then color = Color( 110, 0, 0) end
    self:SetColor( color )
end

function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( self.BaseModel )

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

    --PrintTable(self:GetBodyGroups())

    --self:SetBodygroup(1, 1)

    self:SetUseType( SIMPLE_USE )

    self:PreInit()
end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = -90
	--SpawnAng.y = SpawnAng.y + 180
    --SpawnAng.x = SpawnAng.x + 90
    -- SpawnAng.z = SpawnAng.z + 90

    SpawnPos = SpawnPos + self.SpawnPos
    SpawnAng = SpawnAng + self.SpawnAng

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end
 
function ENT:Think()
    -- We don't need to think, we are just a prop after all!
end

local blockingProps = {
    --["prop_physics"] = true,
    --["prop_dynamic"] = true,
}

function ENT:SpawnMedKit( ply )

    if self:GetState() ~= 1 then self:EmitSound("buttons/button10.wav") return end

    local SpawnPos = self:LocalToWorld( self.MedKitSpawnOffsetPos )
    local SpawnAng = self:LocalToWorldAngles( self.MedKitSpawnOffsetAng )

    local CheckObstruction = ents.FindInSphere( SpawnPos, 2 )
    table.insert( blockingProps, self.MedKitClass )
    local Obstructed = false
    for key, ent in pairs(CheckObstruction) do
        if blockingProps[ent:GetClass()] then Obstructed = true return end
    end
    if Obstructed then self:EmitSound("buttons/button10.wav") return end

    --debugoverlay.Sphere( SpawnPos, 2, 1, Color( 255, 255, 255 ), true )

    local medKit = ents.Create( self.MedKitClass )

    medKit:SetPos( SpawnPos )
    medKit:SetAngles( SpawnAng )

    medKit:Spawn()
    self:EmitSound("buttons/button14.wav")

    --local weld = constraint.Weld( self, medKit, 0, 0, 0, 1, false )

    --self:DeleteOnRemove(medKit)

    undo.Create("MedKit")
        undo.AddEntity( medKit )
        undo.SetPlayer( ply )
    undo.Finish()

    self:SetState( 2 ) // Set state to Regenerating
    self:UpdateVisuals( true )

    timer.Simple( self:GetRespawnTime(), function() 
        self:SetState( 1 ) // Set state to Can Spawn
        self:UpdateVisuals( false )
        if IsValid( medKit ) then
            medKit:Remove()
        end
    end)

    -- timer.Simple( self:GetRespawnTime(), function() 
    --     medKit:Remove()
    -- end)

end

function ENT:Use( activator, caller )
    if ( not activator:IsPlayer() and not activator:IsAlive()) then return end
    --if (activator:GetMaxHealth() <= activator:Health()) then return end

    self:SpawnMedKit( activator )
end