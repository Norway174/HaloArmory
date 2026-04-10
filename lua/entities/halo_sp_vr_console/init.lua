
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:SpawnFunction( ply, tr, class_name )
    if not tr.Hit then return end

    if not IsValid( ply ) then return end

    ply:ConCommand( "haloarmory_open_console_menu" )
end

