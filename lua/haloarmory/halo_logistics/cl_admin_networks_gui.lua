HALOARMORY.MsgC("Client HALO SUPPLY Manage GUI Loading.")


HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Manager_GUI = HALOARMORY.Logistics.Manager_GUI or {}

local GUI = HALOARMORY.Logistics.Manager_GUI

// Template network for new networks
local BaseTemplateNetwork = {
    ["Name"] = "new_network",
    ["MapOnly"] = false,
    ["MaxSupplies"] = 1000,
    ["Supplies"] = 0,
}

local function NewTemplateNetwork()
    return table.Copy( BaseTemplateNetwork )
end

local NetworkBeingEdited = NewTemplateNetwork()
local IsNewNetwork = true
local networks = {}

// ============================================
// HELPER FUNCTIONS
// ============================================

local function sanitize_network_name( name )
    return tostring( name or "" ):lower():gsub( "[^%w_]", "_" )
end

local function normalize_network( network_table )
    network_table = network_table or {}

    network_table.Name = sanitize_network_name( network_table.Name or "" )
    network_table.MapOnly = tobool( network_table.MapOnly ) or false
    network_table.MaxSupplies = tonumber( network_table.MaxSupplies ) or 1000
    network_table.Supplies = tonumber( network_table.Supplies ) or 0

    // Clamp supplies to max
    network_table.Supplies = math.Clamp( network_table.Supplies, 0, network_table.MaxSupplies )

    return network_table
end

local function serialize_network( network_table )
    return util.TableToJSON( normalize_network( table.Copy( network_table or {} ) ), true ) or ""
end

local function sorted_network_keys( network_list )
    local keys = {}

    for network_key in pairs( network_list or {} ) do
        table.insert( keys, network_key )
    end

    table.sort( keys, function( a, b )
        return tostring( a ) < tostring( b )
    end )

    return keys
end

local function create_editor_row( parent, label_text, row_height )
    local row = vgui.Create( "DPanel", parent )
    row:Dock( TOP )
    row:SetTall( row_height or 28 )
    row:DockMargin( 8, 0, 8, 6 )
    row.Paint = nil

    local label = vgui.Create( "DLabel", row )
    label:Dock( LEFT )
    label:SetWide( 120 )
    label:SetText( label_text )

    return row
end

// ============================================
// GUI FUNCTIONS
// ============================================

function GUI.GetNetworkBeingEdited()
    return NetworkBeingEdited
end

function GUI.SetNetworkBeingEdited( network_table )
    NetworkBeingEdited = network_table
end

function GUI.GetIsNewNetwork()
    return IsNewNetwork
end

function GUI.SetIsNewNetwork( is_new )
    IsNewNetwork = is_new == true
end

function GUI.OpenNetworkEditor( network_table )
    local normalized = normalize_network( table.Copy( network_table or NetworkBeingEdited or NewTemplateNetwork() ) )
    local is_new = network_table == nil and IsNewNetwork or not istable( network_table )

    normalized.Name = sanitize_network_name( normalized.Name )
    GUI.SetNetworkBeingEdited( normalized )

    GUI.PendingEditNetwork = table.Copy( normalized )
    GUI.PendingSelection = normalized.Name
    GUI.PendingStartEdit = true
    GUI.PendingNewNetwork = is_new

    if IsValid( GUI.MainFrame ) and isfunction( GUI.MainFrame.LoadNetworkIntoEditor ) then
        GUI.MainFrame:LoadNetworkIntoEditor( normalized, {
            is_new = is_new,
            source_name = normalized.old_name or normalized.Name,
            force = true,
        } )
        GUI.MainFrame:Show()
        GUI.MainFrame:MakePopup()
        return
    end

    GUI.OpenGUI( GUI.NetworkList )
end

