
ENT.Type = "anim"
ENT.Base = "halo_pc_base"
 
ENT.PrintName = "Requisition Console"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true


function ENT:CustomDataTables()

    self:NetworkVar( "String", 0, "ConsoleName", { KeyName = "ConsoleName",	Edit = { type = "String", order = 1 } } )
    self:NetworkVar( "String", 1, "ConsoleID", { KeyName = "ConsoleID",	Edit = { type = "String", order = 2 } } )

    if SERVER then
        self:SetConsoleName( self.PrintName )
        --self:SetConsoleID( "UNSC" )
    end

end