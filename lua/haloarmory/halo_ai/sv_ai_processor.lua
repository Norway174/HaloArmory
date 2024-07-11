HALOARMORY.MsgC("Server HALO AI Loading.")

HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.AIs = HALOARMORY.AI.AIs or {}


util.AddNetworkString("HALOARMORY.AI")



hook.Add( "InitPostEntity", "HaloArmory.AI-ULX", function()
    if not ULib then HALOARMORY.MsgC( "HaloArmory AI-ULX integration failed, no ULib." ) return end

    ULib.ucl.registerAccess("AI Access", "user", "Restricts access to the AI command.", "HALOARMORY")
    ULib.ucl.registerAccess("GM AI Access", "admin", "Restricts GameMaster access to the AI command.", "HALOARMORY")

    HALOARMORY.MsgC( "HaloArmory AI-ULX integration completed." )
end )


function HALOARMORY.AI.Prompt( API, Post, call_back )

    if not API then HALOARMORY.MsgC( "AI ERROR: No API Key defined." ) return end
    if not Post then HALOARMORY.MsgC( "AI ERROR: No Post defined." ) return end

    Post = util.TableToJSON( Post )

    // Replace all "XX" (numbers) with XX (numbers) using a pattern and string.gsub.
    Post = string.gsub( Post, "\"(%d+)\"", "%1" )

    HTTP( {
        -- onFailure function
        failed = function( reason )
            HALOARMORY.MsgC( "AI ERROR: HTTP Error. Response: \"" .. message .. "\"" )
        end,
        -- onSuccess function
        success = function( code, body, headers )
            if isfunction( call_back ) then
                    
                pcall(call_back, body)
            else
                HALOARMORY.MsgC( "AI ERROR: No function defined. AI Response: \"" .. body .. "\"" )
            end
        end,

        method = "POST",
        url = "https://api.openai.com/v1/chat/completions",
        headers = {
            ["Authorization"] = "Bearer " .. API
        },
        body = Post,
        type = "application/json"
    } )

end


local function getLocation()

    // TODO: Get the map details.

    return ""

end

local function replaceString( str, ai_details, ply )

    // Replace all {player} with the player's name.
    if IsValid(ply) and ply:IsPlayer() then
        str = string.Replace( str, "{player}", ply:Nick() )
    end

    // Replace all {map} with the current map.
    str = string.Replace( str, "{map}", game.GetMap() )

    // Replace all {ai-name} with the AI's name.
    str = string.Replace( str, "{ai-name}", ai_details["name"] )

    // Replace all {players} with a list of all the players.
    local players = ""
    for k, v in pairs( player.GetAll() ) do
        players = players .. v:Nick() .. ", "
    end
    str = string.Replace( str, "{players}", players )

    // Replace all {map-details} with the current location.
    str = string.Replace( str, "{map-details}", getLocation() )

    return str

end


