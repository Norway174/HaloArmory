AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Screen Base"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.DeviceType = "generic_screen"

ENT.PanelPos = Vector(-2.5, 30.8, 21)
ENT.PanelAng = Angle(0, -90, 90)
ENT.PanelScale = .07

ENT.frameW, ENT.frameH = 946, 600

ENT.Model = "models/valk/halo3/unsc/props/military/monitor_sm.mdl"

ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 168, 168, 168 ),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}

if SERVER then
    function ENT:Initialize()

        self:SetModel(self.Model)

        self:SetColor(Color(37, 37, 37))

        self:SetSubMaterial(0, "model_color")
        self:SetSubMaterial(2, "null")

        -- Physics stuff
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        -- Init physics only on the server, so it doesn't mess up physgun beam
        if SERVER then
            self:PhysicsInit(SOLID_VPHYSICS)
        end

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false)
        end

        self:PreInit()
    end

    ENT.SpawnAngles = Angle(0,0,0)
    function ENT:SpawnFunction( ply, tr, ClassName )

        if ( !tr.Hit ) then return end
        
        local SpawnPos = tr.HitPos + tr.HitNormal
        local SpawnAng = ply:EyeAngles()
        
        local ent = ents.Create( ClassName )
    
        local SpawnOff = ent.SpawnAngles
        SpawnAng.p = 0
        SpawnAng.p = SpawnAng.p + SpawnOff.p
        SpawnAng.y = SpawnAng.y + SpawnOff.y
        SpawnAng.z = SpawnAng.z + SpawnOff.z
    
        ent:SetPos( SpawnPos )
        ent:SetAngles( SpawnAng )
        ent:Spawn()
        ent:Activate()
    
        return ent
    
    end
end

if CLIENT then
    function ENT:Draw()
        --render.SuppressEngineLighting(true)
        self:DrawModel()
        --render.SuppressEngineLighting(false)

        if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

            local succ, err = pcall(HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager, self)
            if not succ then
                print("Error from Supply Point Base Function related to device:", self )
                print(err)
            end

        ui3d2d.endDraw() --Finish the UI render
    end

    function ENT:Initialize()

        self:PreInit()
    end
end

function ENT:PreInit()
end