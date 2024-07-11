--[[

	"Sandbox Shields" by Vuthakral.
	
	This script is provided as-is and is made purely for example on how to utilize the Draconic Base's shield system.
	You are free to edit, modify, and reupload edits of THIS script.
	
	Particle effects made by Dopey.
	
	Vuthakral: https://steamcommunity.com/id/Vuthakral/
	Dopey: https://steamcommunity.com/profiles/76561198040373516
	
	Edited for HaloRP by Norway174.

--]]

if GetConVar("sv_sandshields_enabled") == nil then
	CreateConVar("sv_sandshields_enabled", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_DEMO}, "Enable/Disable Sandbox Shields.")
end

if GetConVar("sv_sandshields_shielddelay") == nil then
	CreateConVar("sv_sandshields_shielddelay", 8, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_DEMO}, "Shield recharge delay after taking damage.")
end

if GetConVar("sv_sandshields_shieldhealth") == nil then
	CreateConVar("sv_sandshields_shieldhealth", 500, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_DEMO}, "Set the health of the shields.")
end

if GetConVar("sv_sandshields_shieldregenamount") == nil then
	CreateConVar("sv_sandshields_shieldregenamount", 42, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_DEMO}, "Amount of health (per second) which shields regenerate at.")
end

hook.Add("PlayerLoadout", "DRCShield_ply", function(ply)
	if not DRC then
		print("Draconic Base not found, shields will not be enabled.")
		hook.Remove("PlayerLoadout", "DRCShield_ply")
		return
	end


	if GetConVar("sv_sandshields_enabled"):GetFloat() == 1 and (DarkRP and ( ply:getJobTable().spartan_shield or isnumber( ply:getJobTable().spartan_shield ) ) ) then

		local delay = GetConVar("sv_sandshields_shielddelay"):GetFloat()
		local amount = GetConVar("sv_sandshields_shieldregenamount"):GetFloat()
		local health = GetConVar("sv_sandshields_shieldhealth"):GetFloat()

		if isnumber( ply:getJobTable().spartan_shield ) then health = ply:getJobTable().spartan_shield end

		local shieldtable = {
			["Regenerating"] = true, -- Should the shield regenerate at all?
			["RegenDelay"] = delay, -- Delay (in seconds) before the shield will regenerate after taking damage.
			["RegenAmount"] = amount, -- Amount (per second) which the shield will regenerate
			["Health"] = health, -- Total HP of the shield
			["Effects"] = {
				["BloodEnum"] = BLOOD_COLOR_RED,
				["Impact"] = "drc_shieldspark_sandbox",
				["Deplete"] = "drc_shieldpop_sandbox",
				["Recharge"] = "drc_shieldregen_sandbox",
			},
			-- ["Sounds"] = {
			-- 	["Impact"] = "draconic.ShieldImpactGeneric",
			-- 	["Deplete"] = "draconic.ShieldDepleteGeneric",
			-- 	["Recharge"] = "draconic.ShieldRechargeGeneric",
			-- },
			["Sounds"] = {
				["Impact"] = "haloarmory/halo_shields/shield_hit_1.wav",
				["Deplete"] = "haloarmory/halo_shields/shield_break.wav",
				["Recharge"] = "haloarmory/halo_shields/shield_charge.wav",
			},
			["Material"] = "models/vuthakral/shield_example",
			["AlwaysVisible"] = false,
			["ScaleMax"] = 1.15, -- The scale the shield will reach when taking damage
			["ScaleMin"] = 1.05, -- The scale the shield will be when idle.
		}

		DRC:SetShieldInfo(ply, true, shieldtable)
	else
		DRC:SetShieldInfo(ply, false)
	end
end)

--resource.AddFile( "particles/drc_energy_shield_effects.pcf" )
game.AddParticles( "particles/drc_energy_shield_effects.pcf" )

PrecacheParticleSystem( "drc_halo_3_shield_deplete" )
PrecacheParticleSystem( "drc_halo_3_shield_deplete_arcs" )
PrecacheParticleSystem( "drc_halo_3_shield_impact_effect" )
PrecacheParticleSystem( "drc_halo_3_shield_recharge" )