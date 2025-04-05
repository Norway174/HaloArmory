
HALOARMORY.MsgC("Client HALO Augmented Reality IFF2 Loading.")


HALOARMORY.AR = HALOARMORY.AR or {}
HALOARMORY.AR.IFF2 = HALOARMORY.AR.IFF2 or {}

HALOARMORY.AR.IFF2.Targets = HALOARMORY.AR.IFF2.Targets or {}

local ARIFF2_HOOK = "HALOARMORY.DrawARIFF2"

HALOARMORY.AR.IFF2.IFFenabled = HALOARMORY.AR.IFF2.IFFenabled or false


local IFF2_Friend = Color( 0, 255, 0 )
local IFF2_Foe = Color( 255, 0, 0 )
local IFF2_Neutral = Color( 255, 255, 255)
local IFF2_Prop = Color( 255, 225, 142)

--hook.Add("PreDrawOutlines", ARIFF2_HOOK, function()
--	HALOARMORY.AR.IFF2.DrawIFF2()
--end)


function HALOARMORY.AR.IFF2.DrawIFF2()
	if !HALOARMORY.AR.IFF2.IFFenabled then return end

	--outline.Add(ents, color, mode, render_type, outline_thickness)

	local Outline_Ents = {}

	// For each ents
	for k, v in pairs( ents.GetAll() ) do
		if IsValid( v ) then
			
			if isentity( v ) and v.GetModel then
				if util.IsValidProp( tostring( v:GetModel() or "" ) ) then
					table.insert( Outline_Ents, v )
				end
			end
			
		end
	end

	--outline.Add( Outline_Ents, IFF2_Foe, OUTLINE_MODE_NOTVISIBLE, OUTLINE_RENDERTYPE_AFTER_EF, 1 )
	--print("IFF2: ", tostring(success))

	halo.Add( Outline_Ents, IFF_Foe, 2, 2, 1, true, false )
		
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



-- HALOARMORY.AR.RegisterApp( "AR_IFF2", -1, "Toggle HUD2", "vgui/haloarmory/icons/IFF.png", function()
--     RunConsoleCommand( "AR_IFF2.Toggle" )
--     surface.PlaySound( "buttons/button24.wav" )
-- end,
-- function()
--     return HALOARMORY.AR.IFF2.IFFenabled and "IFF2 HUD [ON]" or "IFF2 HUD [OFF]"
-- end )


