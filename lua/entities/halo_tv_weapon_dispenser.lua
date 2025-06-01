AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"

ENT.PrintName = "Weapon Dispenser"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true
ENT.DeviceType = "weapon_screen"
ENT.Editable = true
ENT.SelectedModel = 1

function ENT:SetupDataTables()
    for i = 1, 4 do
        self:NetworkVar("String", i - 1, "WeaponClass" .. i, { KeyName = "Weapon Class " .. i, Edit = { type = "String", order = i * 3 - 2, category = "Weapon #" .. i } })
        self:NetworkVar("Int", i * 2 - 2, "AmmoPri" .. i, { KeyName = "Give Primary Ammo " .. i, Edit = { type = "Int", order = i * 3 - 1, category = "Weapon #" .. i } })
        self:NetworkVar("Int", i * 2 - 1, "AmmoSec" .. i, { KeyName = "Give Secondary Ammo " .. i, Edit = { type = "Int", order = i * 3, category = "Weapon #" .. i } })
    end
    
    if SERVER then
        for i = 1, 4 do
            self["SetWeaponClass" .. i](self, "")
            self["SetAmmoPri" .. i](self, 0)
            self["SetAmmoSec" .. i](self, 0)
        end
    end

    if CLIENT then
        for i = 1, 4 do
            self:NetworkVarNotify("WeaponClass" .. i, self.WeaponClassChanged)
        end
    end
end

if SERVER then
    concommand.Add("halo_tv_weapon_dispenser_addremoveweapon", function(ply, cmd, args)
        // Check if the player is looking at a weapon dispenser
        local ent = ply:GetEyeTrace().Entity
        if not IsValid(ent) or not ent.IsHALOARMORY or ent.DeviceType ~= "weapon_screen" then return end

        // Check if the player is closer than 200 units
        if ply:GetPos():DistToSqr(ent:GetPos()) > 200 * 200 then return end

        // Check if the weapon index is valid
        local weapon_index = tonumber(args[1])
        if not weapon_index or weapon_index < 1 or weapon_index > 4 then return end

        // Then, add or remove the weapon
        local weapon_class = ent["GetWeaponClass" .. weapon_index](ent)
        local has_wep = ply:HasWeapon(weapon_class)

        if has_wep then
            if ply:GetActiveWeapon():GetClass() == weapon_class then
                ply:SwitchToDefaultWeapon()
            end
            ply:StripWeapon(weapon_class)

            local name = ply:GetWeapon( weapon_class ).PrintName or weapon_class
            ply:SendLua("notification.AddLegacy('You have dropped " .. name .. "', NOTIFY_ERROR, 5)")

        else
            local ammo_pri = ent["GetAmmoPri" .. weapon_index](ent)
            local ammo_sec = ent["GetAmmoSec" .. weapon_index](ent)
            ply:Give(weapon_class)
            ply:SelectWeapon(weapon_class)

            local name = ply:GetWeapon( weapon_class ).PrintName or weapon_class
            ply:SendLua("notification.AddLegacy('You have received " .. name .. "', NOTIFY_GENERIC, 5)")

            if ammo_pri > 0 then
                ply:GiveAmmo(ammo_pri, weapons.Get(weapon_class).Primary.Ammo)
            end

            if ammo_sec > 0 then
                ply:GiveAmmo(ammo_sec, weapons.Get(weapon_class).Secondary.Ammo)
            end
        end
    end)
end

