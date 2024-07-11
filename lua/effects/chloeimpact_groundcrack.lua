
local maxScale = GetConVar("chloeimpact_max_scale")
local maxChunks = GetConVar("chloeimpact_max_debris_props")
local maxDust = GetConVar("chloeimpact_max_debris_effects")
local lifetime = GetConVar("chloeimpact_impact_lifetime")
local lifetimedebris = GetConVar("chloeimpact_impact_debris_lifetime")
local rocks = {
	"models/props_debris/physics_debris_rock1.mdl",
	"models/props_debris/physics_debris_rock2.mdl",
	"models/props_debris/physics_debris_rock3.mdl",
	"models/props_debris/physics_debris_rock5.mdl",
	"models/props_debris/physics_debris_rock7.mdl",
	"models/props_debris/physics_debris_rock8.mdl",
	"models/props_debris/physics_debris_rock9.mdl",
	"models/props_debris/physics_debris_rock10.mdl",
	"models/props_debris/physics_debris_rock11.mdl",
}

local ant_gibs = {
	"models/gibs/antlion_gib_medium_1.mdl",
	"models/gibs/antlion_gib_medium_2.mdl",
	"models/gibs/antlion_gib_medium_3.mdl",
	"models/gibs/antlion_gib_medium_3a.mdl",
	"models/gibs/antlion_gib_small_1.mdl",
	"models/gibs/antlion_gib_small_2.mdl",
	"models/gibs/antlion_gib_small_3.mdl",
}
local metal_gibs = {
	"models/props_debris/metal_panelshard01a.mdl",
	"models/props_debris/metal_panelshard01b.mdl",
	"models/props_debris/metal_panelshard01c.mdl",
	"models/props_debris/metal_panelshard01d.mdl",
}

for k,v in pairs(rocks) do
	util.PrecacheModel(v)
end
for k,v in pairs(ant_gibs) do
	util.PrecacheModel(v)
end
for k,v in pairs(metal_gibs) do
	util.PrecacheModel(v)
end

local matlist = {}

local DebrisScale = GetConVar("chloeimpact_effects_scale")

local mat_cover = CreateMaterial("impact_rock", "VertexLitGeneric", {
	["$vertexcolor"] = 1,
	["$basetexture"] = "",
	["$translucent"] = 0,
})

