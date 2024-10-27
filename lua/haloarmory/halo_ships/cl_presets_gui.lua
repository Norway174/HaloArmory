HALOARMORY.MsgC("Client HALO SHIP Presets GUI Loading.")


HALOARMORY.Ships = HALOARMORY.Ships or {}
HALOARMORY.Ships.Presets = HALOARMORY.Ships.Presets or {}
HALOARMORY.Ships.Presets.GUI = HALOARMORY.Ships.Presets.GUI or {}

local ScrWi, ScrHe = math.min(ScrW() - 10, 350), math.min(ScrH() - 10, 550)
--ScrWi, ScrHe = 800, 600

hook.Add( "OnScreenSizeChanged", "HALOARMORY.Ships.Presets.GUI.OnSizeChange", function( oldWidth, oldHeight )
    ScrWi, ScrHe = math.min(ScrW() - 10, 350), math.min(ScrH() - 10, 550)
end )



local function TAB_LoadPreset( ship_class, parent, presetList )

    // Create a list of presets
    local presetListPanel = vgui.Create( "DListView", parent )
    presetListPanel:Dock( FILL )
    presetListPanel:SetMultiSelect( false )
    presetListPanel:AddColumn( "Name" )


    for k, v in pairs( presetList ) do
        presetListPanel:AddLine( v )
    end

    // Add the rightclick menu to the list
    presetListPanel.OnRowRightClick = function( self, index, row )

        // Add right click menu to the list, to load and to delete
        local rightClickMenu = DermaMenu()
        
        rightClickMenu:AddOption( "Load", function()
            // Send a request to the server to load the preset
            net.Start( "HALOARMORY.SHIPS.PRESETS.LoadPreset" )
            net.WriteEntity( ship_class )
            net.WriteString( row:GetValue(1) )
            net.SendToServer()

            net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
            net.WriteEntity( ship_class )
            net.SendToServer()

        end ):SetIcon( "icon16/accept.png" )

        rightClickMenu:AddSpacer()

        // Add a button to rename the select preset
        rightClickMenu:AddOption( "Rename", function()
            // Create a frame to hold the text entry and buttons
            local renameFrame = vgui.Create( "DFrame" )
            renameFrame:SetSize( 200, 80 )
            renameFrame:Center()
            renameFrame:SetTitle( "Rename Preset" )
            renameFrame:MakePopup()

            // Create a text entry to enter the new name of the preset
            local renameEntry = vgui.Create( "DTextEntry", renameFrame )
            renameEntry:SetPlaceholderText( "New Name" )

            // Create a button to confirm the rename
            local renameButton = vgui.Create( "DButton", renameFrame )
            renameButton:SetText( "Rename" )


            // When the rename button is clicked, send a request to the server to rename the preset
            renameButton.DoClick = function()
                net.Start( "HALOARMORY.SHIPS.PRESETS.RenamePreset" )
                net.WriteEntity( ship_class )
                net.WriteString( row:GetValue(1) )
                net.WriteString( renameEntry:GetValue() )
                net.SendToServer()

                renameFrame:Close()

                // Update the preset list
                net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
                net.WriteEntity( ship_class )
                net.SendToServer()
            end

            // Add the text entry and buttons to the frame
            renameEntry:Dock( TOP )
            renameButton:Dock( BOTTOM )

        end ):SetIcon( "icon16/pencil.png" )

        rightClickMenu:AddSpacer()

        rightClickMenu:AddOption( "Delete", function()
            // Send a request to the server to delete the preset
            net.Start( "HALOARMORY.SHIPS.PRESETS.DeletePreset" )
            net.WriteEntity( ship_class )
            net.WriteString( row:GetValue(1) )
            net.SendToServer()

            // Update the preset list
            net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
            net.WriteEntity( ship_class )
            net.SendToServer()

        end ):SetIcon( "icon16/cross.png" )

        rightClickMenu:Open()
    end

    // Add a button to load the selected preset
    local loadButton = vgui.Create( "DButton", parent )
    loadButton:SetText( "Load" )
    loadButton:Dock( BOTTOM )

    // When the button is clicked, send a request to the server to load the preset
    loadButton.DoClick = function()
        local selectedLine = presetListPanel:GetSelectedLine()

        if selectedLine then
            local selectedPreset = presetListPanel:GetLine( selectedLine ):GetValue(1)

            net.Start( "HALOARMORY.SHIPS.PRESETS.LoadPreset" )
            net.WriteEntity( ship_class )
            net.WriteString( selectedPreset )
            net.SendToServer()

            net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
            net.WriteEntity( ship_class )
            net.SendToServer()
        end
    end

end


