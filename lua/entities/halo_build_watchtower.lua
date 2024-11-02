AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Watchtower"
ENT.Category = "HALOARMORY - FOB"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Model = "models/valk/h3odst/unsc/props/watchtower/watchtower.mdl" // Halo UNSC Prop Pack - Halo 3 ODST


if SERVER then
    function ENT:Initialize()
        self:SetModel(self.Model)

        -- Physics stuff
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        -- Init physics only on server, so it doesn't mess up physgun beam
        if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end

        local phys = self:GetPhysicsObject()
        if ( IsValid( phys ) ) then
            phys:Wake()
            --phys:Sleep()
            phys:EnableMotion( false )
        end

        self:UpdateLadder(true)
    end

    function ENT:UpdateLadder(bCreate)
        if (bCreate) then
            local oldAngs = self:GetAngles()

            self:SetAngles(Angle(0, 0, 0))

            local pos = self:GetPos()
            local dist = 100
            local dismountDist = 10
            local bottom = self:LocalToWorld(Vector(dist, 0, 0))
            local top = self:LocalToWorld(Vector(dist, 0, 230))

            for k, v in pairs(self:GetChildren()) do
                SafeRemoveEntity(v)
            end

            self.ladder = ents.Create("func_useableladder")
            self.ladder:SetPos(pos + self:GetForward() * dist + self:GetUp() * 10)
            self.ladder:SetKeyValue("point0", tostring(bottom))
            self.ladder:SetKeyValue("point1", tostring(top))
            self.ladder:SetKeyValue("targetname", "zladder_" .. self:EntIndex())
            self.ladder:SetParent(self)
            self.ladder:Spawn()

            self.bottomDismount = ents.Create("info_ladder_dismount")
            self.bottomDismount:SetPos( self:LocalToWorld(Vector(117, 0, 12)))
            self.bottomDismount:SetKeyValue("laddername", "zladder_" .. self:EntIndex())
            self.bottomDismount:SetParent(self)
            self.bottomDismount:Spawn()

            self.topDismount = ents.Create("info_ladder_dismount")
            self.topDismount:SetPos( self:LocalToWorld(Vector(76, 0, 240)))
            self.topDismount:SetKeyValue("laddername", "zladder_" .. self:EntIndex())
            self.topDismount:SetParent(self)
            self.topDismount:Spawn()

            self.ladder:Activate()

            self:SetAngles(oldAngs)
        else
            self.ladder:Activate()
        end
    end

    function ENT:Think()
        if (IsValid(self.ladder)) then
            self:UpdateLadder()
            self:NextThink(CurTime() + 1)
            return true
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end