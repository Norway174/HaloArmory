
ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Requisition Console"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.SelectedModel = 4


function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "ConsoleName", { KeyName = "ConsoleName",	Edit = { type = "String", order = 1 } } )
    self:NetworkVar( "Int", 0, "PadIDLink", { KeyName = "PadIDLink",	Edit = { type = "Int", order = 2, min = 0, max = 999999 } } )
    self:NetworkVar( "String", 1, "ConsoleCategory", {
        KeyName = "ConsoleCategory",
        Edit = {
            type = "Combo",
            order = 3,
            values = HALOARMORY.Requisition.GetCategoryValues(),
        }
    } )

    if SERVER then
        self:SetConsoleName( self.PrintName )
        self:SetConsoleCategory( HALOARMORY.Requisition.GetDefaultCategory() )
    end

end

-- Legacy ConsoleID getter/setter for backwards compatibility with PermaProps
-- Old saves had ConsoleID as String, now it's stored as Int in PadIDLink
function ENT:SetConsoleID( value )
    if isstring( value ) then
        value = tonumber( value ) or 0
    end
    self:SetPadIDLink( value or 0 )
end

function ENT:GetConsoleID()
    return self:GetPadIDLink() or 0
end

function ENT:ApplyConsoleConfig( config_data )
    if not istable( config_data ) then return false end

    if isstring( config_data.console_name ) and config_data.console_name ~= "" then
        self:SetConsoleName( config_data.console_name )
    end

    if isnumber( config_data.console_id ) then
        self:SetConsoleID( config_data.console_id )
    end

    if isstring( config_data.category ) then
        self:SetConsoleCategory( config_data.category )
    end

    if isnumber( config_data.model_index ) and config_data.model_index ~= self.SelectedModel then
        if istable( self.ScreenModels ) and istable( self.ScreenModels[config_data.model_index] ) then
            self.SelectedModel = config_data.model_index
            if SERVER then
                self:SetModel( self.ScreenModels[config_data.model_index]["model"] )
                self:SetColor( Color( 255, 255, 255 ) )
                self:SetSubMaterial( nil, nil )
                if isfunction( self.ScreenModels[config_data.model_index]["model_func"] ) then
                    self.ScreenModels[config_data.model_index]["model_func"]( self )
                end
            end
        end
    end

    return true
end
