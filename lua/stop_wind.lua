

// This was an attempt at getting the HL2 weapons table.

-- print("Update wep changes hook monitor")

-- // "wep" is a global defined variable, that is used to store the current weapon.
-- // Write a function to debug.trace the wep global variable when it's changed.
-- // We need to change wep's metatable.

-- local wep_mt = getmetatable( wep )

-- local old_index = wep_mt.__index

-- wep_mt.__index = function( self, key )

--     --print( "wep changed to: " .. tostring( self ) .. " from: " .. debug.traceback() )

--     --debug.Trace()  


--     return old_index( self, key )

-- end

// Now, when wep is changed, it will print a debug.traceback() to the console.






















// This was an attempt at trying to remove the wind sound from the map (gm_fork), but it didn't work.

--Entity( 635 ):Remove()


--[[ local c_entities = ents.FindByClass( "class C_BaseEntity" )

print( "Found Entities: " .. #c_entities )

--PrintTable( c_entities )

for key, value in pairs(c_entities) do

    --print(key, value)
    
    -- value:StopSound( "ambient/wind/windgust_strong.wav" )
    -- value:StopSound( "ambient/wind/windgust.wav" )
    -- value:StopSound( "ambient/wind/wind_rooftop1.wav" )
    --value:StopSound( )

    

    

end ]]

--[[ 
] soundscape_dumpclient 
Client Soundscape data dump:
   Position: 5350.70 -3076.67 12728.83
   soundscape index: 2
   entity index: 635
   entity pos: 0.00 0.00 10240.00
End dump.
] lua_run_cl print( Entity( 635 ) )
Entity [635][class C_BaseEntity]
 ]]


--[[
] soundlist 
 ( 4b)  32236 : garrysmod\ui_hover.wav
L( 2b) 171008 : weapons\flaregun\burn.wav
L( 1b)  84724 : vehicles\diesel_loop2.wav
L( 2b)  80422 : ambient\atmosphere\indoor2.wav
 ( 2b)  15886 : ambient\water\drip4.wav
 ( 2b)  13154 : ambient\water\drip1.wav
 ( 2b)  19160 : ambient\water\drip2.wav
L( 1b) 131197 : physics\metal\metal_box_scrape_rough_loop1.wav
 ( 2b)  25868 : physics\metal\weapon_impact_soft2.wav
 ( 2b)  30752 : physics\metal\weapon_impact_soft1.wav
 ( 2b)  60334 : physics\metal\metal_solid_impact_bullet4.wav
 ( 2b)  42666 : physics\metal\metal_solid_impact_bullet3.wav
 ( 2b)  59402 : physics\metal\metal_solid_impact_bullet2.wav
 ( 2b)  39048 : physics\metal\metal_solid_impact_bullet1.wav
L( 2b) 305408 : impulse\halo\cover\instantcover_loop\instant_cover2.wav
L( 2b) 244992 : impulse\halo\cover\instantcover_loop\instant_cover4.wav
L( 2b) 153600 : impulse\halo\cover\instantcover_loop\instant_cover3.wav
 ( 4b)  60156 : weapons\airboat\airboat_gun_loop2.wav
L( 1b) 175149 : vehicles\airboat\pontoon_fast_water_loop2.wav
L( 4b) 524388 : vehicles\airboat\pontoon_stopped_water_loop1.wav
L( 1b)  63039 : vehicles\airboat\fan_blade_fullthrottle_loop1.wav
L( 2b) 163908 : vehicles\airboat\fan_blade_idle_loop1.wav
L( 1b) 114036 : vehicles\airboat\fan_motor_idle_loop1.wav
L( 1b) 131584 : ambient\wind\wind_rooftop1.wav
 ( 4b) 1359868 : ambient\wind\windgust_strong.wav
 ( 4b) 547708 : ambient\wind\windgust.wav
L( 2b) 107010 : simpleweather\rain.wav
 ( 2b)  74498 : player\pl_drown1.wav
 ( 4b) 133080 : items\ammo_pickup.wav
 ( 2b)  17926 : buttons\button14.wav
 ( 2b)   7172 : buttons\button17.wav
 ( 4b) 446464 : assault_rifle\ar_fire_1.wav
 ( 4b) 451584 : assault_rifle\ar_fire_3.wav
 ( 4b) 548864 : assault_rifle\ar_fire_2.wav
 ( 2b) 113706 : physics\concrete\concrete_impact_bullet4.wav
 ( 2b) 143998 : physics\concrete\concrete_impact_bullet2.wav
 ( 2b)  39624 : player\footsteps\metal4.wav
 ( 2b)  33490 : player\footsteps\metal1.wav
 ( 2b)  39178 : player\footsteps\metal2.wav
 ( 2b)  43248 : player\footsteps\metal3.wav
 ( 2b)  18242 : npc\turret_floor\click1.wav
 ( 2b) 197944 : common\bugreporter_failed.wav
 ( 4b)   2404 : common\talk.wav
L( 4b) 2646000 : ambient\forest_day.wav
 ( 2b)  33978 : plats\hall_elev_door.wav
Total resident: 9748103
 ]]