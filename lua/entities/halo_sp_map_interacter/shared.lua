
ENT.Type = "anim"
ENT.Base = "halo_sp_base"
 
ENT.PrintName = "Map Interacter"
ENT.Category = "HALOARMORY - Logistics"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true


ENT.DeviceName = "Map Interacter"
ENT.DeviceType = "map_interacter"

ENT.DeviceModel = "models/props_lab/reciever01b.mdl"



function ENT:CustomDataTables()

    self:NetworkVar( "String", 3, "MapEntity", { KeyName = "MapEntity",	Edit = { title = "Map Entity ID", type = "Generic", order = 3 } } )
    self:NetworkVar( "Bool", 1, "Toggled", { KeyName = "Toggled",	Edit = { title = "Toggled", type = "Boolean", order = 5 } } )
    self:NetworkVar( "Int", 2, "TriggerMin", { KeyName = "TriggerMin",	Edit = { title = "Min %", type = "Int", order = 6, min = 0, max = 100 } } )
    self:NetworkVar( "Int", 3, "TriggerMax", { KeyName = "TriggerMax",	Edit = { title = "Max %", type = "Int", order = 7, min = 0, max = 100 } } )
    self:NetworkVar( "Bool", 2, "PressOnToggle", { KeyName = "PressOnToggle",	Edit = { title = "Press on Toggled", type = "Boolean", order = 8 } } )
    self:NetworkVar( "Bool", 3, "LockedOn", { KeyName = "LockedOn",	Edit = { title = "Locked ON", type = "Boolean", order = 9 } } )
    self:NetworkVar( "Bool", 4, "LockedOff", { KeyName = "LockedOff",	Edit = { title = "Locked OFF", type = "Boolean", order = 10 } } )

    if SERVER then

        self:SetMapEntity( "" )
        self:SetToggled( false )
        self:SetTriggerMin( 0 )
        self:SetTriggerMax( 1 )
        self:SetPressOnToggle( true )
        self:SetLockedOn( true )
        self:SetLockedOff( true )


        self:NetworkVarNotify( "MapEntity", self.OnMapEntityChanged )

        self:NetworkVarNotify( "Toggled", self.OnLinkToggled )
        self:NetworkVarNotify( "LockedOn", self.OnLockUpdate )
        self:NetworkVarNotify( "LockedOff", self.OnLockUpdate )

    end

end


--[[ 
    lua_run print( Entity(2301):Fire( "Press" ) )
> print( Entity(2301):GetName() )...
BaseLightsToggle 
]]