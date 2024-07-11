
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Radar Tower"
ENT.Category = "HALOARMORY - ATC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.RadarModel = "models/valk/haloreach/unsc/props/crate/antenna_mast.mdl"



-- ENT.ScanFor = {}

-- ENT.ScanFor["Air"] = {
--     ["imp_halo_lfs_basescript_gunship"] = true,
-- }

-- ENT.ScanFor["Ground"] = {
--     ["simfphys_base"] = true,
-- }




function ENT:SetupDataTables()

    local RadarTypes = {
        ["Air"] = "Air",
        ["Ground"] = "Ground",
    }

    self:NetworkVar( "String", 0, "RadarNetwork", { KeyName = "RadarNetwork",	Edit = { type = "Generic", order = 1 } } )
    self:NetworkVar( "String", 1, "ScanType", { KeyName = "Scan For",	Edit = { type = "Combo", order = 2, values = RadarTypes } } )

    if SERVER then
        self:SetRadarNetwork( "network_1" )
        self:SetScanType( "Air" )
    end

end