if CLIENT then
    function ENT:Think()
        -- Future client-side functionality goes here.
    end

    ENT.weapon_cache = {}

    function ENT:WeaponClassChanged(varName, old, new)
        -- Clear the cache for this weapon slot
        local slot = 0
        for i = 1, 4 do
            if self["GetWeaponClass" .. i](self) == old then
                slot = i
                break
            end
        end
        self.weapon_cache[slot] = nil

        -- Cache the new weapon data
        if new and new ~= "" then
            local weapon_table = weapons.Get(new)
            if weapon_table then
                self.weapon_cache[slot] = {
                    class = new,
                    printname = weapon_table.PrintName or "Unknown Weapon",
                    material = nil -- Will be set when needed
                }
            elseif file.Exists("scripts/weapons/" .. new .. ".txt", "GAME") then
                local wep_file = file.Read("scripts/weapons/" .. new .. ".txt", "GAME")
                local printname = string.match(wep_file, '"printname"		"(.-)"')
                
                if printname then
                    self.weapon_cache[slot] = {
                        class = new,
                        printname = printname,
                        material = nil -- Will be set when needed
                    }
                end
            end
        end
    end

    local placeHolderMat = Material("weapons/swep")

    function ENT:DrawWeaponInfo(x, y, weapon_data)
        if not weapon_data then return end

        local boxW, boxH = 250, 200
        local boxX, boxY = x - boxW / 2, y - boxH / 2
        
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(boxX, boxY, boxW, boxH)

        // Draw a slightly different colored box if the player has the weapon
        if LocalPlayer():HasWeapon(weapon_data.class) then
            surface.SetDrawColor(22, 68, 22)
            surface.DrawRect(boxX, boxY, boxW, boxH)
        end


        // Get the weapon's icon
        if not weapon_data.material then
            local path = "entities/" .. weapon_data.class .. ".png"
            if file.Exists("materials/" .. path, "GAME") then
                weapon_data.material = Material(path)
            elseif weapons.Get(weapon_data.class) and weapons.Get(weapon_data.class).Icon then
                weapon_data.material = Material(weapons.Get(weapon_data.class).Icon)
            else
                weapon_data.material = placeHolderMat
            end
        end

        // Use "weapons/swep" as a placeholder
        local iconW, iconH = 128, 128
        local iconX, iconY = x - iconW / 2, boxY + 50
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(weapon_data.material)
        surface.DrawTexturedRect(iconX, iconY, iconW, iconH)

        // Hovering & Clicking
        if ui3d2d.isHovering(boxX, boxY, boxW, boxH) then --Check if the box is being hovered
            if ui3d2d.isPressed() then --Check if input is being held
                surface.SetDrawColor(50, 50, 50, 200)
                surface.DrawRect(boxX, boxY, boxW, boxH)

                // Don't send the weapon class, instead, send the index of the weapon
                local weapon_index = 0
                for i = 1, 4 do
                    if self["GetWeaponClass" .. i](self) == weapon_data.class then
                        weapon_index = i
                        break
                    end
                end
                RunConsoleCommand("halo_tv_weapon_dispenser_addremoveweapon", weapon_index)
    
            else
                surface.SetDrawColor(43, 43, 43, 200)
                surface.DrawRect(boxX, boxY, boxW, boxH)
            end
        end
        
        // Draw the title
        draw.SimpleText(weapon_data.printname, "HudHintTextLarge", x, boxY + 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    function ENT:DrawScreen()
        local model_table = self.ScreenModels[self.Model]
        self.frameW = model_table.frameW
        self.frameH = model_table.frameH
        
        draw.SimpleText("Weapons", "SP_QuanticoHeader", self.frameW * 0.5, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        surface.SetDrawColor(Color(255, 255, 255, 42))
        surface.DrawRect(20, 100, self.frameW - 40, 2)

        local positions = {
            [1] = { {0.5, 0.5} },
            [2] = { {0.35, 0.5}, {0.65, 0.5} },
            [3] = { {0.5, 0.35}, {0.35, 0.72}, {0.65, 0.72} },
            [4] = { {0.35, 0.35}, {0.65, 0.35}, {0.35, 0.72}, {0.65, 0.72} }
        }

        for i, pos in ipairs(positions[table.Count(self.weapon_cache)] or {}) do
            self:DrawWeaponInfo(self.frameW * pos[1], self.frameH * pos[2], self.weapon_cache[i])
        end

        if table.Count(self.weapon_cache) == 0 then
            draw.SimpleText("// OFFLINE //", "SP_QuanticoHeader", self.frameW * 0.5, self.frameH * 0.5, Color(107, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            if LocalPlayer():IsAdmin() then
                draw.SimpleText("This weapon dispenser is unconfigured. Edit it's properties to configure", "HudHintTextLarge", self.frameW * 0.5, self.frameH * 0.9, Color(109, 109, 109), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end
