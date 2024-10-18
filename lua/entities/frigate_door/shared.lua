
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Frigate Door"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.IsHALOARMORY = true

ENT.Editable = true

ENT.DoorModel = "models/valk/h3odst/unsc/props/doors/door_entrance1.mdl" -- Halo UNSC Prop Pack - Halo 3 ODST

ENT.ControlPanel = {}

ENT.ControlPanel.EntClass = "interface_controlpanel"

ENT.ControlPanel.Inner = {}
ENT.ControlPanel.Inner.Pos = Vector(10,35,55)
ENT.ControlPanel.Inner.Ang = Angle(180,-90,-90)

ENT.ControlPanel.Outter = {}
ENT.ControlPanel.Outter.Pos = Vector(-10,-35,55)
ENT.ControlPanel.Outter.Ang = Angle(180,90,-90)

ENT.Sounds = {}
ENT.Sounds.Door = "buttons/button24.wav"
ENT.Sounds.BellChime = "ambient/levels/canals/windchime2.wav"
ENT.Sounds.LockDoor = "buttons/button6.wav"
ENT.Sounds.UnlockDoor = "buttons/button5.wav"

ENT.NETSTRING_DOOROPEN = "HALOARMORY.FRIGATEDOOR.DOOROPEN"
ENT.NETSTRING_DOORBELL = "HALOARMORY.FRIGATEDOOR.DOORBELL"
ENT.NETSTRING_DOORLOCK = "HALOARMORY.FRIGATEDOOR.DOORLOCK"

ENT.AccessList = ENT.AccessList or {
    ["DarkRP"] = {
        ["categories"] = {
            ["UNSC Naval Personnel"] = true,
        },
        ["jobs"] = {
            --["Cadet"] = true,
        }
    },
    ["MRS"] = {
        ["group"] = {
            --["Example_branch"] = 3, -- Rank number
        },
    },
    ["_Override"] = {
        ["DarkRP"] = {
            ["categories"] = {
                --["Example_category"] = true,
            },
            ["jobs"] = {
                --["Example_job"] = true,
            }
        },
        ["MRS"] = {
            ["group"] = {
                --["Example_branch"] = 7, -- Rank number
            },
        },
    }
}

--ENT.ControlPanelInside = <Entity>
--ENT.ControlPanelOutside = <Entity>

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "RoomName", { KeyName = "RoomName", Edit = { type = "Generic", order = 1 } } )

    self:NetworkVar( "Bool", 1, "DoorOpen", { KeyName = "DoorOpen", Edit = { type = "Boolean", order = 2 } } )
    self:NetworkVar( "Bool", 2, "DoorAutoclose", { KeyName = "DoorAutoclose", Edit = { type = "Boolean", order = 3 } } )
    self:NetworkVar( "Int", 1, "DoorAutoclose_Timeout", { KeyName = "DoorAutoclose_timeout", Edit = { type = "Int", order = 4, min = 0, max = 120 } } )

    self:NetworkVar( "Bool", 3, "DoorBellActive", { KeyName = "DoorBellActive", Edit = { type = "Boolean", order = 5 } } )
    self:NetworkVar( "Entity", 0, "DoorBellPerson" )

    self:NetworkVar( "Bool", 4, "DoorLocked", { KeyName = "DoorLocked", Edit = { type = "Boolean", order = 6 } } )

    if ( SERVER ) then
        self:SetRoomName( "Room Name" )
        self:NetworkVarNotify( "DoorOpen", self.ToggleDoor )
        self:SetDoorOpen( false )
        self:SetDoorAutoclose( true )
        self:SetDoorAutoclose_Timeout( 5 )

        self:SetDoorLocked( false )

    end

end

ENT.NETWORK_STR_HALOARMORY_SETACCESS = "HALOARMORY.DOOR.SETACCESS"
ENT.NETWORK_STR_HALOARMORY_REQACCESS = "HALOARMORY.DOOR.REQACCESS"
ENT.NETWORK_STR_HALOARMORY_REQACCESS_ALL = "HALOARMORY.DOOR.REQACCESS.ALL"
if SERVER then
    util.AddNetworkString( ENT.NETWORK_STR_HALOARMORY_SETACCESS )
    util.AddNetworkString( ENT.NETWORK_STR_HALOARMORY_REQACCESS )
    util.AddNetworkString( ENT.NETWORK_STR_HALOARMORY_REQACCESS_ALL )
end

