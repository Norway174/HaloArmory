include('shared.lua')

// Global render target for the minimap
ENT.GLOBAL_MINIMAP_RT = false

// Create a material for the render target
ENT.GLOBAL_MINIMAP_MATERIAL = false

// No-draw function to disable certain render elements during capture
local function NoDrawFunc() return true end

ENT.MINIMAP_RT = nil
ENT.MINIMAP_MATERIAL = nil

// Function to capture the world and draw it onto the render target
function ENT:CaptureWorldToMinimap()
    if not self.MINIMAP_RT then return end
    if not self.MINIMAP_MATERIAL then return end

    // Get the actual map center
    local theWorld = game.GetWorld()
    if not theWorld then
        return
    end
    local mapMins, mapMaxs = theWorld:GetModelBounds()
    local mapCenter = self:GetPos()  //Vector((mapMins.x + mapMaxs.x) / 2, (mapMins.y + mapMaxs.y) / 2, 0)
    local mapHeight = 2000

    //print( -mapMaxs.y * .5, mapMins.x * .5, mapMaxs.x * .5, -mapMins.y * .5 )

    // Temporarily disable specific rendering features
    hook.Add("PreDrawSkyBox", self.HookId, NoDrawFunc)
    hook.Add("PrePlayerDraw", self.HookId, NoDrawFunc)
    hook.Add("PreDrawViewModel", self.HookId, NoDrawFunc)

    local ort = 0.25

    // Capture view settings
    local captureView = {
        origin = mapCenter + Vector(0, 0, mapHeight), // Position above the map
        angles = Angle(90, 0, 0),   // Looking straight down
        x = 0,
        y = 0,
        w = 1024,
        h = 1024,
        znear = 10,
        zfar = 10000,
        drawhud = false,
        drawmonitors = false,
        drawviewmodel = false,
        dopostprocess = false,
        ortho = {
            top = -mapMaxs.y * ort,
            left = mapMins.x * ort,
            right = mapMaxs.x * ort,
            bottom = -mapMins.y * ort
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

    self.MINIMAP_MATERIAL:SetInt( "$flags", 16 )
	self.MINIMAP_MATERIAL:SetInt( "$model", 1 )
	self.MINIMAP_MATERIAL:SetTexture( "$basetexture", self.MINIMAP_RT )

    // Restore rendering features
    hook.Remove("PreDrawSkyBox", self.HookId)
    hook.Remove("PrePlayerDraw", self.HookId)
    hook.Remove("PreDrawViewModel", self.HookId)
end

// Periodically update the minimap render target
-- timer.Create("UpdateGlobalMinimap", 5, 0, function()
--     --CaptureWorldToMinimap()
-- end)


local Error_StopDraw = false
function ENT:Draw()
    self:DrawModel()

    Error_StopDraw = true
    for k, v in pairs(self.ScreenModels) do
        if v["model"] == self:GetModel() then
            self.Model = k
            Error_StopDraw = false
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
    
        if isfunction(model_table["draw_bg"]) then
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

    self:UpdateHoloModel()
end

function ENT:DrawScreen()
    local w, h = self.frameW, self.frameH

    // Draw Minimap
    if self:GetDrawMap() then

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

function ENT:PreInit()
    // No need to initialize a radar anymore
    // Render target for the minimap
    self.MINIMAP_RT = GetRenderTarget("MinimapRT_" .. self:EntIndex(), ScrW(), ScrH())

    // Create a material for the render target
    self.MINIMAP_MATERIAL = CreateMaterial("MinimapMaterial_" .. self:EntIndex(), "UnlitGeneric", {
        ["$basetexture"] = "concrete/concrete_sidewalk001b",
        ["$ignorez"] = "1",
        ["$translucent"] = "1" 
    })

    // Create unique hook ID
    self.HookId = "MinimapCapture_" .. tostring(self:EntIndex())
end

function ENT:UpdateHoloModel()
    // Empty the function
end

function ENT:Think()
    self:CaptureWorldToMinimap()

    self:SetNextClientThink(CurTime() + 1 )
    return true
end


function ENT:OnRemove()
    hook.Remove("PreDrawSkyBox", self.HookId)
    hook.Remove("PrePlayerDraw", self.HookId)
    hook.Remove("PreDrawViewModel", self.HookId)
end
