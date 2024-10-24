
HALOARMORY.MsgC("Client HALO Augmented Reality Helmet Loading.")

HALOARMORY.AR = HALOARMORY.AR or {}
HALOARMORY.AR.APPS = HALOARMORY.AR.APPS or {}


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
    ContextButton( window, "Helmet AR", "vgui/haloarmory/icons/HelmetAlt2.png", function()
        window:Remove()
    end )

	for app, data in SortedPairsByMemberValue( HALOARMORY.AR.APPS, "order", false ) do
		ContextButton( window, data.name, data.icon, data.func, data.name_func )
	end

    // Example Button to call the Concomand.
    -- ContextButton( window, "Toggle HUD", "vgui/haloarmory/icons/iff.png", function()
    --     RunConsoleCommand( "AR_IFF.Toggle" )
    --     surface.PlaySound( "buttons/button24.wav" )
    -- end,
    -- function()
    --     return hook.GetTable()["PreDrawHalos"][ARIFF_HOOK] and "Disable IFF HUD" or "Enable IFF HUD"
    -- end )

end

list.Set( "DesktopWindows", "HALOARMORY.AR_IFF", {
    title		= "Helmet AR",
    icon		= "vgui/haloarmory/icons/HelmetAlt2.png",
    width		= 80 * (table.Count( HALOARMORY.AR.APPS ) + 1),
    height		= 84,
    onewindow	= true,
    init		= ContextWindow
} )




function HALOARMORY.AR.RegisterApp( app, order, name, icon, func, name_func )
	HALOARMORY.AR.APPS[app] = {
		order = order or 99,
		name = name,
		icon = icon,
		func = func,
		name_func = name_func,
	}

	MsgC( "Registered AR App: ", name, "\n" )

	list.Set( "DesktopWindows", "HALOARMORY.AR_IFF", {
		title		= "Helmet AR",
		icon		= "vgui/haloarmory/icons/HelmetAlt2.png",
		width		= 80 * (table.Count( HALOARMORY.AR.APPS ) + 1),
		height		= 84,
		onewindow	= true,
		init		= ContextWindow
	} )
end

