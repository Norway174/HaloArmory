
include('shared.lua')


ENT.PanelPos = Vector(0, 0, 2)
ENT.PanelAng = Angle(0, 0, 0)
ENT.PanelScale = .76

ENT.frameW, ENT.frameH = 1000, 1000

-- Custom function to calculate a number between 60 and 10 based on distance
function CalculateNumberBasedOnDistance(targetPosition)
    local localPlayer = LocalPlayer()
    
    if not IsValid(localPlayer) or not isvector(targetPosition) then
        return 0
    end
    
    -- Define the distance thresholds
    local closeDistance = 1000
    local farDistance = 2000
    
    -- Calculate the distance between the local player and the target position
    local distance = localPlayer:GetPos():Distance(targetPosition)
    
    -- Calculate the number based on distance
    local number = 60 -- Default value
    
    if distance > closeDistance then
        -- Linearly interpolate between 60 and 10 based on the distance
        local t = (distance - closeDistance) / (farDistance - closeDistance)
        number = 60 - (t * (60 - 10))
        -- Ensure the number is within the range of 10 to 60
        number = math.max(10, math.min(60, number))
    end

    --print(number, distance )
    
    return number
end


-- Custom function to draw a circle with a custom width
local function DrawCustomWidthCircle(x, y, radius, thickness, set_color, detail)
    local segment_count = detail or 10 -- Number of line segments to approximate the circle
    
    local inner_radius = math.max(radius - thickness, 0)
    
    local precision = 2 * math.pi / segment_count -- Angle increment for each segment
    
    -- Calculate points around the circumference
    local points_outer = {}
    local points_inner = {}
    for i = 1, segment_count do
        local angle = i * precision
        local outer_x = x + math.cos(angle) * radius
        local outer_y = y + math.sin(angle) * radius
        local inner_x = x + math.cos(angle) * inner_radius
        local inner_y = y + math.sin(angle) * inner_radius
        table.insert(points_outer, {x = outer_x, y = outer_y})
        table.insert(points_inner, {x = inner_x, y = inner_y})
    end
    
    -- Draw the filled area between the inner and outer circles
    for i = 1, #points_outer do
        local next_index = i % #points_outer + 1
        local triangle = {
            {x = points_inner[i].x, y = points_inner[i].y},
            {x = points_outer[i].x, y = points_outer[i].y},
            {x = points_outer[next_index].x, y = points_outer[next_index].y}
        }
        draw.NoTexture()
        surface.SetDrawColor(set_color)
        surface.DrawPoly(triangle)
        
        triangle = {
            {x = points_inner[i].x, y = points_inner[i].y},
            {x = points_outer[next_index].x, y = points_outer[next_index].y},
            {x = points_inner[next_index].x, y = points_inner[next_index].y}
        }
        draw.NoTexture()
        surface.SetDrawColor(set_color)
        surface.DrawPoly(triangle)
    end
end








function ENT:DrawTranslucent()
    if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP && LocalPlayer():IsAdmin() then
        self:DrawModel()
    end

    --local pos = self:GetPos() + self.VehicleSpawnPos
    --render.DrawWireframeSphere( pos, self.VehicleSpawnRadius, 10, 10, Color( 9, 177, 255), true)


    local Posit = self:LocalToWorld(self.PanelPos)
    local Angl = self:LocalToWorldAngles(self.PanelAng)

    cam.Start3D2D( Posit, Angl, self.PanelScale )

        --draw.RoundedBox(0, -self.frameW/2, -self.frameH/2, self.frameW, self.frameH, Color(0, 0, 0, 255))

        // Draw a "H" in the middle.
        draw.SimpleTextOutlined("H", "SP_QuanticoPad", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))

        // Draw a circle around the "H".
        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255, 255)
        --surface.DrawCircle(0, 0, 100, Color(255, 255, 255, 255))

        --surface.DrawCircle( 0, 0, 100 + math.sin( CurTime() ) * 50, Color( 255, 120, 0 ) )

        DrawCustomWidthCircle(0, 0, 101, 7, Color(0, 0, 0), CalculateNumberBasedOnDistance( self:GetPos() ) )
        DrawCustomWidthCircle(0, 0, 100, 5, Color(255, 255, 255, 255), CalculateNumberBasedOnDistance( self:GetPos() ) )


        if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP && LocalPlayer():IsAdmin() then
            draw.SimpleTextOutlined("▼", "SP_QuanticoHeader", 0, 140, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 50))
        end

    cam.End3D2D()

end