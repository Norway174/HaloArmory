
HALOARMORY.MsgC("Client HALO Augmented Reality IFF Loading.")


HALOARMORY.AR = HALOARMORY.AR or {}
HALOARMORY.AR.IFF = HALOARMORY.AR.IFF or {}

HALOARMORY.AR.IFF.Targets = HALOARMORY.AR.IFF.Targets or {}

local ARIFF_HOOK = "HALOARMORY.DrawARIFF"


local IFF_Friend = Color( 0, 255, 0 )
local IFF_Foe = Color( 255, 0, 0 )
local IFF_Neutral = Color( 255, 255, 255)
local IFF_Prop = Color( 255, 225, 142)

function HALOARMORY.AR.IFF.DrawIFF()


	local FRIEND = {}
	local FOE = {}
	local NEUTRAL = {}
	local PROP = {}

	for _, target in pairs( HALOARMORY.AR.IFF.Targets ) do
		local ent = target.Ent
		local entType = target.EntType

		if not IsValid( ent ) then continue end

		if entType == "Player" then
			if ent == LocalPlayer() then continue end

			if not ent:Alive() then continue end

			if ent.Team and ent:Team() == LocalPlayer():Team() then
				table.insert( FRIEND, ent )
			else
				table.insert( FRIEND, ent )
			end

		elseif entType == "NPC-Friendly" then
			
			table.insert( FRIEND, ent )

		elseif entType == "NPC-Hostile" then
			
			table.insert( FOE, ent )

		elseif entType == "NPC-Neutral" then
			
			table.insert( NEUTRAL, ent )

		elseif entType == "Prop" then
			table.insert( PROP, ent )

		end
	end

	// Draw the halos.
	halo.Add( FRIEND, IFF_Friend, 2, 2, 1, true, false )
	halo.Add( FOE, IFF_Foe, 2, 2, 1, true, false )
	halo.Add( NEUTRAL, IFF_Neutral, 2, 2, 1, true, false )
	halo.Add( PROP, IFF_Prop, 2, 2, 1, true, false )
end

function HALOARMORY.AR.IFF.ToggleIFF()
	if hook.GetTable()["PreDrawHalos"][ARIFF_HOOK] then
		hook.Remove( "PreDrawHalos", ARIFF_HOOK )
	else
		hook.Add( "PreDrawHalos", ARIFF_HOOK, HALOARMORY.AR.IFF.DrawIFF )
	end
end

concommand.Add( "AR_IFF.Toggle", function( ply, cmd, args )
	HALOARMORY.AR.IFF.ToggleIFF()
end )


net.Receive("HALOARMORY.AR.IFF", function()
	local str = net.ReadString()
	if str == "SendTargets" then
		HALOARMORY.AR.IFF.Targets = net.ReadTable()
		--print("Received Targets:")
		--PrintTable( HALOARMORY.AR.IFF.Targets )
	end
end)


// DEBUG: Refresh the hook.
if hook.GetTable()["PreDrawHalos"][ARIFF_HOOK] then
	hook.Add( "PreDrawHalos", ARIFF_HOOK, HALOARMORY.AR.IFF.DrawIFF )
end



HALOARMORY.AR.RegisterApp( "AR_IFF", 1, "Toggle HUD", "vgui/haloarmory/icons/iff.png", function()
    RunConsoleCommand( "AR_IFF.Toggle" )
    surface.PlaySound( "buttons/button24.wav" )

    // Turn off FLIR if it's on. Since it's buggy with DrawHalos.
    if NV.Status() and GetConVar("nv_type"):GetBool() then
        RunConsoleCommand("nv_toggle")
    end
end,
function()
    return hook.GetTable()["PreDrawHalos"][ARIFF_HOOK] and "IFF HUD [ON]" or "IFF HUD [OFF]"
end )
