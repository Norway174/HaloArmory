
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Health Kit Station"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.BaseModel = "models/valk/halo3odst/unsc/props/civilian/health_pack_mount.mdl"

ENT.SpawnPos = Vector( 0, 0, 0 )
ENT.SpawnAng = Angle( 90, 180, 0 )

// MEDKIT

ENT.MedKitClass = "halohealthkit"

ENT.MedKitSpawnOffsetPos = Vector( 4, 0, -7 )
ENT.MedKitSpawnOffsetAng = Angle( 0, 0, 0 )


// CLIENT RENDER

ENT.PanelPos = Vector( 6.51, -4.1, 9.81 )
ENT.PanelAng = Angle( 0, 90, 90 )

ENT.frameW, ENT.frameH = 299, 56

ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 161, 0, 0, 0),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(16, 51, 102),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}


function ENT:SetupDataTables()

    --self:NetworkVar( "Entity", 0, "DoorParent" )
    self:NetworkVar( "Int", 0, "State", { KeyName = "State", Edit = { type = "Combo", order = 1, values = {
        ["Can Spawn"] = 1,
        ["Regenerating"] = 2,
        ["Locked"] = 3,
    } } } )
    self:NetworkVar( "Int", 1, "RespawnTime", { KeyName = "RespawnTime", Edit = { type = "Int", order = 3, min = 0, max = 120 } } )

    if SERVER then
        self:SetState( 1 )
        self:SetRespawnTime( 5 )
    end

end