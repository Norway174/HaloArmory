
HALOARMORY.MsgC("Shared HALO SHIPS Permissions Loading.")

--[[ 
##================================##
||                                ||
|| Prevent certain Entities from  ||
||being picked up and manipulated.||
||                                ||
##================================##
 ]]

// Always ensure the ship attacher tool can be used
local function ShipTool( ply, trace, tool )
    if not tool.HALOARMORY_ShipAttacher then return end
    if IsValid(trace.Entity) and trace.Entity.HALOARMORY_Ships_Presets then return true end
end
hook.Add( "CanTool", "!!!HALOARMORY.ShipTool", ShipTool )


// Prevent the Ships from being picked up! 
local function ShipPickup( ply, ent, phys )
    if ( ent.HALOARMORY_Ships_Presets ) then return false end
end
hook.Add( "PhysgunPickup", "!!!HALOARMORY.ShipPickup", ShipPickup )

--------------------------------------------------------------
if not SERVER then return end // ONLY Server after this.
--------------------------------------------------------------

hook.Add( "CanPlayerUnfreeze", "!!!HALOARMORY.ShipPickup", ShipPickup )



// PermaProp Compat - Server Only
timer.Simple(2, function()

    if not PermaProps then return end // PermaProps not found

    HALOARMORY.MsgC( "PermaProps found. Overriding PermaProps hooks." )

    // hook.Add("PhysgunPickup", "PermaPropsPhys", PermaPropsPhys)
    if hook.GetTable()["PhysgunPickup"]["PermaPropsPhys"] then
        local old_func = hook.GetTable()["PhysgunPickup"]["PermaPropsPhys"]
        hook.Add( "PhysgunPickup", "PermaPropsPhys", function( ply, ent, phys )
            if ( ent.HALOARMORY_Ships_Presets ) then return end // If it's a ship, then don't call the old function
            return old_func( ply, ent, phys )
        end )
    end

    // hook.Add( "CanPlayerUnfreeze", "PermaPropsUnfreeze", PermaPropsPhys)
    if hook.GetTable()["CanPlayerUnfreeze"]["PermaPropsUnfreeze"] then
        local old_func = hook.GetTable()["CanPlayerUnfreeze"]["PermaPropsUnfreeze"]
        hook.Add( "CanPlayerUnfreeze", "PermaPropsUnfreeze", function( ply, ent, phys )
            if ( ent.HALOARMORY_Ships_Presets ) then return end // If it's a ship, then don't call the old function
            return old_func( ply, ent, phys )
        end )
    end

    // hook.Add( "CanTool", "PermaPropsTool", PermaPropsTool)
    if hook.GetTable()["CanTool"]["PermaPropsTool"] then
        local old_func = hook.GetTable()["CanTool"]["PermaPropsTool"]
        hook.Add( "CanTool", "PermaPropsTool", function( ply, trace, tool )
            if ( trace.Entity.HALOARMORY_Ships_Presets ) then return end // If it's a ship, then don't call the old function
            return old_func( ply, trace, tool )
        end )
    end

    // hook.Add( "CanProperty", "PermaPropsProperty", PermaPropsProperty)
    if hook.GetTable()["CanProperty"]["PermaPropsProperty"] then
        local old_func = hook.GetTable()["CanProperty"]["PermaPropsProperty"]
        hook.Add( "CanProperty", "PermaPropsProperty", function( ply, property, ent )
            if ( ent.HALOARMORY_Ships_Presets ) then return end // If it's a ship, then don't call the old function
            return old_func( ply, property, ent )
        end )
    end

end)