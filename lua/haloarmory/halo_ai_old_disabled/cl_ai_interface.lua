HALOARMORY.MsgC("Client HALO AI Loading.")

local function AddAIMessage( prefix, name, color, message )

    --print("AddAIMessage", name, color, message)

    chat.AddText(
        Color(0, 255, 255),
        "[ " .. prefix .. " ] ",
        color,
        name .. ": " .. message
    )

end

net.Receive( "haloarmory_ai_input", function( len )
    local ply = net.ReadEntity()
    local message = net.ReadString()

    AddAIMessage( "AI-COMMS", ply:Nick(), team.GetColor( ply:Team() ), message )
end )

net.Receive( "haloarmory_ai_input_gm", function( len )
    local ply = net.ReadEntity()
    local message = net.ReadString()

    AddAIMessage( "GM->AI", ply:Nick(), team.GetColor( ply:Team() ), message )
end )

net.Receive( "haloarmory_ai_output", function( len )
    local message = net.ReadString()

    AddAIMessage( "AI-COMMS", HALOARMORY.AI.Name, HALOARMORY.AI.Color, message )
end )

net.Receive( "haloarmory_ai_no_access", function( len )
    local ply = net.ReadEntity()
    local message = net.ReadString()
    print("NO ACCESS TO AI!", message)

    AddAIMessage( "PRIVATE", ply:Nick(), team.GetColor( ply:Team() ), message )

    AddAIMessage( "PRIVATE", "ERROR", Color(189, 189, 189), "No access to the command." )
end )