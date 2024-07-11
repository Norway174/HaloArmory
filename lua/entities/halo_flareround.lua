/*--------------------------------------------------
    *** Copyright (c) 2012-2023 by DrVrej, All rights reserved. ***
    No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
    without the prior written consent of the author, unless otherwise indicated for stand-alone materials.


    Source code from https://github.com/DrVrej/VJ-Base/blob/master/lua/entities/obj_vj_flareround.lua

    Used with permission from DrVrej.
    Modified by Norway174.
--------------------------------------------------*/
AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.PrintName		= "Flare Round"
ENT.Author 			= "DrVrej & Norway174"
ENT.Contact 		= "Norway174"
ENT.Information		= "Marks the area with a flare light."
ENT.Category		= "HALOARMORY - UNSC"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.IsHALOARMORY = true

ENT.Model = "models/valk/halo3/unsc/props/military/flare.mdl"
---------------------------------------------------------------------------------------------------------------------------------------------
if CLIENT then
    language.Add("obj_vj_flareround", "Flare Round")
    killicon.Add("obj_vj_flareround","HUD/killicons/default",Color(255,80,0,255))

    language.Add("#obj_vj_flareround", "Flare Round")
    killicon.Add("#obj_vj_flareround","HUD/killicons/default",Color(255,80,0,255))
    
    function ENT:Draw() self:DrawModel() end
end
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
if !SERVER then return end

ENT.IdleSound1 = Sound("weapons/flaregun/burn.wav")
ENT.TouchSound = Sound("weapons/hegrenade/he_bounce-1.wav")
ENT.TouchSoundv = 75
ENT.Decal = "Scorch"
ENT.AlreadyPaintedDeathDecal = false
ENT.Dead = false
ENT.FussTime = 10
ENT.NextTouchSound = 0
---------------------------------------------------------------------------------------------------------------------------------------------
local colorRed = Color(255, 0, 0)
local colorTrailRed = Color(155, 0, 0, 150)
--
function ENT:Initialize()
    if self:GetModel() == "models/error.mdl" then self:SetModel( self.Model ) end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetColor(colorRed)
    self:SetUseType(SIMPLE_USE)

    -- Physics Functions
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(true)
        phys:SetBuoyancyRatio(0)
    end

    -- Misc Functions
    //util.SpriteTrail(self, 0, Color(90,90,90,255), false, 10, 1, 3, 1/(15+1)*0.5, "trails/smoke.vmt")
    //ParticleEffectAttach("vj_rpg1_smoke", PATTACH_ABSORIGIN_FOLLOW, self, 0)
    //ParticleEffectAttach("vj_rpg2_smoke2", PATTACH_ABSORIGIN_FOLLOW, self, 0)
    util.SpriteTrail(self, 0, colorTrailRed, false, 1, 100, 5, 5 / ((2 + 10) * 0.5), "trails/smoke.vmt")

    local envFlare = ents.Create("env_flare")
    envFlare:SetPos(self:GetPos())
    envFlare:SetAngles(self:GetAngles())
    envFlare:SetParent(self)
    envFlare:SetKeyValue("Scale","5")
    envFlare:SetKeyValue("spawnflags","4")
    envFlare:Spawn()
    envFlare:SetColor(colorRed)

    self.CurrentIdleSound = CreateSound(self, self.IdleSound1)
    self.CurrentIdleSound:SetSoundLevel(60)
    self.CurrentIdleSound:PlayEx(1, 100)

    --[[
    local owner = self:GetOwner()
    if IsValid(owner) && owner.FlareAttackFussTime then
        timer.Simple(owner.FlareAttackFussTime, function() if IsValid(self) then self:DoDeath() end end)
    else
        timer.Simple(60, function() if IsValid(self) then self:DoDeath() end end)
    end
    ]]

    -- Make it drop after in the air for a while
    timer.Simple(2, function()
        if IsValid(self) then
            phys = self:GetPhysicsObject()
            if IsValid(phys) && phys:GetVelocity():Length() > 500 then
                phys:SetMass(0.005)
                timer.Simple(10, function()
                    if IsValid(self) then
                        phys:SetMass(5)
                    end
                end)
            end
        end
    end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Use(activator, caller)
    if IsValid(activator) && activator:IsPlayer() then
        activator:PickupObject(self)
    end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PhysicsCollide(data, physobj)
    local hitEnt = data.HitEntity
    if IsValid(hitEnt) && (hitEnt:IsNPC() or hitEnt:IsPlayer()) then
        //hitEnt:Ignite(1)
        local dmg = DamageInfo()
        dmg:SetDamage(math.random(4, 8))
        dmg:SetDamageType(DMG_BURN)
        dmg:SetAttacker(self)
        dmg:SetInflictor(self)
        dmg:SetDamagePosition(data.HitPos)
        hitEnt:TakeDamageInfo(dmg, self)
    end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnTakeDamage(dmginfo)
    self:GetPhysicsObject():AddVelocity(dmginfo:GetDamageForce() * 0.1)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoDeath()
    self.Dead = true
    if self.CurrentIdleSound then self.CurrentIdleSound:Stop() end
    self:StopParticles()
    
    timer.Simple(2, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnRemove()
    self.Dead = true
    if self.CurrentIdleSound then self.CurrentIdleSound:Stop() end
end