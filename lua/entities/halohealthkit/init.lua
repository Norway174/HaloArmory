
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( self.MedKitModel )

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

    --PrintTable(self:GetBodyGroups())

    --self:SetBodygroup(1, 1)

    self:SetUseType( SIMPLE_USE )
end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = -90
	SpawnAng.y = SpawnAng.y + 180
    SpawnAng.x = SpawnAng.x + 90
    -- SpawnAng.z = SpawnAng.z + 90

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end


function ENT:Use( activator, caller )
    if ( not activator:IsPlayer() and not activator:IsAlive()) then return end
    if (activator:GetMaxHealth() <= activator:Health()) then
        activator:EmitSound("items/medshotno1.wav")
        return
    end

    activator:EmitSound("items/medshot4.wav")
    activator:SetHealth(activator:GetMaxHealth())
    
    if self.OneTimeUse then
        self:Remove()
    end
end
 
function ENT:Think()
    -- We don't need to think, we are just a prop after all!
end
 