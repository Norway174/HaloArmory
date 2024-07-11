HALOARMORY.MsgC("Server HALO ARMORY Spawn Restrictor Loading.")

local RankWhitelist = {
    ["event_coordinator"] = true
}


local function HALOCanSpawnObject( ply, class, info )
    print( "HALOARMORY: " .. ply:GetName() .. " tried to spawn " .. class)
    --ply:PrintMessage( HUD_PRINTTALK, "HALOARMORY: " .. ply:GetName() .. " tried to spawn " .. class )

    if ply:IsAdmin() then
        return
    end
    if RankWhitelist[ply:GetUserGroup()] then
        return
    end
    if (GAS) then
        for k,v in pairs(RankWhitelist) do
            if OpenPermissions:IsUserGroup(ply, k) then
                return
            end
        end
    end


    ply:PrintMessage( HUD_PRINTTALK, "Sorry! You don't have permission to spawn weapons." )
    return false
end


hook.Add( "PlayerSpawnSWEP", "HALOARMORY.SpawnBlockSWEP", HALOCanSpawnObject )
hook.Add( "PlayerGiveSWEP", "HALOARMORY.SpawnBlockSWEP2", HALOCanSpawnObject )

// haloarmory/sv_spawnrestrictor.lua

