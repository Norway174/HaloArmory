HALOARMORY.Requisition = HALOARMORY.Requisition or {}
HALOARMORY.Requisition.ConsoleGUI = HALOARMORY.Requisition.ConsoleGUI or {}

local function sort_by_distance( values )
    table.sort( values, function( a, b )
        return ( a.distance or 999999 ) < ( b.distance or 999999 )
    end )
end

local function create_label_row( parent, label_text, tall )
    local row = vgui.Create( "DPanel", parent )
    row:Dock( TOP )
    row:SetTall( tall or 28 )
    row:DockMargin( 8, 0, 8, 6 )
    row.Paint = nil

    local label = vgui.Create( "DLabel", row )
    label:Dock( LEFT )
    label:SetWide( 120 )
    label:SetText( label_text )

    return row
end

local function get_console_value( console_ent, getter_name, fallback )
    if not IsValid( console_ent ) then
        return fallback
    end

    local getter = console_ent[getter_name]
    if not isfunction( getter ) then
        return fallback
    end

    local value = getter( console_ent )
    if value == nil then
        return fallback
    end

    return value
end

local function get_nearby_pads( category, position, max_distance )
    local pads = {}
    max_distance = max_distance or 2000

    for _, ent in ipairs( ents.GetAll() ) do
        if not IsValid( ent ) then continue end
        if not ent.VehiclePad then continue end
        if not isfunction( ent.GetPadCategory ) then continue end
        if not isfunction( ent.GetPadID ) then continue end
        if not isfunction( ent.GetDeviceName ) then continue end
        if not isfunction( ent.GetNetworkID ) then continue end

        -- Check category match
        local pad_category = HALOARMORY.Requisition.NormalizeCategory( ent:GetPadCategory() )
        if pad_category ~= category then continue end

        -- Calculate distance
        local dist = position:DistToSqr( ent:GetPos() )
        if dist > max_distance * max_distance then continue end

        table.insert( pads, {
            id = ent:GetPadID(),
            name = ent:GetDeviceName() or "Unknown",
            network = ent:GetNetworkID() or "0",
            distance = math.sqrt( dist ),
            entity = ent,
        } )
    end

    sort_by_distance( pads )
    return pads
end

local function get_screen_models( console_ent )
    -- Get models from parent class (halo_tv_screen)
    local models = {}
    local screen_models = nil

    -- First, check if console_ent is valid and has ScreenModels directly
    if IsValid( console_ent ) and istable( console_ent.ScreenModels ) then
        screen_models = console_ent.ScreenModels
    end

    if not istable( screen_models ) then
        -- Try to get from the entity's class
        local class_name = IsValid( console_ent ) and console_ent:GetClass() or "halo_sp_vr_console"
        local class = scripted_ents.GetStored( class_name )
        if istable( class ) and istable( class.t ) and istable( class.t.ScreenModels ) then
            screen_models = class.t.ScreenModels
        end
    end

    if not istable( screen_models ) then
        -- Fallback to halo_tv_screen directly
        local base_class = scripted_ents.GetStored( "halo_tv_screen" )
        if istable( base_class ) and istable( base_class.t ) and istable( base_class.t.ScreenModels ) then
            screen_models = base_class.t.ScreenModels
        end
    end

    if istable( screen_models ) then
        for i, model_data in ipairs( screen_models ) do
            if istable( model_data ) and isstring( model_data.model ) then
                table.insert( models, {
                    index = i,
                    model = model_data.model,
                    name = model_data.model, -- Could be improved with friendly names
                } )
            end
        end
    end

    return models
end

