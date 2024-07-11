
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

ENT.DeviceModel = "models/valk/halo2a/unsc/props/military/crate_packing_pallet.mdl"
function ENT:SetupModel()
end

ENT.PanelPos = Vector(19.5, 20.5, 17.5)
ENT.PanelAng = Angle(0, -90, 0)
ENT.PanelScale = .0664

ENT.frameW, ENT.frameH = 616, 585


ENT.Theme = {
    ["background"] = "vgui/character_creator/unsc_logo_black.png",
    ["colors"] = {
        ["background_color"] = Color( 29, 29, 29),
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