function GUI.OpenGUI( network_list )
    local has_access = true
    if CAMI then
        has_access = CAMI.PlayerHasAccess( LocalPlayer(), "HALOARMORY.Network Editor" )
    elseif IsValid( LocalPlayer() ) then
        has_access = LocalPlayer():IsSuperAdmin()
    end

    if not has_access then
        chat.AddText( Color( 255, 0, 0 ), "You do not have access to this command!" )
        return "No Access!"
    end

    if IsValid( GUI.MainFrame ) then
        GUI.MainFrame:Remove()
        GUI.MainFrame = nil
    end

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 960, 600 )
    frame:Center()
    frame:SetTitle( "HALOARMORY.NETWORKS.EDITOR" )
    frame:SetSizable( true )
    frame:SetMinWidth( 800 )
    frame:SetMinHeight( 500 )
    frame:MakePopup()

    GUI.MainFrame = frame
    GUI.MainFrameEditor = frame

    // Create the network list view early so it can receive updates
    // This will be populated by refresh_list_view and updated via net messages
    
    frame.OnClose = function()
        GUI.MainFrame = nil
        GUI.MainFrameEditor = nil

        net.Start( "HALOARMORY.Logistics.NETWORKS.MENUCLOSED" )
        net.SendToServer()
    end

    // Use cached data if available, otherwise request from server
    local had_cached_data = istable( GUI.NetworkList ) and table.Count( GUI.NetworkList ) > 0
    
    if not istable( network_list ) and had_cached_data then
        network_list = GUI.NetworkList
    end

    if not istable( network_list ) then
        // No cached data - request from server and build UI with empty state
        network_list = {}
        net.Start( "HALOARMORY.Logistics.NETWORKS.GET" )
        net.SendToServer()
    end

    GUI.NetworkList = network_list
    networks = table.Copy( network_list )

    // Request full network details in the background
    net.Start( "HALOARMORY.Logistics.NETWORKS.GET_DETAILS" )
    net.SendToServer()

    local selected_name = GUI.PendingSelection
    local active_network_key = nil
    local editor_baseline = nil
    local network_list_view
    local network_rows = {}
    local right_panel
    local save_button
    local delete_button
    local dirty_status_label
    local validation_label
    local refresh_list_view
    local load_network_into_editor

    local function current_network()
        return GUI.GetNetworkBeingEdited()
    end

    local function editor_dirty()
        local network_table = current_network()
        if not network_table or not editor_baseline then return false end

        return serialize_network( network_table ) ~= editor_baseline
    end

    local function validate_network()
        local network_table = current_network() or {}
        local name = sanitize_network_name( network_table.Name )

        if name == "" then return false, "Network name is required." end
        if name == "new_network" and GUI.GetIsNewNetwork() then
            // Allow new_network as placeholder for new networks
        elseif not GUI.GetIsNewNetwork() and active_network_key and name ~= active_network_key then
            // Renaming - check if new name exists
            if networks[name] and name ~= active_network_key then
                return false, "A network with that name already exists."
            end
        end

        if network_table.MaxSupplies < 0 then return false, "Max supplies cannot be negative." end
        if network_table.Supplies < 0 then return false, "Supplies cannot be negative." end
        if network_table.Supplies > network_table.MaxSupplies then return false, "Supplies cannot exceed max supplies." end

        return true, "Network configuration is valid."
    end

    local function update_status()
        local network_table = current_network()
        if not IsValid( dirty_status_label ) or not IsValid( validation_label ) or not network_table then return end

        dirty_status_label:SetText( editor_dirty() and "Unsaved changes" or "Up to date" )

        local can_save, validation_text = validate_network()
        validation_label:SetText( validation_text )
        validation_label:SetTextColor( can_save and Color( 80, 170, 80 ) or Color( 210, 120, 80 ) )

        if IsValid( save_button ) then
            save_button:SetEnabled( can_save )
        end

        if IsValid( delete_button ) then
            delete_button:SetEnabled( not GUI.GetIsNewNetwork() and active_network_key ~= nil )
        end
    end

    local function confirm_discard( on_accept )
        if not isfunction( on_accept ) then return end

        if not editor_dirty() then
            on_accept()
            return
        end

        Derma_Query(
            "Discard the current unsaved network changes?",
            "Unsaved Changes",
            "Discard",
            on_accept,
            "Keep Editing"
        )
    end

    local function select_network_row( network_key )
        if not IsValid( network_list_view ) then return end

        local line = network_rows[network_key]
        if not IsValid( line ) then return end

        network_list_view:ClearSelection()
        line:SetSelected( true )
        network_list_view:OnRowSelected( line:GetID(), line )
    end

    local function request_refresh( selection_key, start_edit )
        GUI.PendingSelection = selection_key
        GUI.PendingStartEdit = start_edit == true
        GUI.PendingEditNetwork = nil
        GUI.PendingNewNetwork = false

        net.Start( "HALOARMORY.Logistics.NETWORKS.GET" )
        net.SendToServer()
    end

    local function remove_network( network_key )
        if not isstring( network_key ) or network_key == "" then return end

        Derma_Query(
            "Delete network '" .. network_key .. "'?\nThis will also remove all device associations.",
            "Delete Network",
            "Delete",
            function()
                GUI.PendingSelection = nil
                GUI.PendingStartEdit = false
                GUI.PendingEditNetwork = nil
                GUI.PendingNewNetwork = false

                net.Start( "HALOARMORY.Logistics.NETWORKS.REMOVE" )
                net.WriteString( network_key )
                net.SendToServer()
            end,
            "Cancel"
        )
    end

    local function save_network()
        local network_table = normalize_network( table.Copy( current_network() ) )
        network_table.Name = sanitize_network_name( network_table.Name )
        GUI.SetNetworkBeingEdited( network_table )

        local save_name = network_table.Name
        local overwrite_other = networks[save_name] ~= nil and active_network_key ~= save_name

        local function do_save()
            GUI.PendingSelection = save_name
            GUI.PendingStartEdit = true
            GUI.PendingEditNetwork = nil
            GUI.PendingNewNetwork = false

            net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT.SAVE" )
                local network_to_save = {
                    old_network = { Name = active_network_key },
                    new_network = network_table
                }
                net.WriteTable( network_to_save )
            net.SendToServer()
        end

        if overwrite_other then
            Derma_Query(
                "A network with that name already exists. Overwrite it?",
                "Overwrite Network",
                "Overwrite",
                do_save,
                "Cancel"
            )
            return
        end

        do_save()
    end

    local function rebuild_editor()
        right_panel:Clear()

        local network_table = current_network()
        if not network_table then return end

        local scroll = vgui.Create( "DScrollPanel", right_panel )
        scroll:Dock( FILL )

        // Header
        local header = vgui.Create( "DLabel", scroll )
        header:Dock( TOP )
        header:DockMargin( 8, 8, 8, 4 )
        header:SetFont( "DermaLarge" )
        header:SetTall( 28 )
        header:SetText( GUI.GetIsNewNetwork() and "New Network" or tostring( network_table.Name ) )

        dirty_status_label = vgui.Create( "DLabel", scroll )
        dirty_status_label:Dock( TOP )
        dirty_status_label:DockMargin( 8, 0, 8, 2 )

        validation_label = vgui.Create( "DLabel", scroll )
        validation_label:Dock( TOP )
        validation_label:DockMargin( 8, 0, 8, 8 )

        // Network Name
        local name_row = create_editor_row( scroll, "Network Name:" )
        local name_entry = vgui.Create( "DTextEntry", name_row )
        name_entry:Dock( FILL )
        name_entry:SetValue( tostring( network_table.Name or "" ) )
        name_entry:SetUpdateOnType( true )

        // Map Only Toggle
        local maponly_row = create_editor_row( scroll, "Map Restricted:" )
        local maponly_panel = vgui.Create( "DPanel", maponly_row )
        maponly_panel:Dock( FILL )
        maponly_panel.Paint = nil

        local maponly_checkbox = vgui.Create( "DCheckBox", maponly_panel )
        maponly_checkbox:Dock( LEFT )
        maponly_checkbox:SetSize( 20, 20 )
        maponly_checkbox:SetValue( network_table.MapOnly or false )

        local maponly_label = vgui.Create( "DLabel", maponly_panel )
        maponly_label:Dock( FILL )
        maponly_label:DockMargin( 8, 0, 0, 0 )
        maponly_label:SetText( "Only enable for " .. game.GetMap() )
        maponly_label:SetDark( true )

        // Max Supplies
        local maxsupplies_row = create_editor_row( scroll, "Max Supplies:" )
        local maxsupplies_entry = vgui.Create( "DNumberWang", maxsupplies_row )
        maxsupplies_entry:Dock( FILL )
        maxsupplies_entry:SetMin( 0 )
        maxsupplies_entry:SetMax( (1.7976931348623157 * 10^308) - 2 )
        maxsupplies_entry:SetDecimals( 0 )
        maxsupplies_entry:SetValue( tonumber( network_table.MaxSupplies ) or 1000 )

        local maxsupplies_display = vgui.Create( "DLabel", scroll )
        maxsupplies_display:Dock( TOP )
        maxsupplies_display:DockMargin( 8, 0, 8, 6 )
        maxsupplies_display:SetText( "Formatted: " .. HALOARMORY.INTERFACE.PrettyFormatNumber( maxsupplies_entry:GetValue() ) )
        maxsupplies_display:SetDark( true )

        // Current Supplies
        local supplies_row = create_editor_row( scroll, "Current Supplies:" )
        local supplies_entry = vgui.Create( "DNumSlider", supplies_row )
        supplies_entry:Dock( FILL )
        supplies_entry:SetText( "" )
        supplies_entry:SetMin( 0 )
        supplies_entry:SetMax( maxsupplies_entry:GetValue() )
        supplies_entry:SetDecimals( 0 )
        supplies_entry:SetValue( tonumber( network_table.Supplies ) or 0 )

        // Device Count (Read-only display)
        local device_row = create_editor_row( scroll, "Connected Devices:" )
        local device_label = vgui.Create( "DLabel", device_row )
        device_label:Dock( FILL )
        device_label:SetText( tostring( network_table.DeviceCount or 0 ) .. " devices connected" )
        device_label:SetDark( true )

        // Actions Section Header
        local action_header = vgui.Create( "DLabel", scroll )
        action_header:Dock( TOP )
        action_header:DockMargin( 8, 12, 8, 4 )
        action_header:SetFont( "DermaDefaultBold" )
        action_header:SetText( "Network Actions" )

        // Action buttons in scroll panel
        local action_buttons = vgui.Create( "DPanel", scroll )
        action_buttons:Dock( TOP )
        action_buttons:SetTall( 32 )
        action_buttons:DockMargin( 8, 0, 8, 8 )
        action_buttons.Paint = nil

        local refill_button = vgui.Create( "DButton", action_buttons )
        refill_button:Dock( LEFT )
        refill_button:SetWide( 170 )
        refill_button:SetText( "Refill to Max" )
        refill_button:SetIcon( "icon16/arrow_up.png" )

        local clear_button = vgui.Create( "DButton", action_buttons )
        clear_button:Dock( LEFT )
        clear_button:DockMargin( 8, 0, 0, 0 )
        clear_button:SetWide( 170 )
        clear_button:SetText( "Clear Supplies" )
        clear_button:SetIcon( "icon16/arrow_down.png" )

        // Bottom Action Buttons - two rows to prevent overlap
        local action_row1 = vgui.Create( "DPanel", right_panel )
        action_row1:Dock( BOTTOM )
        action_row1:SetTall( 36 )
        action_row1:DockMargin( 8, 4, 8, 8 )
        action_row1.Paint = nil

        local action_row2 = vgui.Create( "DPanel", right_panel )
        action_row2:Dock( BOTTOM )
        action_row2:SetTall( 36 )
        action_row2:DockMargin( 8, 8, 8, 0 )
        action_row2.Paint = nil

        save_button = vgui.Create( "DButton", action_row2 )
        save_button:Dock( LEFT )
        save_button:SetWide( 150 )
        save_button:SetText( "Save Network" )
        save_button:SetIcon( "icon16/disk.png" )

        local revert_button = vgui.Create( "DButton", action_row2 )
        revert_button:Dock( LEFT )
        revert_button:DockMargin( 8, 0, 0, 0 )
        revert_button:SetWide( 150 )
        revert_button:SetText( "Revert Changes" )
        revert_button:SetIcon( "icon16/arrow_undo.png" )

        delete_button = vgui.Create( "DButton", action_row1 )
        delete_button:Dock( LEFT )
        delete_button:SetWide( 150 )
        delete_button:SetText( "Delete Network" )
        delete_button:SetIcon( "icon16/delete.png" )

        // Event Handlers
        local function refresh_header()
            header:SetText( GUI.GetIsNewNetwork() and "New Network" or tostring( network_table.Name ) )
            update_status()
        end

        name_entry.OnValueChange = function( self, value )
            local new_name = sanitize_network_name( value )

            // Check for duplicate names
            if networks[new_name] and new_name ~= active_network_key then
                name_entry:SetTextColor( Color( 255, 0, 0 ) )
                save_button:SetDisabled( true )
            else
                name_entry:SetTextColor( Color( 0, 0, 0 ) )
                save_button:SetDisabled( false )
            end

            network_table.Name = new_name
            refresh_header()
        end

        maponly_checkbox.OnChange = function( self, value )
            network_table.MapOnly = value
            update_status()
        end

        maxsupplies_entry.OnValueChanged = function( self, value )
            value = math.Round( value )
            value = math.Clamp( value, 0, self:GetMax() )

            supplies_entry:SetMax( value )
            supplies_entry:SetValue( math.Clamp( supplies_entry:GetValue(), 0, value ) )

            maxsupplies_display:SetText( "Formatted: " .. HALOARMORY.INTERFACE.PrettyFormatNumber( value ) )

            network_table.MaxSupplies = value
            update_status()
        end

        supplies_entry.OnValueChanged = function( self, value )
            value = math.Round( value )
            if value > maxsupplies_entry:GetValue() then
                self:SetValue( maxsupplies_entry:GetValue() )
            end
            network_table.Supplies = value
            update_status()
        end

        refill_button.DoClick = function()
            supplies_entry:SetValue( maxsupplies_entry:GetValue() )
        end

        clear_button.DoClick = function()
            supplies_entry:SetValue( 0 )
        end

        save_button.DoClick = function()
            local can_save, validation_text = validate_network()
            if not can_save then
                notification.AddLegacy( validation_text, NOTIFY_ERROR, 4 )
                return
            end
            save_network()
        end

        revert_button.DoClick = function()
            confirm_discard( function()
                if GUI.GetIsNewNetwork() then
                    load_network_into_editor( NewTemplateNetwork(), {
                        is_new = true,
                        force = true,
                    } )
                    return
                end

                // Request the network data from server for reverting
                if active_network_key then
                    GUI.PendingRevert = true
                    net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT" )
                        net.WriteString( active_network_key )
                    net.SendToServer()
                end
            end )
        end

        delete_button.DoClick = function()
            if active_network_key then
                remove_network( active_network_key )
            end
        end

        update_status()
    end

    load_network_into_editor = function( network_table, options )
        options = options or {}

        if not options.force then
            confirm_discard( function()
                load_network_into_editor( network_table, {
                    is_new = options.is_new,
                    source_name = options.source_name,
                    force = true,
                } )
            end )
            return
        end

        // Handle case where network_table might be a string (network name) instead of table
        local network_data = network_table
        if istable( network_table ) then
            network_data = table.Copy( network_table )
        elseif isstring( network_table ) and networks[network_table] then
            network_data = table.Copy( networks[network_table] )
        else
            network_data = NewTemplateNetwork()
        end

        local normalized = normalize_network( network_data )
        normalized.Name = sanitize_network_name( normalized.Name )

        GUI.SetNetworkBeingEdited( normalized )
        GUI.SetIsNewNetwork( options.is_new == true )

        active_network_key = not GUI.GetIsNewNetwork() and sanitize_network_name( options.source_name or normalized.old_name or normalized.Name ) or nil
        if GUI.GetIsNewNetwork() then
            normalized.old_name = nil
            selected_name = nil
        else
            normalized.old_name = active_network_key
            selected_name = active_network_key
        end

        editor_baseline = serialize_network( normalized )
        rebuild_editor()
        select_network_row( selected_name )
    end

    refresh_list_view = function()
        network_rows = {}
        network_list_view:Clear()

        for _, network_key in ipairs( sorted_network_keys( networks ) ) do
            // networks table values might be strings (names only) or tables (full data)
            local network_data = networks[network_key]
            local is_full_data = istable( network_data )
            
            local line = network_list_view:AddLine(
                network_key,
                is_full_data and tostring( math.Round( tonumber( network_data.Supplies ) or 0 ) ) or "-",
                is_full_data and tostring( math.Round( tonumber( network_data.MaxSupplies ) or 1000 ) ) or "-",
                is_full_data and ( network_data.MapOnly and game.GetMap() or "Any Map" ) or "-",
                is_full_data and tostring( network_data.DeviceCount or 0 ) or "-"
            )

            line.NetworkName = network_key
            network_rows[network_key] = line
        end

        // Store in GUI for access from net.Receive handlers
        GUI.NetworkRows = network_rows

        if selected_name then
            select_network_row( selected_name )
        end
    end

    // ============================================
    // BUILD MAIN FRAME UI
    // ============================================

    // Toolbar
    local toolbar = vgui.Create( "DPanel", frame )
    toolbar:Dock( TOP )
    toolbar:SetTall( 36 )
    toolbar:DockMargin( 8, 4, 8, 8 )
    toolbar.Paint = nil

    local add_network_button = vgui.Create( "DButton", toolbar )
    add_network_button:Dock( LEFT )
    add_network_button:SetWide( 130 )
    add_network_button:SetText( "Add Network" )
    add_network_button:SetIcon( "icon16/add.png" )

    local duplicate_button = vgui.Create( "DButton", toolbar )
    duplicate_button:Dock( LEFT )
    duplicate_button:DockMargin( 8, 0, 0, 0 )
    duplicate_button:SetWide( 150 )
    duplicate_button:SetText( "Duplicate Selected" )
    duplicate_button:SetIcon( "icon16/page_copy.png" )

    local refresh_button = vgui.Create( "DButton", toolbar )
    refresh_button:Dock( LEFT )
    refresh_button:DockMargin( 8, 0, 0, 0 )
    refresh_button:SetWide( 120 )
    refresh_button:SetText( "Refresh List" )
    refresh_button:SetIcon( "icon16/arrow_refresh.png" )

    local hint_label = vgui.Create( "DLabel", toolbar )
    hint_label:Dock( FILL )
    hint_label:DockMargin( 12, 0, 12, 0 )
    hint_label:SetText( "Double-click a row to load it into the editor panel." )
    hint_label:SetContentAlignment( 4 )

    // Main Splitter
    local splitter = vgui.Create( "DHorizontalDivider", frame )
    splitter:Dock( FILL )
    splitter:SetLeftWidth( 480 )
    splitter:SetDividerWidth( 4 )

    local left_panel = vgui.Create( "DPanel", frame )
    left_panel.Paint = nil

    right_panel = vgui.Create( "DPanel", frame )
    right_panel.Paint = nil

    splitter:SetLeft( left_panel )
    splitter:SetRight( right_panel )

    // Table Header
    local table_header = vgui.Create( "DLabel", left_panel )
    table_header:Dock( TOP )
    table_header:DockMargin( 8, 8, 8, 4 )
    table_header:SetFont( "DermaDefaultBold" )
    table_header:SetText( "Network Table" )

    // Network List View
    network_list_view = vgui.Create( "DListView", left_panel )
    network_list_view:Dock( FILL )
    network_list_view:DockMargin( 8, 0, 8, 8 )
    network_list_view:SetMultiSelect( false )
    network_list_view:AddColumn( "Name" )
    network_list_view:AddColumn( "Supplies" )
    network_list_view:AddColumn( "Max Supplies" )
    network_list_view:AddColumn( "Map" )
    network_list_view:AddColumn( "Devices" )

    // Store reference for net.Receive
    frame.NetworkListView = network_list_view

    // Right-click context menu
    network_list_view.OnRowRightClick = function( panel, lineID, line )
        local NetworkMenu = DermaMenu()

        local editNetwork = NetworkMenu:AddOption( "Edit Network", function()
            if not IsValid( line ) then return end
            local network_key = line.NetworkName
            if not network_key then return end

            // Request the full network data from the server
            net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT" )
                net.WriteString( network_key )
            net.SendToServer()
        end )
        editNetwork:SetIcon( "icon16/pencil.png" )

        NetworkMenu:AddSpacer()

        local deleteNetwork = NetworkMenu:AddOption( "Delete Network", function()
            if not IsValid( line ) then return end
            local network_key = line.NetworkName
            remove_network( network_key )
        end )
        deleteNetwork:SetIcon( "icon16/delete.png" )

        NetworkMenu:Open()
    end

    network_list_view.OnRowSelected = function( _, _, line )
        if not IsValid( line ) then return end
        selected_name = line.NetworkName
    end

    network_list_view.DoDoubleClick = function( _, _, line )
        if not IsValid( line ) then return end

        local network_key = line.NetworkName
        if not network_key then return end

        // Request the full network data from the server
        net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT" )
            net.WriteString( network_key )
        net.SendToServer()
    end

    add_network_button.DoClick = function()
        confirm_discard( function()
            load_network_into_editor( NewTemplateNetwork(), {
                is_new = true,
                force = true,
            } )
        end )
    end

    duplicate_button.DoClick = function()
        if not selected_name or not networks[selected_name] then
            notification.AddLegacy( "Select a network to duplicate first.", NOTIFY_ERROR, 3 )
            return
        end

        confirm_discard( function()
            // Request the network data from server, then create a copy
            // Store a pending action for when we receive the data
            GUI.PendingDuplicate = selected_name
            GUI.PendingStartEdit = true
            
            net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT" )
                net.WriteString( selected_name )
            net.SendToServer()
        end )
    end

    refresh_button.DoClick = function()
        confirm_discard( function()
            request_refresh( selected_name, false )
        end )
    end

    frame.LoadNetworkIntoEditor = function( _, network_table, options )
        load_network_into_editor( network_table, options )
    end

    refresh_list_view()

    // Handle pending operations
    local pending_network = GUI.PendingEditNetwork
    local pending_selection = GUI.PendingSelection
    local pending_start_edit = GUI.PendingStartEdit == true
    local pending_new_network = GUI.PendingNewNetwork == true

    GUI.PendingEditNetwork = nil
    GUI.PendingSelection = nil
    GUI.PendingStartEdit = nil
    GUI.PendingNewNetwork = nil

    if istable( pending_network ) then
        load_network_into_editor( pending_network, {
            is_new = pending_new_network,
            source_name = pending_network.old_name or pending_network.Name,
            force = true,
        } )
    elseif pending_start_edit and pending_selection and networks[pending_selection] then
        load_network_into_editor( networks[pending_selection], {
            is_new = false,
            source_name = pending_selection,
            force = true,
        } )
    else
        if pending_selection and networks[pending_selection] then
            selected_name = pending_selection
            select_network_row( pending_selection )
        end

        local empty_title = vgui.Create( "DLabel", right_panel )
        empty_title:Dock( TOP )
        empty_title:DockMargin( 8, 16, 8, 0 )
        empty_title:SetFont( "DermaLarge" )
        empty_title:SetTall( 28 )
        empty_title:SetText( "Network Editor" )

        local empty_help = vgui.Create( "DLabel", right_panel )
        empty_help:Dock( TOP )
        empty_help:DockMargin( 8, 4, 8, 0 )
        empty_help:SetWrap( true )
        empty_help:SetAutoStretchVertical( true )
        empty_help:SetText( "Double-click a row to edit it here. Networks manage supply distribution across connected devices." )
    end
