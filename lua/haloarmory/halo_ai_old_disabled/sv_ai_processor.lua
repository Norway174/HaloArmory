HALOARMORY.MsgC("Server HALO AI Loading.")

HALOARMORY.AI = HALOARMORY.AI or {}

local API_KEY = "ninW4!M6BBiQXBEaBXBB"

local nets = {
    "haloarmory_ai_input",
    "haloarmory_ai_input_gm",
    "haloarmory_ai_output",
    "haloarmory_ai_no_access",
}
for _, net in pairs(nets) do
    util.AddNetworkString(net)
end


hook.Add( "InitPostEntity", "HaloArmory.AI-ULX", function()
    if not ULib then HALOARMORY.MsgC( "HaloArmory AI-ULX integration failed, no ULib." ) return end

    ULib.ucl.registerAccess("AI Access", "user", "Restricts access to the AI command.", "HALOARMORY")
    ULib.ucl.registerAccess("GM AI Access", "admin", "Restricts GameMaster access to the AI command.", "HALOARMORY")

    HALOARMORY.MsgC( "HaloArmory AI-ULX integration completed." )
end )




function HALOARMORY.AI.Prompt( text, call_back )

    http.Post( "http://54.37.245.225:7629", { api_key = API_KEY, prompt = text },

            -- onSuccess function
            function( body, length, headers, code )
                if isfunction( call_back ) then
                    
                    pcall(call_back, body)
                else
                    print( "AI ERROR: No function defined. AI Response: \"" .. body .. "\"" )
                end
            end,

            -- onFailure function
            function( message )
                if isfunction( call_back ) then
                    call_back( "AI Unavalible." )
                else
                    print( "AI ERROR: HTTP Error. Response: \"" .. message .. "\"" )
                end
            end

        )

end


local function getLocation()

    local Maps_Locations = {}

    Maps_Locations["rp_valhalla_v1"] = [[
We are currently on planet Gnadus R8.

The main base is located at X 10339, Y 12499, Z 964. With a radius of 150 meters.

There is a SOS base located underground at X 2774, Y 11115, Z -6914. With a radius of 80 meters.
]]
    return Maps_Locations[game.GetMap()] or ""
end

local function getPlayers()
    local list_players = ""
    for i, ply in ipairs( player.GetAll() ) do

        local job = "No job"
        if DarkRP then
            job = ply:getDarkRPVar("job") or "Unknown job"
        end

        local pos = "X " .. math.Round(ply:GetPos().x) .. ", Y " .. math.Round(ply:GetPos().y) .. ", Z " .. math.Round(ply:GetPos().z)

        local person = string.format("%s ( Job: %s | Pos: %s )", ply:Nick(), job, pos )

        list_players = list_players .. person .. ", "
    end
    return list_players
end

function HALOARMORY.AI.PromptEngineer( name, text )

    local prompt = string.format([[You are an UNSC AI called %s in the Halo Universe.
Your task is to assist the UNSC personnel in whatever their task or mission may be.
The current UNIX time is %s. (If you're gonna use the time, convert it to human readable.)
%s
There are several key personnel available: %s

Please treat the person speaking with respect to their rank, and refer to them by their rank.
Always stay in character. Refrain from asking questions. Any information that isn't provided, make up with your knowledge of the halo universe.
-----------------

%s: %s]], HALOARMORY.AI.Name, os.time(), getLocation(), getPlayers(), name, text)

    return prompt

end

function HALOARMORY.AI.PromptEngineer_GM( text )

    local prompt = string.format([[You are an UNSC AI called %s in the Halo Universe.
And event is triggered. Execute the following task, or relay to the troops.
-----------------

%s]], HALOARMORY.AI.Name, text)

    return prompt

end


hook.Add( "PlayerSay", "HALOARMORY.AI", function( ply, text )

    // Normal Access AI
    if ( string.StartWith(string.lower( text ), "!ai") ) then

        text = string.sub( text, 5 )

        if not ULib.ucl.query( ply, "AI Access" ) then
            net.Start( "haloarmory_ai_no_access" )
            net.WriteEntity( ply )
            net.WriteString( text )
            net.Send( ply )
            return ""
        end

        net.Start( "haloarmory_ai_input" )
        net.WriteEntity( ply )
        net.WriteString( text )
        net.Broadcast()

        local prompt = HALOARMORY.AI.PromptEngineer( ply:Nick(), text )

        --prompt = string.Replace( prompt, "Norway174", "CAPT Zoey McKenzie" )

        HALOARMORY.AI.Prompt( prompt, function( response )

            // Check if AI already started with their own prefix name. If so, remove it.
            if string.StartWith( response, HALOARMORY.AI.Name) then response = string.sub( response, #HALOARMORY.AI.Name + 3 ) end

            net.Start( "haloarmory_ai_output" )
            net.WriteString( response )
            net.Broadcast()

        end)

        return ""
    end

    // Gamemaster AI Access
    if ( string.StartWith(string.lower( text ), "!gmai") ) then

        text = string.sub( text, 7 )

        if not ULib.ucl.query( ply, "GM AI Access", true ) then
            net.Start( "haloarmory_ai_no_access" )
            net.WriteEntity( ply )
            net.WriteString( text )
            net.Send( ply )
            return ""
        end

        local gm_players = {}
        for i, ply2 in ipairs( player.GetAll() ) do
            if ULib.ucl.query( ply2, "GM AI Access" ) then table.insert( gm_players, ply2 ) end
        end

        net.Start( "haloarmory_ai_input_gm" )
        net.WriteEntity( ply )
        net.WriteString( text )
        net.Send( gm_players )

        local prompt = HALOARMORY.AI.PromptEngineer_GM( text )

        --prompt = string.Replace( prompt, "Norway174", "PO1 Zoey McKenzie" )

        HALOARMORY.AI.Prompt( prompt, function( response )

            // Check if AI already started with their own prefix name. If so, remove it.
            if string.StartWith( response, HALOARMORY.AI.Name) then response = string.sub( response, #HALOARMORY.AI.Name + 3 ) end
        
            net.Start( "haloarmory_ai_output" )
            net.WriteString( response )
            net.Send( gm_players )

        end)

        return ""
    end

end )