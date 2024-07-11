include('shared.lua')
 
--[[---------------------------------------------------------
   Name: Draw
   Purpose: Draw the model in-game.
   Remember, the things you render first will be underneath!
---------------------------------------------------------]]
function ENT:Draw()

    self:DrawModel()

end

concommand.Add( "HALOARMORY.DOORS.SyncAccess", function( ply, cmd, args )
    net.Start( "HALOARMORY.DOOR.REQACCESS.ALL" )
    net.SendToServer()
end )

hook.Add( "InitPostEntity", "HALOARMORY.DOOR.SYNCALL", function()
    net.Start( "HALOARMORY.DOOR.REQACCESS.ALL" )
    net.SendToServer()
end )