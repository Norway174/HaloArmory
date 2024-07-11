
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[ 
["Amount"]	=	1
["BaseClass"]	=	npc_citizen
["Models"]:
		[1]	=	models/jessev92/halo/unsc_h3_marine/m01_reb.mdl
		[2]	=	models/jessev92/halo/unsc_h3_marine/m02_reb.mdl
		[3]	=	models/jessev92/halo/unsc_h3_marine/m03_reb.mdl
		[4]	=	models/jessev92/halo/unsc_h3_marine/m04_reb.mdl
		[5]	=	models/jessev92/halo/unsc_h3_marine/m05_reb.mdl
		[6]	=	models/jessev92/halo/unsc_h3_marine/m06_reb.mdl
		[7]	=	models/jessev92/halo/unsc_h3_marine/m07_reb.mdl
		[8]	=	models/jessev92/halo/unsc_h3_marine/m08_reb.mdl
		[9]	=	models/jessev92/halo/unsc_h3_marine/m09_reb.mdl
["Weapons"]:
		[1]	=	npc_halo3_m41
		[2]	=	npc_halo3_br55hbsr
		[3]	=	npc_halo3_ma5c
		[4]	=	npc_halo3_m6g
		[5]	=	npc_halo3_m7
		[6]	=	npc_halo3_m90


76 85 63

 ]]


function ENT:Initialize()
    self:SetModel( "models/props_borealis/bluebarrel001.mdl" )

    print("HALOARMRY - Init NPC Entity", self )

    --self:SetColor( Color( 255, 255, 255, 0) )
    --print("Init NPC Entity", self )
    -- timer.Simple( 0.01, function()
    --     self:PostInit()
    -- end)
end

ENT.Executed = false
function ENT:Think()
    print("HALOARMRY - Think NPC Entity", self, self.NPCTable )
    
    if not self.NPCTable and not istable( self.NPCTable ) then return end
    if self.Executed then return end

    self.Executed = true
    self:PostInit()

end


