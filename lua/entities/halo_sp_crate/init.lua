
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Sets what model to use
    self:SetupModel()

    -- Physics stuff
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    -- Init physics only on server, so it doesn't mess up physgun beam
    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end

    -- Make prop to fall on spawn
    self:PhysWake()

    -- local phys = self:GetPhysicsObject()
    -- if ( IsValid( phys ) ) then 
    --     print( "Mass: ", phys:GetMass() )
    --     --phys:SetMass( 35 )
    -- end

    self:SetUseType( SIMPLE_USE )

end


function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end

    local SpawnPos = tr.HitPos + tr.HitNormal * 10
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0
    SpawnAng.y = SpawnAng.y + 0

    local ent = ents.Create( ClassName ) // Manually set entity to the base class

    local RandomMin = ent.RandomMin or 0
    local RandomMax = ent.RandomMax or 0

    ent:Remove()

    ent = ents.Create( "halo_sp_crate" )
    
    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )

    // Pick a random model from DeviceModelAlts
    local _, model = table.Random( ent.DeviceModelAlts )
    ent.DeviceModel = model

    print( "Spawning " .. ClassName .. " with model " .. model)


    ent:Spawn()
    ent:Activate()

    // Set a random supplies between min and max.
    // If min and max are the same. Then skip this step.
    print( "MinSupplies: " .. RandomMin .. " MaxSupplies: " .. RandomMax)
    --if ( RandomMin != RandomMax ) then
        --print( "Randomizing supplies")
        ent:SetStored( math.random( RandomMin, RandomMax ) )
    --end
    


    return ent

end

--SetMaxCapacity
--SetStored

function ENT:OnTakeDamage( dmginfo )
	-- Make sure we're not already applying damage a second time
	-- This prevents infinite loops
	if ( not self.m_bApplyingDamage ) then

        local damageAmount = dmginfo:GetDamage() -- The amount of damage done to the entity

        -- If the damage is less than 0, don't do anything
        if ( damageAmount <= 0 ) then return end

        -- If the damage is more than 0, take damage
        self:SetStored( self:GetStored() - damageAmount )

        -- If the health is less than 0, remove the entity
        if ( self:GetStored() <= 0 ) then

            local explosion = ents.Create( "env_explosion" ) -- The explosion entity
            explosion:SetPos( self:GetPos() ) -- Put the position of the explosion at the position of the entity
            explosion:Spawn() -- Spawn the explosion
            explosion:SetKeyValue( "iMagnitude", "1" ) -- the magnitude of the explosion
            explosion:Fire( "Explode", 0, 0 ) -- explode

            self:Remove()
        end
    end
end

function ENT:Use( activator )

    if activator:IsPlayer() then 

        if ( activator:IsPlayerHolding() ) then 
            activator:DropObject()
        else
            activator:PickupObject( self )
        end

    end

end