
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( self.BedModel )

	-- Sets what color to use
	--self:SetColor( Color( 200, 255, 200 ) )

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

    -- Create a seat for the player to sit in
    self.PodSeat = ents.Create( 'prop_vehicle_prisoner_pod' )
    self.PodSeat:SetModel( "models/vehicles/prisoner_pod_inner.mdl" )
    self.PodSeat:SetPos( self:LocalToWorld(Vector(0,34,40)) )
    self.PodSeat:SetAngles( self:LocalToWorldAngles(Angle(-90,90,0)) )
    self.PodSeat:SetKeyValue( "limitview", 0 )
    self.PodSeat:SetNoDraw( true )
    self.PodSeat:SetColor( Color( 255, 255, 255, 0 ) )

    self.PodSeat:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    self.PodSeat:Spawn()
    self.PodSeat:SetParent( self )
    self:DeleteOnRemove( self.PodSeat)

    -- Create a vertical metal beam
    self.MetalBeamVert = ents.Create( "prop_dynamic" )
    self.MetalBeamVert:SetModel( "models/xeon133/slider/slider_12x12x96.mdl" )
    self.MetalBeamVert:SetColor( Color( 255, 255, 255, 255 ) )
    self.MetalBeamVert:SetMaterial( "phoenix_storms/Future_vents" )
    self.MetalBeamVert:SetPos( self:LocalToWorld(Vector(0,-45,50)) )
    self.MetalBeamVert:SetAngles( self:LocalToWorldAngles(Angle(-90,0,0)) )

    self.MetalBeamVert:Spawn()
    self.MetalBeamVert:SetParent( self )
    self:DeleteOnRemove(self.MetalBeamVert)

    -- Create a horizontal metal beam
    self.MetalBeamHori = ents.Create( "prop_dynamic" )
    self.MetalBeamHori:SetModel( "models/xeon133/slider/slider_12x12x48.mdl" )
    self.MetalBeamHori:SetColor( Color( 255, 255, 255, 255 ) )
    self.MetalBeamHori:SetMaterial( "phoenix_storms/Future_vents" )
    self.MetalBeamHori:SetPos( self:LocalToWorld(Vector(0,-27,104)) )
    self.MetalBeamHori:SetAngles( self:LocalToWorldAngles(Angle(0,-90,0)) )

    self.MetalBeamHori:Spawn()
    self.MetalBeamHori:SetParent( self )
    self:DeleteOnRemove(self.MetalBeamHori)

    // Create a vertical screen
    self.Screen1 = ents.Create( "halo_tv_autodoc_screen" )
    self.Screen1:SetPos( self:LocalToWorld(Vector(2.5,-40,70)) )
    self.Screen1:SetAngles( self:LocalToWorldAngles(Angle(0,-90,0)) )

    self.Screen1:Spawn()
    self.Screen1:Activate()
    self.Screen1:SetParent( self )
    self:DeleteOnRemove(self.Screen1)


    // Create a horizontal screen
    self.Screen2 = ents.Create( "halo_tv_autodoc_screen" )
    self.Screen2:SetPos( self:LocalToWorld(Vector(-2.5,-5,97)) )
    self.Screen2:SetAngles( self:LocalToWorldAngles(Angle(-90,-90,180)) )

    self.Screen2:Spawn()
    self.Screen2:SetParent( self )
    self:DeleteOnRemove(self.Screen2)


end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = -90
	SpawnAng.y = SpawnAng.y + 180
    SpawnAng.x = SpawnAng.x + 90
    -- SpawnAng.z = SpawnAng.z + 90

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end


ENT.lastHeal = 0
ENT.last_patient = nil

function ENT:Think()

    // Optimisation - only do this if the player has changed
    if self.PodSeat:GetDriver() != self.last_patient then
        self.last_patient = self.PodSeat:GetDriver()
        self:SetPatient( self.PodSeat:GetDriver() )
        self:SetDoScan( tobool( IsValid(self.last_patient) ) )
    end


    // Check if the player is in the pod
    if ( IsValid( self.last_patient ) ) then
        
        // Slowly over time, heal the patient
        if ( CurTime() > self.lastHeal + 3 ) then
            self.lastHeal = CurTime()
            // Heal the player
            if ( self.last_patient:Health() < self.last_patient:GetMaxHealth() ) then
                self.last_patient:SetHealth( self.last_patient:Health() + 1 )

            // Heal the player's armor
            elseif ( self.last_patient:Armor() < self.last_patient:GetMaxArmor() ) then
                self.last_patient:SetArmor( self.last_patient:Armor() + 1 )

            end
            
        end
        
    end

end

util.AddNetworkString( "HALOARMORY.AUTODOC.KICKPATIENT" )
util.AddNetworkString( "HALOARMORY.AUTODOC.SELECTMENU" )

net.Receive( "HALOARMORY.AUTODOC.KICKPATIENT", function( len, ply )

    local ent = net.ReadEntity()
    if ( !IsValid( ent ) ) then return end

    local patient = ent:GetPatient()
    if ( !IsValid( patient ) ) then return end

    patient:ExitVehicle()

end )

net.Receive( "HALOARMORY.AUTODOC.SELECTMENU", function( len, ply )

    local ent = net.ReadEntity()
    if ( !IsValid( ent ) ) then return end

    local menu_name = net.ReadString()
    ent:SetSelectedMenu( menu_name )

end )