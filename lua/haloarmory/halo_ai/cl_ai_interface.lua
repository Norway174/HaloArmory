HALOARMORY.MsgC("Client HALO AI Loading.")

local function AddAIMessage( prefix, name, color, message )

    --print("AddAIMessage", name, color, message)

    chat.AddText(
        Color(0, 255, 255),
        "[ " .. prefix .. " ] ",
        color,
        message
    )

end

net.Receive("HALOARMORY.AI", function( len )
    local action = net.ReadString()

    --print("HALOARMORY.AI", action)

    if string.StartsWith( action, "EditAI") then
        --print( "Match" )
        HALOARMORY.AI.Manager_GUI.RouteNetwork( len, action )

    elseif action == "chat_input_public" then
        local ply = net.ReadEntity()
        local message = net.ReadString()
    
        AddAIMessage( "AI-COMMS", ply:Nick(), team.GetColor( ply:Team() ), message )

    elseif action == "chat_input_gm" then
        local ply = net.ReadEntity()
        local message = net.ReadString()

        AddAIMessage( "GM->AI", ply:Nick(), team.GetColor( ply:Team() ), message )

    elseif action == "chat_output_public" then
        local AI_Name = net.ReadString()
        local AI_Color = net.ReadTable()
        local message = net.ReadString()

        AddAIMessage( "AI-COMMS", AI_Name, AI_Color, message )

    elseif action == "chat_no_access" then
        local ply = net.ReadEntity()
        local message = net.ReadString()
        print("NO ACCESS TO AI!", message)

        AddAIMessage( "PRIVATE", ply:Nick(), team.GetColor( ply:Team() ), message )

        AddAIMessage( "PRIVATE", "ERROR", Color(189, 189, 189), "No access to the command." )
    end

    --print("HALOARMORY.AI", action, "END")
end )