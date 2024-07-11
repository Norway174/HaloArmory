
// STOP THIS FILE:
--if true then return end

HALOARMORY.MsgC("Client Vehicle Pickup DEBUG HUD Loading.")

local PICKUPBOUNDS_HOOK = "HALOARMORY.DrawVehiclePickupBounds"
local CARGOHUD_HOOK = "HALOARMORY.DrawVehicleCargoHUD"

local function DrawBoxShip()

    for _, ent in pairs( ents.GetAll() ) do
        if not HALOARMORY.Vehicles.allowedVehicles[ent.GetSpawn_List and ent:GetSpawn_List() or ent:GetClass()] then continue end
        

        local pos = ent:GetPos()
        --local offset = Vector(-500, 0, 60)
        local offset = HALOARMORY.Vehicles.allowedVehicles[ent.GetSpawn_List and ent:GetSpawn_List() or ent:GetClass()].pos
        pos = ent:LocalToWorld(offset)

        local radius = HALOARMORY.Vehicles.allowedVehicles[ent.GetSpawn_List and ent:GetSpawn_List() or ent:GetClass()].rad

        -- Draw the wireframe sphere!
        render.DrawWireframeSphere( pos, radius, 10, 10, Color( 9, 177, 255), true)

    end

end

concommand.Add( "VEHICLE.PickupHUD", function( ply, cmd, args )

    if hook.GetTable()["PostDrawOpaqueRenderables"][PICKUPBOUNDS_HOOK] then
        hook.Remove( "PostDrawOpaqueRenderables", PICKUPBOUNDS_HOOK )
        print("Removed the hook.")
    else
        hook.Add( "PostDrawOpaqueRenderables", PICKUPBOUNDS_HOOK, DrawBoxShip )
        print("Hook added.")
    end
    
end )


local first_run = first_run or false
if first_run and hook.GetTable()["PostDrawOpaqueRenderables"][PICKUPBOUNDS_HOOK] then
    hook.Add( "PostDrawOpaqueRenderables", PICKUPBOUNDS_HOOK, DrawBoxShip )
    print("Hook updated.")
else
    first_run = true
end



local function CheckVehicleCargo()
    ply = LocalPlayer()

    local ent = nil

    local tr = util.TraceLine( util.GetPlayerTrace( ply ) )
    if IsValid(tr.Entity) then
        ent = HALOARMORY.Vehicles.GetVehicle( tr.Entity )
    end

    if not IsValid( ent ) then return end


    local CanCarry = HALOARMORY.Vehicles.allowedVehicles[ent.GetSpawn_List and ent:GetSpawn_List() or ent:GetClass()]

    local name = ent.PrintName or ent.ClassName or "Vehicle"

    if (ent:GetClass():lower() == "gmod_sent_vehicle_fphysics_base") then
        name = list.Get( "simfphys_vehicles" )[ent:GetSpawn_List()]["Name"]
    end

    surface.SetDrawColor( 0, 0, 0, 182)
    
    local w, h = 150, 35
    local posX, posY = ScrW() / 2 * .25 + 150 + 20, (ScrH() / 2) * .12 - (h / 2)

    // Check if the context menu is open, if so, move the HUD down.
    if not ( IsValid( g_ContextMenu ) && !g_ContextMenu:IsVisible() ) then
		posY = posY + 30
	end

    surface.DrawRect( posX - (w / 2), posY - h, w, h )

    local offset = 6
    draw.SimpleText( name, "Default", posX, posY - (h / 2) - offset, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
    local IsLoaded, TheLoad = HALOARMORY.Vehicles.IsLoadedVehicle( ent )

    if not CanCarry then
        draw.SimpleText( "No load capacity", "DefaultSmall", posX, posY - (h / 2) + offset, Color(248,168,18), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    elseif IsLoaded then
        draw.SimpleText( "Loaded: "..#TheLoad, "DefaultSmall", posX, posY - (h / 2) + offset, Color(163,255,14), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

        for k, v in ipairs(TheLoad) do
            if not IsValid( v.ent ) then continue end
            debugoverlay.EntityTextAtPosition( v.ent:GetPos(), 1, v.ent:GetClass(), FrameTime(), Color( 255, 255, 255 ) )
        end

    else
        draw.SimpleText( "Unloaded", "DefaultSmall", posX, posY - (h / 2) + offset, Color(255,14,14), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

end
hook.Add( "HUDPaint", CARGOHUD_HOOK, CheckVehicleCargo )




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
    ContextButton( window, "Vehicle Cargo", "vgui/haloarmory/icons/package.png", function()
        window:Remove()
    end )

    // 2nd Button to load the vehicle.
    ContextButton( window, "Load Vehicle", "vgui/haloarmory/icons/supplies-in.png", function()
        HALOARMORY.Vehicles.LoadVehicle( LocalPlayer() )
        --surface.PlaySound( "buttons/button5.wav" )
    end )
    
    // 3rd Button to unload the vehicle.
    ContextButton( window, "Unload Vehicle", "vgui/haloarmory/icons/supplies-out.png", function()
        HALOARMORY.Vehicles.UnLoadVehicle( LocalPlayer() )
        --surface.PlaySound( "buttons/button6.wav" )
    end )

    // 4th Button to call the Concomand.
    ContextButton( window, "Toggle HUD", "vgui/haloarmory/icons/globe.png", function()
        RunConsoleCommand( "VEHICLE.PickupHUD" )
        surface.PlaySound( "buttons/button24.wav" )
    end,
    function()
        return hook.GetTable()["PostDrawOpaqueRenderables"][PICKUPBOUNDS_HOOK] and "Disable HUD" or "Enable HUD"
    end )

end

list.Set( "DesktopWindows", "HALOARMORY.VehiclePickup", {
    title		= "Vehicle Cargo",
    icon		= "vgui/haloarmory/icons/package.png",
    width		= 80 * 4,
    height		= 84,
    onewindow	= true,
    init		= ContextWindow
} )
