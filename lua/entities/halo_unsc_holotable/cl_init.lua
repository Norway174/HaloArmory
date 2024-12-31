include('shared.lua')

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
end

function ENT:DrawScreen()
    local w, h = self.frameW, self.frameH
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

function ENT:Initialize()
    self:PreInit()
end

function ENT:PreInit()
    // No need to initialize a radar anymore
end

// HOLOGRAMS
ENT.HoloModels = {}
ENT.DefaultHoloPos = Vector(-60, 0, 0)
ENT.DefaultHoloAng = Angle(0, 90, -90)
ENT.HoloMaterial = "ace/sw/holoproj"
ENT.HoloColor = Color(0, 242, 255, 198)

function ENT:UpdateHoloModel()
    for i = 1, 4 do
        local modelKey = "HoloModel" .. i

        local enabled = self["Get" .. modelKey .. "_Enable"](self)
        local modelPath = self["Get" .. modelKey .. "_Model"](self)
        
        if enabled and modelPath ~= "" then
            if not IsValid(self.HoloModels[i]) then
                self.HoloModels[i] = ClientsideModel(modelPath)
            end

            local posF = self["Get" .. modelKey .. "_PosF"](self)
            local posL = self["Get" .. modelKey .. "_PosL"](self)
            local posU = self["Get" .. modelKey .. "_PosU"](self)
            local ang = self["Get" .. modelKey .. "_Ang"](self)
            local scale = self["Get" .. modelKey .. "_Scale"](self)

            local hologram = self.HoloModels[i]
            local offsetPos = Vector(posU, posF, posL)
            hologram:SetPos(self:LocalToWorld(self.DefaultHoloPos + offsetPos))
            hologram:SetAngles(self:LocalToWorldAngles(self.DefaultHoloAng + Angle(ang, 0, 0)))
            hologram:SetModelScale(scale * .01, 0)

            hologram:DrawModel()

            if self["Get" .. modelKey .. "_Hologram"](self) then
                hologram:SetMaterial(self.HoloMaterial)
                hologram:SetColor(self.HoloColor)
            else
                hologram:SetMaterial("")
                hologram:SetColor(Color(255, 255, 255, 255))
            end
        else
            if IsValid(self.HoloModels[i]) then
                self.HoloModels[i]:Remove()
                self.HoloModels[i] = nil
            end
        end
    end
end


function ENT:Think()
    self:UpdateHoloModel()
    self:NextThink(CurTime() + 30 )
    return true
end

function ENT:OnRemove()
    for i = 1, 4 do
        if IsValid(self.HoloModels[i]) then
            self.HoloModels[i]:Remove()
        end
    end
end
