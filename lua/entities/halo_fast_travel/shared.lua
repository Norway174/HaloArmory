

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Fast Travel Terminal"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true


ENT.Editable = true

local CONSTS = {
    NETWORK = "HALOARMORY.FASTTRAVEL",
    ACTIONS = {
        TELEPORT = 1,
        SYNC = 2,
        SYNC_ALL = 3,
        REMOVE = 4,
    },
}

local Destinations = {}

ENT.Editable = true

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "Destination", { KeyName = "Destination Name",	Edit = { type = "Generic", order = 1 } } )
    self:NetworkVar( "Bool", 0, "Enabled", { KeyName = "Enabled",	Edit = { type = "Boolean", order = 2 } } )


    if SERVER then
        self:SetDestination( "N/A" )
        self:SetEnabled( false )

        self:NetworkVarNotify( "Destination", function( ent, name, old, new )
            timer.Simple( 0.1, function()
                ent:NetSync()
            end )
        end )

        self:NetworkVarNotify( "Enabled", function( ent, name, old, new )
            timer.Simple( 0.1, function()
                ent:NetSync()
            end )
        end )
    end

end

ENT.FastTravelScreen = true

properties.Add( "update_destinations", {
    MenuLabel = "Refresh Destinations", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/arrow_refresh.png", -- The icon to display next to the property
    PrependSpacer = true, -- Prepend a spacer between this one and the one before it
    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        return ent.FastTravelScreen or false
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()

    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        local ent = net.ReadEntity()

        if ( !self:Filter( ent, ply ) ) then return end

        ent:NetSyncAll()
    end 
} )