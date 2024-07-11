HALOARMORY.MsgC("Shared HALO ARMORY Loadout GUI Loading.")

HALOARMORY = HALOARMORY or {}
HALOARMORY.ARMORY = HALOARMORY.ARMORY or {}

HALOARMORY.ARMORY.MaxAmmo = 9999

HALOARMORY.ARMORY.Theme = {
    ["roundness"] = 24,
    ["background"] = Color(20,20,20),
    ["text"] = Color(255,255,255,255),
    ["header_color"] = Color(0,0,0),
    ["divider_color"] = Color(255,255,255,10),
    ["apply_btn"] = Color(0,97,0),
    ["cancel_btn"] = Color(97,0,0),
}

HALOARMORY.ARMORY.WepOverrides = {
    weapon_physgun = {
        Name = "Physgun",
        modelOverwrite = "models/weapons/w_Physics.mdl",
        forceEnable = true,
    },
    weapon_pistol = {
        Name = "Pistol",
        modelOverwrite = "models/weapons/w_pistol.mdl",
    },
    keys = {
        modelOverwrite = "models/props_c17/TrapPropeller_Lever.mdl",
    },
    none = {
        modelOverwrite = "models/weapons/c_arms_animations.mdl",
    },
    salute_swep = {
        modelOverwrite = "models/weapons/c_arms_animations.mdl",
    },
    weapon_fists = {
        modelOverwrite = "models/weapons/c_arms_animations.mdl",
    },
    weapon_cuff_elastic = {
        modelOverwrite = "models/weapons/c_arms_animations.mdl",
    },
}