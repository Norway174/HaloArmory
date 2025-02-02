
include('shared.lua')
include('cl_map.lua')

function ENT:Initialize()
    self:PreInit()
end

function ENT:PreInit()

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

            hologram.Think = function()
                if not IsValid(self) then
                    hologram:Remove()
                end
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
    //self:CaptureWorldToMinimap()
    self:UpdateHoloModel()

    self:SetNextClientThink(CurTime() + 1 )
    return true
end

function ENT:OnRemove()

    if self.HookId then
        hook.Remove("PreDrawSkyBox", self.HookId)
        hook.Remove("PrePlayerDraw", self.HookId)
        hook.Remove("PreDrawViewModel", self.HookId)
    end

    for i = 1, 4 do
        if IsValid(self.HoloModels[i]) then
            self.HoloModels[i]:Remove()
        end
    end
end