local function TAB_SavePreset( ship_class, parent, presetList )

    // Create a panel
    local panel = vgui.Create( "DPanel", parent )
    panel:Dock( TOP )


    // Create a text entry to enter the name of the preset
    local presetNameEntry = vgui.Create( "DTextEntry", panel )
    presetNameEntry:Dock( LEFT )
    presetNameEntry:SetPlaceholderText( "Preset Name" )

    presetNameEntry:SetWide( ScrWi * 0.80 )

    // Create a DropDown Combo box to select a preset to overwrite
    local presetOverwriteCombo = vgui.Create( "DComboBox", panel )
    presetOverwriteCombo:Dock( RIGHT )
    presetOverwriteCombo:SetValue( "Select" )

    presetOverwriteCombo:SetWide( ScrWi * 0.20 )

    for k, v in pairs( presetList ) do
        presetOverwriteCombo:AddChoice( v )
    end

    // When a preset is selected, set the text entry to the name of the preset
    // And set the combo box back to the default value
    presetOverwriteCombo.OnSelect = function( self, index, value )
        presetNameEntry:SetValue( value )
        presetOverwriteCombo:SetValue( "Select" )
    end


    // Create a button to save the preset
    local saveButton = vgui.Create( "DButton", parent )
    saveButton:SetText( "Save" )
    saveButton:Dock( BOTTOM )

    // When the button is clicked, send a request to the server to save the preset
    saveButton.DoClick = function()
        net.Start( "HALOARMORY.SHIPS.PRESETS.SavePreset" )
        net.WriteEntity( ship_class )
        net.WriteString( presetNameEntry:GetValue() )
        net.SendToServer()

        // Update the preset list
        net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
        net.WriteEntity( ship_class )
        net.SendToServer()
    end

end

local function TAB_Settings( ship_class, parent, presetList, autoLoadPreset )

    -- // Create a button to toggle the Debug HUD
    -- local DebugHUDButton = vgui.Create( "DButton", parent )
    -- DebugHUDButton:SetText( "Toggle Debug HUD" )
    -- DebugHUDButton:Dock( TOP )

    -- // On click, run this console command HALOARMORY.ToggleShipDebug
    -- DebugHUDButton.DoClick = function()
    --     RunConsoleCommand( "HALOARMORY.ToggleShipDebug" )
    -- end

    // Create a button to toggle the Debug HUD
    local WipeShip = vgui.Create( "DButton", parent )
    WipeShip:SetText( "Clear Ship" )
    WipeShip:Dock( TOP )

    // On click, run this console command HALOARMORY.ToggleShipDebug
    WipeShip.DoClick = function()
        net.Start( "HALOARMORY.SHIPS.PRESETS.WipeShip" )
        net.WriteEntity( ship_class )
        net.SendToServer()
    end

    // Create a checkbox to enable/disable the preset system
    local AutoLoadPresetLabel = vgui.Create( "DLabel", parent )
    AutoLoadPresetLabel:Dock( TOP )
    AutoLoadPresetLabel:SetText( "Auto-Load Preset" )
    AutoLoadPresetLabel:SetColor( Color( 0, 0, 0 ) )

    // Create a checkbox to enable/disable the preset system
    local AutoLoadPreset = vgui.Create( "DComboBox", parent )
    AutoLoadPreset:Dock( TOP )
    AutoLoadPreset:SetSortItems( false )

    if autoLoadPreset == "false" then autoLoadPreset = "None" end
    AutoLoadPreset:SetValue( autoLoadPreset )

    AutoLoadPreset:AddChoice( "None" )
    for k, v in pairs( presetList ) do
        AutoLoadPreset:AddChoice( v )
    end

    // When the combo box is changed, send a request to the server to change the preset
    AutoLoadPreset.OnSelect = function( self, index, value )
        if value == "None" then value = "false" end

        net.Start( "HALOARMORY.SHIPS.PRESETS.SetAutoLoadPreset" )
        net.WriteEntity( ship_class )
        net.WriteString( value )
        net.SendToServer()
    end

    // Create a label under the combo box
    local AutoLoadPresetLabelNotice = vgui.Create( "RichText", parent )
    AutoLoadPresetLabelNotice:Dock( TOP )
    AutoLoadPresetLabelNotice:SetTall( 200 )
    AutoLoadPresetLabelNotice:InsertColorChange( 25, 25, 25, 255 )
    AutoLoadPresetLabelNotice:AppendText( [[
This will automatically load the selected preset when you
spawn it in.

NOTICE: This feature is still WIP. And a such, you can only
set ONE GLOBAL preset for both ships.

If you only wish to load the preset for one ship, simply
ensure only that ship has the correct preset name.

To load presets on multiple ships, they need to have the same
name. Presets are still saved per-ship.

So you can have a different preset on the Frigate and on the
Lich, but still using the same name.]] )

end




