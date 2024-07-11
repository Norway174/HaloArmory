HALOARMORY.MsgC("Shared Vehicle Pickup loaded!")

HALOARMORY.Vehicles = HALOARMORY.Vehicles or {}


--[[ 
##============================##
||                            ||
||          Settings          ||
||                            ||
##============================##
 ]]

HALOARMORY.Vehicles.allowedVehicles = {
    // [LFS] - Halo [UNSC]
    ["imp_halo_hum_pelican_d77tc"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_ce"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_d77police"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_h2"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_tcipolice"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_tci"] = {
        {
            ["pos"] = Vector(-500, 0, 60),
            ["rad"] = 200,
        },
        {
            ["pos"] = Vector(-100, 0, 140),
            ["rad"] = 120,
        }
    },
    ["imp_halo_hum_pelican_d79h"] = {
        {
            ["pos"] = Vector(-380, 0, -50),
            ["rad"] = 150,
        },
        {
            ["pos"] = Vector(230, 0, -40),
            ["rad"] = 110,
        }
    },
    ["imp_halo_hum_albatross"] = {
        ["pos"] = Vector(50, 0, 160),
        ["rad"] = 270,
    },
    ["imp_halo_hum_falcon"] = { 
        ["pos"] = Vector(-10, 0, 55),
        ["rad"] = 60,
    },
    ["imp_halo_hum_falcon_medical"] = {
        ["pos"] = Vector(-10, 0, 55),
        ["rad"] = 60,
    },
    // [LFS] - Halo [Covenant]
    ["imp_halo_cov_phantom"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_cov_phantom_kezkatu"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_cov_phantom_gunboat"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_cov_spirit"] = {
        ["pos"] = Vector(400, 0, 120),
        ["rad"] = 300,
    },
    ["imp_halo_cov_shadow"] = {
        ["pos"] = Vector(-20, 0, 50),
        ["rad"] = 100,
    },
    // [LFS] - Halo [Seperatist]
    ["imp_halo_sch_phantom"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_sch_phantom_kezkatu"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_sch_phantom_gunboat"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["imp_halo_sch_spirit"] = {
        ["pos"] = Vector(400, 0, 120),
        ["rad"] = 300,
    },
    // [LFS] - Halo [Insurrectionists]
    ["imp_halo_urf_pelican_d77tc"] = {
        ["pos"] = Vector(-500, 0, 60),
        ["rad"] = 200,
    },
    // [LFS] - Halo [Flock]
    ["imp_halo_flock_falcon"] = { 
        ["pos"] = Vector(-10, 0, 55),
        ["rad"] = 60,
    },
    ["imp_halo_flock_falcon_urf"] = { 
        ["pos"] = Vector(-10, 0, 55),
        ["rad"] = 60,
    },
    // LFS Halo
    // UNSC
    ["lunasflightschool_pelicanv1"] = {
        ["pos"] = Vector(-400, 0, -40),
        ["rad"] = 200,
    },
    ["lunasflightschool_pelicanv2"] = {
        ["pos"] = Vector(-400, 0, -40),
        ["rad"] = 200,
    },
    ["lunasflightschool_pelicanv3"] = {
        ["pos"] = Vector(-400, 0, -40),
        ["rad"] = 200,
    },
    ["lunasflightschool_pelicanv4"] = {
        ["pos"] = Vector(-400, 0, -40),
        ["rad"] = 200,
    },
    ["lunasflightschool_albatross"] = {
        ["pos"] = Vector(0, 0, 180),
        ["rad"] = 200,
    },
    // Covie
    ["lunasflightschool_phantomv1"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["lunasflightschool_phantomv2"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    ["lunasflightschool_phantomv3"] = {
        ["pos"] = Vector(0, 0, 80),
        ["rad"] = 200,
    },
    // Simphys
    // Halo [UNSC]
    ["sim_fphys_halo_warthog_scout"] = {
        ["pos"] = Vector(-65, 0, 70),
        ["rad"] = 30,
    },
    ["sim_fphys_halo_warthog_scout_civ"] = {
        ["pos"] = Vector(-65, 0, 70),
        ["rad"] = 30,
    },
    ["sim_fphys_halo_warthog_scout_rally"] = {
        ["pos"] = Vector(-65, 0, 70),
        ["rad"] = 30,
    },
    ["sim_fphys_halo_warthog_Extended"] = {
        ["pos"] = Vector(-80, 0, 70),
        ["rad"] = 45,
    },
    ["sim_fphys_halo_spade1"] = {
        ["pos"] = Vector(-70, 0, 60),
        ["rad"] = 40,
    },
    ["sim_fphys_halo_Forklift"] = {
        ["pos"] = Vector(100, 0, 45),
        ["rad"] = 40,
    },
    ["sim_fphys_halo_Cart"] = {
        ["pos"] = Vector(30, 0, 45),
        ["rad"] = 35,
    },
    ["sim_fphys_halo_militarytruck_long_flat"] = {
        {
            ["pos"] = Vector(-200, 0, 100),
            ["rad"] = 75,
        },
        {
            ["pos"] = Vector(-80, 0, 100),
            ["rad"] = 75,
        }
    },
    ["sim_fphys_halo_militarytruck_long_flat_gun"] = {
        {
            ["pos"] = Vector(-200, 0, 100),
            ["rad"] = 75,
        },
        {
            ["pos"] = Vector(-80, 0, 100),
            ["rad"] = 75,
        }
    },
    ["sim_fphys_halo_militarytruck_long_covered"] = {
        {
            ["pos"] = Vector(-200, 0, 100),
            ["rad"] = 75,
        },
        {
            ["pos"] = Vector(-80, 0, 100),
            ["rad"] = 75,
        }
    },
    ["sim_fphys_halo_militarytruck_long_covered_gun"] = {
        {
            ["pos"] = Vector(-200, 0, 100),
            ["rad"] = 75,
        },
        {
            ["pos"] = Vector(-80, 0, 100),
            ["rad"] = 75,
        }
    },
    ["sim_fphys_halo_Elephant_H3"] = {
        {
            ["pos"] = Vector(-230, 0, 100),
            ["rad"] = 150,
        },
        {
            ["pos"] = Vector(-30, 0, 120),
            ["rad"] = 120,
        },
        {
            ["pos"] = Vector(165, 0, 130),
            ["rad"] = 120,
        }
    },
    // Halo Custom Edition
    ["sim_fphys_halorevamp_warthog"] = {
        ["pos"] = Vector(-55, 0, 70),
        ["rad"] = 30,
    },
    ["sim_fphys_halorevamp_warthog_treaded"] = {
        ["pos"] = Vector(-55, 0, 70),
        ["rad"] = 30,
    },
    ["sim_fphys_halorevamp_militarytruck_long_exposed"] = {
        ["pos"] = Vector(-130, 0, 100),
        ["rad"] = 60,
    },
    ["sim_fphys_halorevamp_militarytruck_long_covered"] = {
        ["pos"] = Vector(-130, 0, 100),
        ["rad"] = 60,
    },
    ["sim_fphys_halorevamp_militarytruck_long"] = {
        ["pos"] = Vector(-130, 0, 100),
        ["rad"] = 60,
    },
    ["sim_fphys_halorevamp_militarytruck_long_bed"] = {
        ["pos"] = Vector(-130, 0, 100),
        ["rad"] = 60,
    },
    ["sim_fphys_halorevamp_militarytruck_bed"] = {
        ["pos"] = Vector(-85, 0, 100),
        ["rad"] = 60,
    },
    ["sim_fphys_halorevamp_spade"] = {
        ["pos"] = Vector(-70, 0, 60),
        ["rad"] = 35,
    },
    ["sim_fphys_halorevamp_forklift"] = {
        ["pos"] = Vector(100, 0, 45),
        ["rad"] = 40,
    },
    ["sim_fphys_halorevamp_cart"] = {
        ["pos"] = Vector(30, 0, 45),
        ["rad"] = 35,
    },
    // Halo Covenant Edition
    ["simfphys_covshadowemptysnow"] = {
        ["pos"] = Vector(0, 0, 50),
        ["rad"] = 100,
    },
}

HALOARMORY.Vehicles.allowedObjectsToLoad = {
    ["prop_physics"] = true,
    ["prop_vehicle_jeep"] = true,
    ["sent_ball"] = true,
    //Simfphys vehicles
    ["gmod_sent_vehicle_fphysics_base"] = true,
    //HALOARMORY - UNSC
    ["haloarmory"] = true,
    ["halohealth_station"] = true,
    ["halohealthkit"] = true,
    ["halo_sp_crate"] = true,
    //HALOARMORY - Covenant
    ["haloarmory_covie"] = true,
    ["halohealthkit_covie"] = true,
    ["halohealth_station_covie"] = true,
    //HALOARMORY - Banished
    ["haloarmory_banished"] = true,
    //HBOMBS Main
    ["hb_main_500lb"] = true,
    ["hb_main_sodacan"] = true,
    ["hb_main_blu82"] = true,
    ["hb_main_clusterbomb"] = true,
    ["hb_misc_combinebomb"] = true,
    ["hb_main_fab"] = true,
    ["hb_main_fusionbomb"] = true,
    ["hb_main_gasleakbomb"] = true,
    ["hb_main_thermobaric"] = true,
    ["hb_main_implosionbomb"] = true,
    ["hb_main_bigjdam"] = true,
    ["hb_main_napalm"] = true,
    ["hb_main_moab"] = true,
    ["hb_misc_grenade"] = true,
    ["hb_misc_volcano"] = true,
    //HBOMBS Misc
    ["hb_emp"] = true,
    ["hb_fridge"] = true,
    ["hb_mortar_cache"] = true,
    ["nuclear_siren"] = true,
    //HBOMBS Nukes
    ["hb_nuclear_castlebravo"] = true,
    ["hb_nuclear_castlebravo_noflash"] = true,
    ["hb_nuclear_clusternuke"] = true,
    ["hb_nuclear_davycrockett"] = true,
    ["hb_nuclear_davycrockett_noflash"] = true,
    ["hb_nuclear_fatman"] = true,
    ["hb_nuclear_fatman_noflash"] = true,
    ["hb_nuclear_trinity"] = true,
    ["hb_nuclear_trinity_noflash"] = true,
    ["hb_nuclear_ionbomb"] = true,
    ["hb_nuclear_ivyking"] = true,
    ["hb_nuclear_ivyking_noflash"] = true,
    ["hb_nuclear_ivymike"] = true,
    ["hb_nuclear_ivymike_noflash"] = true,
    ["hb_nuclear_littleboy"] = true,
    ["hb_nuclear_littleboy_noflash"] = true,
    ["hb_nuclear_megatonbomb"] = true,
    ["hb_nuclear_megatonbomb_noflash"] = true,
    ["hb_nuclear_grable"] = true,
    ["hb_nuclear_grable_noflash"] = true,
    ["hb_nuclear_slownuke"] = true,
    ["hb_nuclear_slownuke_noflash"] = true,
    ["hb_sp_spacenuke"] = true,
    ["hb_nuclear_tsarbomba"] = true,
    ["hb_nuclear_tsarbomba_noflash"] = true,
    ["hb_proj_v2_small"] = true,
    //HBOMS Custom
    ["hb_nuclear_c_tritium"] = true,
    //["hb_proj_icbm"] = true, // Very large!
    //["hb_proj_icbm_wh"] = true,
    ["hb_nuclear_initiator"] = true,
    ["hb_nuclear_c_b1"] = true,
    ["hb_nuclear_c_h1"] = true,
    ["hb_nuclear_c_plutonium"] = true,
    ["hb_nuclear_c_uranium"] = true,
    //Halo - Mantis
    ["halo_mantis_mkix_mining"] = true,
    ["halo_mantis_mkix_hannibal"] = true,
    //["halo_mantis_mk2"] = true, // Huge Mantis. Way too big.
    ["halo_mantis_mkix"] = true,
    ["halo_mantis_mkix_insurgent"] = true,
    ["halo_repairplatform"] = true,
    ["halo_mantis_mkix_oni"] = true,
    ["halo_mantis_mkix_camo_tundra"] = true,
    //Halo - Resupply
    ["imp_halo_util_ordnancepod"] = true,
    ["imp_halo_util_supplypod"] = true,
    ["imp_halo_util_supplypod_ar"] = true,
    ["imp_halo_util_supplypod_br"] = true,
    ["imp_halo_util_supplypod_pis"] = true,
    ["imp_halo_util_supplypod_rocket"] = true,
    ["imp_halo_util_supplypod_shotgun"] = true,
    ["imp_halo_util_supplypod_smg"] = true,
    ["imp_halo_util_supplypod_sniper"] = true,
    ["imp_halo_util_supplypod_splaser"] = true,
    //Halo - Covenant
    ["imp_halo_cov_plasmastorage_bulk"] = true,
    ["imp_halo_cov_stool"] = true,
    ["imp_halo_cov_deployablecover"] = true,
    ["imp_halo_cov_watchtower"] = true,
    ["imp_halo_cov_fuel_cell_a"] = true,
    ["imp_halo_cov_fuel_cell_b"] = true,
    ["imp_halo_cov_fuel_cell_c"] = true,
    ["imp_halo_cov_hologram_projector"] = true,
    ["imp_halo_cov_methane_refueling"] = true,
    ["imp_halo_cov_plasmabattery"] = true,
    ["imp_halo_cov_signal_jammer"] = true,
    ["imp_halo_cov_supplypod"] = true,
    ["imp_halo_crate_cov_h3"] = true,
    ["imp_halo_crate_cov_reach"] = true,
    ["imp_halo_cov_veh_fuel_storage"] = true,
    ["imp_halo_cov_watchtower_pod"] = true,
    //Halo
    ["astw2_halo_reach_ammo_box"] = true,
    ["snowce_uplink"] = true,
    //[LFS] - Halo [UNSC]
    ["imp_halo_hum_wasp"] = true,
    ["imp_halo_hum_wasp_oni"] = true,
    ["imp_halo_hum_wasp_hannibal"] = true,
    ["imp_halo_hum_hornet"] = true,
    ["imp_halo_hum_falcon"] = true,
    ["imp_halo_hum_falcon_medical"] = true,
    ["imp_halo_hum_hornet"] = true,
    ["imp_halo_hum_hornet_h2a"] = true,
    ["imp_halo_hum_sparrowhawk"] = true,
    //[LFS] - Halo [Covenant]
    ["imp_halo_cov_chopper_online"] = true,
    ["imp_halo_cov_chopper"] = true,
    ["imp_halo_cov_wraith_protos"] = true,
    ["imp_halo_cov_wraith"] = true,
    ["imp_halo_cov_banshee_typea"] = true,
    ["imp_halo_cov_banshee_typeaz"] = true,
    ["imp_halo_cov_banshee_typeb"] = true,
    ["imp_halo_cov_banshee_typebz"] = true,
    ["imp_halo_cov_banshee_typec"] = true,
    ["imp_halo_cov_banshee_typeb_xmf"] = true,
    ["imp_halo_cov_shadow"] = true,
    ["imp_halo_shadowseats"] = true,
    ["imp_halo_cov_ghost"] = true,
    ["imp_halo_cov_ghost_h3"] = true,
    ["imp_halo_cov_spectre"] = true,
    ["imp_halo_cov_revenant"] = true,
    ["imp_halo_cov_wraith_aa"] = true,
    ["imp_halo_cov_prowler"] = true,
    ["imp_halo_cov_revenant_storm"] = true,
    //[LFS] Halo
    ["lfs_h3_snow_banshee"] = true,
    //[LFS] - Halo [Emplacements  Batteries]
    ["imp_halo_hum_machinegun_h3"] = true,
    ["imp_halo_hum_missilepod"] = true,
    ["imp_halo_hum_gpmg"] = true,
    ["imp_halo_hum_gpmg_turret"] = true,
    ["imp_halo_oni_antiinfantry"] = true,
    ["imp_halo_hum_hardpoint"] = true,
    ["imp_halo_cov_shade_aa"] = true,
    ["imp_halo_cov_shade"] = true,
    ["imp_halo_cov_shade_fuelrod"] = true,
    ["imp_halo_cov_shade_heavy"] = true,
    ["imp_halo_cov_shade_h2a"] = true,
    ["imp_halo_cov_defender"] = true,
    ["imp_halo_cov_shade_cea"] = true,
    ["imp_halo_cov_t42"] = true,
    ["imp_halo_cov_t52"] = true,
    ["imp_halo_cov_shade_heavy"] = true,
    ["imp_halo_cov_shade_heavy"] = true,
    //[LFS] - Halo [Insurrectionists]
    ["imp_halo_urf_falcon"] = true,
    //[LFS] - Halo [Seperatist]
    ["imp_halo_sch_chopper"] = true,
    ["imp_halo_sch_wraith_protos"] = true,
    ["imp_halo_sch_wraith"] = true,
    ["imp_halo_sch_banshee_typeb"] = true,
    ["imp_halo_sch_banshee_typec"] = true,
    ["imp_halo_sch_banshee_typeb_xmf"] = true,
    ["imp_halo_sch_shadow"] = true,
    ["imp_halo_sch_ghost"] = true,
    ["imp_halo_sch_ghost_h3"] = true,
    ["imp_halo_sch_spectre"] = true,
    ["imp_halo_sch_revenant"] = true,
    ["imp_halo_sch_revenant_storm"] = true,
    //Summe
    ["comlink_array"] = true,
    //Halo - Mantis
    ["halo_mantis_mkix_mining"] = true,
    ["halo_mantis_mkix_hannibal"] = true,
    --["halo_mantis_mk2"] = true, // Large Mantis. Way too big.
    ["halo_mantis_mkix"] = true,
    ["halo_mantis_mkix_insurgent"] = true,
    ["halo_mantis_mkix_oni"] = true,
    ["halo_mantis_mkix_camo_tundra"] = true,
}

--[[ 
##============================##
||                            ||
||   Local Helper Functions   ||
||                            ||
##============================##

 ]]





--[[ 
##============================##
||                            ||
||  Global Helper Functions   ||
||                            ||
##============================##
]]


function HALOARMORY.Vehicles.GetVehicle( ent )
    if not ent:IsValid() then
        return
    end

    if ent:IsPlayer() and ent:GetVehicle():IsValid() then
        return HALOARMORY.Vehicles.GetVehicle(ent:GetVehicle())
    end

    if ent:IsValid() and ent.GetSpawn_List and HALOARMORY.Vehicles.allowedVehicles[ent:GetSpawn_List()] then
        return ent
    end

    if ent:IsValid() and HALOARMORY.Vehicles.allowedVehicles[ent:GetClass()] then
        return ent
    else
        return HALOARMORY.Vehicles.GetVehicle(ent:GetParent())
    end
end


function HALOARMORY.Vehicles.GetFromTraceVehicle( ply )

    if not IsValid( ply ) then return end

    local ent = nil

    if ply:InVehicle() then
        ent = HALOARMORY.Vehicles.GetVehicle( ply:GetVehicle() )

        if IsValid( ent ) then
            return ent
        end
    end

    local tr = util.TraceLine( util.GetPlayerTrace( ply ) )
    if IsValid(tr.Entity) then
        ent = HALOARMORY.Vehicles.GetVehicle( tr.Entity )
    end

    return ent
end



-- concommand.Add( "VEHICLE.DebugSH", function( ply, cmd, args )
--     local veh = HALOARMORY.Vehicles.GetFromTraceVehicle( ply )
    
--     PrintTable( veh:GetNW2VarTable() )
-- end )


-- if CLIENT then

--     local tr = util.TraceLine( util.GetPlayerTrace( LocalPlayer() ) )
--     if IsValid(tr.Entity) then
--         print(tr.Entity)

--         --PrintTable( list.Get( "simfphys_vehicles" ) )

--         --PrintTable( list.Get( "simfphys_vehicles" )[tr.Entity:GetSpawn_List()].name )

--         print( tr.Entity:GetClass():lower() == "gmod_sent_vehicle_fphysics_base" )

--         --print( tr.Entity:GetSpawn_List() )
--     end

-- end

-- print( list.Get( "simfphys_vehicles" )[tr.Entity:GetSpawn_List()]["Name"] )