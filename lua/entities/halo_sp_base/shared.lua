
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Controller - Base"
ENT.Category = "HALOARMORY - Logistics"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.HALOARMORY_Device = true

ENT.DeviceName = "Base"
ENT.DeviceType = "base"

ENT.DeviceModel = "models/props_c17/oildrum001.mdl"
function ENT:SetupModel()
end

// This is literally the most convoluted fucked up shit
// First, we send the request from the client to the server.
// Then server sends that shit back to the client.
// To which then the client sets the Network Var.
// All for some stupid ass table of network names.
if SERVER then
    util.AddNetworkString( "HALOARMORY_Logistics_NetworkUpdate" )
end
function ENT:UpdateGlobalNetworks()
    if CLIENT then
        net.Start( "HALOARMORY_Logistics_NetworkUpdate" )
        net.WriteEntity( self )
        net.SendToServer()
        return
    end

    local networks = HALOARMORY.Logistics.SyncNetworks()

    self:NetworkVar( "String", 0, "NetworkID", { KeyName = "NetworkID",	Edit = { type = "Combo", order = 1, text = "Select network...", values = networks } } )
    if SERVER then self:NetworkVarNotify( "NetworkID", self.OnNetworkIDChanged ) end
end

if SERVER then
    net.Receive( "HALOARMORY_Logistics_NetworkUpdate", function( len, ply )
        --print( "Server recieved. Sending back to client.")
        local ent = net.ReadEntity()
        local network = HALOARMORY.Logistics.SyncNetworks()
        if istable( network ) then
            net.Start( "HALOARMORY_Logistics_NetworkUpdate" )
                net.WriteEntity( ent )
                net.WriteTable( network )
            net.Send( ply )
        end
    end )
else
    net.Receive( "HALOARMORY_Logistics_NetworkUpdate", function( len, ply )
        local ent = net.ReadEntity()
        local network = net.ReadTable()

        ent:NetworkVar( "String", 0, "NetworkID", { KeyName = "NetworkID",	Edit = { type = "Combo", order = 1, text = "Select network...", values = network } } )
    end )
end
// End of stupid shit. I hate this.

function ENT:CustomDataTables()
end

function ENT:SetupDataTables()

    self:UpdateGlobalNetworks()
    self:NetworkVar( "String", 1, "DeviceName", { KeyName = "DeviceName",	Edit = { type = "Generic", order = 2 } } )
    self:NetworkVar( "String", 2, "NetworkTable" )

    if SERVER then
        self:SetNetworkID( "0" )
        self:SetDeviceName( self.DeviceName )
        self:NetworkVarNotify( "NetworkID", self.OnNetworkIDChanged )
    end

    self:CustomDataTables()

end

function ENT:OnNetworkIDChanged( name, old, new )

    local network = HALOARMORY.Logistics.Networks[new]
    if istable(network) then
        self:SetNetworkTable( util.TableToJSON(network) )
    else
        self:SetNetworkTable( "false" )
    end

    self:UpdateGlobalNetworks()
end

function ENT:OnNetworkUpdate( network )
    if istable( network ) then
        self:SetNetworkTable( util.TableToJSON(network) )
    else
        self:SetNetworkTable( "false" )
    end
end




ENT.AllowNetworkMenu = true
properties.Add( "networks_menu", {
    MenuLabel = "Admin Networks", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/shield.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( !ent.AllowNetworkMenu ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end

        // Very sneaky code to update the network table
        ent:UpdateGlobalNetworks()
        // End of sneaky code

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        HALOARMORY.Logistics.OpenNetworkManagerGUI()
    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
    
    end
} )