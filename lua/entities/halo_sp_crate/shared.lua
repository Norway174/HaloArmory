
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Crate [EMPTY]"
ENT.Category = "HALOARMORY - Logistics"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.Editable = true


ENT.DeviceName = "Crate"
ENT.DeviceType = "storage"

ENT.StoredSupplies = 0
ENT.MaxCapacity = 5000

ENT.RandomMin = 0
ENT.RandomMax = 0

ENT.DeviceModel = "models/ishi/halo_rebirth/props/human/packing_crate_small.mdl" -- Halo UNSC Prop Pack
ENT.DeviceModelAlts = {
    -- Halo Models
    --["models/h3/objects/gear/human/military/crate_packing/crate_packing.mdl"] = true,
    -- Halo Reach Model Pack
    ["models/rena_haloreach/crate_packing.mdl"] = true,
    -- Halo UNSC Prop Pack
    ["models/ishi/halo_rebirth/props/human/oni_crate_small.mdl"] = true,
    ["models/ishi/halo_rebirth/props/human/packing_crate_small.mdl"] = true,
    -- Halo UNSC Prop Pack - Halo 3
    ["models/valk/h3/unsc/props/crates/crate_packing.mdl"] = true,
    -- Halo UNSC Prop Pack - Halo 4
    ["models/valk/h4/unsc/props/crate/crate.mdl"] = true,
    -- Halo UNSC Prop Pack - Halo Reach
    ["models/valk/haloreach/unsc/props/crate/crate_packing.mdl"] = true,
    -- Halo UNSC Prop Pack Redux - Halo 2A
    ["models/valk/halo2a/unsc/props/military/crate_packing.mdl"] = true,
    -- Halo UNSC Prop Pack Redux - Halo 3
    ["models/valk/halo3/unsc/props/industrial/box_wooden_small_b.mdl"] = true,
    ["models/valk/halo3/unsc/props/industrial/crate_multi_single.mdl"] = true,
    ["models/valk/halo3/unsc/props/military/crate_packing.mdl"] = true,
    -- Halo UNSC Prop Pack Redux - Halo Reach
    ["models/valk/haloreach/unsc/props/military/crate_packing.mdl"] = true,
    -- Halo Covenant Prop Pack
    ["models/valk/h5/covenant/props/crates/crate_packing.mdl"] = true,
}

function ENT:SetupModel()
    self:SetModel( self.DeviceModel )
end

ENT.PanelPos = Vector(0, 0, 45)
--ENT.PanelAng = Angle(0, -90, 67.8)
ENT.PanelScale = .1


ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 0, 0, 0, 210),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}

function ENT:RandomColor()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return Color(r, g, b)
end


function ENT:SetupDataTables()

    self:NetworkVar( "String", 1, "BoxName", { KeyName = "Name",	Edit = { type = "Generic", order = 1 } } )
    self:NetworkVar( "Vector", 0, "HeaderColor", { KeyName = "HeaderColor",	Edit = { type = "VectorColor", order = 3 } } )
    self:NetworkVar( "Int", 2, "MaxCapacity", { KeyName = "MaxCapacity",	Edit = { title = "Max Capacity", type = "Int", order = 6, min = 0, max = 999999999 } } )
    self:NetworkVar( "Int", 3, "Stored", { KeyName = "Stored",	Edit = { title = "Stored Supplies", type = "Int", order = 7, min = 0, max = self.MaxCapacity } } )
    self:OnMaxCapUpdate( "", 0, self.MaxCapacity )

    if SERVER then
        self:SetBoxName( self.DeviceName )
        self:SetHeaderColor( self:RandomColor():ToVector() )
        self:SetMaxCapacity( self.MaxCapacity )
        self:SetStored( self.StoredSupplies )
    end

    self:NetworkVarNotify( "MaxCapacity", self.OnMaxCapUpdate )
end

function ENT:OnMaxCapUpdate( name, old, new )
    self:NetworkVar( "Int", 3, "Stored", { KeyName = "Stored",	Edit = { title = "Stored Supplies", type = "Int", order = 7, min = 0, max = new } } )

    if SERVER and ( self:GetStored( ) >= new ) then
        self:SetStored( new )
    end
end