local matSpecific = {
	[MAT_ANTLION] = function(self)
		local fx = EffectData()
		fx:SetOrigin(self.Pos)
		fx:SetNormal(self.Normal)
		fx:SetMagnitude(self.Scale)
		fx:SetRadius(self.Scale)
		fx:SetScale(self.Scale)
		util.Effect("AntlionGib", fx, true, true)
		for i=1, math.min(maxChunks:GetInt(), self.Scale/20) do
			local mdl = ents.CreateClientProp(table.Random(ant_gibs))
			local dir = VectorRand()
			dir.x = dir.x / 55
			dir:Rotate(self.Normal:Angle())
			dir:Normalize()
			mdl:SetPos(self.Pos + self.Normal * 24)
			local dir2 = ((self.Pos - (self.Normal * 70) + self.AttackAngle)):GetNormalized()
			mdl:SetAngles(dir2:Angle())
			mdl:Spawn()
			mdl:Activate()
			mdl:GetPhysicsObject():SetVelocity((self.AttackAngle)/4)
			table.insert(self.CSProps, mdl)
			mdl:SetNoDraw(true)
		end
	end,
	[MAT_FLESH] = function(self)
	end,
	[MAT_CONCRETE] = function(self)
		for i=1, math.min(maxDust:GetInt(), self.Scale) do
			local AttackDir = self.AttackAngle * 1
			AttackDir = self.Normal * 2 + AttackDir
			self.Pos = self.OPos + AttackDir/300 * i
			--Smoke Plume
			local velocity = (self.Normal + AttackDir/300 + (VectorRand() * 0.65)):GetNormalized() * (math.Rand(100, 100) * self.Scale/200)
			
			local p = self.Emitter:Add("particle/particle_smoke_dust", self.Pos + VectorRand() * self.Scale/5)
			p:SetDieTime(math.Clamp(math.Rand(1, 2) * self.Scale/100, 0.5, 3))
			p:SetVelocity(self.Normal + ((AttackDir/5) * math.random(-1,1)))
			p:SetAirResistance(200)
			p:SetStartAlpha(15)
			p:SetEndAlpha(0)
			p:SetStartSize(math.random(36, 67) * self.Scale/300)
			p:SetEndSize(math.random(125, 250) * self.Scale/300)
			p:SetRollDelta(math.Rand(-0.25, 0.25))
			p:SetColor(100,100, 100)
		end
		for i=1, math.min(maxChunks:GetInt(), self.Scale/15) do
			local mdl = ents.CreateClientProp(table.Random(rocks))
			local dir = VectorRand()
			dir.x = dir.x / 55
			dir:Rotate(self.Normal:Angle())
			dir:Normalize()
			mdl:SetPos(self.Pos + self.Normal * 12)
			local dir2 = ((self.Pos - (self.Normal * 70))):GetNormalized()
			mdl:SetAngles(dir2:Angle())
			mdl:Spawn()
			mdl:SetModelScale(math.Clamp(self.Scale/100, 0.2, 1) * DebrisScale:GetFloat())
			mdl:Activate()
			debugoverlay.Line(self.Pos, self.Pos + (self.Normal * 300))
			if not IsValid(mdl:GetPhysicsObject()) then mdl:Remove() continue end
			mdl:GetPhysicsObject():SetVelocity((dir2 * 100 + VectorRand()))
			table.insert(self.CSProps, mdl)
		end
		if self.Scale > 120 then
			local distmod = self.Pos:Distance(self.OPos)/500
			for i=1, math.min(maxChunks:GetInt()/2, self.Scale/distmod) do
				local AttackDir = self.AttackAngle * 1.3
				AttackDir = self.Normal * 2 + AttackDir
				self.Pos = self.OPos + (AttackDir * (i / math.min(maxChunks:GetInt()/2, self.Scale)))
				local mdl = ClientsideModel(table.Random(rocks))
				mdl:SetModelScale(math.Rand(3, self.Scale/100) * DebrisScale:GetFloat())
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl.IdealPos = (self.Pos + (dir * (100) * math.Rand(0.1, 1) * self.Scale/300))
				if self.HitAngle == 2 then
					self.Pos = self.OPos
				end
				local tr = util.TraceHull({
					start=mdl.IdealPos,
					endpos=mdl.IdealPos,
					mask = MASK_SOLID,
					mins=-Vector(15,15,15),
					maxs=Vector(15,15,15)
				})
				if tr.Hit then
					mdl:SetPos(self.Pos - self.Normal + dir * (self.Scale/4) * math.Rand(0.6,2) )
					local dir2 = (mdl.IdealPos - (self.Pos - (self.Normal * 15))):GetNormalized()
					mdl:SetAngles(dir2:Angle())
					mdl:Spawn()
					mdl:Activate()
					mdl:SetNoDraw(true)
					table.insert(self.CSModels, mdl)
					
				else
					mdl:Remove()
				end
				local mdl = ents.CreateClientProp(table.Random(rocks))
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl:SetPos(self.Pos + self.Normal * 24)
				local dir2 = ((self.Pos - (self.Normal * 70) + self.AttackAngle)):GetNormalized()
				mdl:SetAngles(dir2:Angle())
				mdl:Spawn()
				mdl:Activate()
				mdl:SetNoDraw(true)
				if IsValid(mdl) and IsValid(mdl:GetPhysicsObject()) then
					mdl:Activate()
					mdl:GetPhysicsObject():SetVelocity((self.AttackAngle)/4)
					mdl:GetPhysicsObject():SetMaterial("concrete")
				end
				table.insert(self.CSProps, mdl)
			end
		end
	end,
	[MAT_METAL] = function(self)
		for i=1, math.min(maxDust:GetInt(), self.Scale) do
			local AttackDir = self.AttackAngle * 1
			AttackDir = self.Normal * 2 + AttackDir
			self.Pos = self.OPos + AttackDir/300 * i
			--Smoke Plume
			local velocity = (self.Normal + AttackDir/300 + (VectorRand() * 0.65)):GetNormalized() * (math.Rand(100, 100) * self.Scale/200)
			
			local p = self.Emitter:Add("particle/particle_smoke_dust", self.Pos + VectorRand() * self.Scale/5)
			p:SetDieTime(math.Clamp(math.Rand(1, 2) * self.Scale/100, 0.5, 3))
			p:SetVelocity(self.Normal + ((AttackDir/5) * math.random(-1,1)))
			p:SetAirResistance(200)
			p:SetStartAlpha(15)
			p:SetEndAlpha(0)
			p:SetStartSize(math.random(36, 67) * self.Scale/300)
			p:SetEndSize(math.random(125, 250) * self.Scale/300)
			p:SetRollDelta(math.Rand(-0.25, 0.25))
			p:SetColor(100,100, 100)
		end
		if self.Scale > 120 then
			local distmod = self.Pos:Distance(self.OPos)/500
			for i=1, math.min(maxChunks:GetInt()/2, self.Scale/distmod) do
				local AttackDir = self.AttackAngle * 1.3
				AttackDir = self.Normal * 2 + AttackDir
				self.Pos = self.OPos + (AttackDir * (i / math.min(maxChunks:GetInt()/2, self.Scale)))
				debugoverlay.Cross(self.Pos, 15)
				local mdl = ClientsideModel(table.Random(metal_gibs))
				mdl:SetModelScale(math.Rand(3, self.Scale/100) * DebrisScale:GetFloat())
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl.IdealPos = (self.Pos + (dir * (100) * math.Rand(0.1, 1) * self.Scale/300))
				if self.HitAngle == 2 then
					self.Pos = self.OPos
				end
				local tr = util.TraceHull({
					start=mdl.IdealPos,
					endpos=mdl.IdealPos,
					mask = MASK_SOLID,
					mins=-Vector(15,15,15),
					maxs=Vector(15,15,15)
				})
				if tr.Hit then
					mdl:SetPos(self.Pos - self.Normal + dir * (self.Scale/4) * math.Rand(0.6,2) )
					local dir2 = (mdl.IdealPos - (self.Pos - (self.Normal * 15))):GetNormalized()
					mdl:SetAngles(dir2:Angle())
					mdl:Spawn()
					mdl:Activate()
					mdl:SetNoDraw(true)
					table.insert(self.CSModels, mdl)
					
				else
					mdl:Remove()
				end
				local mdl = ents.CreateClientProp(table.Random(metal_gibs))
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl:SetPos(self.Pos + self.Normal * 24)
				local dir2 = ((self.Pos - (self.Normal * 70) + self.AttackAngle)):GetNormalized()
				mdl:SetAngles(dir2:Angle())
				mdl:Spawn()
				mdl:Activate()
				mdl:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
				mdl:SetNoDraw(true)
				if IsValid(mdl) and IsValid(mdl:GetPhysicsObject()) then
					mdl:Activate()
					mdl:GetPhysicsObject():SetVelocity((self.AttackAngle + VectorRand() * self.Scale))
					mdl:GetPhysicsObject():SetMaterial("metal")
				end
				table.insert(self.CSProps, mdl)
			end
		end
	end,
	[MAT_DIRT] = function(self)
		for i=1, math.min(maxDust:GetInt(), self.Scale) do
			local AttackDir = self.AttackAngle * 1
			AttackDir = self.Normal * 2 + AttackDir
			self.Pos = self.OPos + AttackDir/300 * i
			--Smoke Plume
			local velocity = (self.Normal + AttackDir/300 + (VectorRand() * 0.65)):GetNormalized() * (math.Rand(100, 100) * self.Scale/200)
			
			local p = self.Emitter:Add("particle/particle_smoke_dust", self.Pos + AttackDir:GetNormalized() * 15 * i)
			p:SetDieTime(math.Clamp(math.Rand(0.1, 0.5) * self.Scale/100, 0.5, 3))
			p:SetVelocity(VectorRand() * 5 + self.Normal + ((AttackDir/3) * math.random(-1,1)))
			p:SetAirResistance(200)
			p:SetStartAlpha(55)
			p:SetEndAlpha(0)
			p:SetStartSize(math.random(55, 125) * self.Scale/300)
			p:SetEndSize(math.random(125, 450) * self.Scale/300)
			p:SetRollDelta(math.Rand(-0.25, 0.25))
			p:SetColor(200,150, 100)
		end
		if self.Scale > 120 then
			local distmod = self.Pos:Distance(self.OPos)/500
			for i=1, math.min(maxChunks:GetInt()/2, self.Scale/distmod) do
				local AttackDir = self.AttackAngle * 1.3
				AttackDir = self.Normal * 2 + AttackDir
				self.Pos = self.OPos + (AttackDir * (i / math.min(maxChunks:GetInt()/2, self.Scale)))
				debugoverlay.Cross(self.Pos, 15)
				local mdl = ClientsideModel(table.Random(rocks))
				mdl:SetModelScale(math.Rand(3, self.Scale/100) * DebrisScale:GetFloat())
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl.IdealPos = (self.Pos + (dir * (100) * math.Rand(0.1, 1) * self.Scale/300))
				if self.HitAngle == 2 then
					self.Pos = self.OPos
				end
				local tr = util.TraceHull({
					start=mdl.IdealPos,
					endpos=mdl.IdealPos,
					mask = MASK_SOLID,
					mins=-Vector(15,15,15),
					maxs=Vector(15,15,15)
				})
				if tr.Hit then
					mdl:SetPos(self.Pos - self.Normal + dir * (self.Scale/4) * math.Rand(0.6,2) )
					local dir2 = (mdl.IdealPos - (self.Pos - (self.Normal * 15))):GetNormalized()
					mdl:SetAngles(dir2:Angle())
					mdl:Spawn()
					mdl:Activate()
					mdl:SetNoDraw(true)
					table.insert(self.CSModels, mdl)
					
				else
					mdl:Remove()
				end
				local mdl = ents.CreateClientProp(table.Random(rocks))
				local dir = VectorRand()
				dir.x = dir.x / 55
				dir:Rotate(self.Normal:Angle())
				dir:Normalize()
				mdl:SetPos(self.Pos + self.Normal * 24)
				local dir2 = ((self.Pos - (self.Normal * 70) + self.AttackAngle)):GetNormalized()
				mdl:SetAngles(dir2:Angle())
				mdl:Spawn()
				mdl:Activate()
				mdl:SetNoDraw(true)
				if IsValid(mdl) and IsValid(mdl:GetPhysicsObject()) then
					mdl:Activate()
					mdl:GetPhysicsObject():SetVelocity((self.AttackAngle)/4)
					mdl:GetPhysicsObject():SetMaterial("dirt")
				end
				mdl:SetMaterial("models/props_wasteland/dirtwall001a")
				table.insert(self.CSProps, mdl)
			end
		end
	end,
	[MAT_EGGSHELL] = function(self) end
}

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.OPos = self.Pos
	self.Normal = data:GetNormal()
	self.HitAngle = data:GetFlags()
	self.AttackAngle = data:GetStart()
	self.Scale = math.min(maxScale:GetInt(), data:GetScale()/5 or 1)
	self.Surface = util.GetSurfaceData(data:GetSurfaceProp())
	self.Emitter = ParticleEmitter(self.Pos)
	
	self.CSModels = {}
	self.CSProps = {}
	local vec = Vector(self.Scale, self.Scale, self.Scale)
	self:SetRenderBounds(-vec, vec)
	self:EmitSound(self.Surface.impactHardSound)
	self:EmitSound(self.Surface.strainSound)
	local mattype = self.Surface.material or MAT_CONCRETE
	if mattype == MAT_TILE then mattype = MAT_CONCRETE end
	if mattype == MAT_DEFAULT then mattype = MAT_CONCRETE end
	if mattype == MAT_GRASS then mattype = MAT_DIRT end
	if mattype == MAT_BLOODYFLESH then mattype = MAT_FLESH end
	if mattype == MAT_GRATE then mattype = MAT_METAL end
	if mattype == MAT_COMPUTER then mattype = MAT_METAL end
	self.Surface.material = mattype
	if not matSpecific[mattype] then 
		self.Emitter:Finish()
		return
	end
	matSpecific[mattype](self)
	self.Emitter:Finish()
	
