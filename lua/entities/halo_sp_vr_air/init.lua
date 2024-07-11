
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


ENT.lights = {}



function ENT:PostInit()

    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

    self:DrawShadow( false )


    self:CreateLights()
end


function ENT:CreateLights()
    for i, light in pairs(self.lights) do
        if IsValid(light) then
            light:Remove()
        end
    end

    local Segments = self:GetSegments()
    local Radius = self:GetRadius()

    for i = 1, Segments do
        local light = ents.Create("gmod_light")

        // Spawn in a circle around self, in the given radius
        local angle = (i-1) * (360/Segments)
        local x = Radius * math.cos(math.rad(angle))
        local y = Radius * math.sin(math.rad(angle))

        light:SetPos(self:GetPos() + Vector(x, y, 0))
        light:SetParent(self)
        light:Spawn()

        self.lights[i] = light

        self:DeleteOnRemove(light)

        --light:SetModel("models/m_anm.mdl")
        light:SetRenderMode(RENDERMODE_TRANSCOLOR)

        light:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

    end

    --timer.Simple(0.1, function() self:UpdateLights() end)
    self:UpdateLights()
end


function ENT:UpdateLights()
    for i, light in pairs(self.lights) do

        if !IsValid(light) then
            self.lights[i] = nil
            continue
        end

        // Set the color
        local LightColor = self:GetLightColor():ToColor() //or Color(18, 39, 133, 102)
        --print(HeaderColor:Unpack())
        LightColor.a = 1
        light:SetColor( LightColor )

        // Set the brightness
        light:SetBrightness( self:GetLightBrightness() )

        // Set the radius
        light:SetLightSize( self:GetLightSize() )

        // Set the light world
        light:SetLightWorld( !self:GetLightWorld() )

        // Set the light model
        light:SetLightModels( !self:GetLightModel() )

        // Set the light on
        light:SetOn( self:GetLightOn() )
        
    end
end


function ENT:AirPadThink()


    if not self:GetLightAutoChange() then return end


    if IsValid( self:GetOnPad() ) then
        self:SetLightColor( Color( 255, 0, 0):ToVector() )
    else 
        self:SetLightColor( Color( 0, 255, 0):ToVector() )
    end

end


