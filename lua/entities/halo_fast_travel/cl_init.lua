
include('shared.lua')

local CONSTS = {
    NETWORK = "HALOARMORY.FASTTRAVEL",
    ACTIONS = {
        TELEPORT = 1,
        SYNC = 2,
        SYNC_ALL = 3,
        REMOVE = 4,
    },
}

local Destinations = {}

net.Receive(CONSTS.NETWORK, function()
    local action = net.ReadUInt(8)


    if action == CONSTS.ACTIONS.SYNC_ALL then
        local count = net.ReadUInt(8)

        Destinations = {}

        for i = 1, count do
            local id = net.ReadUInt(13)
            local dest_tmp = {}

            dest_tmp.ID = id
            dest_tmp.Destination = net.ReadString()
            dest_tmp.Enabled = net.ReadBool()
            dest_tmp.Entity = net.ReadEntity()
            dest_tmp.Pos = net.ReadVector()

            Destinations[id] = dest_tmp
        end

    elseif action == CONSTS.ACTIONS.SYNC then
        local id = net.ReadUInt(13)

        Destinations[id] = {}

        Destinations[id].ID = id
        Destinations[id].Destination = net.ReadString()
        Destinations[id].Enabled = net.ReadBool()
        Destinations[id].Entity = net.ReadEntity()
        Destinations[id].Pos = net.ReadVector()

    elseif action == CONSTS.ACTIONS.REMOVE then
        local id = net.ReadUInt(13)

        Destinations[id] = nil
    end
end)


function ENT:Draw()
    --render.SuppressEngineLighting(true)
    self:DrawModel()
    --render.SuppressEngineLighting(false)

    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

        local succ, err = pcall(self.DrawScreen, self)
        if not succ then
            print("Error from Supply Point Base Function related to device:", self )
            print(err)
        end

    ui3d2d.endDraw() --Finish the UI render
end

local unsc_logo = Material( "vgui/character_creator/unsc_logo_white.png", "smooth" )

local EnabledDestinations = {}
ENT.Scrollbar = 1
ENT.RowHeight = 0