function HALOARMORY.Requisition.OpenConsoleConfigGUI( console_ent )
    if HALOARMORY.Requisition.ConsoleGUI.Panel then
        HALOARMORY.Requisition.ConsoleGUI.Panel:Remove()
        HALOARMORY.Requisition.ConsoleGUI.Panel = nil
    end

    local creating_console = not IsValid( console_ent )

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 600, 550 )
    frame:Center()
    frame:SetTitle( creating_console and "Create Requisition Console" or "Requisition Console Setup" )
    frame:MakePopup()

    HALOARMORY.Requisition.ConsoleGUI.Panel = frame

    frame.OnClose = function()
        HALOARMORY.Requisition.ConsoleGUI.Panel = nil
    end

    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )
    scroll:DockMargin( 0, 4, 0, 0 )

    local current_category = HALOARMORY.Requisition.NormalizeCategory( get_console_value( console_ent, "GetConsoleCategory", nil ) )
    local current_name = get_console_value( console_ent, "GetConsoleName", "Requisition Console" )
    local current_console_id = get_console_value( console_ent, "GetConsoleID", 0 )
    local current_model_index = get_console_value( console_ent, "SelectedModel", 4 ) -- Default to 4 like in the entity
    local screen_models = get_screen_models( console_ent )
    local selected_model_index = current_model_index

    -- Console Name
    local name_row = create_label_row( scroll, "Console Name:" )
    local name_entry = vgui.Create( "DTextEntry", name_row )
    name_entry:Dock( FILL )
    name_entry:SetValue( current_name )

    -- Model Selection
    local model_header = vgui.Create( "DLabel", scroll )
    model_header:Dock( TOP )
    model_header:DockMargin( 8, 8, 8, 6 )
    model_header:SetText( "Screen Model" )
    model_header:SetFont( "DermaDefaultBold" )

    local model_holder = vgui.Create( "DPanel", scroll )
    model_holder:Dock( TOP )
    model_holder:SetTall( 100 )
    model_holder:DockMargin( 8, 0, 8, 8 )
    model_holder.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 120 ) )
    end

    local model_layout = vgui.Create( "DIconLayout", model_holder )
    model_layout:Dock( FILL )
    model_layout:DockMargin( 4, 4, 4, 4 )
    model_layout:SetSpaceX( 4 )
    model_layout:SetSpaceY( 4 )

    local model_buttons = {}
    for _, model_data in ipairs( screen_models ) do
        local icon = vgui.Create( "SpawnIcon", model_layout )
        icon:SetSize( 64, 64 )
        icon:SetModel( model_data.model )
        icon:SetTooltip( model_data.name )
        icon.ModelIndex = model_data.index
        icon.Selected = icon.ModelIndex == selected_model_index

        icon.PaintOver = function( self, w, h )
            if self.Selected then
                surface.SetDrawColor( 50, 160, 255, 255 )
                surface.DrawOutlinedRect( 0, 0, w, h, 2 )
            end
        end

        icon.DoClick = function()
            selected_model_index = model_data.index
            for _, btn in ipairs( model_buttons ) do
                btn.Selected = ( btn.ModelIndex == selected_model_index )
            end
        end

        table.insert( model_buttons, icon )
    end

    -- Forward declare selected_category_choice so refresh_pad_list can use it
    local selected_category_choice = current_category

    -- Category Selection (define early so refresh_pad_list can be defined)
    local category_row = create_label_row( scroll, "Category:" )
    local category_combo = vgui.Create( "DComboBox", category_row )
    category_combo:Dock( FILL )
    local category_choices = HALOARMORY.Requisition.GetCategories( { current_category } )
    local category_idx = nil

    for i, category in ipairs( category_choices ) do
        category_combo:AddChoice( category.id )
        if category.id == current_category then
            category_idx = i
        end
    end

    -- Console ID (define early so pads list callback can use it)
    local console_id_row = create_label_row( scroll, "Console ID:" )
    local console_id_entry = vgui.Create( "DNumberWang", console_id_row )
    console_id_entry:Dock( FILL )
    console_id_entry:SetMin( 0 )
    console_id_entry:SetMax( 999999 )
    if creating_console then
        console_id_entry:SetValue( 0 )
    else
        console_id_entry:SetValue( current_console_id )
    end

    -- Nearby Pads Section (define early so refresh_pad_list can be defined)
    local pads_header = vgui.Create( "DLabel", scroll )
    pads_header:Dock( TOP )
    pads_header:DockMargin( 8, 8, 8, 6 )
    pads_header:SetText( "Nearby Pads (Same Category)" )
    pads_header:SetFont( "DermaDefaultBold" )

    local pads_help = vgui.Create( "DLabel", scroll )
    pads_help:Dock( TOP )
    pads_help:DockMargin( 8, 0, 8, 6 )
    pads_help:SetText( "Click on a pad to set the Console ID to match. This links the console to that pad." )
    pads_help:SetTextColor( Color( 150, 150, 150 ) )

    local pads_list_panel = vgui.Create( "DPanel", scroll )
    pads_list_panel:Dock( TOP )
    pads_list_panel:SetTall( 150 )
    pads_list_panel:DockMargin( 8, 0, 8, 8 )
    pads_list_panel.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 40, 40, 40 ) )
    end

    local pads_list = vgui.Create( "DListView", pads_list_panel )
    pads_list:Dock( FILL )
    pads_list:SetMultiSelect( false )
    pads_list:AddColumn( "ID" ):SetFixedWidth( 60 )
    pads_list:AddColumn( "Name" ):SetFixedWidth( 150 )
    pads_list:AddColumn( "Network" ):SetFixedWidth( 70 )
    pads_list:AddColumn( "Distance" ):SetFixedWidth( 70 )

    pads_list.OnRowSelected = function( _, _, line )
        local pad_data = line:GetColumnText( 1 )
        local pad_id = tonumber( pad_data )
        if pad_id then
            console_id_entry:SetValue( pad_id )
        end
    end

    -- Now define refresh_pad_list (after all the controls it uses are defined)
    local function refresh_pad_list()
        pads_list:Clear()

        local local_player = LocalPlayer()
        if not IsValid( local_player ) then return end

        local eye_trace = local_player:GetEyeTrace()
        local position = eye_trace and eye_trace.HitPos or local_player:GetPos()

        if creating_console then
            -- For new consoles, use player's eye position
            position = local_player:EyePos()
        else
            -- For existing consoles, use console position
            position = console_ent:GetPos()
        end

        local nearby_pads = get_nearby_pads( selected_category_choice, position, 2000 )

        for _, pad_data in ipairs( nearby_pads ) do
            local line = pads_list:AddLine(
                pad_data.id,
                pad_data.name,
                pad_data.network == "0" and "None" or pad_data.network,
                string.format( "%.0f", pad_data.distance )
            )
        end
    end

    -- Set up category combo callback and initial selection (after refresh_pad_list is defined)
    category_combo.OnSelect = function( _, _, value )
        selected_category_choice = value
        -- Refresh the nearby pads list when category changes
        refresh_pad_list()
    end
    category_combo:ChooseOptionID( category_idx or 1 )

    refresh_pad_list()

    -- Action Buttons
    local action_row = vgui.Create( "DPanel", scroll )
    action_row:Dock( TOP )
    action_row:SetTall( 36 )
    action_row:DockMargin( 8, 0, 8, 8 )
    action_row.Paint = nil

    local apply_button = vgui.Create( "DButton", action_row )
    apply_button:Dock( LEFT )
    apply_button:SetWide( 180 )
    apply_button:SetText( creating_console and "Spawn Console" or "Apply Setup" )

    local cancel_button = vgui.Create( "DButton", action_row )
    cancel_button:Dock( RIGHT )
    cancel_button:SetWide( 120 )
    cancel_button:SetText( "Cancel" )

    cancel_button.DoClick = function()
        frame:Close()
    end

    apply_button.DoClick = function()
        apply_button:SetEnabled( false )

        local payload = {
            console_name = name_entry:GetValue(),
            model_index = selected_model_index,
            category = selected_category_choice,
            console_id = console_id_entry:GetValue(),
        }

        if creating_console then
            local local_player = LocalPlayer()
            local eye_trace = IsValid( local_player ) and ( local_player.GetEyeTraceNoCursor and local_player:GetEyeTraceNoCursor() or local_player:GetEyeTrace() ) or nil

            if eye_trace and eye_trace.Hit then
                local spawn_pos = eye_trace.HitPos + eye_trace.HitNormal * 10
                local spawn_ang = local_player:EyeAngles()
                spawn_ang.p = 0

                HALOARMORY.VEHICLES.NETWORK.CreateConsole( spawn_pos, spawn_ang, payload, function( success )
                    apply_button:SetEnabled( true )
                    if success then
                        frame:Close()
                    end
                end )
            else
                apply_button:SetEnabled( true )
            end
        else
            HALOARMORY.VEHICLES.NETWORK.ApplyConsoleConfig( console_ent, payload, function( success )
                apply_button:SetEnabled( true )
                if success then
                    frame:Close()
                end
            end )
        end
    end
end

concommand.Add( "haloarmory_open_console_menu", function()
    HALOARMORY.Requisition.OpenConsoleConfigGUI( nil )
end )
