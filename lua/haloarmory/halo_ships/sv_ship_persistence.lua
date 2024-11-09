HALOARMORY.MsgC("Server HALO SHIP Persistence Loading.")


HALOARMORY.Ships = HALOARMORY.Ships or {}

--[[ 
##============================##
||                            ||
||     Utility Functions      ||
||                            ||
##============================##
 ]]

local function GetAttached(haloFrigate)
    if not haloFrigate.HALOARMORY_Attached then
        return
    end

    // check if each prop is still valid, if not remove it from haloFrigate.HALOARMORY_Attached
    local props = haloFrigate.HALOARMORY_Attached
    for i = #props, 1, -1 do
        if not IsValid(props[i]) then
            table.remove(props, i)
        end
    end
    haloFrigate.HALOARMORY_Attached = props

    return haloFrigate.HALOARMORY_Attached
end

function HALOARMORY.Ships.AddProp(ship, prop)

    if not IsValid(ship) or not ship.HALOARMORY_Attached then return false, "Invalid ship" end
    if not IsValid(prop) then return false, "Invalid object" end

    if table.HasValue(ship.HALOARMORY_Attached, prop) then return false, "Object attached" end

    // Attach
    table.insert(ship.HALOARMORY_Attached, prop)
    ship:DeleteOnRemove( prop )
    prop.HALOARMORY_AttachedTo = ship
    print("Attached", prop, "to", ship)

    return true, "Object attached"
end

function HALOARMORY.Ships.RemoveProp(ship, prop)

    if not IsValid(ship) or not ship.HALOARMORY_Attached then return false, "Invalid ship" end
    if not IsValid(prop) then return false, "Invalid object" end

    if not table.HasValue(ship.HALOARMORY_Attached, prop) then return false, "Object is not attached" end

    // Detach
    table.RemoveByValue(ship.HALOARMORY_Attached, prop)
    ship:DontDeleteOnRemove( prop )
    prop.HALOARMORY_AttachedTo = nil
    print("Detached", prop, "from", ship)

    return true, "Object detached"
end


function HALOARMORY.Ships.DeleteShip(entity, fileName)
    entity = entity:GetClass()

    if not file.IsDir("haloarmory/ships/"..entity, "DATA") then
        return
    end

    -- Delete the ship file
    file.Delete("haloarmory/ships/" .. entity .. "/" .. fileName .. ".json")
    print("Deleted preset 'haloarmory/ships/" .. entity .. "/" .. fileName .. ".json'")

end


function HALOARMORY.Ships.RenameShip(entity, fileName, newfileName)
    entity = entity:GetClass()

    if not file.IsDir("haloarmory/ships/"..entity, "DATA") then
        return
    end

    -- Rename the ship file
    file.Rename("haloarmory/ships/" .. entity .. "/" .. fileName .. ".json", "haloarmory/ships/" .. entity .. "/" .. newfileName .. ".json")

    print("Preset renamed from 'haloarmory/ships/" .. entity .. "/" .. fileName .. ".json' to 'haloarmory/ships/" .. entity .. "/" .. newfileName .. ".json'")

end