end

// ============================================
// NETWORK RECEIVE HANDLERS
// ============================================

net.Receive( "HALOARMORY.Logistics.NETWORKS.GET", function()
    networks = net.ReadTable()

    // If the main frame doesn't exist yet, open the GUI with the data
    if not IsValid( GUI.MainFrame ) then
        GUI.NetworkList = networks
        GUI.OpenGUI( networks )
        return
    end

    // Store the network list
    GUI.NetworkList = networks

    // Refresh the list with network names (details will come via GET_DETAILS)
    local network_list_view = GUI.MainFrame.NetworkListView
    if not network_list_view then return end

    network_list_view:Clear()
    GUI.NetworkRows = {}

    for _, network_key in ipairs( sorted_network_keys( networks ) ) do
        // networks table values might be strings (names only) or tables (full data)
        local network_data = networks[network_key]
        local is_full_data = istable( network_data )
        
        local line = network_list_view:AddLine(
            network_key,
            is_full_data and tostring( math.Round( tonumber( network_data.Supplies ) or 0 ) ) or "-",
            is_full_data and tostring( math.Round( tonumber( network_data.MaxSupplies ) or 1000 ) ) or "-",
            is_full_data and ( network_data.MapOnly and game.GetMap() or "Any Map" ) or "-",
            is_full_data and tostring( network_data.DeviceCount or 0 ) or "-"
        )

        line.NetworkName = network_key
        GUI.NetworkRows[network_key] = line
    end

    // Request full network details to populate the list
    net.Start( "HALOARMORY.Logistics.NETWORKS.GET_DETAILS" )
    net.SendToServer()
end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.ADD", function()
    local new_network_names = net.ReadTable()
    
    // If the main frame doesn't exist, just cache the data
    if not IsValid( GUI.MainFrame ) then
        GUI.NetworkList = new_network_names
        networks = new_network_names
        return
    end

    // Update the network names list (preserving any existing full data we have)
    for name, _ in pairs( new_network_names ) do
        if not networks[name] then
            networks[name] = name  // New network, add as string placeholder
        end
        // If networks[name] already exists as a table, keep it
    end
    
    // Remove networks that no longer exist
    for name, _ in pairs( networks ) do
        if not new_network_names[name] then
            networks[name] = nil
        end
    end

    GUI.NetworkList = networks

    // Refresh the list view
    local network_list_view = GUI.MainFrame.NetworkListView
    if not network_list_view then return end

    network_list_view:Clear()
    GUI.NetworkRows = {}

    for _, network_key in ipairs( sorted_network_keys( networks ) ) do
        local network_data = networks[network_key]
        local is_full_data = istable( network_data )
        
        local line = network_list_view:AddLine(
            network_key,
            is_full_data and tostring( math.Round( tonumber( network_data.Supplies ) or 0 ) ) or "-",
            is_full_data and tostring( math.Round( tonumber( network_data.MaxSupplies ) or 1000 ) ) or "-",
            is_full_data and ( network_data.MapOnly and game.GetMap() or "Any Map" ) or "-",
            is_full_data and tostring( network_data.DeviceCount or 0 ) or "-"
        )

        line.NetworkName = network_key
        GUI.NetworkRows[network_key] = line
    end
end )

