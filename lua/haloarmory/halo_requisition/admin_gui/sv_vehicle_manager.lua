HALOARMORY.MsgC("VEHICLE ADMIN Manager Loaded")


HALOARMORY.VEHICLES = HALOARMORY.VEHICLES or {}
HALOARMORY.VEHICLES.ADMIN = HALOARMORY.VEHICLES.ADMIN or {}
HALOARMORY.VEHICLES.LIST = HALOARMORY.VEHICLES.LIST or {}

// Save path
local vehicles_path = "haloarmory/vehicles/"

function HALOARMORY.VEHICLES.ADMIN.SAVEVEHICLE( vehicle_filename, vehicle_table )

    // Save the vehivcle to the file

    // Check if the folder exists
    if not file.Exists( vehicles_path, "DATA" ) then
        file.CreateDir( vehicles_path )
    end

    local full_path = vehicles_path..vehicle_filename..".json"

    if vehicle_table["old_filename"] and file.Exists( vehicles_path..vehicle_table["old_filename"]..".json", "DATA" ) then
        file.Rename( vehicles_path..vehicle_table["old_filename"]..".json", full_path )
    end
    vehicle_table["old_filename"] = nil

    // Write file to disk
    file.Write( full_path, util.TableToJSON( vehicle_table, true ) )

    // Add or Update the vehicle in the table
    HALOARMORY.VEHICLES.LIST[ vehicle_filename ] = vehicle_table
    

end


function HALOARMORY.VEHICLES.ADMIN.LOADVEHICLES()

    // Load all the vehicles from the folder

    // Check if the folder exists
    if not file.Exists( vehicles_path, "DATA" ) then
        file.CreateDir( vehicles_path )
    end

    // Get all the files in the folder
    local files, folders = file.Find( vehicles_path.."*.json", "DATA" )

    HALOARMORY.VEHICLES.LIST = {}

    // Loop through all the files
    for k, v in pairs( files ) do

        // Check if the file is a json file
        if string.GetExtensionFromFilename( v ) == "json" then

            // Load the file
            local file_content = file.Read( vehicles_path..v, "DATA" )

            // Convert the json to a table
            local file_table = util.JSONToTable( file_content )

            // Fix the table

            // 1st convert the colors to a color table
            for color_k, color_v in pairs( file_table.colors ) do
                file_table.colors[color_k] = Color( color_v.r, color_v.g, color_v.b, color_v.a )
            end

            // Check if the table is valid
            if file_table then

                // Add the vehicle to the table
                HALOARMORY.VEHICLES.LIST[ file_table.filename ] = file_table

            end

        end

    end

    --print("Loaded vehicles", #HALOARMORY.VEHICLES.LIST, table.Count( HALOARMORY.VEHICLES.LIST ) )
    --PrintTable( HALOARMORY.VEHICLES.LIST )

end



local MenuUsers = {}

util.AddNetworkString("HALOARMORY.VEHICLES.ADMIN")


net.Receive("HALOARMORY.VEHICLES.ADMIN", function(len, ply)

    if ULib and not ULib.ucl.query( ply, "Vehicle Editor" ) then
        --chat.AddText( Color( 255, 0, 0 ), "You do not have access to this command!" )
        return "No Access!"
    elseif not ULib and not ply:IsAdmin() then
        --chat.AddText( Color( 255, 0, 0 ), "You do have access to this command!" )
        return "No Access!"
    end

    local Type = net.ReadString()

    if Type == "GETVEHICLES" then

        net.Start("HALOARMORY.VEHICLES.ADMIN")

            MenuUsers[ply] = true

            net.WriteString("GETVEHICLES")

            HALOARMORY.VEHICLES.ADMIN.LOADVEHICLES()

            local FileNames = {}

            for k, v in pairs( HALOARMORY.VEHICLES.LIST ) do
                table.insert( FileNames, k )
            end

            net.WriteTable(FileNames)

        net.Send(ply)

    elseif Type == "MENUCLOSED" then
            MenuUsers[ply] = nil

    elseif Type == "EDITVEHICLE" then

        local VehicleFilenameToEdit = net.ReadString()

        if not VehicleFilenameToEdit then return end

        local Vehicle_table = HALOARMORY.VEHICLES.LIST[ VehicleFilenameToEdit ]

        net.Start("HALOARMORY.VEHICLES.ADMIN")

            net.WriteString("EDITVEHICLE")

            net.WriteTable(Vehicle_table)

        net.Send(ply)

    elseif Type == "SAVEVEHICLE" then

        local Vehicle = net.ReadTable()

        if not Vehicle then return end

        --print("Saving vehicle", Vehicle.filename )

        --PrintTable(Vehicle)

        HALOARMORY.VEHICLES.ADMIN.SAVEVEHICLE( Vehicle.filename, Vehicle )

    elseif Type == "REMOVEVEHICLE" then

        local VehicleFilenameToDelete = net.ReadString()

        if not VehicleFilenameToDelete then return end

        HALOARMORY.VEHICLES.LIST[ VehicleFilenameToDelete ] = nil

        file.Delete( vehicles_path..VehicleFilenameToDelete..".json" )

        HALOARMORY.VEHICLES.ADMIN.LOADVEHICLES()

        net.Start("HALOARMORY.VEHICLES.ADMIN")

            net.WriteString("GETVEHICLES")

            local FileNames = {}

            for k, v in pairs( HALOARMORY.VEHICLES.LIST ) do
                table.insert( FileNames, k )
            end

            net.WriteTable(FileNames)

        net.Send(ply)

    end

end)