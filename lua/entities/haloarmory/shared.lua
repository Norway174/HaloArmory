
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Armory"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.Model = "models/ishi/halo_rebirth/props/human/ammo_box.mdl" -- Halo UNSC Prop Pack
ENT.Skin = 0
ENT.Bodygroups = {
    [1] = 1,
}

ENT.SpawnAngles = Angle(0,-90,0)

ENT.Theme = {
    panel = Color(0,0,0,200),
    titleText = Color(255,255,255,255),
    btnColor = Color(14,14,14),
    btnHover = Color(29,29,29),
    btnClick = Color(201,0,0,200),
    btnDisabled = Color(53,53,53),
}

ENT.PanelPos = Vector(-8, -15, 62)
ENT.PanelAng = Angle(0, 0, 75)
ENT.PanelScale = .1

ENT.frameW, ENT.frameH = 175, 200

ENT.yPadding = ENT.frameH * .02

ENT.titleText = "ARMORY"
ENT.titleH = ENT.frameH * .2

ENT.btnAmmoText = " /> Take Ammo"
ENT.btnAmmoTextFull = " /- Max Ammo"
ENT.ammoH = ENT.frameH * .2
ENT.ammoY = ENT.titleH + ENT.yPadding + 5

ENT.btnArmorText = " /> Take Armor"
ENT.btnArmorTextFull = " /- Max Armor"
ENT.armorH = ENT.frameH * .2
ENT.armorY = ENT.ammoY + ENT.titleH + ENT.yPadding

ENT.AllowLoadout = true

ENT.btnLoadoutText = " /> Loadout..."
ENT.btnLoadoutTextFull = " /- Loadout..."
ENT.loadoutH = ENT.frameH * .2
ENT.loadoutY = ENT.armorY + ENT.titleH + ENT.yPadding
