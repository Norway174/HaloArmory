HALOARMORY.MsgC("Shared HALOARMORY requisition config loaded!")

HALOARMORY.Requisition = HALOARMORY.Requisition or {}

HALOARMORY.Requisition.Config = HALOARMORY.Requisition.Config or {}

local function normalize_key( value )
    return string.Trim( tostring( value or "" ):lower() )
end

HALOARMORY.Requisition.Config.DefaultCategory = "default"

HALOARMORY.Requisition.Config.Categories = HALOARMORY.Requisition.Config.Categories or {
    {
        id = "default",
        name = "Default",
    },
}

local DEFAULT_PAD_MODELS = {
    {
        id = "small",
        name = "Small Pad",
        model = "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc_small.mdl",
        icon = "vgui/haloarmory/icons/smallpad.png",
        render_helipad = false,
        spawn_pos = Vector( 0, 0, 10 ),
        spawn_ang = Angle( 0, -90, 0 ),
        spawn_radius = 100,
    },
    {
        id = "large",
        name = "Large Pad",
        model = "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc.mdl",
        icon = "vgui/haloarmory/icons/largepad.png",
        render_helipad = false,
        spawn_pos = Vector( 0, 0, 65 ),
        spawn_ang = Angle( 0, -90, 0 ),
        spawn_radius = 300,
    },
    {
        id = "air",
        name = "Air Pad",
        model = "models/hunter/plates/plate2x2.mdl",
        icon = "vgui/haloarmory/icons/airpad.png",
        render_helipad = true,
        spawn_pos = Vector( 0, 0, 65 ),
        spawn_ang = Angle( 0, -90, 0 ),
        spawn_radius = 300,
    },
}

local function copy_table( input )
    return istable( input ) and table.Copy( input ) or {}
end

local function find_default_pad_model( model_data )
    local model_id = normalize_key( istable( model_data ) and model_data.id or nil )
    local model_path = normalize_key( istable( model_data ) and model_data.model or nil )

    for _, default_data in ipairs( DEFAULT_PAD_MODELS ) do
        if normalize_key( default_data.id ) == model_id then
            return default_data
        end

        if normalize_key( default_data.model ) == model_path then
            return default_data
        end
    end

    return nil
end

local function normalize_pad_models()
    local configured_models = HALOARMORY.Requisition.Config.PadModels

    if not istable( configured_models ) or #configured_models <= 0 then
        HALOARMORY.Requisition.Config.PadModels = table.Copy( DEFAULT_PAD_MODELS )
        return
    end

    local normalized_models = {}

    for _, model_data in ipairs( configured_models ) do
        if not istable( model_data ) then continue end

        local merged_data = copy_table( model_data )
        local default_data = find_default_pad_model( model_data )

        if istable( default_data ) then
            for key, value in pairs( default_data ) do
                if merged_data[key] == nil then
                    merged_data[key] = value
                end
            end
        end

        table.insert( normalized_models, merged_data )
    end

    HALOARMORY.Requisition.Config.PadModels = normalized_models
end

normalize_pad_models()

function HALOARMORY.Requisition.GetCategories()
    return HALOARMORY.Requisition.Config.Categories or {}
end

function HALOARMORY.Requisition.GetDefaultCategory()
    return HALOARMORY.Requisition.Config.DefaultCategory or "default"
end

function HALOARMORY.Requisition.GetCategoryValues()
    local values = {}

    for _, category in ipairs( HALOARMORY.Requisition.GetCategories() ) do
        if isstring( category.id ) and category.id ~= "" then
            values[category.id] = category.id
        end
    end

    values[HALOARMORY.Requisition.GetDefaultCategory()] = HALOARMORY.Requisition.GetDefaultCategory()

    return values
end

function HALOARMORY.Requisition.GetCategoryName( category_id )
    category_id = normalize_key( category_id )

    for _, category in ipairs( HALOARMORY.Requisition.GetCategories() ) do
        if normalize_key( category.id ) == category_id then
            return category.name or category.id
        end
    end

    return category_id ~= "" and category_id or HALOARMORY.Requisition.GetDefaultCategory()