function ENT:DrawDestinationsList(x, y, w, h)
    -- Background
    surface.SetDrawColor(Color(0, 0, 0, 99))
    surface.DrawRect(x, y, w, h)

    -- Draw alternating rows
    local row_height = h * 0.2
    self.RowHeight = math.floor(h / row_height)

    for index = 0, math.floor(h / row_height) do
        local SetIndex = 1 + index + (self.Scrollbar - 1) * self.RowHeight
        if index % 2 == 0 then
            surface.SetDrawColor(Color(0, 0, 0, 99))
            surface.DrawRect(x, y + (index * row_height), w, row_height)
        end
    end

    -- Draw the contacts
    local start_index = 1 + (self.Scrollbar - 1) * (self.RowHeight + 1)

    for index = start_index, start_index + math.floor(h / row_height) - 0 do

        if not EnabledDestinations[index] then
            continue
        end

        -- if not IsValid(EnabledDestinations[index]) then
        --     continue
        -- end

        if EnabledDestinations[index].Enabled == false then
            continue
        end

        // Draw a hover box
        if ui3d2d.isHovering( x, y + ((index - start_index) * row_height), w, row_height ) then
            surface.SetDrawColor( Color( 0, 0, 0, 220) )

            if ui3d2d.isPressed() then
                surface.SetDrawColor( Color(7, 20, 41) )

                // TODO: Travel to destination
                //print( "Travel to destination: " .. EnabledDestinations[index]:GetDestination() )
                surface.PlaySound( "buttons/button24.wav" )

                net.Start( CONSTS.NETWORK )
                    net.WriteUInt( CONSTS.ACTIONS.TELEPORT, 8 )
                    net.WriteUInt( EnabledDestinations[index].ID, 13 )
                net.SendToServer()
            end

            surface.DrawRect( x, y + ((index - start_index) * row_height), w, row_height )
        end
        
        draw.SimpleText(index .. "", "SP_QuanticoNormal", x + 4, y + ((index - start_index) * row_height) + (row_height / 2), Color(88, 88, 88), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText(EnabledDestinations[index].Destination, "SP_QuanticoNormal", x + 15 + 20, y + ((index - start_index) * row_height) + (row_height / 2), Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Draw distance to Destination
        local distance = math.floor(EnabledDestinations[index].Pos:Distance(self:GetPos()) / 100) / 1
        draw.SimpleText(distance .. "m", "SP_QuanticoNormal", x + w - 4, y + ((index - start_index) * row_height) + (row_height / 2), Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    
    end
end



function ENT:DrawScreen()
    local ply = LocalPlayer()
    --if not IsValid(ent) then ui3d2d.endDraw() return end
    --if not IsValid(ply) and not ply:IsPlayer() then ply = LocalPlayer() end
    --if not IsValid(ply) and not ply:IsPlayer() then ui3d2d.endDraw() return end

    --if ent:GetPos():Distance( ply:GetPos() ) >= 700 then ui3d2d.endDraw() return end

    // Populate the list of enabled destinations
    EnabledDestinations = {}
    for k, v in pairs( Destinations ) do
        if v.Entity == self then continue end
        if v.Enabled then
            table.insert( EnabledDestinations, v )
        end
    end

    // Sort the destinations by distance
    table.sort( EnabledDestinations, function( a, b )
        local a_dist = a.Pos:Distance( self:GetPos() )
        local b_dist = b.Pos:Distance( self:GetPos() )

        if IsValid( a.Entity ) then
            a_dist = a.Entity:GetPos():Distance( self:GetPos() )
        end

        if IsValid( b.Entity ) then
            b_dist = b.Entity:GetPos():Distance( self:GetPos() )
        end

        return a_dist < b_dist
    end )

    surface.SetMaterial( unsc_logo )
    surface.SetDrawColor( Color( 0, 0, 0, 79) )
    surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( "TRAVEL", "SP_QuanticoHeader", self.frameW/2, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    if self:GetPos():Distance( ply:GetPos() ) >= 250 then return end

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, self.frameW - 40, 2 )


    // Draw an offline screen if the device is disabled
    if self:GetEnabled() == false then
        surface.SetDrawColor( Color( 0, 0, 0, 99) )
        surface.DrawRect( 20, 100, self.frameW - 40, self.frameH - 100 - 20 - 100 )

        draw.SimpleText( "OFFLINE", "SP_QuanticoHeader", self.frameW/2, self.frameH / 2, Color(141,31,31), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        return
    end

    // Draw You are here
    draw.SimpleText( "YOU ARE HERE:", "SP_QuanticoNormal", 20, 110, Color(99,99,99), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    surface.SetDrawColor( Color( 0, 0, 0, 166) )
    surface.DrawRect( 200, 110, self.frameW - 40 - 200, 35 )

    draw.SimpleText( self:GetDestination(), "SP_QuanticoNormal", 205, 110, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

    // Draw You are here
    -- surface.SetDrawColor( Color( 0, 0, 0, 166) )
    -- surface.DrawRect( 20, 110, self.frameW - 40, 35 )

    -- draw.SimpleText( self:GetDestination(), "SP_QuanticoNormal", self.frameW/2, 110, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    --Draw the destinations list
    self:DrawDestinationsList( 20, 152, self.frameW - 40, self.frameH - 100 - 20 - 152)

    local CurrentPage = self.Scrollbar
    local TotalPages = math.ceil(math.max(#EnabledDestinations - 1, 1) / self.RowHeight)

    // Draw scroll buttons
    local scroll_button_size = 75
    local scroll_button_spacing = 90
    local scroll_button_x = self.frameW / 2 - scroll_button_size - scroll_button_spacing / 2
    local scroll_button_y = self.frameH - scroll_button_size - 30
    local scroll_button_w = scroll_button_size
    local scroll_button_h = scroll_button_size

    local SoundToPlay = "buttons/button15.wav"

    // Draw left button
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    if ui3d2d.isHovering( scroll_button_x, scroll_button_y, scroll_button_w, scroll_button_h ) then
        if ui3d2d.isPressed() then
            surface.SetDrawColor( Color(7, 20, 41) )

            self.Scrollbar = math.Clamp(self.Scrollbar - 1, 1, math.max(TotalPages, 1))

            surface.PlaySound( SoundToPlay )
        else
            surface.SetDrawColor( Color(22, 53, 99) )
        end
    end
    
    surface.DrawRect( scroll_button_x, scroll_button_y, scroll_button_w, scroll_button_h )

    draw.SimpleText( "<", "SP_QuanticoNormal", scroll_button_x + (scroll_button_w / 2), scroll_button_y + (scroll_button_h / 2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    // Draw right button
    surface.SetDrawColor( Color( 0, 0, 0, 99) )
    if ui3d2d.isHovering( scroll_button_x + scroll_button_w + scroll_button_spacing, scroll_button_y, scroll_button_w, scroll_button_h ) then
        if ui3d2d.isPressed() then
            surface.SetDrawColor( Color(7, 20, 41) )

            self.Scrollbar = math.Clamp(self.Scrollbar + 1, 1, math.max(TotalPages, 1))

            surface.PlaySound( SoundToPlay )
        else
            surface.SetDrawColor( Color(22, 53, 99) )
        end
    end

    surface.DrawRect( scroll_button_x + scroll_button_w + scroll_button_spacing, scroll_button_y, scroll_button_w, scroll_button_h )

    draw.SimpleText( ">", "SP_QuanticoNormal", scroll_button_x + scroll_button_w + scroll_button_spacing + (scroll_button_w / 2), scroll_button_y + (scroll_button_h / 2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
    // Add a page number between the buttons, which looks like so: 1 / 2

    draw.SimpleText( CurrentPage .. " / " .. TotalPages, "SP_QuanticoNormal", scroll_button_x + scroll_button_w + scroll_button_spacing / 2, scroll_button_y + (scroll_button_h / 2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )


end


local function RequestSyncFromServer()
    net.Start(CONSTS.NETWORK)
    net.WriteUInt(CONSTS.ACTIONS.SYNC_ALL, 8)
    net.SendToServer()
end


hook.Add( "InitPostEntity", "HALOARMORY.FAST.TRAVEL", function()
    RequestSyncFromServer()
end )

// Request the destinations from the server
timer.Simple(0.1, function()
    RequestSyncFromServer()
end)