end

function EFFECT:Think( )
  	self.LifeTime = self.LifeTime or CurTime() + lifetime:GetFloat()
  	self.LifeTimeDebris = self.LifeTimeDebris or CurTime() + lifetimedebris:GetFloat()
	if CurTime() > self.LifeTimeDebris then
		for k,v in pairs(self.CSProps) do
			if IsValid(v) then
				v:Remove()
			end
		end
	end
	if CurTime() > self.LifeTime then
		for k,v in pairs(self.CSModels) do
			if IsValid(v) then
				v:Remove()
			end
		end
		for k,v in pairs(self.CSProps) do
			if IsValid(v) then
				v:Remove()
			end
		end
		return false
	end
	
	return true
end

local mdls = {}

local rockmats = {
	[MAT_CONCRETE] = "",
	[MAT_DIRT] = "nature/dirtwall001a"
}
local tra = {}
local trdataa = {
	mask=MASK_VISIBLE,
	output = tra
}

function EFFECT:Render( )
	if not self.TexturesSet then
		for k,mdl in pairs(self.CSModels) do
			if IsValid(mdl) then
				trdataa.start = mdl:GetPos() + self.Normal * 15
				trdataa.endpos = mdl:GetPos() - self.Normal * 15
				util.TraceLine(trdataa)
				if tra.Hit then
					if tra.HitTexture ~= "**empty**" and tra.HitTexture ~= "**displacement**" and not string.StartWith(tra.HitTexture, "TOOLS") then
						matlist[tra.HitTexture] = matlist[tra.HitTexture] or Material(tra.HitTexture)
						mdl.mat = matlist[tra.HitTexture]:GetTexture("$basetexture")
					else
						local mattype = self.Surface.material
						mdl.mat = rockmats[mattype]
					end
				else
					mdl:Remove()
				end
			end
		end
		self.TexturesSet = true
	end
	for k,mdl in pairs(self.CSModels) do
		if IsValid(mdl) then
			local pos = self.Pos
			local norm = self.Normal
			if bit.band(util.PointContents(mdl:GetPos() - self.Normal ), CONTENTS_SOLID) == CONTENTS_SOLID then
				mdl:SetPos(mdl:GetPos() + self.Normal)
				mdl.CheckIndex = (mdl.CheckIndex or 1) +1
			end
			if mdl.CheckIndex and mdl.CheckIndex > 5 then
				mdl:Remove()
			end
			if mdl.mat and mdl.mat ~= "" then
				mat_cover:SetTexture("$basetexture", mdl.mat or "")
				render.MaterialOverride(mat_cover)
			end
			if self.LifeTime then
				local mult = self.LifeTime - CurTime()
				if mult < 0.5 then
					render.SetBlend((2 * mult))
				end
			end
			local normal = self.Normal -- Everything "behind" this normal will be clipped
			local position = normal:Dot( self.Pos ) -- self:GetPos() is the origin of the clipping plane

			local oldEC = render.EnableClipping( true )
			render.PushCustomClipPlane( normal, position )
			mdl:DrawModel()
			render.PopCustomClipPlane()
			render.EnableClipping( oldEC )
			render.SetBlend(1)
			render.MaterialOverride()
		end
	end
	if not self.RockMat then
		trdataa.start = self:GetPos() + self.Normal * 555
		trdataa.endpos = self:GetPos() - self.Normal * 555
		util.TraceLine(trdataa)
		if tra.Hit then
			if tra.HitTexture ~= "**empty**" and tra.HitTexture ~= "**displacement**" and not string.StartWith(tra.HitTexture, "TOOLS") then
				matlist[tra.HitTexture] = matlist[tra.HitTexture] or Material(tra.HitTexture)	
				self.RockMat = matlist[tra.HitTexture]:GetTexture("$basetexture")
			else
				local mattype = self.Surface.material
				self.RockMat = rockmats[mattype]
			end
		end
	end
	for k,mdl in pairs(self.CSProps) do
		if IsValid(mdl) then
			if self.RockMat and self.RockMat ~= "" then
				mat_cover:SetTexture("$basetexture", self.RockMat or "")
				render.MaterialOverride(mat_cover)
			end
			if self.LifeTimeDebris then
				local mult = self.LifeTimeDebris - CurTime()
				if mult < 0.5 then
					render.SetBlend((2 * mult))
				end
			end
			
			mdl:DrawModel()
			render.SetBlend(1)
			render.MaterialOverride()
		end
	end
	
	return false
end