// Handle incoming network details (updates the list progressively)
net.Receive( "HALOARMORY.Logistics.NETWORKS.GET_DETAILS", function()
    local network_name = net.ReadString()
    local network_data = net.ReadTable()

    if not network_name or not network_data then return end

    // Store the full network data
    networks[network_name] = network_data
    GUI.NetworkList = networks

    // Update the specific row in the list view
    local network_list_view = GUI.MainFrame and GUI.MainFrame.NetworkListView
    if not network_list_view then return end

    // Use the stored network rows reference
    local line = GUI.NetworkRows and GUI.NetworkRows[network_name]
    if IsValid( line ) then
        // Update the line's columns
        line:SetColumnText( 1, network_name )
        line:SetColumnText( 2, tostring( math.Round( tonumber( network_data.Supplies ) or 0 ) ) )
        line:SetColumnText( 3, tostring( math.Round( tonumber( network_data.MaxSupplies ) or 1000 ) ) )
        line:SetColumnText( 4, network_data.MapOnly and game.GetMap() or "Any Map" )
        line:SetColumnText( 5, tostring( network_data.DeviceCount or 0 ) )
    end
end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.EDIT", function()
    local the_network = net.ReadTable()

    // Remove the devices from the network for editing
    the_network.Devices = nil

    // Check if this is a pending duplicate action
    if GUI.PendingDuplicate then
        local base_name = GUI.PendingDuplicate
        local new_name = base_name .. "_copy"
        local counter = 1
        while networks[new_name] do
            new_name = base_name .. "_copy" .. tostring( counter )
            counter = counter + 1
        end
        
        the_network.Name = new_name
        GUI.PendingDuplicate = nil
        
        GUI.OpenNetworkEditor( the_network )
        GUI.SetIsNewNetwork( true )
        return
    end

    // Check if this is a pending revert action
    if GUI.PendingRevert then
        GUI.PendingRevert = nil
        // Load the network data directly into editor (not as new)
        if IsValid( GUI.MainFrame ) and isfunction( GUI.MainFrame.LoadNetworkIntoEditor ) then
            GUI.MainFrame:LoadNetworkIntoEditor( the_network, {
                is_new = false,
                source_name = the_network.Name,
                force = true,
            } )
        end
        return
    end

    GUI.OpenNetworkEditor( the_network )
end )

