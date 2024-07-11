
include('shared.lua')

local function GetAmmoForCurrentWeapon()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if ( !IsValid( wep ) ) then return -1 end
    if (wep:GetMaxClip1() == -1) then return -1 end
    if (wep:GetPrimaryAmmoType() == -1) then return -1 end
 
	return ply:GetAmmoCount( wep:GetPrimaryAmmoType() )
end

function ENT:DrawTranslucent()
    self:DrawModel()

    local ang = self:GetAngles()

    --Skip drawing if the player can't see the UI
    if not ui3d2d.startDraw(self:LocalToWorld(self.PanelPos), self:LocalToWorldAngles(self.PanelAng), self.PanelScale, self) then return end 

    -- Background
    surface.SetDrawColor(self.Theme.panel)

    local frameH = self.frameH
    if (!self.AllowLoadout) then
        frameH = self.frameH - self.loadoutH
    end

    surface.DrawRect(0, 0, self.frameW, frameH, self.Theme.panel)

    -- Title bar
    surface.DrawRect(0,0 , self.frameW, self.titleH)
    draw.SimpleText(self.titleText, "HaloArmory_32", self.frameW * .5, self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Give ammo button
    if (GetAmmoForCurrentWeapon() > -1 and GetAmmoForCurrentWeapon() < (HALOARMORY.ARMORY.MaxAmmo or 500)) then
        surface.SetDrawColor(self.Theme.btnColor)
        if ui3d2d.isHovering(0, self.ammoY, self.frameW, self.ammoH) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(self.Theme.btnClick)
                --print("Ammo is pressed")
                surface.PlaySound( "items/ammo_pickup.wav" )
                net.Start( "haloarmory_giveammo" )
                net.SendToServer()
            else
                surface.SetDrawColor(self.Theme.btnHover)
            end
        end
        surface.DrawRect(0, self.ammoY, self.frameW, self.ammoH)
        draw.SimpleText(self.btnAmmoText, "HaloArmory_24", self.frameW * .5, self.ammoY + self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        surface.SetDrawColor(self.Theme.btnDisabled)
        surface.DrawRect(0, self.ammoY, self.frameW, self.ammoH)
        draw.SimpleText(self.btnAmmoTextFull, "HaloArmory_24", self.frameW * .5, self.ammoY + self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    end

    -- Give Armor button
    if(LocalPlayer():Armor() < LocalPlayer():GetMaxArmor()) then
        surface.SetDrawColor(self.Theme.btnColor)
        if ui3d2d.isHovering(0, self.armorY, self.frameW, self.armorH) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(self.Theme.btnClick)
                --print("Armor is pressed")
                surface.PlaySound( "items/battery_pickup.wav" )
                net.Start( "haloarmory_givearmor" )
                net.SendToServer()
            else
                surface.SetDrawColor(self.Theme.btnHover)
            end
        end
        surface.DrawRect(0, self.armorY, self.frameW, self.armorH)
        draw.SimpleText(self.btnArmorText, "HaloArmory_24", self.frameW * .5, self.armorY + self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        surface.SetDrawColor(self.Theme.btnDisabled)
        surface.DrawRect(0, self.armorY, self.frameW, self.armorH)
        draw.SimpleText(self.btnArmorTextFull, "HaloArmory_24", self.frameW * .5, self.armorY + self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Open Loadout button
    if(self.AllowLoadout) then
        surface.SetDrawColor(self.Theme.btnColor)
        if ui3d2d.isHovering(0, self.loadoutY, self.frameW, self.loadoutH) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(self.Theme.btnClick)
                surface.PlaySound("garrysmod/ui_click.wav")
                HALOARMORY.ARMORY.Open()
            else
                surface.SetDrawColor(self.Theme.btnHover)
            end
        end
        surface.DrawRect(0, self.loadoutY, self.frameW, self.loadoutH)
        draw.SimpleText(self.btnLoadoutText, "HaloArmory_24", self.frameW * .5, self.loadoutY + self.titleH * .5, self.Theme.titleText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ui3d2d.endDraw() --Finish the UI render
end