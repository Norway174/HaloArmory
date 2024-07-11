
ENT.Type = "anim"
ENT.Base = "halo_sp_base"
 
ENT.PrintName = "Small Pad"
ENT.Category = "HALOARMORY - Vehicle Requisition"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.HALOARMORY_Device = true

ENT.DeviceName = "Vehicle Requisition Small"
ENT.DeviceType = "vehicle_requisition_small"

ENT.DeviceIcon = "vgui/haloarmory/icons/smallpad.png"

ENT.VehiclePad = true
ENT.VehicleSize = { "small" }

ENT.RequiresSupplies = true

ENT.VehicleQueue = {}

ENT.VehicleSpawnPos = Vector( 0, 0, 10 )
ENT.VehicleSpawnAng = Angle( 0, -90, 0 )
ENT.VehicleSpawnRadius = 100

ENT.DeviceModel = "models/valk/h4/unsc/props/vehiclepad/vehiclepad_unsc_small.mdl"
function ENT:SetupModel()
end

function ENT:CustomDataTablesAirPads()
end

function ENT:CustomDataTables()

    self:NetworkVar( "String", 3, "PadID", { KeyName = "PadID",	Edit = { type = "String", order = 1 } } )
    self:NetworkVar( "Entity", 1, "OnPad" )
    self:NetworkVar( "Entity", 2, "Building" )

    self:NetworkVar( "Bool", 0, "RequiresSupplies", { KeyName = "RequiresSupplies", Edit = { type = "Boolean", order = 2 } } )

    if SERVER then
        local random_uuid = util.CRC( tostring( self:EntIndex() ) .. "_" .. tostring( CurTime() ) .. "_" .. tostring( math.random( 0, 100000 ) ) )
        for i = 1, 10 do
            // Check if the UUID is already in use
            local found = false
            for k, v in pairs( ents.GetAll() ) do
                if !v.getPadID then continue end 
                if v:getPadID() == random_uuid then
                    random_uuid = util.CRC( tostring( self:EntIndex() ) .. "_" .. tostring( CurTime() ) .. "_" .. tostring( math.random( 0, 100000 ) ) )
                    found = true
                end
            end
            if !found then break end
        end
        self:SetPadID( random_uuid )
        
        self:SetOnPad( NULL )

        self:SetRequiresSupplies( self.RequiresSupplies or true )
    end

    self:CustomDataTablesAirPads()

end




function ENT:CanAfford( SelectedVehicle )

    if not self.RequiresSupplies then
        return true
    end

    local controller_network = util.JSONToTable( self:GetNetworkTable() )
    if not istable(controller_network) then return false end
    
    local CurrentResource, MaxResource = controller_network.Supplies, controller_network.MaxSupplies

    local Cost = 0
    if SelectedVehicle["cost"] then
        Cost = SelectedVehicle["cost"]
    end

    return Cost <= CurrentResource

end