// ============================================
// CONCOMMAND AND DESKTOP WINDOW REGISTRATION
// ============================================

concommand.Add( "HALOARMORY.ManageNetworks", function()
    GUI.OpenGUI()
end )

// Backward compatibility alias - old function name used by entities
function HALOARMORY.Logistics.OpenNetworkManagerGUI()
    GUI.OpenGUI()
end

// Backward compatibility alias - old function name for opening editor directly
function HALOARMORY.Logistics.OpenNetworkEditorGUI( network )
    GUI.OpenNetworkEditor( network )
end

list.Set( "DesktopWindows", "HALOARMORY.NETWORKS.EDITOR", {
    title = "Networks Editor",
    icon = "vgui/haloarmory/icons/anchor.png",
    init = function()
        GUI.OpenGUI()
    end,
} )

// ============================================
// REOPEN GUI IF ALREADY OPEN (ON AUTOREFRESH)
// ============================================

if IsValid( GUI.MainFrame ) then
    GUI.MainFrame:Remove()
    GUI.MainFrame = nil
    GUI.MainFrameEditor = nil
    GUI.OpenGUI( nil )
elseif IsValid( GUI.MainFrameEditor ) then
    GUI.MainFrameEditor:Remove()
    GUI.MainFrameEditor = nil
    GUI.OpenGUI( nil )
end


--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]

-- if GUI.MainFrame then GUI.MainFrame:Remove() end
-- GUI.OpenGUI()