function ENT:PostInit()
    print("HALOARMRY - Post-Init NPC Entity", self, self.NPCTable )
    if istable( self.NPCTable ) then
        --PrintTable( self.NPCTable )
    end

    if not self.NPCTable then
        self.Executed = false
        return
    end

    -- print("--------------------")
    -- if istable( self:GetTable() ) then
    --     PrintTable( self:GetTable() )
    -- end
    -- print("--------------------")

    local NPCTable = self.NPCTable.Haloarmory

    NPCTable.SpawnType = NPCTable.SpawnType or "circle-random"


    local NPCs = {}


    for i = 1, NPCTable.Amount do
        --local pos = self:PosCircle(i, NPCTable.Amount)
        local pos = self:SpawnInsideCircle(NPCTable.Amount)

        local ang = Angle(0, math.random(0, 360), 0)
        local NPC = self:SpawnNPC(NPCTable, pos, ang)
        table.insert(NPCs, NPC)
    end
    


    if #NPCs <= 0 then
        print("No NPCs spawned!")
        return
    end

    // Get the spawning player
    local spawner_ply = self:GetPlayer()
    if IsValid( self:GetPlayer() ) then
        spawner_ply = self:GetPlayer()
    elseif IsValid( self.FPPOwner ) then
        spawner_ply = self.FPPOwner
    elseif IsValid( self.GAS_EntityCreator ) then
        spawner_ply = self.GAS_EntityCreator
    end

    // Create Undo
    undo.Create( "HALOARMORY NPCs ["..tostring( self:GetClass() ).."/"..tostring( #NPCs ).."]" )
        for k, v in pairs( NPCs ) do
            undo.AddEntity( v )
        end

        undo.SetPlayer( spawner_ply )
    undo.Finish()

    // Cleanup NPCs
    for k, v in pairs( NPCs ) do
        spawner_ply:AddCleanup( "npcs", v )
    end

    self:Remove()
end


function ENT:SpawnNPC( NPCTable, pos, ang )

    if not istable( NPCTable ) then return end
    if not NPCTable.BaseClass then return end

    local NPC = ents.Create( NPCTable.BaseClass )
    if not IsValid( NPC ) then return end

    // Set the NPC position and angles
    NPC:SetPos( pos or self:GetPos() )
    NPC:SetAngles( ang or self:GetAngles() )

    // Set the NPC model
    NPC:SetModel( NPCTable.Models[ math.random( 1, #NPCTable.Models ) ] )

    // Get the NPC skins, and set one at random
    local skincount = NPC:SkinCount()
    if skincount > 0 then
        NPC:SetSkin( math.random( 0, skincount - 1 ) )
    end

    // Get the NPC bodygroups, and set one at random
    local groups = NPC:GetNumBodyGroups()
    for i = 0, groups - 1 do
        NPC:SetBodygroup( i, math.random( 0, NPC:GetBodygroupCount( i ) - 1 ) )
    end

    // Set the NPC keyvalues
    NPC:SetKeyValue( "additionalequipment", table.Random( NPCTable.Weapons ) )
    NPC:SetKeyValue( "citizentype", 4 )
    NPC:SetKeyValue( "DontPickupWeapons", 1 )
    NPC:SetKeyValue( "Expression Type", "Random" )

    // Spawnflags
    local SpawnFlags = bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK )

    // Spawn the NPC
    local attempts, maxAttempts = 0, 10
    local nudgeAmount = 10
    local newPos = pos or self:GetPos()

    local function isPositionValid(testPos)
        local tr = util.TraceHull({
            start = testPos,
            endpos = testPos,
            mins = NPC:OBBMins(),
            maxs = NPC:OBBMaxs(),
            filter = NPC
        })

        return not tr.Hit
    end

    while attempts < maxAttempts do
        NPC:SetPos(newPos)
        NPC:SetAngles(ang or self:GetAngles())

        if isPositionValid(newPos) then
            NPC:Spawn()
            break -- Found a suitable position
        else
            -- Nudge the position slightly and try again
            newPos = newPos + Vector(math.random(-nudgeAmount, nudgeAmount), math.random(-nudgeAmount, nudgeAmount), 0)
            attempts = attempts + 1
        end
    end

    if attempts >= maxAttempts then
        --print("Failed to find a suitable position for NPC.")
        NPC:Remove()
        return nil
    end

    NPC:SetSchedule( SCHED_COMBAT_SWEEP )

    return NPC

end


function ENT:PosCircle(curr_amount, total_amount)
    local centerPos = self:GetPos() -- Center position

    -- Constants
    local npcSpacing = 100 -- The space allocated for each NPC along the circumference
    local minDiameter = 200 -- Minimum diameter of the circle
    local nudgeAmount = 20 -- Maximum amount to nudge NPCs (in units)

    -- Spawning the first NPC at the center
    if curr_amount == 1 then
        return centerPos, Angle(0, 0, 0) -- Return center position and angle for the first NPC
    end

    local totalCircumference = npcSpacing * (total_amount - 1)
    local radius = totalCircumference / (2 * math.pi) -- Calculating the radius
    radius = math.max(radius, minDiameter / 2) -- Ensure the radius is not less than half of the minimum diameter

    -- Calculating position in a circle for current NPC
    local angle = 2 * math.pi * (curr_amount - 1) / (total_amount - 1) -- Evenly spaced angles
    local xOffset = math.cos(angle) * radius
    local yOffset = math.sin(angle) * radius
    local pos = centerPos + Vector(xOffset, yOffset, 0)

    -- Add random nudge
    pos = pos + Vector(math.random(-nudgeAmount, nudgeAmount), math.random(-nudgeAmount, nudgeAmount), 0)

    return pos
end


function ENT:SpawnInsideCircle(total_amount)
    local centerPos = self:GetPos() -- Center position
    local minDiameter = 200 -- Minimum diameter of the circle
    local radius = math.max(minDiameter / 2, (100 * (total_amount - 1)) / (2 * math.pi)) -- Calculating the radius

    local angle = math.random() * 2 * math.pi
    local dist = math.random() * radius
    local xOffset = math.cos(angle) * dist
    local yOffset = math.sin(angle) * dist
    local randomPos = centerPos + Vector(xOffset, yOffset, 0)

    return randomPos
end

