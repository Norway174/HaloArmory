include( "shared.lua" )

ENT.PanelPos = Vector( 0, 0, 2 )
ENT.PanelAng = Angle( 0, 0, 0 )
ENT.PanelScale = 0.76

ENT.frameW = 1000
ENT.frameH = 1000

local function calculate_number_based_on_distance( target_position )
    local local_player = LocalPlayer()

    if not IsValid( local_player ) or not isvector( target_position ) then
        return 0
    end

    local close_distance = 1000
    local far_distance = 2000
    local distance = local_player:GetPos():Distance( target_position )
    local number = 60

    if distance > close_distance then
        local t = ( distance - close_distance ) / ( far_distance - close_distance )
        number = 60 - ( t * ( 60 - 10 ) )
        number = math.max( 10, math.min( 60, number ) )
    end

    return number
end

local function draw_custom_width_circle( x, y, radius, thickness, set_color, detail )
    local segment_count = detail or 10
    local inner_radius = math.max( radius - thickness, 0 )
    local precision = 2 * math.pi / segment_count

    local points_outer = {}
    local points_inner = {}

    for i = 1, segment_count do
        local angle = i * precision
        local outer_x = x + math.cos( angle ) * radius
        local outer_y = y + math.sin( angle ) * radius
        local inner_x = x + math.cos( angle ) * inner_radius
        local inner_y = y + math.sin( angle ) * inner_radius

        table.insert( points_outer, { x = outer_x, y = outer_y } )
        table.insert( points_inner, { x = inner_x, y = inner_y } )
    end

    for i = 1, #points_outer do
        local next_index = i % #points_outer + 1

        local triangle = {
            { x = points_inner[i].x, y = points_inner[i].y },
            { x = points_outer[i].x, y = points_outer[i].y },
            { x = points_outer[next_index].x, y = points_outer[next_index].y },
        }

        draw.NoTexture()
        surface.SetDrawColor( set_color )
        surface.DrawPoly( triangle )

        triangle = {
            { x = points_inner[i].x, y = points_inner[i].y },
            { x = points_outer[next_index].x, y = points_outer[next_index].y },
            { x = points_inner[next_index].x, y = points_inner[next_index].y },
        }

        draw.NoTexture()
        surface.SetDrawColor( set_color )
        surface.DrawPoly( triangle )
    end
end

function ENT:DrawTranslucent()
    --print( self:ShouldRenderHelipad() )
    local should_render_helipad = self:ShouldRenderHelipad()

    self:DrawShadow( not should_render_helipad )

    if not should_render_helipad then
        self:DrawModel()
        return
    end

    if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP and LocalPlayer():IsAdmin() then
        self:DrawModel()
    end

    local posit = self:LocalToWorld( self.PanelPos )
    local angl = self:LocalToWorldAngles( self.PanelAng )

    cam.Start3D2D( posit, angl, self.PanelScale )
        draw.SimpleTextOutlined( "H", "SP_QuanticoPad", 0, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 255 ) )

        draw_custom_width_circle( 0, 0, 101, 7, Color( 0, 0, 0 ), calculate_number_based_on_distance( self:GetPos() ) )
        draw_custom_width_circle( 0, 0, 100, 5, Color( 255, 255, 255, 255 ), calculate_number_based_on_distance( self:GetPos() ) )

        if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP and LocalPlayer():IsAdmin() then
            draw.SimpleTextOutlined( "▼", "SP_QuanticoHeader", 0, 140, Color( 255, 255, 255, 50 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 50 ) )
        end
    cam.End3D2D()
end

function ENT:Draw()
    self:DrawTranslucent()
end
