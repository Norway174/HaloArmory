HALOARMORY.MsgC("Server HALO SHIPS Manager Loading.")

--[[ 
##============================##
||                            ||
||        Ship Spawns         ||
||                            ||
##============================##
 ]]

HALOARMORY.Ships = HALOARMORY.Ships or {}
HALOARMORY.Ships.Maps = HALOARMORY.Ships.Maps or {}

HALOARMORY.Ships.Maps["halo_frigate"] = {
    -- ["gm_construct"] = {
    --     ["pos"] = Vector(-1513, 1555, 4915),
    --     ["ang"] = Angle(0,-90,0),
    -- },
    -- ["gm_flatgrass"] = {
    --     ["pos"] = Vector(0, 0, 0),
    --     ["ang"] = Angle(0,0,0),
    -- },
    -- ["rp_tfghalov5"] = {
    --     ["pos"] = Vector(1000, 12000, 2600),
    --     ["ang"] = Angle(0,0,0),
    -- },
    -- ["gm_fork"] = {
    --     ["pos"] = Vector(2324, -3670, -2390),
    --     ["ang"] = Angle(0,45,0),
    -- },
    -- ["fork"] = {
    --     ["pos"] = Vector(2324, -3670, -2390),
    --     ["ang"] = Angle(0,45,0),
    -- },
    -- ["gm_fork_nosound"] = {
    --     ["pos"] = Vector(2324, -3670, -2390),
    --     ["ang"] = Angle(0,45,0),
    -- },
    -- ["gm_infmap"] = {
    --     ["pos"] = Vector(0, 0, 5000),
    --     ["ang"] = Angle(0,-90,0),
    -- },
    -- ["rp_valhalla_v1"] = {
    --     ["pos"] = Vector(-3623, -8098, 4843),
    --     ["ang"] = Angle(0,0,0),
    -- },
}

HALOARMORY.Ships.Maps["halo_lich"] = {
    -- ["gm_fork"] = {
    --     ["pos"] = Vector(5210, 8700, 1148),
    --     ["ang"] = Angle(0,90+45,0),
    -- },
}

HALOARMORY.Ships.Persist = CreateConVar( "HALOARMORY.PersistShips", 0, {FCVAR_ARCHIVE}, "Enable or disable automatic ship spawning.", 0, 1 )
HALOARMORY.Ships.Autoload = CreateConVar( "HALOARMORY.AutoloadShip", "false", {FCVAR_ARCHIVE}, "Enter the filename to autoload on ship spawn. Or set to false to disable." )

function HALOARMORY.Ships.SpawnShips()

    if not HALOARMORY.Ships.Persist:GetBool() then return end

    
    for ClassName, TheMaps in pairs(HALOARMORY.Ships.Maps) do

        local map_info = TheMaps[game.GetMap()]
        if ( not map_info ) then continue end

        if ( #ents.FindByClass( ClassName ) > 0) then
            continue
        end
    
        local ent = ents.Create( ClassName )

        local pos, ang = map_info["pos"], map_info["ang"]

        ent:SetPos(pos)
        ent:SetAngles(ang)
        ent:Spawn()
        ent:Activate()
    
    end

end
--hook.Add( "InitPostEntity", "HALOARMORY.SpawnShipsInit", HALOARMORY.Ships.SpawnShips )
--hook.Add( "PostCleanupMap", "HALOARMORY.SpawnShipsCleanup", HALOARMORY.Ships.SpawnShips )


--[[ 
##================================##
||                                ||
|| Prevent certain Entities from  ||
||being picked up and manipulated.||
||                                ||
##================================##
 ]]

// Prevent the Ships from being picked up! 
local function ShipPickup( ply, ent, phys )
    if ( ent.HALOARMORY_Ships_Presets ) then return false end
end
hook.Add( "PhysgunPickup", "HALOARMORY.ShipPickup", ShipPickup )
hook.Add( "CanPlayerUnfreeze", "HALOARMORY.ShipPickup", ShipPickup )
