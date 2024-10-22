
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:SpawnCargo( ply, amount, CargoName, CargoModel )

    // If there are more than 10 cargo crates, don't spawn any more
    local ListOfCargo = ents.FindByClass( "halo_sp_crate" )
    if #ListOfCargo > 20 then return end // Max 10 cargo crates globally


    local name = self:GetNetworkID()
    local CurrentSupplies, MaxSupplies = HALOARMORY.Logistics.GetNetworksupplies( name )

    --print( "Spawned cargo", amount, CurrentSupplies, math.Clamp( amount, 1, CurrentSupplies ) )

    --if not CurrentSupplies then return end
    --if CurrentSupplies == 0 then return end
    --if amount == 0 then return end

    local Cargo = ents.Create( "halo_sp_crate" )
    
    // Spawn the crates 50 units in front of the spawner
    local pos = self:GetPos() + (self:GetUp() * 75)
    Cargo:SetPos( pos )
    Cargo:SetAngles( self:GetAngles() )


    // Pick a random model from DeviceModelAlts
    local _, model = table.Random( Cargo.DeviceModelAlts )
    Cargo.DeviceModel = CargoModel or model

    Cargo:SetBoxName(CargoName or "Crate")

    Cargo:Spawn()

    Cargo:SetStored( math.Clamp( amount, 0, CurrentSupplies ) )

    local network_name = self:GetNetworkID()

    HALOARMORY.Logistics.AddNetworkSupplies( network_name, -amount)

    // Add to undo
    -- undo.Create( "halo_sp_crate" )
    --     undo.AddEntity( Cargo )
    --     undo.SetPlayer( ply )
    --     undo.AddFunction( function( tab, network_name_undo, amount_undo )
    --         print( "Undoing", network_name_undo, amount_undo )
    --         HALOARMORY.Logistics.AddNetworkSupplies( network_name_undo, amount_undo )
    --     end, network_name, Cargo:GetStored() )
    -- undo.Finish()

    return true

end


function ENT:InsertCargo( ply, cargo_ent, amount )

    local name = self:GetNetworkID()


    local current_cargo = cargo_ent:GetStored()
    local new_cargo = math.Clamp( amount, -cargo_ent:GetMaxCapacity(), cargo_ent:GetMaxCapacity() )

    print( "Inserting cargo", cargo_ent, amount, new_cargo )

    --cargo_ent:SetStored( new_cargo )


    local success, inserted = HALOARMORY.Logistics.AddNetworkSupplies( name, new_cargo )

    print( "Inserting cargo 2", success, inserted )

    if success then
        cargo_ent:SetStored( math.Clamp(current_cargo - inserted, 0, cargo_ent:GetMaxCapacity()) )
    end


end