function HALOARMORY.Ships.Presets.OpenGUI( ship_class )

    // Create a new VGUI element
    HALOARMORY.Ships.Presets.GUI.Menu = vgui.Create( "DFrame" )
    HALOARMORY.Ships.Presets.GUI.Menu:SetSize( 250, 250 ) 
    HALOARMORY.Ships.Presets.GUI.Menu:Center()
    HALOARMORY.Ships.Presets.GUI.Menu:SetTitle( "Presets" ) 
    HALOARMORY.Ships.Presets.GUI.Menu:SetVisible( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:SetDraggable( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:ShowCloseButton( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:MakePopup()

    // Create a label and dock it to the bottom.
    local label = vgui.Create( "DLabel", HALOARMORY.Ships.Presets.GUI.Menu )
    label:SetText( "Loading Presets..." )
    label:SetFont( "DermaLarge" )
    label:Dock( BOTTOM )
    label:SetContentAlignment( 5 )
    label:SetHeight( 30 )



    local loader_icon = vgui.Create("DSprite", HALOARMORY.Ships.Presets.GUI.Menu)
    loader_icon:SetMaterial(Material("gui/gmod_logo"))
    --loader_icon:Dock( FILL )
    loader_icon:SizeToContents()
    loader_icon:Center()
    loader_icon:SetSize( 64, 64 )

    loader_icon:SetPos( 100 + 16, 100 + 16)

    // Make the icon spin
    local spin = 0
    loader_icon.Think = function()
        spin = spin + 1
        loader_icon:SetRotation( spin )
    end

    // Send a request to the server to get the presets
    net.Start( "HALOARMORY.SHIPS.PRESETS.PresetsList" )
    net.WriteEntity( ship_class )
    net.SendToServer()


end

local function OpenMainGUI( ship_class, presetList, autoLoadPreset )

    if HALOARMORY.Ships.Presets.GUI.Menu then HALOARMORY.Ships.Presets.GUI.Menu:Remove() end

    // Create a new VGUI element
    HALOARMORY.Ships.Presets.GUI.Menu = vgui.Create( "DFrame" )
    HALOARMORY.Ships.Presets.GUI.Menu:SetSize( ScrWi, ScrHe ) 
    HALOARMORY.Ships.Presets.GUI.Menu:Center()
    HALOARMORY.Ships.Presets.GUI.Menu:SetTitle( "Presets" ) 
    HALOARMORY.Ships.Presets.GUI.Menu:SetVisible( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:SetDraggable( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:ShowCloseButton( true ) 
    HALOARMORY.Ships.Presets.GUI.Menu:MakePopup()

    // Create a panel to hold the label and text entry
    local topPanel = vgui.Create( "DPanel", HALOARMORY.Ships.Presets.GUI.Menu )
    topPanel:Dock( TOP )
    topPanel:SetHeight( 25 )
    topPanel.Paint = function( self, w, h )
        --  draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255 ) )
    end


    // Create a label and dock it to the top.
    local label = vgui.Create( "DLabel", topPanel )
    label:SetText( "Selected ship:" )
    --label:SetFont( "DermaLarge" )
    label:SetWide( 70 )
    label:Dock( LEFT )
    --label:SetContentAlignment( 5 )

    // Add a non-editable text label next to the label
    local text = vgui.Create( "DTextEntry", topPanel )
    text:SetText( tostring(ship_class) )
    text:SetDisabled( true )
    text:Dock( FILL )

    // Create a tabbed panel and dock it to the whole window.
    // Add 3 tabs to the panel, "Load", "Save" and "Settings".

    local tabs = vgui.Create( "DPropertySheet", HALOARMORY.Ships.Presets.GUI.Menu )
    tabs:Dock( FILL )

    local load_tab = vgui.Create( "DPanel", tabs )
    load_tab:Dock( FILL )

    local save_tab = vgui.Create( "DPanel", tabs )
    save_tab:Dock( FILL )


    local settings = vgui.Create( "DPanel", tabs )
    settings:Dock( FILL )


    tabs:AddSheet( "Presets", load_tab, "icon16/folder.png" )
    tabs:AddSheet( "Save", save_tab, "icon16/disk.png" )
    tabs:AddSheet( "Settings", settings, "icon16/wrench.png" )

    TAB_LoadPreset( ship_class, load_tab, presetList )
    TAB_SavePreset( ship_class, save_tab, presetList )
    TAB_Settings( ship_class, settings, presetList, autoLoadPreset )

end


net.Receive( "HALOARMORY.SHIPS.PRESETS.PresetsList", function( len, ply )

    --print("Received Presets List")
    local ship_class = net.ReadEntity()
    local presetList = net.ReadTable()
    local autoLoadPreset = net.ReadString()

    OpenMainGUI( ship_class, presetList, autoLoadPreset )

end )





properties.Add( "presets_menu", {
    MenuLabel = "Presets...", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/disk.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( !ent.HALOARMORY_Ships_Presets ) then return false end
        if ( ent.deployed ~= nil and ent.deployed ~= true ) then return false end
        if ( not ply:IsAdmin() ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        // Open the Presets GUI
        HALOARMORY.Ships.Presets.OpenGUI( ent )

    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        // Nothing
    end 
} )

--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]

--if HALOARMORY.Ships.Presets.GUI.Menu then HALOARMORY.Ships.Presets.GUI.Menu:Remove() end

--HALOARMORY.Ships.Presets.OpenGUI( "halo_frigate" )