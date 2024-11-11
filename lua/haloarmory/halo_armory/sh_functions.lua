HALOARMORY.MsgC("Shared HALO ARMORY Loadout FUNCTIONS Loading.")

HALOARMORY.ARMORY = HALOARMORY.ARMORY or {}

local HALOARMORY_NETWORK_APPLYWEAPONNS = "HALOARMORY.NET.ApplyWeapons"

if SERVER then
    local nets = {
        "haloarmory_giveammo",
        "haloarmory_givearmor",
        "haloarmory_openloadout",
        HALOARMORY_NETWORK_APPLYWEAPONNS,
    }
    for _, net in pairs(nets) do
        util.AddNetworkString(net)
    end
end


function HALOARMORY.ARMORY.GetWeapons( ply )

    local listOfWeapons = {}
    local loadoutWeapons = {}
    local AdminWeapons = {}

    if DarkRP then
        table.Add(listOfWeapons, ply:getJobTable().weapons)
        table.Add(loadoutWeapons, ply:getJobTable().weapons)

        table.Add(listOfWeapons, GAMEMODE.Config.DefaultWeapons)
        table.Add(loadoutWeapons, GAMEMODE.Config.DefaultWeapons)

        if ply:IsAdmin() then
            table.Add(listOfWeapons, GAMEMODE.Config.AdminWeapons)
            table.Add(loadoutWeapons, GAMEMODE.Config.AdminWeapons)
            table.Add(AdminWeapons, GAMEMODE.Config.AdminWeapons)
        end
    else
        table.Add(listOfWeapons, {"weapon_physgun"} )
    end

    --PrintTable(listOfWeapons)


    regex = "Weapon %[[0-9]*%]%[(.*)%]"
    for k, v in pairs( ply:GetWeapons() ) do
        for s in string.gmatch(tostring(v), regex) do
            table.insert(listOfWeapons, s)
        end
    end

    // Call a hook to allow other addons to add weapons to the list
    local hooks = hook.GetTable()["HALOARMORY.ARMORY.GetWeapons"]
    for k, v in pairs( hooks or {}) do
        if isfunction(v) then
            local success, err = pcall(function()

                local weps, adminweps = v(ply)

                if weps and istable(weps) then
                    print("Adding weapons from hook", unpack(weps))
                    table.Add(listOfWeapons, weps)
                end
                if adminweps and istable(adminweps) then
                    print("Adding admin weapons from hook", unpack(adminweps))
                    table.Add(listOfWeapons, adminweps)
                    table.Add(AdminWeapons, adminweps)
                end
            end)
            
            if not success then
                ErrorNoHalt("Error in HALOARMORY.ARMORY.GetWeapons hook: ", err)
            end
        end
    end


    local return_list = {}
    for k, v in pairs(listOfWeapons) do
        return_list[v] = {
            ["equipped"] = false,
            ["loadout"] = false,
        }
        if ply:HasWeapon( v ) then
            return_list[v]["equipped"] = true
        end

        if table.HasValue(AdminWeapons, v) then
            return_list[v]["admin_only"] = true
        end

        if table.HasValue(loadoutWeapons, v) then
            return_list[v]["loadout"] = true
        end

        if HALOARMORY.ARMORY.WepOverrides[v] then
            return_list[v] = table.Merge(return_list[v], HALOARMORY.ARMORY.WepOverrides[v])
        end
    end

    return return_list
end



function HALOARMORY.ARMORY.ApplyWeapons( ply, listOfWeapons, noSave )

    if CLIENT then

        net.Start( HALOARMORY_NETWORK_APPLYWEAPONNS )
        local data = util.Compress(util.TableToJSON(listOfWeapons))
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
        net.SendToServer()
        

    elseif SERVER then

        local canAccess = HALOARMORY.ARMORY.GetWeapons( ply )

        MsgC( Color( 133, 206, 255), ply:Nick() .. " requested a loadout from the ARMORY:\n" )
    
        for key, weap in pairs(listOfWeapons) do
            if not canAccess[key] then
                MsgC( Color( 255, 216, 86), "[NO_ACCESS] " .. key .. "\t" )
                continue
            end

            --print( key, weap )
    
            if weap.equipped and canAccess[key] then
                MsgC( Color( 147, 255, 147), "[ADDED] " .. key .. "\t" )
                ply:Give(key)
            else
                MsgC( Color( 255, 86, 86), "[REMOVED] " .. key .. "\t" )
                ply:StripWeapon(key)
            end
        end
        MsgC( "\n" )

        if not noSave then
            HALOARMORY.ARMORY.PERSISTENCE.SaveWeapons( ply, listOfWeapons )
        end

    end


end

if SERVER then
    net.Receive( HALOARMORY_NETWORK_APPLYWEAPONNS, function( len, ply )
        local len2 = net.ReadUInt(32)
        local weaponsList = net.ReadData(len2) 
        weaponsList = util.JSONToTable(util.Decompress(weaponsList))

        -- print("Recived weapons:", ply:Nick() )
        -- PrintTable(weaponsList)

        HALOARMORY.ARMORY.ApplyWeapons( ply, weaponsList )
    end )

    net.Receive("haloarmory_giveammo", function(len, ply)
        --print("haloarmory_giveammo executed on the server")
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local ammo = ply:GetAmmoCount( wep:GetPrimaryAmmoType() )
            if ammo <= HALOARMORY.ARMORY.MaxAmmo then
                ply:SetAmmo( HALOARMORY.ARMORY.MaxAmmo, wep:GetPrimaryAmmoType(), true )
            end
        end
    end)
    
    net.Receive("haloarmory_givearmor", function(len, ply)
        --print("haloarmory_giveammo executed on the server")
        ply:SetArmor( ply:GetMaxArmor() )
    end)
end
