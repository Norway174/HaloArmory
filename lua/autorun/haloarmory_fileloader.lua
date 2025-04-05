HALOARMORY = HALOARMORY or {}
HALOARMORY.Config = HALOARMORY.Config or {}

-- HaloRP - Content (https://steamcommunity.com/sharedfiles/filedetails/?id=2851837932)
if SERVER then resource.AddWorkshop( "2851837932" ) end

local loadFolders = {
    "haloarmory/libraries", -- Libraries modules.
    "haloarmory/halo_armory", -- Adds the armory.
    "haloarmory/halo_helmet_ar", -- Adds the Augmented Reality Helmet system.
    "haloarmory/halo_interface", -- Core files for various 3D3D UI elements.
    "haloarmory/halo_ships", -- Adds persistent ships. And supports save/load ship presets.
    "haloarmory/halo_logistics", -- Adds a logistics system for genering and using supplies.
    "haloarmory/halo_requisition", -- Adds a requisition system for aquiaring vehicles, using supplies.
    "haloarmory/halo_npcs", -- Experimental NPCs.
    "haloarmory/vehicle_pickup2", -- Adds the ability to pick up vehicles/items and supplies, with Pelicans or other vehicles.
    --"haloarmory/halo_redux", -- Used for the infmap. Experimental. Speeds up Pelicans flights.
    "haloarmory/halo_computer", -- Adds a computer system with emails.
    "haloarmory/modules", -- Loads costum modules if there's any.
}

local ignoreFiles = {}

local fonts = {
    "halorp-bold.ttf",
    "halorp-light.ttf",
    "halorp-medium.ttf",
    "halorp-regular.ttf",
    "halorp-semibold.ttf",
    "quantico-regular.ttf",
    "quantico-bold.ttf",
    "quantico-bolditalic.ttf",
    "quantico-italic.ttf",
}

function HALOARMORY.MsgC( ... )
    local args = {...}

    local message_table = {}

    if SERVER then
        table.insert(message_table, Color(52, 160, 211))
        table.insert(message_table, "[HALOARMORY-SV] ")
    end
    if CLIENT then
        table.insert(message_table, Color(52, 211, 78))
        table.insert(message_table, "[HALOARMORY-CL] ")
    end

    table.insert(message_table, Color(255, 255, 255))
    table.Add(message_table, args)
    table.insert(message_table, Color(198, 52, 211))
    table.insert(message_table, " ["..os.date('%Y-%m-%d %H:%M:%S').."]\n")

    MsgC(unpack(message_table))
end

function HALOARMORY.LoadAllFile(fileDir)
    local files, dirs = file.Find(fileDir .. "*", "LUA")
    
    for _, subFilePath in ipairs(files) do
        if (string.match(subFilePath, ".lua", -4) and not ignoreFiles[subFilePath]) then
            
            local fileRealm = string.sub(subFilePath, 1, 2)

            if SERVER and (fileRealm != "sv" or fileRealm == "sh") then
                HALOARMORY.MsgC("Adding CSLuaFile File " .. fileDir .. subFilePath)
                AddCSLuaFile(fileDir .. subFilePath)
            end

            if CLIENT and (fileRealm != "sv" or fileRealm == "sh") then
                HALOARMORY.MsgC("Including File " .. fileDir .. subFilePath)
                include(fileDir .. subFilePath)
            elseif SERVER and (fileRealm == "sv" or fileRealm == "sh") then
                HALOARMORY.MsgC("Including File " .. fileDir .. subFilePath)
                include(fileDir .. subFilePath)
            end

        end
    end

    for _, dir in ipairs(dirs) do
        HALOARMORY.LoadAllFile(fileDir .. dir .. "/")
    end
end

function HALOARMORY.LoadAllFonts()
    if SERVER and istable( fonts ) then

    for _, f in pairs( fonts ) do
        local src = string.format( 'resource/fonts/%s', f )
        HALOARMORY.MsgC("Loading font: " .. src)
        resource.AddSingleFile( src )
        HALOARMORY.MsgC("Successfully loaded font: " .. src)
    end

    end
end

function HALOARMORY.LoadAllFiles()
    if not istable( loadFolders ) then return end

    for _, f in pairs( loadFolders ) do
        f = f .. "/"
        HALOARMORY.MsgC("Loading folder: " .. f)
        HALOARMORY.LoadAllFile(f)
        HALOARMORY.MsgC("Successfully loaded folder: " .. f)
    end

end

function HALOARMORY.LoadCAMI()
    HALOARMORY.MsgC("Loading CAMI Permissions")

    if not CAMI then
        HALOARMORY.MsgC("CAMI not found, skipping CAMI Permissions")
        return
    end
    
    // Register Vehicle Editor
    CAMI.RegisterPrivilege({
        Name = "HALOARMORY.Vehicle Editor",
        MinAccess = "admin",
        Description = "Let's the user edit vehicles.",
    })



    HALOARMORY.MsgC("Successfully loaded CAMI Permissions")
end

HALOARMORY.MsgC(Color(0,100,255), "---- HALO ARMORY LOADING ----")
HALOARMORY.LoadAllFonts()
HALOARMORY.LoadAllFiles()
HALOARMORY.LoadCAMI()
HALOARMORY.MsgC(Color(0,100,255), "---- HALO ARMORY END ----")

if SERVER then

    if PermaProps then
        local function AddPermaPropsSupport()
            PermaProps.SpecialENTSSave = PermaProps.SpecialENTSSave or {}
            PermaProps.SpecialENTSSave["frigate_door"] = function( ent )

                local content = {}
                content.Other = {}

                content.Other["InnerPos"] = ent.ControlPanelInside:GetPos()
                content.Other["InnerAng"] = ent.ControlPanelInside:GetAngles()

                content.Other["OutterPos"] = ent.ControlPanelOutside:GetPos()
                content.Other["OutterAng"] = ent.ControlPanelOutside:GetAngles()

                content.Other["AccessList"] = ent.AccessList

                PrintTable(content.Other["AccessList"])
    
                return content
            end

            PermaProps.SpecialENTSSpawn = PermaProps.SpecialENTSSpawn or {}
            PermaProps.SpecialENTSSpawn["frigate_door"] = function( ent, data )

                if not data then return end

                ent:Spawn()
                ent:Activate()

                if IsValid( ent.ControlPanelInside ) then
                    print("Setting ControlPanelInside")
                    ent.ControlPanelInside:SetPos( data["InnerPos"] )
                    ent.ControlPanelInside:SetAngles( data["InnerAng"] )
                end

                if IsValid( ent.ControlPanelOutside ) then
                    ent.ControlPanelOutside:SetPos( data["OutterPos"] )
                    ent.ControlPanelOutside:SetAngles( data["OutterAng"] )
                end

                timer.Simple( 0.1, function()
                    ent:SetAccessTable(data["AccessList"])
                end)

                return true
            end

            HALOARMORY.MsgC( "HaloArmory PermaProps integration completed." )
        end
        hook.Add( "Initialize", "HALOARMORYxPERMAPROPS", AddPermaPropsSupport )

        AddPermaPropsSupport()
    end
end







// DEBUG!!!!!

-- Define the custom console command
concommand.Add("check_nwvars_datatables", function(ply, cmd, args)
    -- Perform a trace from the player's view
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 5000,  -- Trace for 5000 units
        filter = ply  -- Ignore the player themselves
    })
    
    -- Check if we hit something
    if tr.Hit and IsValid(tr.Entity) then
        local entityHit = tr.Entity  -- Get the Entity that was hit
        print("Hit Entity:", entityHit)

        -- Gather and print all networked variables (NWVars) on the Entity
        print("\n--- Networked Variables (NWVars) ---")
        
        -- Use the global function BuildNetworkedVarsTable to get all NWVars
        local npcNWVars = entityHit:GetNWVarTable()
        
        if npcNWVars and istable(npcNWVars) and table.Count(npcNWVars) > 0 then
            PrintTable(npcNWVars)
        else
            print("No Networked Variables found for this Entity.")
        end

        -- Gather and print all networked variables (NW2Vars) on the Entity
        print("\n--- Networked Variables (NW2Vars) ---")
        
        -- Use the global function BuildNetworkedVarsTable to get all NWVars
        local npcNW2Vars = entityHit:GetNW2VarTable()
        
        if npcNW2Vars and istable(npcNW2Vars) and table.Count(npcNW2Vars) > 0 then
            PrintTable(npcNW2Vars)
        else
            print("No Networked 2 Variables found for this Entity.")
        end

        -- Now gather and print DataTables
        print("\n--- DataTables ---")
        local saveTable = entityHit.GetNetworkVars and entityHit:GetNetworkVars() or nil

        if saveTable and istable(saveTable) and table.Count(saveTable) > 0 then
            PrintTable(saveTable)
        else
            print("No DataTables found for this Entity.")
        end

    else
        print("No Entity was hit.")
    end
end)



// Remove all VGUI elements
if CLIENT then
    concommand.Add("remove_all_vgui", function(ply, cmd, args)
        print("Removing all VGUI elements.")
        for k, v in pairs(vgui.GetAll()) do
            print("Removing VGUI Element:", v)
            v:Remove()
        end
    end)
end
