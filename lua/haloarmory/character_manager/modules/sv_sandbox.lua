HALOARMORY.MsgC("Server CHARACTHER PERSISTENCE Sandbox Module Loading.")

// SANDBOX SAVE DATA
local function SaveDefaultStats( ply, data )
    
    local DataToSave = {}

    // Default Stats
    DataToSave["health"] = ply:Alive() && ply:Health() or ply:GetMaxHealth()
    DataToSave["max_health"] = ply:GetMaxHealth()
    DataToSave["armor"] = ply:Alive() && ply:Armor() or ply:GetMaxArmor()
    DataToSave["max_armor"] = ply:GetMaxArmor()

    // Model
    DataToSave["model"] = ply:GetModel()
    DataToSave["model_scale"] = ply:GetModelScale()
    DataToSave["skin"] = ply:GetSkin()
    
    DataToSave["bodygroups"] = {}
    for i = 0, ply:GetNumBodyGroups() - 1 do
        DataToSave["bodygroups"][ply:GetBodygroupName(i)] = ply:GetBodygroup(i)
    end

    // Weapons
    DataToSave["weapons"] = {}
    for k, v in pairs(ply:GetWeapons()) do
        table.insert(DataToSave["weapons"], v:GetClass())
    end
    DataToSave["ammo"] = ply:GetAmmo()

    // Position
    if ply:Alive() && (ply:GetMoveType() == MOVETYPE_WALK) then
        DataToSave["pos"] = ply:GetPos()
        DataToSave["ang"] = ply:EyeAngles()
    end
    DataToSave["last_map"] = game.GetMap() // This is used to check if the player is on the same map when they load their character

    // Speed
    DataToSave["speed"] = DataToSave["speed"] or {}
    DataToSave["speed"]["max_speed"] = ply:GetMaxSpeed()
    DataToSave["speed"]["walk_speed"] = ply:GetWalkSpeed()
    DataToSave["speed"]["slow_walk_speed"] = ply:GetSlowWalkSpeed()
    DataToSave["speed"]["run_speed"] = ply:GetRunSpeed()
    DataToSave["speed"]["jump_power"] = ply:GetJumpPower()
    DataToSave["speed"]["crouch_walk_speed"] = ply:GetCrouchedWalkSpeed()
    DataToSave["speed"]["ladder_climb_speed"] = ply:GetLadderClimbSpeed()


    // Misc
    DataToSave["misc_info"] = ply:GetPlayerInfo()


    data["HALOARMORY.Sandbox"] = DataToSave
    
end
hook.Add( "HALOARMORY.SaveCharacter", "HALOARMORY.Sandbox", SaveDefaultStats )

// SANDBOX LOAD DATA
local function LoadSandboxStats( ply, data )
    
    // Default Stats
    if data["health"] then ply:SetHealth( data["health"] ) end
    if data["max_health"] then ply:SetMaxHealth( data["max_health"] ) end
    if data["armor"] then ply:SetArmor( data["armor"] ) end
    if data["max_armor"] then ply:SetMaxArmor( data["max_armor"] ) end

    // Model
    if data["model"] then ply:SetModel( data["model"] ) end
    if data["model_scale"] then ply:SetModelScale( data["model_scale"] ) end
    if data["skin"] then ply:SetSkin( data["skin"] ) end

    if data["bodygroups"] then
        for k, v in pairs(data["bodygroups"]) do
            ply:SetBodygroup( ply:FindBodygroupByName(k), v )
        end
    end

    ply:SetupHands()

    // Weapons
    if data["weapons"] then
        ply:StripWeapons()
        for k, v in pairs(data["weapons"]) do
            ply:Give(v)
        end
    end

    if data["ammo"] then
        ply:StripAmmo()
        for k, v in pairs(data["ammo"]) do
            ply:SetAmmo(v, k)
        end
    end

    // Position
    if data["last_map"] == game.GetMap() && data["pos"] && data["ang"] then
        ply:SetPos( data["pos"] )
        ply:SetEyeAngles( data["ang"] )
    end

    // Speed
    if data["speed"] then
        if data["speed"]["max_speed"] then ply:SetMaxSpeed( data["speed"]["max_speed"] ) end
        if data["speed"]["walk_speed"] then ply:SetWalkSpeed( data["speed"]["walk_speed"] ) end
        if data["speed"]["slow_walk_speed"] then ply:SetSlowWalkSpeed( data["speed"]["slow_walk_speed"] ) end
        if data["speed"]["run_speed"] then ply:SetRunSpeed( data["speed"]["run_speed"] ) end
        if data["speed"]["jump_power"] then ply:SetJumpPower( data["speed"]["jump_power"] ) end
        if data["speed"]["crouch_walk_speed"] then ply:SetCrouchedWalkSpeed( data["speed"]["crouch_walk_speed"] ) end
        if data["speed"]["ladder_climb_speed"] then ply:SetLadderClimbSpeed( data["speed"]["ladder_climb_speed"] ) end
    end
end
hook.Add( "HALOARMORY.LoadCharacter", "HALOARMORY.Sandbox", function( ply, data )
    
    if DarkRP then
        HALOARMORY.MsgC("DarkRP Detected. Delaying Sandbox Module Loading.")
        timer.Simple( 0.2, function()
            LoadSandboxStats( ply, data )
        end)

    else
        LoadSandboxStats( ply, data )
    end
    

end)