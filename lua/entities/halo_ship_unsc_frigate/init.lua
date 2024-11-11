AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


local entIdx = nil // Just for debugging purposes


ENT.ElvatorModel = "models/hunter/plates/plate3x3.mdl"
ENT.ElevatorMoveSound = "plats/elevator_move_loop1.wav"
ENT.ElevatorStopSound = "plats/elevator_stop2.wav"

function ENT:CustomInit()

    -- Set up the moving part of the elevator
    self.bridgeElevator = ents.Create("func_movelinear")
    self.bridgeElevator:SetPos(self:LocalToWorld(Vector(-1279, 0, 2460)))
    self.bridgeElevator:SetAngles(Angle(0, 0, 0))
    self.bridgeElevator:SetNoDraw(true)
    self.bridgeElevator:SetModel( self.ElvatorModel )
	self.bridgeElevator:SetMoveType(MOVETYPE_PUSH)

    self.bridgeElevator:Spawn()
    self.bridgeElevator:Activate()

    self.bridgeElevator:SetKeyValue("startposition", "0") -- Start at 0

    self.bridgeElevator:SetKeyValue("speed", "100")

    self.bridgeElevator:SetSaveValue( "m_vecPosition1", tostring(self:LocalToWorld(Vector(-1279, 0, 2460))))
    self.bridgeElevator:SetSaveValue( "m_vecPosition2", tostring(self:LocalToWorld(Vector(-1279, 0, 3225))))

    self.bridgeElevator:SetKeyValue("StartSound", self.ElevatorMoveSound)
    self.bridgeElevator:SetKeyValue("StopSound", self.ElevatorStopSound)

    self:DeleteOnRemove(self.bridgeElevator) -- Ensure elevator is removed with main entity

    self.atTop = false -- Initialize the elevator at the bottom

    -- Set up the visible part of the elevator using prop_dynamic
    self.elevatorModel = ents.Create("prop_dynamic")
    self.elevatorModel:SetModel( self.ElvatorModel )
    self.elevatorModel:SetPos(self:LocalToWorld(Vector(-1279, 0, 2460)))
    self.elevatorModel:SetAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
    self.elevatorModel:SetParent(self.bridgeElevator) -- Parent the model to the moving part
    self.elevatorModel:Spawn()
    self.elevatorModel:SetNotSolid(true)
    self:DeleteOnRemove(self.elevatorModel) -- Ensure model is removed with main entity

    self.elevatorModel:SetMaterial("001wmetal") -- Set the material to white


    // Elevator Bottom Walls

    // models/hunter/blocks/cube3x3x025.mdl
    --[[
    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: -1279.687500 72.406250 2526.906250
    [HALOARMORY] Relative Angle: 90.000 90.044 0.000

    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: -1352.000000 0.250000 2528.093750
    [HALOARMORY] Relative Angle: 90.000 -179.962 0.000

    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: -1279.593750 -72.312500 2529.437500
    [HALOARMORY] Relative Angle: 90.000 -89.967 0.000
    ]]


    entIdx = self:EntIndex() // Just for debugging purposes
end


-- Function to toggle elevator position
function ENT:ToggleElevator()
    if not IsValid(self.bridgeElevator) then return end

    if self.atTop then
        self.bridgeElevator:Fire("Close") -- Move to the bottom
    else
        self.bridgeElevator:Fire("Open") -- Move to the top
    end

    self.atTop = not self.atTop -- Toggle the position state
end

-- Define the global console command
concommand.Add("haloarmory_frigate_toggle_elevator", function(ply, cmd, args)
    if not args[1] then args[1] = entIdx end -- Ensure an argument is passed

    local entityID = tonumber(args[1])
    if not entityID then return end

    local ent = Entity(entityID)
    if IsValid(ent) and ent.ToggleElevator then

        --PrintTable( ent.bridgeElevator:GetSaveTable() )

        ent:ToggleElevator()
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid entity ID or entity does not support ToggleElevator.")
    end
end)
