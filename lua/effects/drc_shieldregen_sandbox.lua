function EFFECT:Init( data )
	
	local ent = data:GetEntity()
	if !IsValid(ent) then return end
	local abort = false
	if DRC:IsCharacter(ent) then
		if ent:Health() <= 0 then abort = true end
	end
	if abort == true then return end
	
	local part = CreateParticleSystem(ent, "drc_halo_3_shield_recharge", PATTACH_ABSORIGIN_FOLLOW, -1)
	part:SetControlPoint(7, DRC:GetColours(ent).Energy or Vector(255,255,255))
	part:StartEmission()
	--	ParticleEffect("drc_halo_3_shield_recharge", data:GetOrigin(), Angle())
end

function EFFECT:Think()		
	return false
end

function EFFECT:Render()
end