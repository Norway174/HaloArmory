

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_supplies_map_linker.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    //{ name = "reload" },
}

if CLIENT then
    language.Add("tool.halo_supplies_map_linker.name","Map Linker")
    language.Add("tool.halo_supplies_map_linker.desc","Link the Map Interacter to a Map Entity")
    language.Add("tool.halo_supplies_map_linker.left","Link to Map Entity")
    language.Add("tool.halo_supplies_map_linker.right","Select Map Interacter")
    language.Add("tool.halo_supplies_map_linker.reload","")
end



function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "Spawner", Description = [[
This tool can only link to the Map Interacter from Logistics in the HALOARMORY.
    ]]})
end

function TOOL:Think()

    if CLIENT then
        // If the ship is nil, update the desc
        if not IsValid(self:GetEnt( 1 )) then
            language.Add("tool.halo_supplies_map_linker.desc","Link the Map Interacter to a Map Entity (No Map Interacter selected)")
        else
            local ship_class = tostring( self:GetEnt( 1 ) )
            language.Add("tool.halo_supplies_map_linker.desc","Link the Map Interacter to a Map Entity ("..ship_class..")")
        end
    end

end

function TOOL:LeftClick( trace )
    if not IsValid( self:GetEnt( 1 ) ) then
        if CLIENT then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You need to select a Map Interacter first.")
        end
        return
    end
    -- if not IsValid( trace.Entity ) then
    --     if CLIENT then
    --         chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Not a valid entity.")
    --     end
    --     return
    -- end
    if trace.Entity == self:GetEnt( 1 ) then
        if CLIENT then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't link this to itself.")
        end
        return
    end

    if CLIENT then return end


	local entities = ents.FindInSphere( trace.HitPos, 2 )

    // Sort the table for only these entities: func_button, func_door, func_door_rotating
    // And then sort them by distance to the trace.HitPos
    // Then return the first one

    --PrintTable(entities)

    local size = 0
    local ent = nil

    local allowedClasses = {
        ["func_button"] = true,
        ["func_door"] = true,
        ["func_door_rotating"] = true,
    }

    for k,v in pairs( entities ) do
        local class = v:GetClass()
        if allowedClasses[class] then
            local dist = v:GetPos():Distance( trace.HitPos )
            if dist < size or size == 0 then
                size = dist
                ent = v
            end
        end
    end

    --print(ent)

    local message = { "" }
    local EntityMapID = ent:MapCreationID()

    if IsValid( ent ) and EntityMapID ~= -1 then

        local mapEntities = self:GetEnt( 1 ):GetMapEntity()
        mapEntities = string.Explode( ",", mapEntities )

        // Convert all the strings to numbers
        for k,v in pairs( mapEntities ) do
            mapEntities[k] = tonumber( v )
        end

        if table.HasValue( mapEntities, EntityMapID ) then
            message = {
                Color(255,0,0),
                "[HALOARMORY] ",
                Color(255,255,255),
                "Removed ",
                Color(159,241,255),
                ent:GetClass(),
                " (",
                Color(253,255,159),
                EntityMapID,
                Color(159,241,255),
                ")",
                Color(255,255,255),
                " from the Map Interactor."
            }

            table.RemoveByValue( mapEntities, EntityMapID )

        else
            message = {
                Color(255,0,0),
                "[HALOARMORY] ",
                Color(255,255,255),
                "Added ",
                Color(159,241,255),
                ent:GetClass(),
                " (",
                Color(253,255,159),
                EntityMapID,
                Color(159,241,255),
                ")",
                Color(255,255,255),
                " to the Map Interactor."
            }


            table.insert( mapEntities, EntityMapID )
        end

        mapEntities = table.ToString( mapEntities )
        // Trim the first and last character
        mapEntities = string.sub(mapEntities, 2, string.len(mapEntities) - 2)
        
        self:GetEnt( 1 ):SetMapEntity( mapEntities )

    else
        message = {
            Color(255,0,0),
            "[HALOARMORY] ",
            Color(255,255,255),
            "No valid entity found."
        }
    end

    message = table.ToString( message )
    // Trim the first and last character
    message = string.sub(message, 2, string.len(message) - 2)

    local ply = self:GetOwner()
    ply:SendLua("chat.AddText( "..message.." )")

end

function TOOL:RightClick( trace )
    local ent = trace.Entity

    if ent.DeviceType == "map_interacter" then
        if CLIENT then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Map Interacter selected: ", Color(159,241,255), ent:GetClass(), Color(255,255,255), ".")
        end
        
        self:SetObject( 1, ent, trace.HitPos, trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )
    end

end

-- function TOOL:Reload( trace )

-- end



