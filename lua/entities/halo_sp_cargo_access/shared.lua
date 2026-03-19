
ENT.Type = "anim"
ENT.Base = "halo_sp_base"
 
ENT.PrintName = "Cargo Pallet"
ENT.Category = "HALOARMORY - Logistics"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.DeviceName = "Cargo Node"
ENT.DeviceType = "cargo_access"
ENT.RateM = 0 // Positive number to add resources, negative to take away, 0 to disable. Resources are updated every minute.

ENT.DeviceModel = "models/valk/haloreach/unsc/props/military/crate_packing_large_pallet.mdl" -- UNSC Prop Pack Redux - Halo Reach (2978964446)
function ENT:SetupModel()
end

ENT.PanelScale = .0664
ENT.SidePanelOffset = -1.9
ENT.SidePanelHeight = 0.777

ENT.frameW, ENT.frameH = 800, 100


ENT.Theme = {
    ["background"] = "ds",
    ["colors"] = {
        ["background_color"] = Color( 32, 32, 32, 0),
        ["background_logo_color"] = Color( 255, 255, 255),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
    },
}


function ENT:CustomDataTables()

    -- self:NetworkVar( "Vector", 0, "HeaderColor", { KeyName = "HeaderColor",	Edit = { type = "VectorColor", order = 3 } } )
    -- self:NetworkVar( "Int", 2, "RateM", { KeyName = "RateM",	Edit = { title = "Rate / min", type = "Int", order = 6, min = -9999, max = 9999 } } )

    -- if SERVER then
    --     self:SetHeaderColor( Color(18, 39, 133, 102):ToVector() )
    --     self:SetRateM( self.RateM )
    -- end

end


function ENT:ScanPad()
    local ents_on_pad = ents.FindInSphere( self:GetPos() + Vector(0,0,30), 50 )

    // Sort the ents_on_pad to only have cargo
    local cargo = {}
    for k, v in pairs( ents_on_pad ) do
        if v:GetClass() == "halo_sp_crate" then
            table.insert( cargo, v )
        end
    end

    return cargo

end
