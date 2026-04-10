HALOARMORY.Requisition = HALOARMORY.Requisition or {}
HALOARMORY.Requisition.GUI = HALOARMORY.Requisition.GUI or {}

local function sort_strings( values )
    table.sort( values, function( a, b )
        return tostring( a ) < tostring( b )
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

local function get_pad_value( pad_ent, getter_name, fallback )
    if not IsValid( pad_ent ) then
        return fallback
    end

    local getter = pad_ent[getter_name]
    if not isfunction( getter ) then
        return fallback
    end

    local value = getter( pad_ent )
    if value == nil then
        return fallback
    end

    return value
end

local function get_network_values( provided_networks, selected_network )
    local network_values = {}

    for _, network_id in ipairs( provided_networks or {} ) do
        table.insert( network_values, tostring( network_id ) )
    end

    -- Fallback to client-side networks if none provided
    if #network_values <= 0 and istable( HALOARMORY.Logistics ) and istable( HALOARMORY.Logistics.Networks ) then
        for network_id in pairs( HALOARMORY.Logistics.Networks ) do
            table.insert( network_values, tostring( network_id ) )
        end
    end

    -- Add selected_network if it's a valid network ID (not "0" or empty) and not already in list
    if selected_network ~= "" and selected_network ~= "0" and not table.HasValue( network_values, selected_network ) then
        table.insert( network_values, selected_network )
    end

    sort_strings( network_values )

    return network_values
end

function HALOARMORY.Requisition.OpenPadConfigGUI( pad_ent, networks, spawn_request, categories )
    if HALOARMORY.Requisition.GUI.PadConfig then
        HALOARMORY.Requisition.GUI.PadConfig:Remove()
        HALOARMORY.Requisition.GUI.PadConfig = nil
    end

    local creating_pad = not IsValid( pad_ent )

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 760, 760 )
    frame:Center()
    frame:SetTitle( creating_pad and "Create Vehicle Pad" or "Vehicle Pad Setup" )
    frame:MakePopup()

    HALOARMORY.Requisition.GUI.PadConfig = frame

    frame.OnClose = function()
        HALOARMORY.Requisition.GUI.PadConfig = nil
    end

    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )
    scroll:DockMargin( 0, 4, 0, 0 )

    local current_category = HALOARMORY.Requisition.NormalizeCategory( get_pad_value( pad_ent, "GetPadCategory", nil ) )
    local current_model = get_pad_value( pad_ent, "GetModel", HALOARMORY.Requisition.GetDefaultPadModel() )
    local selected_model = HALOARMORY.Requisition.GetPadModelConfig( current_model ) and current_model or HALOARMORY.Requisition.GetDefaultPadModel()
    local selected_network = tostring( get_pad_value( pad_ent, "GetNetworkID", "0" ) )
    local network_values = get_network_values( networks, selected_network )
    local current_pad_id = get_pad_value( pad_ent, "GetPadID", 0 )

    local pad_id_row = create_label_row( scroll, "Pad ID:" )
    local pad_id_entry = vgui.Create( "DNumberWang", pad_id_row )
    pad_id_entry:Dock( FILL )
    pad_id_entry:SetMin( 0 )
    pad_id_entry:SetMax( 999999 )
    if creating_pad then
        -- Generate a unique random ID for new pads
        local function generate_unique_id()
            local new_id = math.random( 1, 999999 )
            for _, ent in ipairs( ents.GetAll() ) do
                if ent.VehiclePad and isfunction( ent.GetPadID ) and ent:GetPadID() == new_id then
                    return nil -- ID already in use
                end
            end
            return new_id
        end

        local attempts = 0
        local unique_id = nil
        while not unique_id and attempts < 100 do
            unique_id = generate_unique_id()
            attempts = attempts + 1
        end
        pad_id_entry:SetValue( unique_id or math.random( 1, 999999 ) )
    else
        pad_id_entry:SetValue( current_pad_id )
    end

    local name_row = create_label_row( scroll, "Device Name:" )
    local device_name = vgui.Create( "DTextEntry", name_row )
    device_name:Dock( FILL )
    device_name:SetValue( get_pad_value( pad_ent, "GetDeviceName", "Vehicle Requisition Pad" ) )

    local network_row = create_label_row( scroll, "Network:" )
    local network_combo = vgui.Create( "DComboBox", network_row )
    network_combo:Dock( FILL )
    network_combo:AddChoice( "None" )
    for _, network_id in ipairs( network_values ) do
        network_combo:AddChoice( network_id )
    end

    local selected_network_choice = selected_network == "0" and "None" or selected_network

    network_combo.OnSelect = function( _, _, value )
        selected_network_choice = value
    end

    if selected_network == "0" then
        network_combo:ChooseOptionID( 1 )
    else
        local found_idx = nil
        for i, network_id in ipairs( network_values ) do
            if network_id == selected_network then
                found_idx = i + 1
                break
            end
        end
        if found_idx then
            network_combo:ChooseOptionID( found_idx )
        else
            network_combo:SetValue( selected_network )
        end
    end

    local category_row = create_label_row( scroll, "Category:" )
    local category_combo = vgui.Create( "DComboBox", category_row )
    category_combo:Dock( FILL )
    local category_choices = categories or HALOARMORY.Requisition.GetCategories( { current_category } )
    local category_idx = nil
    local selected_category_choice = current_category

    category_combo.OnSelect = function( _, _, value )
        selected_category_choice = value
    end

    for i, category in ipairs( category_choices ) do
        category_combo:AddChoice( category.id )
        if category.id == current_category then
            category_idx = i
        end
    end
    category_combo:ChooseOptionID( category_idx or 1 )

    local supply_row = create_label_row( scroll, "Uses Supplies:" )
    local requires_supplies = vgui.Create( "DCheckBoxLabel", supply_row )
    requires_supplies:Dock( FILL )
    requires_supplies:SetText( "Require network supplies to spawn vehicles" )
    requires_supplies:SetValue( get_pad_value( pad_ent, "GetRequiresSupplies", true ) )
    requires_supplies:SizeToContents()

    local model_header = vgui.Create( "DLabel", scroll )
    model_header:Dock( TOP )
    model_header:DockMargin( 8, 8, 8, 6 )
    model_header:SetText( "Pad Model" )
    model_header:SetFont( "DermaDefaultBold" )

    local model_help = vgui.Create( "DLabel", scroll )
    model_help:Dock( TOP )
    model_help:DockMargin( 8, 0, 8, 6 )
    model_help:SetText( "Choose one of the configured pad models. This changes the entity model directly." )

    local model_holder = vgui.Create( "DPanel", scroll )
    model_holder:Dock( TOP )
    model_holder:SetTall( 180 )
    model_holder:DockMargin( 8, 0, 8, 8 )
    model_holder.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 120 ) )
    end

    local model_layout = vgui.Create( "DIconLayout", model_holder )
    model_layout:Dock( FILL )
    model_layout:DockMargin( 8, 8, 8, 8 )
    model_layout:SetSpaceX( 8 )
    model_layout:SetSpaceY( 8 )

    local model_buttons = {}
    local function refresh_model_selection()
        for _, button in ipairs( model_buttons ) do
            button.Selected = ( button.ModelPath == selected_model )
        end
    end

    for _, model_data in ipairs( HALOARMORY.Requisition.GetPadModels() ) do
        local icon = vgui.Create( "SpawnIcon", model_layout )
        icon:SetSize( 140, 140 )
        icon:SetModel( model_data.model )
        icon:SetTooltip( model_data.name or model_data.id )
        icon.ModelPath = model_data.model
        icon.Selected = icon.ModelPath == selected_model

        icon.PaintOver = function( self, w, h )
            if self.Selected then
                surface.SetDrawColor( 50, 160, 255, 255 )
                surface.DrawOutlinedRect( 0, 0, w, h, 3 )
            end

            draw.SimpleText( model_data.name or model_data.id, "DermaDefaultBold", w / 2, h - 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
        end

        icon.DoClick = function()
            selected_model = model_data.model
            refresh_model_selection()
        end

        table.insert( model_buttons, icon )
    end

    refresh_model_selection()

    local lights_header = vgui.Create( "DLabel", scroll )
    lights_header:Dock( TOP )
    lights_header:DockMargin( 8, 8, 8, 6 )
    lights_header:SetText( "Lights" )
    lights_header:SetFont( "DermaDefaultBold" )

    local spawn_lights_row = create_label_row( scroll, "Spawn Lights:" )
    local spawn_lights = vgui.Create( "DCheckBoxLabel", spawn_lights_row )
    spawn_lights:Dock( FILL )
    spawn_lights:SetText( "Spawn the optional light ring" )
    spawn_lights:SetValue( get_pad_value( pad_ent, "GetSpawnLights", false ) )
    spawn_lights:SizeToContents()

    local auto_change_row = create_label_row( scroll, "Auto Change:" )
    local auto_change = vgui.Create( "DCheckBoxLabel", auto_change_row )
    auto_change:Dock( FILL )
    auto_change:SetText( "Swap between green and red depending on occupancy" )
    auto_change:SetValue( get_pad_value( pad_ent, "GetLightAutoChange", false ) )
    auto_change:SizeToContents()

    local light_on_row = create_label_row( scroll, "Light On:" )
    local light_on = vgui.Create( "DCheckBoxLabel", light_on_row )
    light_on:Dock( FILL )
    light_on:SetText( "Enable the spawned lights" )
    light_on:SetValue( get_pad_value( pad_ent, "GetLightOn", false ) )
    light_on:SizeToContents()

    local world_row = create_label_row( scroll, "Light World:" )
    local light_world = vgui.Create( "DCheckBoxLabel", world_row )
    light_world:Dock( FILL )
    light_world:SetText( "Allow the lights to affect the world" )
    light_world:SetValue( get_pad_value( pad_ent, "GetLightWorld", true ) )
    light_world:SizeToContents()

    local model_row = create_label_row( scroll, "Light Model:" )
    local light_model = vgui.Create( "DCheckBoxLabel", model_row )
    light_model:Dock( FILL )
    light_model:SetText( "Draw the light models" )
    light_model:SetValue( get_pad_value( pad_ent, "GetLightModel", true ) )
    light_model:SizeToContents()

    local segments_row = create_label_row( scroll, "Segments:" )
    local segments = vgui.Create( "DNumberWang", segments_row )
    segments:Dock( FILL )
    segments:SetMin( 0 )
    segments:SetMax( 360 )
    segments:SetValue( get_pad_value( pad_ent, "GetSegments", 6 ) )

    local radius_row = create_label_row( scroll, "Radius:" )
    local radius = vgui.Create( "DNumberWang", radius_row )
    radius:Dock( FILL )
    radius:SetMin( 0 )
    radius:SetMax( 2048 )
    radius:SetValue( get_pad_value( pad_ent, "GetRadius", 370 ) )

    local brightness_row = create_label_row( scroll, "Brightness:" )
    local brightness = vgui.Create( "DNumberWang", brightness_row )
    brightness:Dock( FILL )
    brightness:SetMin( 0 )
    brightness:SetMax( 8 )
    brightness:SetDecimals( 1 )
    brightness:SetValue( get_pad_value( pad_ent, "GetLightBrightness", 2 ) )

    local size_row = create_label_row( scroll, "Light Size:" )
    local light_size = vgui.Create( "DNumberWang", size_row )
    light_size:Dock( FILL )
    light_size:SetMin( 0 )
    light_size:SetMax( 2048 )
    light_size:SetDecimals( 1 )
    light_size:SetValue( get_pad_value( pad_ent, "GetLightSize", 256 ) )

    local color_row = vgui.Create( "DPanel", scroll )
    color_row:Dock( TOP )
    color_row:SetTall( 170 )
    color_row:DockMargin( 8, 0, 8, 8 )
    color_row.Paint = nil

    local color_label = vgui.Create( "DLabel", color_row )
    color_label:Dock( TOP )
    color_label:SetText( "Light Color:" )

    local color_picker = vgui.Create( "DColorMixer", color_row )
    color_picker:Dock( FILL )
    color_picker:SetPalette( true )
    color_picker:SetAlphaBar( false )
    color_picker:SetWangs( true )
    color_picker:SetColor( get_pad_value( pad_ent, "GetLightColor", Vector( 0, 50 / 255, 0 ) ):ToColor() )

    local action_row = vgui.Create( "DPanel", scroll )
    action_row:Dock( TOP )
    action_row:SetTall( 36 )
    action_row:DockMargin( 8, 0, 8, 8 )
    action_row.Paint = nil

    local apply_button = vgui.Create( "DButton", action_row )
    apply_button:Dock( LEFT )
    apply_button:SetWide( 180 )
    apply_button:SetText( creating_pad and "Spawn Pad" or "Apply Setup" )

    local cancel_button = vgui.Create( "DButton", action_row )
    cancel_button:Dock( RIGHT )
    cancel_button:SetWide( 120 )
    cancel_button:SetText( "Cancel" )

    cancel_button.DoClick = function()
        frame:Close()
    end

    apply_button.DoClick = function()
        apply_button:SetEnabled( false )

        local network_id_value = selected_network_choice
        if network_id_value == "None" then
            network_id_value = "0"
        end

        local payload = {
            pad_id = pad_id_entry:GetValue(),
            device_name = device_name:GetValue(),
            network_id = network_id_value,
            category = selected_category_choice,
            requires_supplies = requires_supplies:GetChecked(),
            model = selected_model,
            spawn_lights = spawn_lights:GetChecked(),
            light_auto_change = auto_change:GetChecked(),
            light_on = light_on:GetChecked(),
            light_world = light_world:GetChecked(),
            light_model = light_model:GetChecked(),
            segments = segments:GetValue(),
            radius = radius:GetValue(),
            light_brightness = brightness:GetValue(),
            light_size = light_size:GetValue(),
            light_color = color_picker:GetColor(),
        }

        local on_complete = function( success )
            apply_button:SetEnabled( true )

            if success then
                frame:Close()
            end
        end

        if creating_pad then
            local local_player = LocalPlayer()
            local eye_trace = IsValid( local_player ) and ( local_player.GetEyeTraceNoCursor and local_player:GetEyeTraceNoCursor() or local_player:GetEyeTrace() ) or nil
            local spawn_data = spawn_request or {}

            if eye_trace and eye_trace.Hit then
                spawn_data.spawn_pos = eye_trace.HitPos + eye_trace.HitNormal * 10
                spawn_data.spawn_ang = local_player:EyeAngles()
                spawn_data.spawn_ang.p = 0
            end

            HALOARMORY.VEHICLES.NETWORK.CreatePad( spawn_data.class_name or "halo_sp_vr_pad", spawn_data, payload, on_complete )
            return
        end

        HALOARMORY.VEHICLES.NETWORK.ApplyPadConfig( pad_ent, payload, on_complete )
    end
end

concommand.Add( "haloarmory_open_pad_menu", function()
    HALOARMORY.VEHICLES.NETWORK.OpenNewPadConfig()
end )
