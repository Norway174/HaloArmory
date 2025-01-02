
local mapSpesifics = {
    ["gm_construct"] = {
        ["offset"] = Vector(-2000, 1000, 0),
        ["height"] = -.91,
        ["zoom"] = 0.15
    }
}

local function getMapDetails( variable, fallback )
    return mapSpesifics[game.GetMap()] and mapSpesifics[game.GetMap()][variable] or fallback
end

// No-draw function to disable certain render elements during capture
local function NoDrawFunc() return true end

ENT.MINIMAP_RT = nil
ENT.MINIMAP_MATERIAL = nil
ENT.HookId = nil

function ENT:InitRTRender()
    // Create a render target for the minimap
    if not self.MINIMAP_RT then
        self.MINIMAP_RT = GetRenderTarget("MinimapRT_" .. tostring(self:EntIndex()), 2048, 1024)
    end

    // Create a material for the render target
    if not self.MINIMAP_MATERIAL then
        self.MINIMAP_MATERIAL = CreateMaterial("MinimapMaterial_" .. tostring(self:EntIndex()), "UnlitGeneric", {
            ["$basetexture"] = "concrete/concrete_sidewalk001b",
            ["$ignorez"] = "1",
            ["$translucent"] = "1",
        })
    end

    // Create unique hook ID
    self.HookId = "MinimapCapture_" .. tostring(self:EntIndex())
end

// Function to capture the world and draw it onto the render target
function ENT:CaptureWorldToMinimap()

    if not self.MINIMAP_RT or not self.MINIMAP_MATERIAL or not self.HookId then 
        self:InitRTRender()
        return
    end

    // Get the actual map center
    local theWorld = game.GetWorld()
    if not theWorld then
        return
    end

    // Temporarily disable specific rendering features
    local function cleanupHooks()
        hook.Remove("PreDrawSkyBox", self.HookId)
        hook.Remove("PrePlayerDraw", self.HookId)
        hook.Remove("PreDrawViewModel", self.HookId)
    end

    hook.Add("PreDrawSkyBox", self.HookId, NoDrawFunc)
    hook.Add("PrePlayerDraw", self.HookId, NoDrawFunc)
    hook.Add("PreDrawViewModel", self.HookId, NoDrawFunc)

    local mapMins, mapMaxs = theWorld:GetModelBounds()
    local mapCenter = (mapMins + mapMaxs) * 1 + getMapDetails( "offset", Vector(0, 0, 0))
    local mapHeight = math.max(mapMaxs.z, mapMins.z) * getMapDetails( "height", 2)

    local ort = mapMins:Distance( mapMaxs ) * getMapDetails( "zoom", .35) // Adjusted to show the whole map

    -- Calculate the view angle
    local entityYaw = self:GetAngles().yaw + 90
    local ViewAngle = -angle_zero:Up():Angle() + self:GetAngles():Right():Angle()

    -- Capture view settings
    local captureView = {
        origin = mapCenter + Vector(0, 0, mapHeight), -- Position above the map center
        angles = ViewAngle,
        x = 0,
        y = 0,
        w = 2048,
        h = 1024,
        znear = 1,
        zfar = 32768,
        drawhud = false,
        drawmonitors = false,
        drawviewmodel = false,
        dopostprocess = false,
        viewid = 2,
        -- ortho = {
        -- 	top = -mapMaxs.y * ort,
        -- 	left = mapMins.x * ort,
        -- 	right = mapMaxs.x * ort,
        -- 	bottom = -mapMins.y * ort
        -- }
        ortho = {
            top = -ort,
            left = -ort,
            right = ort,
            bottom = ort
        }
    }


    // Render to the minimap texture
    render.PushRenderTarget(self.MINIMAP_RT)
    render.Clear(0, 0, 0, 255, true, true)

    render.SetLightingMode(1) // Disable dynamic lighting for performance

    cam.Start2D()
        render.RenderView(captureView)
    cam.End2D()

    render.SetLightingMode(0)
    render.PopRenderTarget()

    self.MINIMAP_MATERIAL:SetTexture("$basetexture", self.MINIMAP_RT)

    // Restore rendering features
    cleanupHooks()
end


function ENT:Draw()
    self:DrawModel()

    for k, v in pairs(self.ScreenModels) do
        if v["model"] == self:GetModel() then
            self.Model = k
            break
        end
    end

    local model_table = self.ScreenModels[self.Model]
    if not istable(model_table) then return end
    if isstring(model_table["background"]) then
        model_table["background"] = Material(model_table["background"], "smooth")
    end

    if not ui3d2d.startDraw(self:LocalToWorld(model_table["pos"]), self:LocalToWorldAngles(model_table["ang"]), model_table["scale"], self) then return end

        self.frameW = model_table["frameW"]
        self.frameH = model_table["frameH"]
    
        if isfunction(model_table["draw_bg"]) and not self:GetDrawMap() then
            model_table["draw_bg"](self, model_table["background"])
        else
            surface.SetDrawColor(Color(0, 0, 0, 79))
            surface.DrawRect(0, 0, self.frameW, self.frameH)
        end

        local succ, err = pcall(self.DrawScreen, self)
        if not succ then
            print("Error from Supply Point Base Function related to device:", self)
            print(err)
        end

        self:DrawCursor(ui3d2d)

    ui3d2d.endDraw()

end

local last_capture = 0
function ENT:DrawScreen()
    local w, h = self.frameW, self.frameH

    // Draw Minimap
    if self:GetDrawMap() then
        if last_capture < CurTime() then
            timer.Simple(0, function()
                if IsValid(self) then
                    self:CaptureWorldToMinimap()
                end
            end)
            last_capture = CurTime() + 1
            --return
        end

        if not self.MINIMAP_RT then return end
        if not self.MINIMAP_MATERIAL then return end

        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self.MINIMAP_MATERIAL)

        surface.DrawTexturedRect(0, 0, w, h)
    end
end

ENT.DrawCursor = false
ENT.CursorIcon = Material("icon16/bullet_white.png")
function ENT:DrawCursor(ui)
    if self.DrawCursor then return end

    if not ui then return end

    local mouseX, mouseY = ui.getCursorPos()
    local cursor_size = 16

    if not mouseX or not mouseY then return end
    if not ui.isHovering(0, 0, self.frameW, self.frameH) then return end

    surface.SetDrawColor(Color(255, 255, 255))
    surface.SetMaterial(self.CursorIcon)
    surface.DrawTexturedRect(mouseX - cursor_size / 2, mouseY - cursor_size / 2, cursor_size, cursor_size)
end
