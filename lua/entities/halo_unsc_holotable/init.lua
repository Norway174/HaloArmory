
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_map.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:Initialize()
 
	-- Sets what model to use
	self:SetModel( self.TableMdl )

    // Reset the color and submaterials
    self:SetColor(Color(255, 255, 255))
    self:SetSubMaterial(nil, nil)

    // Custom model setup
    for k, v in pairs(self.ScreenModels) do
        if v["model"] == self:GetModel() then
            self.SelectedModel = k
            break
        end
    end

    if istable(self.ScreenModels[self.SelectedModel]) and isfunction(self.ScreenModels[self.SelectedModel]["model_func"]) then
        self.ScreenModels[self.SelectedModel]["model_func"](self)
    end

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


end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = -90
	SpawnAng.y = SpawnAng.y + 180
    SpawnAng.x = SpawnAng.x + 180
    -- SpawnAng.z = SpawnAng.z + 90

    SpawnPos.z = SpawnPos.z + 35

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    
    // Add the legs
    local legs = ents.Create("prop_physics")
    legs:SetModel( ent.TableLegsMdl )
    legs:SetMaterial( "models/gibs/metalgibs/metal_gibs" )
    legs:SetPos( ent:LocalToWorld( Vector(22.847641, -1.557750, -4.312500) ) )
    legs:SetAngles( ent:GetAngles() )
    legs:Spawn()
    legs:Activate()

    constraint.Weld( legs, ent, 0, 0, 0, true, true )


    return ent

end


function ENT:PreInit()
end