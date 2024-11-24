AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


local entIdx = nil // Just for debugging purposes


ENT.ElvatorModel = "models/hunter/plates/plate3x3.mdl"
ENT.ElevatorMoveSound = "plats/elevator_move_loop1.wav"
ENT.ElevatorStopSound = "plats/elevator_stop2.wav"


function ENT:BuildElevator()

    -- Set up the moving part of the elevator
    self.bridgeElevator = ents.Create("func_movelinear")
    self.bridgeElevator:SetPos(self:LocalToWorld(Vector(-1279, 0, 2460)))
    self.bridgeElevator:SetAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
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


    --[[ 
    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: 0.062500 58.562500 59.187500
    [HALOARMORY] Relative Angle: -0.000 0.022 90.000
    ]]

    // Add a floor selector button
    self.floorSelectorButton = ents.Create("interface_controlpanel")
    self.floorSelectorButton:SetPos(self.bridgeElevator:LocalToWorld(Vector(0, 63, 59)))
    self.floorSelectorButton:SetAngles(self.bridgeElevator:LocalToWorldAngles(Angle(0, 0, 90)))

    self.floorSelectorButton:SetDoorParent(self)
    self.floorSelectorButton:SetPanelType("elevator_floors")
    self.floorSelectorButton:Spawn()
    self.floorSelectorButton:Activate()

    self.floorSelectorButton:SetParent(self.bridgeElevator) -- Parent the button to the moving part

    self:DeleteOnRemove(self.floorSelectorButton) -- Ensure button is removed with main entity



    // Elevator Bottom Call Button
    --[[
    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: -1200.031250 70.093750 2518.875000
    [HALOARMORY] Relative Angle: -0.000 89.973 89.989
    ]]
    self.elevatorCallButtonBottom = ents.Create("interface_controlpanel")
    self.elevatorCallButtonBottom:SetPos(self:LocalToWorld(Vector(-1200, 70, 2518)))
    self.elevatorCallButtonBottom:SetAngles(self:LocalToWorldAngles(Angle(0, 90, 90)))

    self.elevatorCallButtonBottom:SetDoorParent(self)
    self.elevatorCallButtonBottom:SetPanelType("elevator_call")
    self.elevatorCallButtonBottom:Spawn()
    self.elevatorCallButtonBottom:Activate()

    self:DeleteOnRemove(self.elevatorCallButtonBottom) -- Ensure button is removed with main entity

    // Elevator Top Call Button
    --[[
    [HALOARMORY] ------------------------------------------------------
    [HALOARMORY] Relative Position: -1199.125000 70.281250 3285.968750
    [HALOARMORY] Relative Angle: -0.000 89.962 90.011
    ]]
    self.elevatorCallButtonTop = ents.Create("interface_controlpanel")
    self.elevatorCallButtonTop:SetPos(self:LocalToWorld(Vector(-1200, 70, 3285)))
    self.elevatorCallButtonTop:SetAngles(self:LocalToWorldAngles(Angle(0, 90, 90)))

    self.elevatorCallButtonTop:SetDoorParent(self)
    self.elevatorCallButtonTop:SetPanelType("elevator_call")
    self.elevatorCallButtonTop:Spawn()
    self.elevatorCallButtonTop:Activate()

    self:DeleteOnRemove(self.elevatorCallButtonTop) -- Ensure button is removed with main entity


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
    self.elevatorWallBottom1 = ents.Create("prop_physics")
    self.elevatorWallBottom1:SetModel("models/hunter/blocks/cube3x3x025.mdl")
    self.elevatorWallBottom1:SetMaterial("models/gibs/metalgibs/metal_gibs")
    self.elevatorWallBottom1:SetPos(self:LocalToWorld(Vector(-1279, 72, 2526)))
    self.elevatorWallBottom1:SetAngles(self:LocalToWorldAngles(Angle(90, 90, 0)))

    self.elevatorWallBottom1:Spawn()

    --self.elevatorWallBottom1:SetMoveType(MOVETYPE_NONE)
    self.elevatorWallBottom1:SetParent(self)

    self:DeleteOnRemove(self.elevatorWallBottom1) -- Ensure wall is removed with main entity

    self.elevatorWallBottom2 = ents.Create("prop_physics")
    self.elevatorWallBottom2:SetModel("models/hunter/blocks/cube3x3x025.mdl")
    self.elevatorWallBottom2:SetMaterial("models/gibs/metalgibs/metal_gibs")
    self.elevatorWallBottom2:SetPos(self:LocalToWorld(Vector(-1352, 0, 2528)))
    self.elevatorWallBottom2:SetAngles(self:LocalToWorldAngles(Angle(90, -180, 0)))
    self.elevatorWallBottom2:Spawn()

    --self.elevatorWallBottom2:SetMoveType(MOVETYPE_NONE)
    self.elevatorWallBottom2:SetParent(self)

    self:DeleteOnRemove(self.elevatorWallBottom2) -- Ensure wall is removed with main entity

    self.elevatorWallBottom3 = ents.Create("prop_physics")
    self.elevatorWallBottom3:SetModel("models/hunter/blocks/cube3x3x025.mdl")
    self.elevatorWallBottom3:SetMaterial("models/gibs/metalgibs/metal_gibs")
    self.elevatorWallBottom3:SetPos(self:LocalToWorld(Vector(-1279, -72, 2529)))
    self.elevatorWallBottom3:SetAngles(self:LocalToWorldAngles(Angle(90, -90, 0)))
    self.elevatorWallBottom3:Spawn()

    --self.elevatorWallBottom3:SetMoveType(MOVETYPE_NONE)
    self.elevatorWallBottom3:SetParent(self)

    self:DeleteOnRemove(self.elevatorWallBottom3) -- Ensure wall is removed with main entity

end


function ENT:CustomInit()
    timer.Simple(0.1, function()
        self:BuildElevator()
    end)

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