function ENT:SendAccessTable( ply )
    if CLIENT then return end -- Only allow server past this point

    net.Start( self.NETWORK_STR_HALOARMORY_SETACCESS )

    local data = util.Compress(util.TableToJSON( self.AccessList ))
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)

    net.WriteEntity( self )

    if IsValid( ply ) and ply:IsPlayer() then
        net.Send( ply )
    else
        net.Broadcast()
    end
end

function ENT:SetAccessTable( theNewTable )

    if not theNewTable and not istable(theNewTable) then print("Not a table!") return end

    if CLIENT then
        local ply = LocalPlayer()
        if not ply:IsAdmin() then print("No access!") return end

        net.Start( self.NETWORK_STR_HALOARMORY_SETACCESS )

        local data = util.Compress(util.TableToJSON(theNewTable))
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)

        net.WriteEntity( self )

        net.SendToServer()

    elseif SERVER then

        self.AccessList = theNewTable

        self:SendAccessTable()
    
    end

end

net.Receive( ENT.NETWORK_STR_HALOARMORY_SETACCESS, function( len, ply )

    if SERVER then
        if not ply:IsAdmin() then print("A user tried to send a network message to set the access table.", ply:Nick(), ply:SteamID() ) return end
    end
    
    local len2 = net.ReadUInt(32)
    local theNewTable = net.ReadData(len2) 
    theNewTable = util.JSONToTable(util.Decompress(theNewTable))

    local ent = net.ReadEntity()

    if SERVER then
        ent:SetAccessTable( theNewTable )

    elseif CLIENT then
        ent.AccessList = theNewTable
    end

end )

if SERVER then
    net.Receive( ENT.NETWORK_STR_HALOARMORY_REQACCESS, function( len, ply )
        local ent = net.ReadEntity()
        ent:SendAccessTable()
    end )

    net.Receive( ENT.NETWORK_STR_HALOARMORY_REQACCESS_ALL, function( len, ply )
        local foundDoors = ents.FindByClass( "frigate_door" )
        for _, ent in pairs(foundDoors) do
            ent:SendAccessTable()
        end
    end )
end


function ENT:CanPlyAcces( ply, accessList )

    if not IsValid(ply) and not ply:IsPlayer() then return false end

    accessList = accessList or self.AccessList or {}

    local _OverrideAccess = false
    if accessList["_Override"] then
        _OverrideAccess = self:CanPlyAcces( ply, accessList["_Override"] )
    end

    -- if MRS then
    --     local group, rank = MRS.GetNWdata(ply, "Group"), MRS.GetNWdata(ply, "Rank")
    --     --print( "MRS:", group, rank, accessList["MRS"]["group"][group] )

    --     if group and rank and accessList["MRS"]["group"][group] then
    --         --print("MRS valid")
    --         if accessList["MRS"]["group"][group] and accessList["MRS"]["group"][group] <= rank then
    --             -- Access Granted
    --             return true, _OverrideAccess
    --         else
    --             -- Wrong Rank
    --             return false, _OverrideAccess
    --         end
            
    --     end
    -- end

    if DarkRP then

        local ply_jobtable = ply:getJobTable()
        local job_cat = ply_jobtable.category or ""
        local job_name = ply_jobtable.name or ""

        if accessList["DarkRP"]["categories"][job_cat] then
            --print("Category is allowed")
            return true, _OverrideAccess

        elseif accessList["DarkRP"]["jobs"][job_name] then
            --print("Job is allowed")
            return true, _OverrideAccess

        else
            return false, _OverrideAccess
        end
    end

    return true, _OverrideAccess

end

-- if CLIENT then
--     print( ents.FindByClass( "frigate_door" )[1]:CanPlyAcces( LocalPlayer() ) )
-- end




// Add to the Context menu when you right click the door.

properties.Add( "access_gui", {
    MenuLabel = "Set Access", -- Name to display on the context menu
    Order = 10000, -- The order to display this property relative to other properties
    MenuIcon = "icon16/group_edit.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:GetClass() ~= "frigate_door" ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        print("Open access GUI")
        HALOARMORY.INTERFACE.ACCESS.Open( ent.AccessList, function( NewAccessList ) 
        
            ent:SetAccessTable( NewAccessList )

        end)

    end,
} )

properties.Add( "save_tablets", {
    MenuLabel = "Save Tablets", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/disk.png", -- The icon to display next to the property

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:GetClass() ~= "frigate_door" ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()

    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        local ent = net.ReadEntity()

        if ( !self:Filter( ent, ply ) ) then return end

        ent:SaveTabletPositions()
    end 
} )

