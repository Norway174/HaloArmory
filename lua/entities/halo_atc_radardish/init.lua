
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString( "HALO.ATC.Contacts.Update" )

function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( self.RadarModel )

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


local lastScanTime = 0
local scanPos = Vector(-18,36,31)
local last_patient = nil

function ENT:Think()


    if ( CurTime() > lastScanTime + 5 ) then
        lastScanTime = CurTime()
        
        if self:GetScanType() == "Air" then
            local results = {}

            // Loop through all ents
            for k, v in pairs( ents.GetAll() ) do
                if v.LFS and (v:GetAITEAM() == 2) then
                    results[#results+1] = v
                end
            end

            // Send results to client
            net.Start( "HALO.ATC.Contacts.Update" )
                net.WriteEntity( self )
                net.WriteTable( results )
            net.Broadcast()

            --print("Scanned for air contacts")
            --PrintTable(results)

        elseif self:GetScanType() == "Ground" then
            // TODO: Add ground scan
        end
        
    end

end

