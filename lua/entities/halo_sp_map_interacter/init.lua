
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.IsUsed = false

function ENT:Think()

    local mapEntities = self:GetMapEntity()
        mapEntities = string.Explode( ",", mapEntities )

    // Convert all the strings to numbers
    for k,v in pairs( mapEntities ) do
        mapEntities[k] = tonumber( v )
    end

    // Get the Network table
    local network = self:GetNetworkTable()
    network = util.JSONToTable( network )

    if not istable( network ) then return end

    // Get the current resource and max resource
    local CurrentResource, MaxResource = network.Supplies, network.MaxSupplies
    local ResourcePercentage = CurrentResource / MaxResource * 100

    // Get the Min and Max supplies needed to trigger
    local MinSupplies = self:GetTriggerMin()
    local MaxSupplies = self:GetTriggerMax()


    for key, EntID in pairs(mapEntities) do
        
        // Get The Map Entity ID
        if not EntID or EntID == -1 or not isnumber( tonumber( EntID ) ) then return end

        local Ent = ents.GetMapCreatedEntity( EntID )
        if not IsValid( Ent ) then return end


        if not self.IsUsed and ResourcePercentage <= MinSupplies then
            --print( "Triggered below Minimum", Ent, MinSupplies, MaxSupplies, ResourcePercentage)

            self.IsUsed = true

            self:SetToggled( self.IsUsed )

        elseif self.IsUsed and ResourcePercentage >= MaxSupplies then
            --print( "Triggered above Maximum" )

            self.IsUsed = false

            self:SetToggled( self.IsUsed )
            
        end


    end



end


function ENT:PostInit()

    timer.Simple( 1, function()
        --print( "Post Init" )
        self:OnMapEntityChanged( "init Timer", nil, self:GetMapEntity() )
    end )

end


function ENT:OnMapEntityChanged( name, old, new )

    --print( name, old, new )

    local mapEntities = self:GetMapEntity()
    mapEntities = string.Explode( ",", mapEntities )

    // Convert all the strings to numbers
    for k,v in pairs( mapEntities ) do
        mapEntities[k] = tonumber( v )
    end

    for key, EntID in pairs(mapEntities) do

        if not EntID or EntID == -1 or not isnumber( tonumber(EntID) ) then return end

        local Ent = ents.GetMapCreatedEntity( EntID )
        if not IsValid( Ent ) then return end

        self:SetLocks( Ent )
    end
end


function ENT:OnLinkToggled( name, old, new )

    --print( name, old, new )

    local mapEntities = self:GetMapEntity()
    mapEntities = string.Explode( ",", mapEntities )

    // Convert all the strings to numbers
    for k,v in pairs( mapEntities ) do
        mapEntities[k] = tonumber( v )
    end

    for key, EntID in pairs(mapEntities) do
        --print( EntID )
        if not EntID or EntID == -1 or not isnumber( tonumber(EntID) ) then return end

        --print( "Passed" )

        local Ent = ents.GetMapCreatedEntity( EntID )
        --print( Ent )
        if not IsValid( Ent ) then return end


        if self:GetPressOnToggle() then
            // Trigger the entity
            self:PressButtonDoor( Ent )
        else
            self:SetLocks( Ent )
        end

        
    end

end

function ENT:OnLockUpdate( name, old, new )

    --print( name, old, new )

    local mapEntities = self:GetMapEntity()
    mapEntities = string.Explode( ",", mapEntities )

    // Convert all the strings to numbers
    for k,v in pairs( mapEntities ) do
        mapEntities[k] = tonumber( v )
    end

    for key, EntID in pairs(mapEntities) do
        if not EntID or EntID == -1 or not isnumber( tonumber(EntID) ) then return end

        --print( "Passed" )

        local Ent = ents.GetMapCreatedEntity( EntID )
        --print( Ent )
        if not IsValid( Ent ) then return end

        timer.Simple( 0.1, function()
            self:SetLocks( Ent )
        end )
    end
end



function ENT:PressButtonDoor( Ent )

    if Ent:GetClass() == "func_door" then 

        // Trigger the entity
        Ent:Fire( "Unlock" )
        Ent:Fire( "Toggle" )
    
    elseif Ent:GetClass() == "func_button" then
    
        // Trigger the entity
        Ent:Fire( "Unlock" )
        Ent:Fire( "Press" )
    end

    self:SetLocks( Ent )
end


function ENT:SetLocks( Ent )

    if self:GetToggled() then
        if self:GetLockedOn() then
            // Lock the entity
            Ent:Fire( "Lock" )
            --print( "Locking1" )
        else 
            // Unlock the entity
            Ent:Fire( "Unlock" )
            --print( "Unlocking1" )
        end
        
    else 
        if self:GetLockedOff() then
            // Lock the entity
            Ent:Fire( "Lock" )
            --print( "Locking2" )
        else 
            // Unlock the entity
            Ent:Fire( "Unlock" )
            --print( "Unlocking2" )
        end
    end

end