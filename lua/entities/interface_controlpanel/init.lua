
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")




function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( "models/nirrti/tablet/tablet_sfm.mdl" )

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

    

end


