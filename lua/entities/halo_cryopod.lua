AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Cryopod"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.IsHALOARMORY = true

ENT.Model = "models/valk/h4/unsc/props/cyropod/cyropod.mdl"

ENT.IsCryoPod = true



function ENT:Initialize()
    if self:GetModel() == "models/error.mdl" then self:SetModel( self.Model ) end

    self:SetRenderMode( RENDERMODE_TRANSALPHA )

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

    if (SERVER) then self:SetUseType( SIMPLE_USE ) end

    if CLIENT then return end

    // Add the seat
    local Pod = ents.Create( "prop_vehicle_prisoner_pod" )

    Pod:SetMoveType( MOVETYPE_NONE )
    --Pod:SetModel( "models/vehicles/prisoner_pod_inner.mdl" )
    Pod:SetModel( "models/nova/airboat_seat.mdl" )
    Pod:SetKeyValue( "vehiclescript", "scripts/vehicles/prisoner_pod.txt" )
    Pod:SetKeyValue( "limitview", 0 )
    Pod:SetPos( self:LocalToWorld( Vector( 0, 20, 10 ) ) )
    Pod:SetAngles( self:LocalToWorldAngles( Angle( 0, 0, 10 ) ) )
    Pod:SetOwner( self )
    Pod:Spawn()
    Pod:Activate()
    Pod:SetParent( self )
    Pod:SetNotSolid( true )
    Pod:SetNoDraw( true )

    Pod:SetColor( Color( 255, 255, 255, 0 ) )
    Pod:SetRenderMode( RENDERMODE_TRANSALPHA )
    Pod:DrawShadow( false )

    Pod.DoNotDuplicate = true

    self:DeleteOnRemove( Pod )

    local DSPhys = Pod:GetPhysicsObject()
	if IsValid( DSPhys ) then
		DSPhys:EnableDrag( false )
		DSPhys:EnableMotion( false )
		DSPhys:SetMass( 1 )
	end

    Pod.IsCryoPod = self.IsCryoPod

    Pod:SetNWEntity( "CryoPod", self )

    self.Pod = Pod

    --self:SetColor( Color( 255, 255, 255, 131) )

end

function ENT:Use(activator, caller)
    if IsValid(activator) && activator:IsPlayer() then
    
        if activator:InVehicle() then return end

        activator:EnterVehicle( self.Pod )

    end
end


function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = -90
	SpawnAng.y = SpawnAng.y + 90
    SpawnAng.x = SpawnAng.x + 90
    --SpawnAng.z = SpawnAng.z + 90

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end

if SERVER then
    // Add the exit hook, to make sure the player doesn't get stuck in the pod or in the roof.
    hook.Add( "PlayerLeaveVehicle", "HALOARMORY.CRYOPOD.EXIT", function( ply, veh )

        if not veh.IsCryoPod then return end

        hook.Remove( "PlayerLeaveVehicle", "HALOARMORY.CRYOPOD.EXIT" )
        hook.Remove( "CalcMainActivity", "HALOARMORY.CRYOPOD.ANIMS" )

        local exitpos = veh:LocalToWorld( Vector( 0, 60, 0 ) )
            
        ply:SetPos( exitpos )
        ply:SetEyeAngles( (veh:GetPos() - exitpos):Angle() )

    end )
end

hook.Add("CalcMainActivity", "HALOARMORY.CRYOPOD.ANIMS", function(ply, vel )


    if not ply:InVehicle() then return end

    local veh = ply:GetVehicle()
    local pod = veh:GetNWEntity( "CryoPod" )

    if not IsValid( pod ) then return end

    return ACT_DRIVE_POD, -1

end )

if CLIENT then

    hook.Add("CalcVehicleView", "HALOARMORY.CRYOPOD.CALCVIEW", function( veh, ply, view )

        local pod = veh:GetNWEntity( "CryoPod" )

        if not IsValid( pod ) then return end

        if ( veh.GetThirdPersonMode == nil || ply:GetViewEntity() != ply ) then
            -- This shouldn't ever happen.
            return
        end

        local eye = ply:GetBonePosition( ply:LookupBone( "ValveBiped.Bip01_Head1" ) )
        view.origin = eye
    
        --
        -- If we're not in third person mode - then get outa here stalker
        --
        if ( !veh:GetThirdPersonMode() ) then return view end
    
        -- Don't roll the camera
        -- view.angles.roll = 0
    
        local mn, mx = veh:GetRenderBounds()
        local radius = ( mn - mx ):Length()
        radius = radius + radius * veh:GetCameraDistance()
    
        -- Trace back from the original eye position, so we don't clip through walls/objects
        local TargetOrigin = view.origin + ( view.angles:Forward() * -radius )
        local WallOffset = 4
    
        local tr = util.TraceHull( {
            start = view.origin,
            endpos = TargetOrigin,
            filter = function( e )
                local c = e:GetClass() -- Avoid contact with entities that can potentially be attached to the vehicle. Ideally, we should check if "e" is constrained to "Vehicle".
                if e ~= pod:GetClass() then return end
                return !c:StartWith( "prop_physics" ) &&!c:StartWith( "prop_dynamic" ) && !c:StartWith( "phys_bone_follower" ) && !c:StartWith( "prop_ragdoll" ) && !e:IsVehicle() && !c:StartWith( "gmod_" )
            end,
            mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
            maxs = Vector( WallOffset, WallOffset, WallOffset ),
        } )
    
        view.origin = tr.HitPos
        view.drawviewer = true
    
        --
        -- If the trace hit something, put the camera there.
        --
        if ( tr.Hit && !tr.StartSolid) then
            view.origin = view.origin + tr.HitNormal * WallOffset
        end
    
        return view

    end )


end