
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


util.AddNetworkString( ENT.NETSTRING_DOOROPEN )
util.AddNetworkString( ENT.NETSTRING_DOORBELL )
util.AddNetworkString( ENT.NETSTRING_DOORLOCK )


function ENT:Initialize()
 
    -- Sets what model to use
    self:SetModel( self.DoorModel )

    -- Physics stuff
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    self:SetRenderMode( RENDERMODE_TRANSCOLOR )

    -- Init physics only on server, so it doesn't mess up physgun beam
    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
    
    local phys = self:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:Wake()
        --phys:Sleep()

        phys:EnableMotion( false )
    end

    // Inside Control Panel
    local controlPanel_inside = ents.Create( self.ControlPanel.EntClass )

    controlPanel_inside:SetPos( self:LocalToWorld( self.ControlPanel.Inner.Pos ) )
    controlPanel_inside:SetAngles( self:LocalToWorldAngles( self.ControlPanel.Inner.Ang ) )
    controlPanel_inside:Spawn()

    controlPanel_inside:SetDoorParent(self)
    controlPanel_inside:SetPanelType("inside")
    self.ControlPanelInside = controlPanel_inside
    
    self:DeleteOnRemove(controlPanel_inside)

    
    // Outside Control Panel
    local controlPanel_outside = ents.Create( self.ControlPanel.EntClass )

    controlPanel_outside:SetPos( self:LocalToWorld( self.ControlPanel.Outter.Pos ) )
    controlPanel_outside:SetAngles( self:LocalToWorldAngles( self.ControlPanel.Outter.Ang ) )
    controlPanel_outside:Spawn()

    controlPanel_outside:SetDoorParent(self)
    controlPanel_outside:SetPanelType("outside")
    self.ControlPanelOutside = controlPanel_outside
    
    self:DeleteOnRemove(controlPanel_outside)

end

function ENT:SpawnFunction( ply, tr, ClassName )

    if ( !tr.Hit ) then return end
    
    local SpawnPos = tr.HitPos + tr.HitNormal
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0
    -- SpawnAng.y = SpawnAng.y + -90
    -- SpawnAng.x = SpawnAng.x + 90
    -- SpawnAng.z = SpawnAng.z + 90

    local ent = ents.Create( ClassName )

    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    return ent

end


function ENT:SaveTabletPositions()

    if ( IsValid(self.ControlPanelInside) ) then
        self.ControlPanel.Inner = {}
        self.ControlPanel.Inner.Pos = self:WorldToLocal( self.ControlPanelInside:GetPos() )
        self.ControlPanel.Inner.Ang = self:WorldToLocalAngles( self.ControlPanelInside:GetAngles() )

    end
    
    if ( IsValid(self.ControlPanelOutside) ) then
        self.ControlPanel.Outter = {}
        self.ControlPanel.Outter.Pos = self:WorldToLocal( self.ControlPanelOutside:GetPos() )
        self.ControlPanel.Outter.Ang = self:WorldToLocalAngles( self.ControlPanelOutside:GetAngles() )
    end

end


function ENT:DoorAutoClose()

    if not self:GetDoorAutoclose() then return end

    local theDoor = self
    local timerID = "HALOARMORY.DOORS.AUTOCLOSE_" .. self:GetCreationID()

    timer.Create( timerID, self:GetDoorAutoclose_Timeout(), 1, function()
        if not IsValid(theDoor) then return end

        theDoor:SetDoorOpen( false )

    end)

end

function ENT:ToggleDoor( name, old, new )

    local curCol = self:GetColor()

    --print( "Door toggled: ", name, old, new)

    if new then
        curCol.a = 160
        self:SetSolid( SOLID_NONE )

        timer.Simple( 0.1, function() self:DoorAutoClose() end)
    else
        curCol.a = 255
        self:SetSolid( SOLID_VPHYSICS )
    end

    self:SetColor( curCol )

end

net.Receive( ENT.NETSTRING_DOOROPEN, function( len, ply )
    local theDoor = net.ReadEntity()
    local DoorOpen = net.ReadBool()

    local CanAccess, CanOverride = theDoor:CanPlyAcces(ply)
    if not (CanAccess or CanOverride) then return end

    theDoor:SetDoorBellActive( false )

    theDoor:SetDoorOpen(DoorOpen) -- When this variable changes, it will automatically trigger the "ToggleDoor" function.
    theDoor.ControlPanelInside:EmitSound( theDoor.Sounds.Door )

end )

net.Receive( ENT.NETSTRING_DOORBELL, function( len, ply )
    local theDoor = net.ReadEntity()
    local RingState = net.ReadBool()

    theDoor:SetDoorBellActive(RingState)

    if RingState then
        theDoor:SetDoorBellPerson(ply)
        theDoor.ControlPanelInside:EmitSound( theDoor.Sounds.BellChime )
    end

end )

net.Receive( ENT.NETSTRING_DOORLOCK, function( len, ply )
    local theDoor = net.ReadEntity()
    local LockState = net.ReadBool()

    local CanAccess, CanOverride = theDoor:CanPlyAcces(ply)
    if not (CanAccess or CanOverride) then return end

    theDoor:SetDoorLocked(LockState)

    if LockState then
        theDoor:SetDoorOpen(false)
        theDoor.ControlPanelInside:EmitSound( theDoor.Sounds.LockDoor )
    else
        theDoor.ControlPanelInside:EmitSound( theDoor.Sounds.UnlockDoor )
    end

end )