HALOARMORY.MsgC("Server HALO AI Manager Loading.")


HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.Manager = HALOARMORY.AI.Manager or {}

HALOARMORY.AI.Manager.SavePathBase = "haloarmory/ai/"
HALOARMORY.AI.Manager.SavePathAI = HALOARMORY.AI.Manager.SavePathBase .. "ai/"
HALOARMORY.AI.Manager.SavePathMaps = HALOARMORY.AI.Manager.SavePathBase .. "maps/"

local function base64_encode_filaneme( filename )
    local base64 = util.Base64Encode(filename)

    // Replace the characters that are not allowed in filenames
    base64 = string.Replace(base64, "/", "_")
    base64 = string.Replace(base64, "+", "-")
    base64 = string.Replace(base64, "=", "")

    // Max filename length is 255
    // Let's cut it down to 15 characters
    base64 = string.sub(base64, 1, 15)

    return base64
end


function HALOARMORY.AI.Manager.LoadAI( aiName )
    // Check if aiName ends with .json, if so, remove it
    if string.EndsWith(aiName, ".json") then
        aiName = string.sub(aiName, 1, -6)
    end

    // Load the AI
    local the_ai = util.JSONToTable(file.Read(HALOARMORY.AI.Manager.SavePathAI .. aiName .. ".json", "DATA"))

    // Return the AI
    return the_ai
end

function HALOARMORY.AI.Manager.GetAIList()
    // Get the list of AIs
    local aiFiles = file.Find(HALOARMORY.AI.Manager.SavePathAI .. "*.json", "DATA")

    // Create a list
    local aiList = {}

    // Load each AI, and grab the names, and add it to a list.
    for k, v in pairs(aiFiles) do
        // Check if aiName ends with .json, if so, remove it
        if string.EndsWith(v, ".json") then
            v = string.sub(v, 1, -6)
        end

        // Load the AI
        local the_ai = HALOARMORY.AI.Manager.LoadAI(v)

        // Add the name to the list
        aiList[v] = the_ai["name"]
    end

    // Return the list
    --PrintTable(aiList)
    return aiList
end

function HALOARMORY.AI.Manager.GetMapList()
    // Get the list of maps
    local mapList = file.Find(HALOARMORY.AI.Manager.SavePathMaps .. "*.json", "DATA")

    // Return the list
    return mapList
end

function HALOARMORY.AI.Manager.DeleteAI( aiName )
    // Check if aiName ends with .json, if so, remove it
    if string.EndsWith(aiName, ".json") then
        aiName = string.sub(aiName, 1, -6)
    end

    // Delete the AI
    file.Delete(HALOARMORY.AI.Manager.SavePathAI .. aiName .. ".json")
end

function HALOARMORY.AI.Manager.SaveAI( aiTable )
    // Get the AI name from the table
    local aiName = aiTable["name"]

    // Check if there's a variable called "old_name", if so, remove it.
    if aiTable["old_name"] then
        HALOARMORY.AI.Manager.DeleteAI( aiTable["old_name"] )
        aiTable["old_name"] = nil
    end

    -- Create the folder if it doesn't exist
    if not file.IsDir(HALOARMORY.AI.Manager.SavePathAI, "DATA") then
        file.CreateDir(HALOARMORY.AI.Manager.SavePathAI)
    end

    // Save the AI
    file.Write(HALOARMORY.AI.Manager.SavePathAI .. base64_encode_filaneme(aiName) .. ".json", util.TableToJSON(aiTable, true))
end


util.AddNetworkString("HALOARMORY.AI")


net.Receive("HALOARMORY.AI", function(len, ply)
    local command = net.ReadString()

    // Check if the player is an admin
    if !ply:IsAdmin() then return end

    if command == "EditAI-List" then
        // Get the list of AIs
        local aiList = HALOARMORY.AI.Manager.GetAIList()
        
        // Send the list to the player
        net.Start("HALOARMORY.AI")
            net.WriteString("EditAI-List-Rply")
            net.WriteTable(aiList)
        net.Send(ply)

    elseif command == "EditAI-Delete" then
        // Get the AI name
        local aiName = net.ReadString()

        // Delete the AI
        HALOARMORY.AI.Manager.DeleteAI(aiName)

        // Update AIs
        HALOARMORY.AI.LoadAIs()

        // Send the list of AIs
        local aiList = HALOARMORY.AI.Manager.GetAIList()
        
        // Send the list to the player
        net.Start("HALOARMORY.AI")
            net.WriteString("EditAI-List-Rply")
            net.WriteTable(aiList)
        net.Send(ply)

    elseif command == "EditAI-Load" then
        // Get the AI name
        local aiName = net.ReadString()

        // Check if aiName ends with .json, if so, remove it
        if string.EndsWith(aiName, ".json") then
            aiName = string.sub(aiName, 1, -6)
        end

        // Update the AI
        HALOARMORY.AI.LoadAIs()

        // Load the AI
        local the_ai = HALOARMORY.AI.Manager.LoadAI(aiName)

        // Send the AI to the player
        net.Start("HALOARMORY.AI")
            net.WriteString("EditAI-Load-Rply")
            net.WriteTable(the_ai)
        net.Send(ply)

    elseif command == "EditAI-Save" then
        // Get the AI table
        local aiTable = net.ReadTable()

        // Save the AI
        HALOARMORY.AI.Manager.SaveAI(aiTable)

        // Update AIs
        HALOARMORY.AI.LoadAIs()

        // Send the list of AIs
        local aiList = HALOARMORY.AI.Manager.GetAIList()
        
        // Send the list to the player
        net.Start("HALOARMORY.AI")
            net.WriteString("EditAI-List-Rply")
            net.WriteTable(aiList)
        net.Send(ply)

    elseif command == "Tokenize" then
        // Get the text
        local text = net.ReadString()
        local SHA = net.ReadString()

        // Tokenize the text
        HALOARMORY.AI.Tokens.Tokenize(text, function(tokens, success)
            // Send the tokens to the player
            ply:SendLua("HALOARMORY.AI.Tokens.EncodeClientCallback('" .. SHA .. "', " .. tokens .. ", " .. tostring(success) .. ")")
        end)

    end
end)