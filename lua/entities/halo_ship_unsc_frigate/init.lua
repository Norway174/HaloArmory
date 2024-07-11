
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()

    --print("Frigate initialized!")

    -- Sets what model to use
    self:SetModel( self.Model )

    -- Physics stuff
    self:SetSolid( SOLID_VPHYSICS )
    --self:SetMoveType( MOVETYPE_NONE )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
    self:SetUnFreezable( true )

    if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
    local phys = self:GetPhysicsObject()
    if ( IsValid( phys ) ) then
        phys:Wake()
        phys:Sleep()
        phys:AddGameFlag( FVPHYSICS_NO_PLAYER_PICKUP )
        phys:EnableMotion( false )
    end
    
    timer.Simple( 1, function() 
        // Remove PermaProp data.
        if self.PermaProps then
            --print("Frigate was a PermaProp.")
            self.PermaProps = nil
        end
    end )

    -- if HALOARMORY.Ships.Autoload:GetString() ~= "false" then
    --     timer.Simple( .1, function()
    --         print("Autoloaded '" .. self:GetClass() .. "': " .. HALOARMORY.Ships.Autoload:GetString())
    --         HALOARMORY.Ships.LoadShip(self:GetClass(), HALOARMORY.Ships.Autoload:GetString())
    --     end)
    -- end

end

function ENT:SpawnFunction( ply, tr, ClassName )
    -- if ( #ents.FindByClass( ClassName ) > 0) then
    --     ply:PrintMessage( HUD_PRINTTALK, "Only one '" .. ClassName .. "' can be spawned a time!" )
    --     return
    -- end

    local ent = ents.Create( ClassName )

    -- local map_info = HALOARMORY.Ships.Maps[ClassName] or {}
    -- map_info = map_info[game.GetMap()] or nil
    local pos, ang = ply:GetPos(), Angle(0,0,0)

    -- if ( map_info ) then
    --     pos, ang = map_info["pos"], map_info["ang"]
    -- end

    // Snap ang to nearest 45 degrees from the players angle
    ang = Angle(0, math.Round(ply:GetAngles().y / 45) * 45, 0)

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()

    return ent

end