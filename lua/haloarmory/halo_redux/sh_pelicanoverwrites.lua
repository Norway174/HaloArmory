
local allowedMaps = {
    ["gm_infmap"] = true,
}

// Stop this file if wrong map.
if ( not allowedMaps[game.GetMap()] ) then return end
print( "Pelican overwrites loaded. '" .. game.GetMap() .. "' is an allowed map.")

// Credits: https://stackoverflow.com/a/10990879
local function numWithCommas(n)
    if ( not isnumber(n) ) then tonumber(n) end
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,")
                                  :gsub(",(%-?)$","%1"):reverse()
end

--[[
  ENT.MaxTurnPitch = 50
  ENT.MaxTurnYaw = 100
  ENT.MaxTurnRoll = 65
  
  ENT.PitchDamping = 1
  ENT.YawDamping = 2
  ENT.RollDamping = 1
  
  ENT.TurnForcePitch = 3000
  ENT.TurnForceYaw = 2000
  ENT.TurnForceRoll = 500
  
  ENT.RPMThrottleIncrement = 75
  
  ENT.MaxVelocity = 3000
  ENT.ReverseDivision = 4
  
  ENT.MaxThrust = 3500
  
  ENT.VerticalTakeoff = true
  ENT.VtolAllowInputBelowThrottle = 300
  ENT.MaxThrustVtol = 400
  ]]



local allowedPelicans = {
    ["imp_halo_hum_pelican_d77tc"] = true,
    ["imp_halo_hum_pelican_ce"] = true,
    ["imp_halo_hum_pelican_d77police"] = true,
    ["imp_halo_hum_pelican_h2"] = true,
    ["imp_halo_hum_pelican_tcipolice"] = true,
    ["imp_halo_hum_pelican_tci"] = true,
    ["imp_halo_hum_pelican_d79h"] = true,
    ["imp_halo_hum_longsword"] = true,
    ["imp_halo_hum_sabre"] = true,
}

local printInfo = true

local function PrintInfo( ent, name, old, new, multiplier )
    if ( not printInfo ) then return end

    print(string.format([[
---- PELICAN OVERWRITER ----
Ent: %s
Type: %s
%s * %s = %s
----------------------------]],
ent, name, numWithCommas(old), numWithCommas(multiplier), numWithCommas(new)))

    -- print("---- Changing value: " .. name .. " ----")
    -- print("Old: " .. old .. " | New: " .. new)
    -- print("-----------------")

end


hook.Add( "OnEntityCreated", "PelicanOverwrites", function( ent )
    if ( not allowedMaps[game.GetMap()] ) then return end

	if ( allowedPelicans[ent:GetClass()] ) then
		--ent:EmitSound( "vo/npc/male01/no02.wav" )
        timer.Simple(.1, function()

            if (ent.MaxVelocity) then
                local oldVel = ent.MaxVelocity
                ent.MaxVelocity = oldVel * 50
                PrintInfo(ent:GetClass(), "MaxVelocity", oldVel, ent.MaxVelocity, 50)
            end

            if (ent.MaxThrust) then
                local oldVel = ent.MaxThrust
                ent.MaxThrust = oldVel * 25
                PrintInfo(ent:GetClass(), "MaxThrust", oldVel, ent.MaxThrust, 25)
            end

        end)
        
	end
end )