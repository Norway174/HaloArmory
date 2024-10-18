
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Auto-Doc"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.BedModel = "models/valk/h3/unsc/props/crashcart/medicalstretcher.mdl" -- Halo UNSC Prop Pack - Halo 3

ENT.CONSTS = {}
ENT.CONSTS.MENU = {}
ENT.CONSTS.MENU.MAIN = ""
ENT.CONSTS.MENU.SCAN = "scan"
ENT.CONSTS.MENU.OPERATE = "operate"
ENT.CONSTS.MENU.INJECT = "inject"


function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Patient" )
    self:NetworkVar( "String", 1, "SelectedMenu" )
    self:NetworkVar( "String", 2, "SelectedOperation" )
    self:NetworkVar( "Bool", 0, "DoScan" )

    if SERVER then
        self:SetPatient( NULL )
        self:SetSelectedMenu( "" )
        self:SetSelectedOperation( "" )
        self:SetDoScan( false )
    end
end