
ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Requisition Console"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.Model = 4


function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "ConsoleName", { KeyName = "ConsoleName",	Edit = { type = "String", order = 1 } } )
    self:NetworkVar( "String", 1, "ConsoleID", { KeyName = "ConsoleID",	Edit = { type = "String", order = 2 } } )

    if SERVER then
        self:SetConsoleName( self.PrintName )
        --self:SetConsoleID( "UNSC" )
    end

end