end

function HALOARMORY.Requisition.NormalizeCategory( category_id )
    category_id = normalize_key( category_id )
    local default_category = HALOARMORY.Requisition.GetDefaultCategory()

    if category_id == "" then
        return default_category
    end

    local values = HALOARMORY.Requisition.GetCategoryValues()
    if values[category_id] then
        return category_id
    end

    return default_category
end

function HALOARMORY.Requisition.GetPadModels()
    return HALOARMORY.Requisition.Config.PadModels or {}
end

function HALOARMORY.Requisition.GetDefaultPadModel()
    local models = HALOARMORY.Requisition.GetPadModels()
    if istable( models ) and istable( models[1] ) and isstring( models[1].model ) then
        return models[1].model
    end

    return "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc_small.mdl"
end

function HALOARMORY.Requisition.FindPadModelConfig( model )
    local normalized_model = normalize_key( model )

    for _, data in ipairs( HALOARMORY.Requisition.GetPadModels() ) do
        if normalize_key( data.model ) == normalized_model then
            return data
        end
    end

    return nil
end

function HALOARMORY.Requisition.GetPadModelConfig( model )
    local exact_match = HALOARMORY.Requisition.FindPadModelConfig( model )
    if istable( exact_match ) then
        return exact_match
    end

    local models = HALOARMORY.Requisition.GetPadModels()
    if istable( models ) and istable( models[1] ) then
        return models[1]
    end

    return nil
end

function HALOARMORY.Requisition.GetPadModelIcon( model )
    local data = HALOARMORY.Requisition.GetPadModelConfig( model )
    if istable( data ) and isstring( data.icon ) then
        return data.icon
    end

    return "vgui/haloarmory/icons/anchor.png"
end

function HALOARMORY.Requisition.NormalizeVehicleCategories( categories )
    local normalized = {}

    if istable( categories ) then
        for category_id, enabled in pairs( categories ) do
            if enabled then
                normalized[HALOARMORY.Requisition.NormalizeCategory( category_id )] = true
            end
        end
    end

    if table.Count( normalized ) <= 0 then
        normalized[HALOARMORY.Requisition.GetDefaultCategory()] = true
    end

    return normalized
end

function HALOARMORY.Requisition.NormalizeVehicleTable( vehicle_table )
    if not istable( vehicle_table ) then
        vehicle_table = {}
    end

    vehicle_table.defaults = vehicle_table.defaults or {}
    vehicle_table.colors = vehicle_table.colors or {
        ["UNSC Green"] = Color( 76, 85, 63 ),
    }
    vehicle_table.skins = vehicle_table.skins or {
        ["Default"] = 0,
    }
    vehicle_table.bodygroups = vehicle_table.bodygroups or {}
    vehicle_table.AccessList = vehicle_table.AccessList or {}

    vehicle_table.defaults.color = vehicle_table.defaults.color or next( vehicle_table.colors ) or "UNSC Green"
    vehicle_table.defaults.skin = vehicle_table.defaults.skin or next( vehicle_table.skins ) or "Default"

    vehicle_table.categories = HALOARMORY.Requisition.NormalizeVehicleCategories( vehicle_table.categories )
    vehicle_table.sizes = nil

    return vehicle_table
end

function HALOARMORY.Requisition.VehicleHasCategory( vehicle_table, category_id )
    vehicle_table = HALOARMORY.Requisition.NormalizeVehicleTable( vehicle_table )
    category_id = HALOARMORY.Requisition.NormalizeCategory( category_id )

    return vehicle_table.categories[category_id] == true
end

function HALOARMORY.Requisition.IsPadCompatibleWithConsole( pad, console )
    if not IsValid( pad ) then return false end
    if not IsValid( console ) or not isfunction( console.GetConsoleCategory ) then return true end
    if not isfunction( pad.GetPadCategory ) then return true end

    return HALOARMORY.Requisition.NormalizeCategory( pad:GetPadCategory() ) == HALOARMORY.Requisition.NormalizeCategory( console:GetConsoleCategory() )
end
