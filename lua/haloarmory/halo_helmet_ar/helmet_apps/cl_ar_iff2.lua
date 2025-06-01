
HALOARMORY.MsgC("Client HALO Augmented Reality IFF2 Loading.")


HALOARMORY.AR = HALOARMORY.AR or {}
HALOARMORY.AR.IFF2 = HALOARMORY.AR.IFF2 or {}

HALOARMORY.AR.IFF2.Targets = HALOARMORY.AR.IFF2.Targets or {}

local ARIFF2_HOOK = "HALOARMORY.DrawARIFF2"

HALOARMORY.AR.IFF2.IFFenabled = HALOARMORY.AR.IFF2.IFFenabled or false

local IFF2_CloseFriend = Color( 0, 255, 213)
local IFF2_Friend = Color( 0, 255, 0 )
local IFF2_Foe = Color( 255, 0, 0 )
local IFF2_Neutral = Color( 255, 255, 255)
local IFF2_Prop = Color( 255, 225, 142)

local HALO_BLURX = 1
local HALO_BLURY = 1
local HALO_PASSES = 1
local HALO_ADDITIVE = true
local HALO_IGNORE_Z = false

--hook.Add("PreDrawOutlines", ARIFF2_HOOK, function()
--	HALOARMORY.AR.IFF2.DrawIFF2()
--end)


function HALOARMORY.AR.IFF2.DrawIFF2()
	if !HALOARMORY.AR.IFF2.IFFenabled then return end

	for _, ent in ents.Iterator() do
		if !IsValid( ent ) then continue end

		if ( ent.DeviceName == "Crate" && ent.DeviceType == "storage" ) then
			halo.Add( {ent}, IFF2_Prop, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )

		elseif ( ent:IsPlayer() ) then
			local LPly = LocalPlayer()
			--if ent == LPly then continue end
			if !ent:Alive() then continue end
			if ent:GetMoveType() == MOVETYPE_NOCLIP then continue end

			if ent:Team() == LPly:Team() then
				halo.Add( {ent}, IFF2_CloseFriend, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
			else
				halo.Add( {ent}, IFF2_Friend, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
			end

		elseif ( ent:IsNPC() || ent:IsNextBot() ) then
			if IsEnemyEntityName( ent:GetClass() ) then
				halo.Add( {ent}, IFF2_Foe, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
			elseif IsFriendEntityName( ent:GetClass() ) then
				halo.Add( {ent}, IFF2_Friend, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
			else

				// Check if the NPC name contains spv3
				if string.find( ent:GetClass(), "spv3" ) then
					// It's an SPV3 NPC. So let's add special rules.
					// Friends will contain "unsc" in the name.
					// Hostiles will contain "cov" and "flood" in the name.
					// We want to ignore all with "dropship" or "turret" in the name.

					if string.find( ent:GetClass(), "dropship" ) || string.find( ent:GetClass(), "turret" ) then continue end

					if string.find( ent:GetClass(), "unsc" ) then
						halo.Add( {ent}, IFF2_Friend, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
					elseif string.find( ent:GetClass(), "cov" ) || string.find( ent:GetClass(), "flood" ) then
						halo.Add( {ent}, IFF2_Foe, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
					else
						halo.Add( {ent}, IFF2_Neutral, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
					end
				else
					halo.Add( {ent}, IFF2_Neutral, HALO_BLURX, HALO_BLURY, HALO_PASSES, HALO_ADDITIVE, HALO_IGNORE_Z )
				end
			end
		end
	end

end
hook.Add("PreDrawHalos", ARIFF2_HOOK, HALOARMORY.AR.IFF2.DrawIFF2)


function HALOARMORY.AR.IFF2.ToggleIFF2()
	-- if hook.GetTable()["HUDPaint"][ARIFF2_HOOK] then
	-- 	hook.Remove( "HUDPaint", ARIFF2_HOOK )
	-- else
	-- 	hook.Add( "HUDPaint", ARIFF2_HOOK, HALOARMORY.AR.IFF2.DrawIFF2 )
	-- end

	HALOARMORY.AR.IFF2.IFFenabled = !HALOARMORY.AR.IFF2.IFFenabled
end

concommand.Add( "AR_IFF2.Toggle", function( ply, cmd, args )
	HALOARMORY.AR.IFF2.ToggleIFF2()
end )


// DEBUG: Refresh the hook.
-- if hook.GetTable()["HUDPaint"][ARIFF2_HOOK] then
-- 	print("Refreshing IFF2 Hook")
-- 	hook.Add( "HUDPaint", ARIFF2_HOOK, HALOARMORY.AR.IFF2.DrawIFF2 )
-- end



HALOARMORY.AR.RegisterApp( "AR_IFF2", -1, "Toggle HUD2", "vgui/haloarmory/icons/IFF.png", function()
    RunConsoleCommand( "AR_IFF2.Toggle" )
    surface.PlaySound( "buttons/button24.wav" )
end,
function()
    return HALOARMORY.AR.IFF2.IFFenabled and "IFF2 HUD [ON]" or "IFF2 HUD [OFF]"
end )


