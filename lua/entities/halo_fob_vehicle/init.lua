
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")



function ENT:Initialize()
    if not self.Deployed then
        self:Undeploy()
    else
        self:Deploy()
    end
end


function ENT:Undeploy()

    if self.Vehicle and IsValid( self.Vehicle ) then
        self.Vehicle:Remove()
    end

    local phys = self:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        self:PhysicsDestroy()
    end

    local pos = isvector(self.OriginalPos) and self.OriginalPos or self:GetPos()
    local ang = isangle(self.OriginalAng) and self.OriginalAng or self:GetAngles()

    // Create a simphys vehicle
    self.Vehicle = simfphys.SpawnVehicleSimple( self.VehicleEnt, pos + Vector( 0,0,20 ), ang ) -- [Simfphys] Halo 5

    self:DeleteOnRemove( self.Vehicle )

    self:SetModel( self.VehiclePackagedModel )

    print( "Vehicle spawned:", self.Vehicle, pos, ang)

    self:SetPos( pos )
    self:SetAngles( ang )
    self:SetParent( self.Vehicle )

    self.Deployed = false
    self:SetNW2Bool( "Deployed", false )

    self.Vehicle:SetNW2Entity( "FOB", self )

    HALOARMORY.Ships.WipeProps( self )

end


function ENT:Deploy()

    if self.Vehicle and IsValid( self.Vehicle ) then
        self:DontDeleteOnRemove( self.Vehicle )
        self:SetParent( nil )

        self.OriginalPos = self.Vehicle:GetPos()
        self.OriginalAng = self.Vehicle:GetAngles()

        self.Vehicle:Remove()

    end

    self:SetModel( self.DeployedModel )


    local pos = self:GetPos()
    local ang = self:GetAngles()

    // Fix the angles, it should always remain flat, only rotate around the Z axis.
    ang.p = 0
    ang.r = 0

    ang.y = ang.y + 180

    self:SetPos( pos )
    self:SetAngles( ang )

    -- Physics stuff
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    -- Init physics only on server, so it doesn't mess up physgun beam
    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end

    local phys = self:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:Wake()
        --phys:Sleep()
        phys:EnableMotion( false )
    end
    

    self.Deployed = true
    self:SetNW2Bool( "Deployed", true )

    if self:GetAutoLoadPreset() ~= "" then
        HALOARMORY.Ships.LoadShip( self, self:GetAutoLoadPreset() )
    end

end


function ENT:ToggleDeploy()
    if self.Deployed then
        self:Undeploy()
    else
        self:Deploy()
    end
end


concommand.Add( "halo_fob_vehicle_toggle_deploy", function( ply, cmd, args )

    // Args: Entity Index
    local entIndex = tonumber( args[1] )
    local ent = Entity( entIndex )

    if not IsValid( ent ) then return end

    print( "Toggling deploy on", ent )

    if isfunction( ent.ToggleDeploy ) then
        ent:ToggleDeploy()
    end

end )

concommand.Add( "halo_fob_vehicle_deploy", function( ply, cmd, args )

    // Args: Entity Index
    local entIndex = tonumber( args[1] )
    local ent = Entity( entIndex )

    if not IsValid( ent ) then return end

    print( "Deploying", ent )

    if isfunction( ent.Deploy ) then
        ent:Deploy()
    end

end )

concommand.Add( "halo_fob_vehicle_undeploy", function( ply, cmd, args )

    // Args: Entity Index
    local entIndex = tonumber( args[1] )
    local ent = Entity( entIndex )

    if not IsValid( ent ) then return end

    print( "Undeploying", ent )

    if isfunction( ent.Undeploy ) then
        ent:Undeploy()
    end

end )

