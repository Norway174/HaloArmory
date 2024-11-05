
AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )
 
ENT.PrintName = "Light Generator"
ENT.Category = "HALOARMORY - FOB"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.Model = "models/valk/h3/unsc/props/crates/generator_light.mdl" // Halo UNSC Prop Pack - Halo 3

ENT.Editable = true

ENT.FlashlightTexture = "effects/flashlight001"

-- Set up our data table
function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "On", { KeyName = "on", Edit = { type = "Boolean", order = 1, title = "#entedit.enabled" } } )
	self:NetworkVar( "Bool", 1, "Toggle", { KeyName = "toggle", Edit = { type = "Boolean", order = 2, title = "#tool.lamp.toggle" } } )
	self:NetworkVar( "Float", 0, "LightFOV", { KeyName = "fov", Edit = { type = "Float", order = 3, min = 10, max = 170, title = "#tool.lamp.fov" } } )
	self:NetworkVar( "Float", 1, "Distance", { KeyName = "dist", Edit = { type = "Float", order = 4, min = 64, max = 2048, title = "#tool.lamp.distance" } } )
	self:NetworkVar( "Float", 2, "Brightness", { KeyName = "bright", Edit = { type = "Float", order = 5, min = 0, max = 8, title = "#tool.lamp.brightness" } } )
    self:NetworkVar( "Vector", 0, "LightColor", { KeyName = "lightcolor", Edit = { type = "VectorColor", order = 6, title = "#tool.lamp.color" } } )
    self:NetworkVar( "Float", 3, "LightAngle", { KeyName = "angle", Edit = { type = "Float", order = 7, min = -45, max = 45, title = "Light Angle" } } )

	if ( SERVER ) then
		self:NetworkVarNotify( "On", self.OnUpdateLight )
		self:NetworkVarNotify( "LightFOV", self.OnUpdateLight )
		self:NetworkVarNotify( "Brightness", self.OnUpdateLight )
		self:NetworkVarNotify( "Distance", self.OnUpdateLight )
        self:NetworkVarNotify( "LightColor", self.OnUpdateLight )

        self:NetworkVarNotify( "LightAngle", self.OnUpdateLight )

        self:SetOn( true )
        self:SetLightFOV( 90 )
        self:SetDistance( 512 )
        self:SetBrightness( 1 )
        self:SetLightColor( Vector( 1, 1, 1 ) )
        self:SetLightAngle( 0 )
	end

end

function ENT:Initialize()

	if ( SERVER ) then

        self:SetModel( self.Model )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:DrawShadow( false )

		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then phys:Wake() end

	end

	if ( CLIENT ) then

		self.PixVis = util.GetPixelVisibleHandle()

	end

end

local defaultOffset = Vector( 1, 13, 89 )
local defaultAngle = Angle( 0, 90, 0 )
function ENT:GetLightInfo()

	local lightInfo = {}

    defaultAngle.z = self:GetLightAngle()

	lightInfo.Offset = lightInfo.Offset or defaultOffset
	lightInfo.Angle = lightInfo.Angle or defaultAngle
	lightInfo.NearZ = lightInfo.NearZ or 12
	lightInfo.Scale = lightInfo.Scale or 2
	lightInfo.Skin = lightInfo.Skin or 1

	return lightInfo

end



ENT.ToggleLightsGenProp = true

properties.Add( "toggle_lightsgen", {
    MenuLabel = "Toggle Lights", -- Name to display on the context menu
    Order = -90006, -- The order to display this property relative to other properties
    MenuIcon = "icon16/lightbulb.png", -- The icon to display next to the property
    PrependSpacer = false,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ent.ToggleLightsGenProp ) then return false end

        return true
    end,
    Action = function( self, ent )
        if ( not IsValid( ent ) ) then return end
        print( "Toggle Lights" )
        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()
    end,
    Receive = function( self, length, player )
        print( "Toggle Lights" )
        local ent = net.ReadEntity()
        if ( not IsValid( ent ) ) then return end
        ent:Toggle()
    end,
} )



