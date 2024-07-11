HALOARMORY.MsgC("Server CHARACTHER Creator Loading.")

HALOARMORY = HALOARMORY or {}
HALOARMORY.Character = HALOARMORY.Character or {}

util.AddNetworkString( "HALOARMORY.Character.OPEN_GUI" )
util.AddNetworkString( "HALOARMORY.Character.SEND_DATA" )


function HALOARMORY.Character.OpenCreator( ply )
    net.Start( "HALOARMORY.Character.OPEN_GUI" )
    net.Send( ply )
end



// The player has made their character.
net.Receive( "HALOARMORY.Character.SEND_DATA", function( len, ply )
    local FirstName = net.ReadString()
    local LastName = net.ReadString()
    local SelectedModel = net.ReadString()

    ply:SetModel( SelectedModel )

    ply:setRPName( FirstName .. " " .. LastName )

    HALOARMORY.Character.SaveCharacter( ply )

end)