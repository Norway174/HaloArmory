HALOARMORY = HALOARMORY or {}
HALOARMORY.Config = HALOARMORY.Config or {}

-- HaloRP - Content (https://steamcommunity.com/sharedfiles/filedetails/?id=2851837932)
if SERVER then resource.AddWorkshop( "2851837932" ) end

local loadFolders = {
    "haloarmory/ui3d2d", -- Library for 3D2D UIs. Used for in-world UIs.
    --"haloarmory/character_manager", -- In active dev. Do not enable.
    "haloarmory/halo_armory", -- Adds the armory.
    --"haloarmory/halo_ai", -- Adds the ChatGPT AI interace. Disabled. Rewrite coming soon!
    --"haloarmory/halo_ai_old_disabled", -- The Original ChatGPT AI interace. Disabled. Used a third party server.
    "haloarmory/halo_interface", -- Core files for various 3D3D UI elements.
    "haloarmory/halo_ships", -- Adds persistent ships. And supports save/load ship presets.
    "haloarmory/halo_logistics", -- Adds a logistics system for genering and using supplies.
    "haloarmory/halo_requisition", -- Adds a requisition system for aquiaring vehicles, using supplies.
    "haloarmory/halo_npcs", -- Experimental NPCs.
    --"haloarmory/vehicle_pickup", -- Adds the ability to pick up vehicles/items and supplies, with Pelicans or other vehicles.
    "haloarmory/vehicle_pickup2", -- Adds the ability to pick up vehicles/items and supplies, with Pelicans or other vehicles.
    --"haloarmory/halo_redux", -- Used for the infmap. Experimental. Speeds up Pelicans flights.
    "haloarmory/halo_requisition", -- Adds the ability to requisition vehicles.
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

HALOARMORY.MsgC(Color(0,100,255), "---- HALO ARMORY LOADING ----")
HALOARMORY.LoadAllFonts()
HALOARMORY.LoadAllFiles()
HALOARMORY.MsgC(Color(0,100,255), "---- HALO ARMORY END ----")

if SERVER then
    hook.Add( "InitPostEntity", "HaloArmory.ULXIntegration", function()
        if not ULib then HALOARMORY.MsgC( "HaloArmory ULX integration failed, no ULib." ) return end

        ULib.ucl.registerAccess("Vehicle Editor", "admin", "Let's the user edit vehicles.", "HALOARMORY")

        HALOARMORY.MsgC( "HaloArmory ULX integration completed." )
    end )
end
