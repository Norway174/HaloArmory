
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
		if target.EntType == "Player" then
			if target.Ent == LocalPlayer() then continue end
			if target.Ent:Team() == LocalPlayer():Team() then
				table.insert( FRIEND, target.Ent )
			else
				table.insert( FRIEND, target.Ent )
			end
		elseif target.EntType == "NPC-Friendly" then
			table.insert( FRIEND, target.Ent )
		elseif target.EntType == "NPC-Hostile" then
			table.insert( FOE, target.Ent )
		elseif target.EntType == "NPC-Neutral" then
			table.insert( NEUTRAL, target.Ent )
		elseif target.EntType == "Prop" then
			table.insert( PROP, target.Ent )
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


--[[ 
##============================##
||                            ||
||      Desktop Context       ||
||                            ||
##============================##
 ]]

 local function ContextButton( window, name, icon, callback_func, callback_text )
    local button = vgui.Create( "DButton", window )
    button:SetText( "" )
    button:SetSize( 80, 80 )
    button:Dock( LEFT )
    button:DockMargin( 0, 0, 0, 0 )
    button.SetCustomName = name

    button.Paint = function( self, w, h )
        // Draw the icon
        surface.SetDrawColor( 255, 255, 255)
        surface.SetMaterial( Material( icon ) )
        surface.DrawTexturedRect( (w * .5) - 32, 0, 64, 64 )

        // Draw the name
        draw.SimpleText( self.SetCustomName, "DermaDefault", w * .5, 70, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    button.DoClick = function()
        callback_func()
    end

    button.Think = function()
        if not callback_text then return end
        button.SetCustomName = callback_text()
    end

end

local function ContextWindow( icon, window )
    window:SetTitle( "" )
    window:ShowCloseButton( false )
    window:DockPadding( 0, 0, 8, 0 )

    window.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
    end

    local w, h = icon:LocalToScreen( 0, 0 )
    window:SetPos( w, h )

    -- timer.Simple( 0.1, function()
    --     window.Think = function()
    --         local x,y = window:CursorPos()
    --         if x > 0 and x < window:GetWide() and y > 0 and y < window:GetTall() then return end
    --         --window:Remove()
    --     end
    -- end )

    // 1st Button to open the GUI.
    ContextButton( window, "Helmet AR", "vgui/haloarmory/icons/package.png", function()
        window:Remove()
    end )

    -- // 2nd Button to load the vehicle.
    -- ContextButton( window, "Load Vehicle", "vgui/haloarmory/icons/supplies-in.png", function() models/valk/haloreach/unsc/characters/marine/props/helmet.mdl
    --     --HALOARMORY.Vehicles.LoadVehicle( LocalPlayer() )
    --     RunConsoleCommand( "VEHICLE.Load" )
    --     --surface.PlaySound( "buttons/button5.wav" )
    -- end )
    
    -- // 3rd Button to unload the vehicle.
    -- ContextButton( window, "Unload Vehicle", "vgui/haloarmory/icons/supplies-out.png", function()
    --     --HALOARMORY.Vehicles.UnLoadVehicle( LocalPlayer() )
    --     RunConsoleCommand( "VEHICLE.Unload" )
    --     --surface.PlaySound( "buttons/button6.wav" )
    -- end )

    // 4th Button to call the Concomand.
    ContextButton( window, "Toggle HUD", "vgui/haloarmory/icons/globe.png", function()
        RunConsoleCommand( "AR_IFF.Toggle" )
        surface.PlaySound( "buttons/button24.wav" )
    end,
    function()
        return hook.GetTable()["PreDrawHalos"][ARIFF_HOOK] and "Disable HUD" or "Enable HUD"
    end )

end

list.Set( "DesktopWindows", "HALOARMORY.AR_IFF", {
    title		= "Helmet AR",
    icon		= "vgui/haloarmory/icons/package.png",
    width		= 80 * 2,
    height		= 84,
    onewindow	= true,
    init		= ContextWindow
} )




-- Define the custom console command
concommand.Add("check_nwvars_datatables", function(ply, cmd, args)
    -- Perform a trace from the player's view
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 5000,  -- Trace for 5000 units
        filter = ply  -- Ignore the player themselves
    })
    
    -- Check if we hit something
    if tr.Hit and IsValid(tr.Entity) then
        local entityHit = tr.Entity  -- Get the Entity that was hit
        print("Hit Entity:", entityHit)

        -- Gather and print all networked variables (NWVars) on the Entity
        print("\n--- Networked Variables (NWVars) ---")
        
        -- Use the global function BuildNetworkedVarsTable to get all NWVars
        local npcNWVars = entityHit:GetNWVarTable()
        
        if npcNWVars and istable(npcNWVars) and table.Count(npcNWVars) > 0 then
            PrintTable(npcNWVars)
        else
            print("No Networked Variables found for this Entity.")
        end

        -- Gather and print all networked variables (NW2Vars) on the Entity
        print("\n--- Networked Variables (NW2Vars) ---")
        
        -- Use the global function BuildNetworkedVarsTable to get all NWVars
        local npcNW2Vars = entityHit:GetNW2VarTable()
        
        if npcNW2Vars and istable(npcNW2Vars) and table.Count(npcNW2Vars) > 0 then
            PrintTable(npcNW2Vars)
        else
            print("No Networked 2 Variables found for this Entity.")
        end

        -- Now gather and print DataTables
        print("\n--- DataTables ---")
        local saveTable = entityHit.GetNetworkVars and entityHit:GetNetworkVars() or nil

        if saveTable and istable(saveTable) and table.Count(saveTable) > 0 then
            PrintTable(saveTable)
        else
            print("No DataTables found for this Entity.")
        end

    else
        print("No Entity was hit.")
    end
end)


