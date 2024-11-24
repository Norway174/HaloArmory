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
        model_table["background"] = Material( model_table["background"], "smooth" )
    end

    if not ui3d2d.startDraw(self:LocalToWorld(model_table["pos"]), self:LocalToWorldAngles(model_table["ang"]), model_table["scale"], self) then return end

        self.frameW = model_table["frameW"]
        self.frameH = model_table["frameH"]
    
        if isfunction( model_table["draw_bg"] ) then
            model_table["draw_bg"]( self, model_table["background"] )
        else
            surface.SetDrawColor( Color( 0, 0, 0, 79) )
            surface.DrawRect( 0, 0, self.frameW, self.frameH )
        end

        local succ, err = pcall(self.DrawScreen, self) --Call the draw function
        if not succ then
            print("Error from Supply Point Base Function related to device:", self )
            print(err)
        end

        self:DrawCursor( ui3d2d )

    ui3d2d.endDraw() --Finish the UI render

    self:UpdateHoloModel()
end

function ENT:DrawScreen()
    // Draw Custom screens here
end

ENT.DrawCursor = false
//ENT.CursorIcon = Material("icon16/cursor.png")
ENT.CursorIcon = Material("icon16/bullet_white.png")
function ENT:DrawCursor( ui )
    if self.DrawCursor then return end

    if not ui then return end

    local mouseX, mouseY = ui.getCursorPos()
    local cursor_size = 16

    if not mouseX or not mouseY then return end
    if not ui.isHovering(0, 0, self.frameW, self.frameH) then return end

    surface.SetDrawColor( Color( 255, 255, 255) )
    surface.SetMaterial( self.CursorIcon )
    surface.DrawTexturedRect( mouseX - cursor_size / 2, mouseY - cursor_size / 2, cursor_size, cursor_size )
end

function ENT:Initialize()
    self:PreInit()
end

function ENT:PreInit()
end


ENT.HoloModels = {} -- Initialize a table for hologram models
ENT.DefaultHoloPos = Vector(-60, 0, 0)
ENT.DefaultHoloAng = Angle(0, 90, -90)

ENT.HoloMaterial = "ace/sw/holoproj"
ENT.HoloColor = Color(0, 242, 255, 198)

function ENT:UpdateHoloModel()
    for i = 1, 4 do
        local modelKey = "HoloModel" .. i

        -- Check if the hologram is enabled
        local enabled = self["Get" .. modelKey .. "_Enable"](self)
        local modelPath = self["Get" .. modelKey .. "_Model"](self)
        
        if enabled and modelPath ~= "" then
            -- Create the model if it doesn't exist
            if not IsValid(self.HoloModels[i]) then
                self.HoloModels[i] = ClientsideModel(modelPath)
                --self.HoloModels[i]:SetNoDraw(true)

                
            end

            -- Update position, angle, and scale based on NetworkVars
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

            -- Draw the hologram
            hologram:DrawModel()

            -- Set the material and color
            if self["Get" .. modelKey .. "_Hologram"](self) then
                hologram:SetMaterial(self.HoloMaterial)
                hologram:SetColor(self.HoloColor)
            else
                hologram:SetMaterial("")
                hologram:SetColor(Color(255, 255, 255, 255))
            end
        else
            -- Remove the model if it exists but shouldn't be enabled
            if IsValid(self.HoloModels[i]) then
                self.HoloModels[i]:Remove()
                self.HoloModels[i] = nil
            end
        end
    end
end


--[[ 
function ENT:UpdateHoloModel()
    for i = 1, 4 do
        local modelKey = "HoloModel" .. i

        -- Ensure the model exists in the table or create it if necessary
        if not IsValid(self.HoloModels[i]) then
            local modelPath = self["Get" .. modelKey .. "_Model"](self) -- Get the current model path
            if modelPath ~= "" then
                self.HoloModels[i] = ClientsideModel(modelPath)
                if IsValid(self.HoloModels[i]) then
                    --self.HoloModels[i]:SetNoDraw(true) -- Prevent drawing until explicitly enabled
                end
            end
        end

        -- Handle specific variable updates
        if name == modelKey .. "_Enable" then
            if new then
                if IsValid(self.HoloModels[i]) then
                    self.HoloModels[i]:SetNoDraw(false) -- Enable drawing
                end
            else
                if IsValid(self.HoloModels[i]) then
                    self.HoloModels[i]:SetNoDraw(true) -- Disable drawing
                end
            end

        elseif name == modelKey .. "_Model" then
            if not IsValid(self.HoloModels[i]) and new ~= "" then
                self.HoloModels[i] = ClientsideModel(new)
                if IsValid(self.HoloModels[i]) then
                    self.HoloModels[i]:SetParent(self)
                    --self.HoloModels[i]:SetNoDraw(true)
                end
            elseif IsValid(self.HoloModels[i]) then
                self.HoloModels[i]:SetModel(new)
            end

        elseif string.StartsWith(name, modelKey .. "_Pos") then
            if IsValid(self.HoloModels[i]) then
                local pos = self.DefaultHoloPos 
                + Vector(self["Get" .. modelKey .. "_PosF"](self), 
                    self["Get" .. modelKey .. "_PosL"](self), 
                    self["Get" .. modelKey .. "_PosU"](self))
                print("UpdatePos",pos)
                self.HoloModels[i]:SetPos(self:LocalToWorld(pos))
            end

        elseif name == modelKey .. "_Ang" then
            if IsValid(self.HoloModels[i]) then
                local ang = Angle(0, self["Get" .. modelKey .. "_Ang"](self), 0)
                self.HoloModels[i]:SetAngles(self:LocalToWorldAngles(ang))
            end

        elseif name == modelKey .. "_Scale" then
            if IsValid(self.HoloModels[i]) then
                self.HoloModels[i]:SetModelScale(new, 0) -- Update the scale with instant transition
            end
        end
    end
end
 ]]

function ENT:OnRemove()
    for i = 1, 4 do
        if IsValid(self.HoloModels[i]) then
            self.HoloModels[i]:Remove()
        end
    end
end