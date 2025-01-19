
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
    
    local SpawnPos = tr.HitPos + tr.HitNormal
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0
    -- SpawnAng.y = SpawnAng.y + -90
    -- SpawnAng.x = SpawnAng.x + 90
    -- SpawnAng.z = SpawnAng.z + 90

    local ent = ents.Create( "halo_fob_vehicle" )

	ent.Deployed = true

    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end
