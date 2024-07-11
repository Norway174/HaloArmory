HALOARMORY.MsgC("Server CHARACTHER PERSISTENCE DarkRP Module Loading.")


// DARKRP SAVE DATA
local function SaveDarkRPStats( ply, data )
    if not DarkRP then return end
    
    local DataToSave = {}

    // Default Stats
    DataToSave["nick"] = ply:Nick()
    DataToSave["job"] = team.GetName( ply:Team() )
    DataToSave["money"] = ply:getDarkRPVar("money") 

    // Extra DarkRP Stats
    DataToSave["license"] = ply:getDarkRPVar("HasGunlicense")
    DataToSave["wanted"] = ply:getDarkRPVar("wanted")
    DataToSave["wantedreason"] = ply:getDarkRPVar("wantedReason")

    // HALOARMORY Shield Support
    DataToSave["shield"] = ply:getJobTable().spartan_shield

    // MRS Support
    if MRS and ply.MRSOGName then
        DataToSave["nick"] = ply:MRSOGName()
    end


    data["HALOARMORY.DarkRP"] = DataToSave
    
end
hook.Add( "HALOARMORY.SaveCharacter", "HALOARMORY.DarkRP", SaveDarkRPStats )

// DARKRP LOAD DATA

local function LoadDarkRPStats( ply, data )
    if not DarkRP then return end
    
    // Default Stats
    if data["nick"] then ply:setRPName( data["nick"] ) end
    if data["money"] then ply:setDarkRPVar("money", data["money"]) end

    // Very complicated hack to set the job. But it works.
    // Basically this: https://github.com/FPtje/DarkRP/blob/52f01d366cdff7adbf48dbe4836ce47694a6320d/gamemode/modules/jobs/sv_jobs.lua#L5
    // But without all the extra overhead functionality. And skips a lot of checks, and other function calls.
    for key, value in pairs(RPExtraTeams) do
        if value.name == data["job"] then
            local TEAM = RPExtraTeams[key]
            if TEAM then
                ply:updateJob(TEAM.name)
                ply:setSelfDarkRPVar("salary", TEAM.salary)
                ply:SetTeam(key)
                player_manager.SetPlayerClass(ply, TEAM.playerClass or "player_darkrp")
                ply:applyPlayerClassVars(false)
                ply.LastJob = CurTime()

                if isfunction(TEAM.PlayerSpawn) then
                     TEAM.PlayerSpawn(ply)
                end
            end
            break // Break the loop when job has been found and set.
        end
    end

    // Extra DarkRP Stats
    if data["license"] then ply:setDarkRPVar("HasGunlicense", data["license"]) end
    if data["wanted"] then ply:setDarkRPVar("wanted", data["wanted"]) end
    if data["wantedreason"] then ply:setDarkRPVar("wantedReason", data["wantedreason"]) end


    // HALOARMORY Shield Support
    if data["shield"] then
        local shield_func = hook.GetTable()["PlayerLoadout"]["DRCShield_ply"] // Get the shield hook manually.
        if isfunction(shield_func) then shield_func(ply) end
    end
    
end
hook.Add( "HALOARMORY.LoadCharacter", "HALOARMORY.DarkRP", LoadDarkRPStats )