function HALOARMORY.AI.PromptEngineer( ai_name, cmd, text, ply )

    --print( "Prompting Engineer: ", ai_name, text )

    local ai_details = HALOARMORY.AI.AIs[ ai_name ]

    if not ai_details then HALOARMORY.MsgC( "AI ERROR: AI not found." ) return end
    if not ai_details["enabled"] then return end
    if not ai_details["API"] then HALOARMORY.MsgC( "AI ERROR: No API Key defined." ) return end
    if not ai_details["model"] then HALOARMORY.MsgC( "AI ERROR: No model defined." ) return end

    --PrintTable( ai_details )

    local ai_api = ai_details["API"]
    local ai_model = ai_details["model"]
    local ai_tokens = ai_details["token_limit"]

    local system_msg = replaceString(ai_details["global_prompt"], ai_details, ply)

    local messages = {}
    // Insert the first system message.
    table.insert( messages, {
        ["role"] = "system",
        ["content"] = system_msg
    } )

    // Insert the AI's history messages.
    for k, v in ipairs( ai_details["history"] ) do
        table.insert( messages, v )
    end

    // Insert the user's message.
    local ply_msg = replaceString(string.Replace(cmd["prompt"], "{message}", text), ai_details, ply)
    table.insert( messages, {
        ["role"] = "user",
        ["content"] = ply_msg
    } )

    // Create the post table.

    local ai_post = {
        ["model"] = ai_model,
        ["messages"] = messages,
        ["max_tokens"] = tostring(ai_tokens),
    }

    if cmd["access"] == "public" then
        print( net.Start("HALOARMORY.AI") )
            net.WriteString( "chat_input_public" ) -- The action.
            net.WriteEntity( ply ) -- The player.
            net.WriteString( ply_msg ) -- The Message.
        net.Broadcast()
    end

    HALOARMORY.AI.Prompt( ai_api, ai_post, function( response )

        response = util.JSONToTable( response )

        if not response then HALOARMORY.MsgC( "AI ERROR: No response." ) return end
        if response["error"] then HALOARMORY.MsgC( "AI ERROR: " .. response["error"] ) return end

        local ai_response = response["choices"][1]["message"]["content"]

        if ai_response == "" then HALOARMORY.MsgC( "AI ERROR: No response: " .. tostring(response) ) return end

        if cmd["access"] == "public" then
            net.Start("HALOARMORY.AI")
                net.WriteString( "chat_output_public" ) -- The action.
                net.WriteString( ai_name ) -- The AI's name.
                net.WriteTable( ai_details["color"] ) -- The AI's color.
                net.WriteString( ai_response ) -- The Message.
            net.Broadcast()
        end

        // Insert the players message into the history.
        table.insert( ai_details["history"], {
            ["role"] = "user",
            ["content"] = ply_msg
        } )

        // Insert the AI's response into the history.
        table.insert( ai_details["history"], {
            ["role"] = "assistant",
            ["content"] = ai_response
        } )

        // Create a loop to remove the oldest messages, if the whole history is over max_tokens long.
        local history_passed = false
        while not history_passed do

            local history_length = 0
            for k, v in ipairs( ai_details["history"] ) do
                local token, _ = HALOARMORY.AI.Tokens.Encode( v["content"] )
                history_length = history_length + token
            end

            if history_length >= ai_tokens then
                table.remove( ai_details["history"], 1 )
            else
                history_passed = true
            end

        end


        // Save the AI's history.
        HALOARMORY.AI.Manager.SaveAI( ai_details )
        HALOARMORY.AI.AIs[ ai_name ] = ai_details

    end )

end



hook.Add( "PlayerSay", "HALOARMORY.AI", function( ply, text )

    // Check all the AIs commands for a match.
    for ai_name, ai_details in pairs( HALOARMORY.AI.AIs ) do

        for cmd_indx, cmd in pairs(ai_details["commands"]) do
            cmd_indx = cmd_indx .. " "

            if string.StartsWith( string.lower(text), string.lower(cmd_indx) ) then
                // Remove the command from the text.
                local msg = string.Replace( text, cmd_indx, "" )

                // Check if the message is empty.
                if msg == "" then return end
                // TODO: If message is empty, cancel the message, and send to the user the prompt can't be empty.

                // Send the message to the Prompt Engineer.
                HALOARMORY.AI.PromptEngineer( ai_name, cmd, msg, ply )

                // Return to stop the message from being sent to chat.
                return ""
                
            end

        end

    end

end )


// Load the AI's
function HALOARMORY.AI.LoadAIs()

    local list_AIs = HALOARMORY.AI.Manager.GetAIList()

    HALOARMORY.AI.AIs = {}

    for k, v in pairs( list_AIs ) do

        local the_AI = HALOARMORY.AI.Manager.LoadAI( k ) -- Load the filename, not the AI name.

        HALOARMORY.AI.AIs[ v ] = the_AI

    end

end

HALOARMORY.AI.LoadAIs()