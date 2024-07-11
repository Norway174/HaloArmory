AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halohealth_station"
 
ENT.PrintName = "Health Kit Station"
ENT.Category = "HALOARMORY - Covenant"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.BaseModel = "models/impulse/halo/props/covenant/military/cov_sword_holder.mdl"

ENT.SpawnPos = Vector( 0, 0, 0 )
ENT.SpawnAng = Angle( 90, -90, 90 )

// MEDKIT

ENT.MedKitClass = "halohealthkit_covie"

ENT.MedKitSpawnOffsetPos = Vector( 0, 0, 16 )
ENT.MedKitSpawnOffsetAng = Angle( 0, 0, 0 )


// CLIENT RENDER

ENT.PanelPos = Vector(-4, 6, 15)
ENT.PanelAng = Angle(0, 0, 0)

ENT.frameW, ENT.frameH = 299, 56

ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 62, 0, 87, 220),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(16, 51, 102),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}

if SERVER then

    function ENT:PreInit()
        self:UpdateVisuals( false )
    end
    
    function ENT:UpdateVisuals( IsSpawned )
        if IsSpawned then
            self:SetBodygroup( 1, 0 )
        else
            self:SetBodygroup( 1, 1 )
        end
    end

end