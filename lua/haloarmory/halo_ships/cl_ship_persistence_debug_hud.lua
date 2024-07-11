
// STOP THIS FILE:
--if true then return end

HALOARMORY.MsgC("Client HALO SHIP Persistence DEBUG HUD Loading.")

local function DrawBoxShip()
    --print("test")
    
    -- Find the "halo_frigate" entity
    local foundEnts = {}
    table.Add(foundEnts, ents.FindByClass("halo_frigate"))
    table.Add(foundEnts, ents.FindByClass("halo_lich"))
    table.Add(foundEnts, ents.FindByClass("halo_unsc_corvette"))

    for key, frigate in pairs(foundEnts) do
            
        if not IsValid(frigate) then
            return
        end


        -- Get the minimum and maximum coordinates of the "halo_frigate" entity's bounding box
        local min, max = frigate:GetCollisionBounds()

        -- Calculate the width, height, and depth of the min and max coordinates
        local width = max.x - min.x
        local height = max.y - min.y
        local depth = max.z - min.z

        --local maxWH = math.max(width, height)

        local position = frigate:LocalToWorld(frigate:OBBCenter())

        -- if frigate.HALOARMORY_CollisionBoundsOffset then
        --     position = frigate:LocalToWorld(frigate.HALOARMORY_CollisionBoundsOffset)
        -- end

        // Get the center pisition of min and max
        --local position = (min + max) / 2

        --local posMin = Vector(maxWH * .45, maxWH * .45, max.z)
        --local posMax = Vector(-maxWH * .45, -maxWH * .45, min.z)

        local posMin = Vector(width / 2, height / 2, depth / 2)
        local posMax = Vector(-width / 2, -height / 2, -depth / 2)

        -- Draw the wireframe box around the bounding box
        render.DrawWireframeBox(position, frigate:GetAngles(), posMin, posMax, Color(255, 0, 0))

        render.SetColorMaterial()

        // Draw a text at the min position
        render.DrawWireframeSphere( position, 50, 30, 30, Color( 175, 0, 0, 100), false )
    end


end


local HookName = "HALOARMORY.DrawFrigateBounds"

concommand.Add( "HALOARMORY.ToggleShipDebug", function( ply, cmd, args )
    if hook.GetTable()["PostDrawOpaqueRenderables"][HookName] then
        hook.Remove( "PostDrawOpaqueRenderables", HookName )
        print("Removed the hook.")
    else
        hook.Add( "PostDrawOpaqueRenderables", HookName, DrawBoxShip )
        print("Hook added.")
    end
    
end )


HALOARMORY.Ships = HALOARMORY.Ships or {}
HALOARMORY.Ships.first_run = HALOARMORY.Ships.first_run or false
if HALOARMORY.Ships.first_run and hook.GetTable()["PostDrawOpaqueRenderables"][HookName] then
    hook.Add( "PostDrawOpaqueRenderables", HookName, DrawBoxShip )
    print("Hook updated.")
else
    HALOARMORY.Ships.first_run = true
end
