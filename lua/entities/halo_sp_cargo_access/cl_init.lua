
include('shared.lua')


ENT.Theme["background"] = Material( ENT.Theme["background"], "smooth" )

local SIDE_PANELS = {
    {
        normal = Vector(0, 1, 0),
        pos = function(mins, maxs, height, offset)
            return Vector(0, maxs.y + offset, height)
        end,
        ang = Angle(0, 180, 90),
    },
    {
        normal = Vector(0, -1, 0),
        pos = function(mins, maxs, height, offset)
            return Vector(0, mins.y - offset, height)
        end,
        ang = Angle(0, 0, 90),
    },
    {
        normal = Vector(1, 0, 0),
        pos = function(mins, maxs, height, offset)
            return Vector(maxs.x + offset, 0, height)
        end,
        ang = Angle(0, 90, 90),
    },
    {
        normal = Vector(-1, 0, 0),
        pos = function(mins, maxs, height, offset)
            return Vector(mins.x - offset, 0, height)
        end,
        ang = Angle(0, -90, 90),
    },
}

function ENT:GetVisibleSidePanels()
    local ply = LocalPlayer()
    if not IsValid(ply) then return {} end

    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    local center = self:OBBCenter()
    local eyeLocal = self:WorldToLocal(ply:EyePos()) - center
    eyeLocal.z = 0

    if eyeLocal:LengthSqr() <= 0 then
        return {}
    end

    eyeLocal:Normalize()

    local height = mins.z + ((maxs.z - mins.z) * self.SidePanelHeight)
    local offset = self.SidePanelOffset or 0
    local visiblePanels = {}

    for _, side in ipairs(SIDE_PANELS) do
        local score = eyeLocal:Dot(side.normal)
        if score > 0 then
            visiblePanels[#visiblePanels + 1] = {
                score = score,
                pos = side.pos(mins, maxs, height, offset),
                ang = side.ang,
            }
        end
    end

    table.sort(visiblePanels, function(a, b)
        return a.score > b.score
    end)

    if #visiblePanels > 2 then
        for index = #visiblePanels, 3, -1 do
            visiblePanels[index] = nil
        end
    end

    return visiblePanels
end

function ENT:DrawPanel()
    draw.RoundedBox( 8, 0, 0, self.frameW, self.frameH, self.Theme["colors"]["background_color"] )

    if isstring(self.Theme["background"]) then
        self.Theme["background"] = Material( self.Theme["background"], "smooth" )
    end

    if !self.Theme["background"]:IsError() then
        surface.SetMaterial( self.Theme["background"] )
        surface.SetDrawColor( self.Theme["colors"]["background_logo_color"] )

        local imgW, imgH = 350, 450
        surface.DrawTexturedRect( (self.frameW / 2) - (imgW / 2), (self.frameH / 2) - (imgH / 2) - 10, imgW, imgH )
    end


    local succ, err = pcall(self.DrawScreen, self)
    if not succ then
        print("Error from Supply Point Base Function related to device:", self )
        print(err)
    end
end

function ENT:GetPanelDrawPos(panel)
    local halfWidth = (self.frameW * self.PanelScale) * -0.5
    return panel.pos + (panel.ang:Forward() * halfWidth)
end

function ENT:DrawTranslucent()
    self:DrawModel()

    for _, panel in ipairs(self:GetVisibleSidePanels()) do
        local drawPos = self:GetPanelDrawPos(panel)
        if ui3d2d.startDraw(self:LocalToWorld(drawPos), self:LocalToWorldAngles(panel.ang), self.PanelScale, self) then
            self:DrawPanel()
            ui3d2d.endDraw()
        end
    end


    --render.DrawWireframeSphere( self:GetPos() + Vector(0,0,30), 50, 10, 10, Color( 255, 0, 0) , false)
end


function ENT:DrawScreen()
    local ent = self

    local RoomName = ent:GetDeviceName() or "ERR: No Name"

    draw.DrawText( RoomName, "SP_QuanticoHeader", ent.frameW / 2, -10, ent.Theme["colors"]["text_color"], TEXT_ALIGN_CENTER )

    local network = ent:GetNetworkTable()
    network = util.JSONToTable( network )

    -- if( !network ) then
    --     draw.DrawText( "Invalid Network ID", "SP_QuanticoRate", ent.frameW / 2, ent.frameH - 90, Color( 255, 0, 0, 96), TEXT_ALIGN_CENTER )
    -- end

    local networkID = "Invalid Network ID"
    if ( ent.GetNetworkID and isfunction(ent.GetNetworkID) ) then
        local netid = ent:GetNetworkID()
        if netid and netid ~= "0" then
            networkID = netid
        end
    end

    // Draw ID
    draw.DrawText( "Network ID: " .. networkID, "SP_QuanticoNormal", ent.frameW / 2, ent.frameH - 35, Color( 173, 173, 173, 33), TEXT_ALIGN_CENTER )

end