function HALOARMORY.Ships.WipeProps(entity)

    --print(haloFrigate)
    if not IsValid(entity) then
        print("Error: Could not find '" .. entity:GetClass() .. "' entity.")
        return
    end

    local props = GetAttached( entity )

    if not props then
        print("Could not find any props in '" .. entity:GetClass() .. "' entity.")
        return
    end

    print("Deleted " .. #props .. " entities from " .. entity:GetClass())

    for _, prop in pairs(props) do
        prop:Remove()
    end

end



--[[ 
##============================##
||                            ||
||    SAVE PROPS IN A SHIP    ||
||                            ||
##============================##
 ]]

function HALOARMORY.Ships.SaveShip(entity, fileName)

        --print(entity)
        if not IsValid(entity) then
            print("Error: Could not find '" .. entity .. "' entity.")
            return
        end
    
        local props = GetAttached( entity )

        if not props then
            print("Could not find any props in '" .. tostring(entity) .. "' entity.")
            return
        end
    
    
        local propData = {}
    
        -- Save the data for the props to the propData table
        for _, prop in pairs(props) do

            local data = {
                Class = prop:GetClass(),
                Pos = entity:WorldToLocal(prop:GetPos()), -- Save the position relative to the "halo_frigate" entity
                Angle = prop:GetAngles() - entity:GetAngles(), -- Save the angle relative to the "halo_frigate" entity
                Model = prop:GetModel(),
                Skin = prop:GetSkin(),
                ColGroup = prop:GetCollisionGroup(),
                Name = prop:GetName(),
                ModelScale = prop:GetModelScale(),
                Color = prop:GetColor(),
                Material = prop:GetMaterial(),
                Sub_Materials = {},
                Solid = prop:GetSolid(),
                RenderMode = prop:GetRenderMode(),
            }

            // For 0 to 31 submaterials
            for i = 0, 31 do
                if prop:GetSubMaterial(i) then
                    data.Sub_Materials[i] = prop:GetSubMaterial(i)
                end
            end

            if prop:GetClass() == "prop_dynamic" then
                data.Class = "prop_physics"
            end

            if (prop:GetClass() == "prop_effect") or (prop:GetClass() == "pp_prop_effect" ) then
                data.Effect = prop.AttachedEntity:GetModel()
            end

            if prop:GetPhysicsObject() and prop:GetPhysicsObject():IsValid() then
                data.Frozen = !prop:GetPhysicsObject():IsMoveable()
            end

            -- local sm = prop:GetMaterials()
            -- if sm and type(sm) == "table" then
            --     data.SubMat = {}
            --     for k, v in pairs(sm) do
            --         if prop:GetSubMaterial(k-1) then
            --             data.SubMat[k] = prop:GetSubMaterial(k-1)
            --         end
            --     end
            -- end

            local bg = prop:GetBodyGroups()
            if bg then
                data.BodyG = {}
                for k, v in pairs(bg) do
                    if prop:GetBodygroup(v.id) > 0 then
                        data.BodyG[v.id] = prop:GetBodygroup(v.id)
                    end
                end
            end

            if ( prop.GetNetworkVars ) then
                data.DT = prop:GetNetworkVars()
            end

            if prop:GetClass() == "sammyservers_textscreen" then
                local content = {}
                content.Other = {}
                content.Other["Lines"] = prop.lines or {}

                local othercontent = content
                if not othercontent then return false end
                if othercontent != nil and istable(othercontent) then
                    table.Merge(data, othercontent)
                end
            end

            if prop:GetClass() == "job_spawn_point" and prop.zpersistance == 0 then
                local content = {}
                content.Other = {}

                --content.Other["Lines"] = prop.lines or {}

                content.Other["ent_red"] = prop.ent_red or 20
                content.Other["ent_green"] = prop.ent_green or 90
                content.Other["ent_bleu"] = prop.ent_bleu or 200
                content.Other["ent_jnom"] = prop.ent_jnom or "Name Ship"
                content.Other["ent_visible"] = prop.ent_visible or 1
                content.Other["autLjob"] = prop.autLjob or {}
                content.Other["autCjob"] = prop.autCjob or {}
                content.Other["autLulx"] = prop.autLulx or {}
                content.Other["autLteamG"] = prop.autLteamG or {}
                --content.Other["zpersistance"] = prop.zpersistance or 0

                local othercontent = content
                if not othercontent then return false end
                if othercontent != nil and istable(othercontent) then
                    table.Merge(data, othercontent)
                end
            end

            if prop:GetClass() == "frigate_door" then
                prop:SaveTabletPositions()

                local content = {}
                content.Other = {}
                content.Other["AccessList"] = prop.AccessList or {}
                content.Other["Tablets"] = prop.ControlPanel or {}

                local othercontent = content
                if not othercontent then return false end
                if othercontent != nil and istable(othercontent) then
                    table.Merge(data, othercontent)
                end

                -- if data.DT["DoorOpen"] ~= nil then
                --     data.DT["DoorOpen"] = nil
                -- end
            end




            table.insert(propData, data)

        end
    
        local foldername = entity:GetClass()
    
        -- Create the folder if it doesn't exist
        if not file.IsDir("haloarmory/ships/"..foldername, "DATA") then
            file.CreateDir("haloarmory/ships/"..foldername)
        end
    
        -- Save the prop data to the file as an array
        local propDataArray = {}
        for _, prop in pairs(propData) do
            table.insert(propDataArray, prop)
        end
        file.Write("haloarmory/ships/" .. foldername .. "/" .. fileName .. ".json", util.TableToJSON(propDataArray, true))
        print("Saved prop data to 'haloarmory/ships/" .. foldername .. "/" .. fileName .. ".json'")

end



--[[ 
##============================##
||                            ||
||    LOAD PROPS IN A SHIP    ||
||                            ||
##============================##
 ]]

 function HALOARMORY.Ships.LoadShip(entity, fileName)

    --print(haloFrigate)
    if not IsValid(entity) then
        print("Error: Could not find '" .. entity .. "' entity.")
        return
    end

    local foldername = entity:GetClass()

    -- Read the file contents
    local fileContents = file.Read("haloarmory/ships/" .. foldername .. "/" .. fileName .. ".json", "DATA")
    if not fileContents then
        print("Error: Could not read file 'haloarmory/ships/" .. foldername .. "/" .. fileName .. ".json'")
        return
    end

    -- Parse the file contents as a JSON array
    local propDataArray = util.JSONToTable(fileContents)
    if not propDataArray then
        print("Error: Could not parse file contents as JSON array")
        return
    end


    // Delete old preset
    HALOARMORY.Ships.WipeProps(entity)

    -- Spawn the props
    for _, propData in pairs(propDataArray) do


        if PermaProps and (propData.Class == "prop_effect" or propData.Class == "pp_prop_effect") then
            propData.Class = "pp_prop_effect"
            propData.Model = propData.Effect
        end



        local prop = ents.Create(propData.Class)

        if not IsValid(prop) then
            print("Error: Could not create prop:", propData.Class)
            continue 
        end

        --prop:SetPos(propData.Pos + haloFrigate:GetPos()) -- Load the position relative to the "halo_frigate" entity
        prop:SetPos(entity:LocalToWorld(propData.Pos)) -- Load the position relative to the "halo_frigate" entity
        prop:SetAngles(propData.Angle + entity:GetAngles()) -- Load the angle relative to the "halo_frigate" entity
        prop:SetModel(propData.Model)
        prop:SetSkin(propData.Skin or 0)
        prop:SetCollisionGroup(propData.ColGroup or COLLISION_GROUP_NONE)
        prop:SetName(propData.Name or "")
        prop:SetModelScale(propData.ModelScale or 1, 0)
        -- We'll have to fix the colors first, since it's not converted properly.
        local oldCol = propData.Color or { ["r"]= 255.0, ["b"]= 255.0, ["a"]= 255.0, ["g"]= 255.0 }
        propData.Color = Color(oldCol.r, oldCol.g, oldCol.b, oldCol.a)
        prop:SetColor(propData.Color or Color(255, 255, 255, 255))

        prop:SetMaterial(propData.Material or "")
        prop:SetSolid(propData.Solid or SOLID_VPHYSICS)
        prop:SetRenderMode(propData.RenderMode or RENDERMODE_NORMAL)

        if propData.SubMat then
            for k, v in pairs(propData.SubMat) do
                prop:SetSubMaterial(k, v)
            end
        end

        if propData.Sub_Materials then
            for k, v in pairs(propData.Sub_Materials) do
                if not v then continue end
                prop:SetSubMaterial(k, v)
            end
        end

        if propData.BodyG then
            for k, v in pairs(propData.BodyG) do
                prop:SetBodygroup(k, v)
            end
        end

        
        -- Was meant to add support for PermaProps. But adding a timer, seems to have made PermaProps play nice with this addon.
        local PropInPlace = ents.FindInSphere(entity:LocalToWorld(propData.Pos), 1)

        --local SkipProp = false

        for key, PIP in pairs(PropInPlace) do
            if PIP == prop then continue end

            local PIPPos = PIP:GetPos()
            local PIPDistance = entity:LocalToWorld(propData.Pos):Distance(PIPPos)

            if (PIPDistance < 1) and ( PIP:GetClass() == propData.Class) and ( PIP:GetModel() == propData.Model) then
                
                print("+", prop, propData.Class, propData.Model)
                print("-", PIP, PIP:GetClass(), PIP:GetModel(), PIPDistance)

                --SkipProp = true
                PIP:Remove()
            end
            
        end

        if propData.Class == "frigate_door" then
            if propData.Other["Tablets"] then
                prop.ControlPanel = propData.Other["Tablets"]
            end

        end


        prop:Spawn()
        prop:Activate()

        if propData.DT then

            for k, v in pairs( propData.DT ) do
    
                if ( propData.DT[ k ] == nil ) then continue end
                if !isfunction(prop[ "Set" .. k ]) then continue end
                prop[ "Set" .. k ]( prop, propData.DT[ k ] )
    
            end
    
        end

        if propData.Frozen then
            local physObj = prop:GetPhysicsObject()
            if ( IsValid( physObj ) ) then
                physObj:EnableMotion(false)
            end
        end

        if propData.Class == "frigate_door" then
            if propData.Other["AccessList"] then
                timer.Simple( 0.1, function()
                    prop:SetAccessTable( propData.Other["AccessList"] )
                end )

            end
        end

        if propData.Class == "sammyservers_textscreen" then
            if propData.Other["Lines"] then

                for k, v in pairs(propData.Other["Lines"] or {}) do
        
                    prop:SetLine(k, v.text, Color(v.color.r, v.color.g, v.color.b, v.color.a), v.size, v.font, v.rainbow or 0)
        
                end
        
            end
        end

        if propData.Class == "job_spawn_point" then
            
            if propData.Other["ent_red"] then
                prop.ent_red = propData.Other["ent_red"]
            end
            if propData.Other["ent_green"] then
                prop.ent_green = propData.Other["ent_green"]
            end
            if propData.Other["ent_bleu"] then
                prop.ent_bleu = propData.Other["ent_bleu"]
            end
            if propData.Other["ent_jnom"] then
                prop.ent_jnom = propData.Other["ent_jnom"]
            end
            if propData.Other["ent_visible"] then
                prop.ent_visible = propData.Other["ent_visible"]
            end
            if propData.Other["autLjob"] then
                prop.autLjob = propData.Other["autLjob"]
            end
            if propData.Other["autCjob"] then
                prop.autCjob = propData.Other["autCjob"]
            end
            if propData.Other["autLulx"] then
                prop.autLulx = propData.Other["autLulx"]
            end
            if propData.Other["autLteamG"] then
                prop.autLteamG = propData.Other["autLteamG"]
            end

        end

        // Add prop to ship table
        HALOARMORY.Ships.AddProp(entity, prop)

    end

end



--[[ 
##============================##
||                            ||
||        Autocomplete        ||
||                            ||
##============================##
 ]]

--[[ local function SaveAutoComplete(cmd, stringargs)
    local tbl = {
        cmd.." frigate filename",
        cmd.." corvette filename",
        cmd.." lich filename",
    }
    return tbl
end

local function LoadAutoComplete(cmd, stringargs)
    local tbl = {
        cmd.." frigate filename",
        cmd.." corvette filename",
        cmd.." lich filename",
    }
    return tbl
end ]]



--[[ 
##============================##
||                            ||
||         ConCommand         ||
||            Save            ||
||                            ||
##============================##
 ]]

--[[ concommand.Add("HALOARMORY.SaveShip", function(player, cmd, args)

    -- Check if the file name was specified in the arguments
    if #args == 0 then
        print("Error: No ship was specified.")
        return
    end

    local EntityToSave = ""

    if(string.Trim(args[1]:lower()) == "frigate") then
        EntityToSave = "halo_frigate"
    elseif(string.Trim(args[1]:lower()) == "lich") then
        EntityToSave = "halo_lich"
    elseif(string.Trim(args[1]:lower()) == "corvette") then
        EntityToSave = "halo_unsc_corvette"
    end

    if EntityToSave == "" then
        print("Error: No ship was specified.")
        return
    end

    -- Check if the file name was specified in the arguments
    if #args <= 1 then
        print("Error: No file name specified.")
        return
    end
    local fileName = table.concat(args, " ", 2)


    HALOARMORY.Ships.SaveShip(EntityToSave, fileName)

end,
SaveAutoComplete) ]]



--[[ 
##============================##
||                            ||
||         ConCommand         ||
||            Load            ||
||                            ||
##============================##
 ]]

--[[ concommand.Add("HALOARMORY.LoadShip", function(player, _, args)
    -- Check if the file name was specified in the arguments
    if #args == 0 then
        print("Error: No ship was specified.")
        return
    end

    local EntityToLoad = ""

    if(string.Trim(args[1]:lower()) == "frigate") then
        EntityToLoad = "halo_frigate"
    elseif(string.Trim(args[1]:lower()) == "lich") then
        EntityToLoad = "halo_lich"
    elseif(string.Trim(args[1]:lower()) == "corvette") then
        EntityToSave = "halo_unsc_corvette"
    end

    if EntityToLoad == "" then
        print("Error: No ship was specified.")
        return
    end

    -- Check if the file name was specified in the arguments
    if #args <= 1 then
        print("Error: No file name specified.")
        return
    end
    local fileName = table.concat(args, " ", 2)

    HALOARMORY.Ships.LoadShip(EntityToLoad, fileName)

end,
LoadAutoComplete) ]]




--[[ 
##============================##
||                            ||
||         ConCommand         ||
||            List            ||
||                            ||
##============================##
 ]]

 concommand.Add("HALOARMORY.ListPropsInShip", function(player, _, args)
    -- Check if the file name was specified in the arguments
 
    -- Find the "halo_frigate" entity
    local haloFrigate = player:GetEyeTrace().Entity
    --print(haloFrigate)
    if not IsValid(haloFrigate) then
        print("Error: Could not find '" .. tostring(haloFrigate) .. "' entity.")
        return
    end

    local props = GetAttached( haloFrigate )

    if not props then
        print("Error: Could not find any props in '" .. tostring(haloFrigate) .. "' entity.")
        return
    end

    print("Props in: " .. tostring(haloFrigate), "Found: " .. #props)

    for _, prop in pairs(props) do

        print(prop, prop:GetModel())

    end

end)



--[[ 
##============================##
||                            ||
||         ConCommand         ||
||            Wipe            ||
||                            ||
##============================##
 ]]

--  concommand.Add("HALOARMORY.WipePropsInShip", function(player, _, args)
--     -- Check if the file name was specified in the arguments
--     if #args == 0 then
--         print("Error: No ship was specified.")
--         return
--     end

--     local EntityToLoad = ""

--     if(string.Trim(args[1]:lower()) == "frigate") then
--         EntityToLoad = "halo_frigate"
--     elseif(string.Trim(args[1]:lower()) == "lich") then
--         EntityToLoad = "halo_lich"
--     elseif(string.Trim(args[1]:lower()) == "corvette") then
--         EntityToSave = "halo_unsc_corvette"
--     end

--     if EntityToLoad == "" then
--         print("Error: No ship was specified.")
--         return
--     end

--     HALOARMORY.Ships.WipeProps(EntityToLoad)

-- end)