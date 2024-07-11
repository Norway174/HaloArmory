HALOARMORY.MsgC("Shared HALOARMORY UNSC [Friendly] NPCs loaded!")

local function AddNPC( t, class )
    list.Set( "NPC", class or t.Class, t )
end

local Category = "HALOARMORY - UNSC [Friendly]"

local NPC_MODELS = {
    "models/jessev92/halo/unsc_h3_marine/m01_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m02_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m03_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m04_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m05_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m06_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m07_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m08_reb.mdl",
    "models/jessev92/halo/unsc_h3_marine/m09_reb.mdl"
}

local NPC_SWEPS	=	{
    "npc_halo3_m41",
    "npc_halo3_br55hbsr",
    "npc_halo3_ma5c",
    --"npc_halo3_m6csocom",
    "npc_halo3_m6g",
    "npc_halo3_m7",
    --"npc_halo3_m7s",
    "npc_halo3_m90"
}

local BaseNPC_Class = "npc_citizen"

--[[
    +-+-+-+ +-+-+-+-+ +-+-+-+-+-+
    |A|D|D| |N|P|C|s| |B|E|L|O|W|
    +-+-+-+ +-+-+-+-+ +-+-+-+-+-+
--]]

AddNPC( {
    // Used by Gmod
    Name = "UNSC Marine",
    Category = Category,
    Class = "haloarmory_npc_base",
    --Model = "models/props_borealis/bluebarrel001.mdl",
    Haloarmory = {
        // Used by HALOARMORY
        Weapons = NPC_SWEPS,
        BaseClass = BaseNPC_Class,
        Models = NPC_MODELS,
        Amount = 20,
        HP = 100,
    },
}, "npc_haloarmory_unsc_marine" )