if ( SERVER ) then

	function ENT:Think()

		self.BaseClass.Think( self )

		if ( !IsValid( self.flashlight ) ) then return end

		if ( string.FromColor( self.flashlight:GetColor() ) != string.FromColor( self:GetColor() ) ) then
			self.flashlight:SetColor( self:GetColor() )
			self:UpdateLight()
		end

	end

	function ENT:OnTakeDamage( dmginfo )

		self:TakePhysicsDamage( dmginfo )

	end

	function ENT:Switch( bOn )
		self:SetOn( bOn )
	end

	function ENT:OnSwitch( bOn )

		if ( bOn && IsValid( self.flashlight ) ) then return end

		if ( !bOn ) then

			SafeRemoveEntity( self.flashlight )
			self.flashlight = nil
			return

		end

		local lightInfo = self:GetLightInfo()

		self.flashlight = ents.Create( "env_projectedtexture" )
		self.flashlight:SetParent( self )

		-- The local positions are the offsets from parent..
		local offset = lightInfo.Offset * -1
		offset.x = offset.x + 5 -- Move the position a bit back to preserve old behavior. Ideally this would be moved by NearZ?

		self.flashlight:SetLocalPos( -offset )
		self.flashlight:SetLocalAngles( lightInfo.Angle )

		self.flashlight:SetKeyValue( "enableshadows", 1 )
		self.flashlight:SetKeyValue( "nearz", lightInfo.NearZ )
		self.flashlight:SetKeyValue( "lightfov", math.Clamp( self:GetLightFOV(), 10, 170 ) )

		local dist = self:GetDistance()
		if ( !game.SinglePlayer() ) then dist = math.Clamp( dist, 64, 2048 ) end
		self.flashlight:SetKeyValue( "farz", dist )

		local c = self:GetLightColor():ToColor()
		local b = self:GetBrightness()
		if ( !game.SinglePlayer() ) then b = math.Clamp( b, 0, 8 ) end
		self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

		self.flashlight:Spawn()

		self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.FlashlightTexture )

	end

	function ENT:Toggle()

		self:SetOn( !self:GetOn() )

	end

	function ENT:OnUpdateLight( name, old, new )

		if ( name == "On" ) then
			self:OnSwitch( new )
		end

		if ( !IsValid( self.flashlight ) ) then return end

		if ( name == "LightFOV" ) then
			self.flashlight:Input( "FOV", NULL, NULL, tostring( math.Clamp( new, 10, 170 ) ) )
		elseif ( name == "Distance" ) then
			if ( !game.SinglePlayer() ) then new = math.Clamp( new, 64, 2048 ) end
			self.flashlight:SetKeyValue( "farz", new )
		elseif ( name == "Brightness" ) then
			local c = self:GetLightColor():ToColor()
			local b = new
			if ( !game.SinglePlayer() ) then b = math.Clamp( b, 0, 8 ) end
			self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )
        elseif ( name == "LightColor" ) then
            local c = new:ToColor()
            local b = self:GetBrightness()
            if ( !game.SinglePlayer() ) then b = math.Clamp( b, 0, 8 ) end
            self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )
        elseif ( name == "LightAngle" ) then
            self.flashlight:SetLocalAngles( Angle( -new, 90, 0 ) )
		end

	end

	function ENT:UpdateLight()

		if ( !IsValid( self.flashlight ) ) then return end

		self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.FlashlightTexture )
		self.flashlight:Input( "FOV", NULL, NULL, tostring( math.Clamp( self:GetLightFOV(), 10, 170 ) ) )

		local dist = self:GetDistance()
		if ( !game.SinglePlayer() ) then dist = math.Clamp( dist, 64, 2048 ) end
		self.flashlight:SetKeyValue( "farz", dist )

		local c = self:GetLightColor():ToColor()
		local b = self:GetBrightness()
		if ( !game.SinglePlayer() ) then b = math.Clamp( b, 0, 8 ) end

        print( c, b )

		self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

	end

	-- The rest is for client only
	return
end

-- Show the name of the player that spawned it..
function ENT:GetOverlayText()

	return self:GetPlayerName()

end

local matLight = Material( "sprites/light_ignorez" )
--local matBeam = Material( "effects/lamp_beam" )
function ENT:DrawEffects()

	-- No glow if we're not switched on!
	if ( !self:GetOn() ) then return end

	local lightInfo = self:GetLightInfo()

	local LightPos = self:LocalToWorld( lightInfo.Offset )
	local LightNrm = self:LocalToWorldAngles( lightInfo.Angle ):Forward()

	-- glow sprite
	--[[
	render.SetMaterial( matBeam )

	local BeamDot = BeamDot = 0.25

	render.StartBeam( 3 )
		render.AddBeam( LightPos + LightNrm * 1, 128, 0.0, Color( r, g, b, 255 * BeamDot) )
		render.AddBeam( LightPos - LightNrm * 100, 128, 0.5, Color( r, g, b, 64 * BeamDot) )
		render.AddBeam( LightPos - LightNrm * 200, 128, 1, Color( r, g, b, 0) )
	render.EndBeam()
	--]]

	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )

	if ( ViewDot >= 0 ) then

		render.SetMaterial( matLight )
		local Visibile = util.PixelVisible( LightPos, 16, self.PixVis )

		if ( !Visibile ) then return end

		local Size = math.Clamp( Distance * Visibile * ViewDot * lightInfo.Scale, 64, 512 )

		Distance = math.Clamp( Distance, 32, 800 )
		local Alpha = math.Clamp( ( 1000 - Distance ) * Visibile * ViewDot, 0, 100 )
		local Col = self:GetColor()
		Col.a = Alpha

		render.DrawSprite( LightPos, Size, Size, Col )
		render.DrawSprite( LightPos, Size * 0.4, Size * 0.4, Color( 255, 255, 255, Alpha ) )

	end

end

ENT.WantsTranslucency = true -- If model is opaque, still call DrawTranslucent
function ENT:DrawTranslucent( flags )

	BaseClass.DrawTranslucent( self, flags )
	self:DrawEffects()

end


