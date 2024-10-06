
HALOARMORY.MsgC("Server HALO Augmented Reality Controller Loading.")


HALOARMORY.AR = HALOARMORY.AR or {}
HALOARMORY.AR.IFF = HALOARMORY.AR.IFF or {}

util.AddNetworkString("HALOARMORY.AR.IFF")

function HALOARMORY.AR.IFF.SendTargets()

	local Targets = {}

	// Add all players to the target list.
	for _, ply in ipairs( player.GetAll() ) do
		local Target = {}
		Target.Ent = ply
		Target.EntType = "Player"
		table.insert( Targets, Target )
	end

	// Add all props to the target list.
	for _, prop in ipairs( ents.FindByClass( "halo_sp_crate" ) ) do
		local Target = {}
		Target.Ent = prop
		Target.EntType = "Prop"
		table.insert( Targets, Target )
	end

	for _, ply in pairs(player.GetAll()) do

		// Add all NPCs to the target list.
		for _, npc in pairs( ents.FindByClass( "npc_*" ) ) do
			if npc:IsNPC() or npc:IsNextBot() then
				// Get NPC disposition.
				if ( isfunction(npc.Disposition) ) then
					if ( npc:Disposition( ply ) == D_LI ) then
						local Target = {}
						Target.Ent = npc
						Target.EntType = "NPC-Friendly"
						table.insert( Targets, Target )
					elseif ( npc:Disposition( ply ) == D_HT ) then
						local Target = {}
						Target.Ent = npc
						Target.EntType = "NPC-Hostile"
						table.insert( Targets, Target )
					elseif ( npc:Disposition( ply ) == D_NU ) then
						local Target = {}
						Target.Ent = npc
						Target.EntType = "NPC-Neutral"
						table.insert( Targets, Target )
					end
				else
					local Target = {}
					Target.Ent = npc
					Target.EntType = "NPC-Unkown"
					table.insert( Targets, Target )
				end
			end
		end


		// Send the target list to the client.
		net.Start("HALOARMORY.AR.IFF", true)
			net.WriteString("SendTargets")
			net.WriteTable(Targets)
		net.Send( ply )

	end

end
	

timer.Create("HALOARMORY.AR.IFF.SendTargets", 5, 0, function()
	HALOARMORY.AR.IFF.SendTargets()
end)