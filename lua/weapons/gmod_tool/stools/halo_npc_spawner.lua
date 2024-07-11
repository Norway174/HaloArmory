

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_npc_spawner.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.halo_npc_spawner.name","NPC Spawner")
    language.Add("tool.halo_npc_spawner.desc","Spawns the configured NPC.")
    language.Add("tool.halo_npc_spawner.left","Spawn NPC")
    language.Add("tool.halo_npc_spawner.right","Delete NPC")
    language.Add("tool.halo_npc_spawner.reload","Clear all NPCs")
end



function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "Spawner", Description = [[
This tool is still work in progress. And is not functional yet.
    ]]})
end

function TOOL:Think()

    if CLIENT then
        // If the ship is nil, update the desc
        if not IsValid(self:GetEnt( 1 )) then
            language.Add("tool.halo_npc_spawner.desc","Attaches a prop to the ship (No ship selected)")
        else
            local ship_class = self:GetEnt( 1 ):GetClass()
            language.Add("tool.halo_npc_spawner.desc","Attaches a prop to the ship ("..ship_class..")")
        end
    end

end

function TOOL:LeftClick( trace )
    if trace.Entity == self:GetEnt( 1 ) then
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't attach the ship to itself.")
        return
    end

    print("Left click")

end

function TOOL:RightClick( trace )
    if trace.Entity == self:GetEnt( 1 ) then
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't deatach the ship from itself.")
        return
    end

    print("Right click")

end

function TOOL:Reload( trace )
    local ent = trace.Entity

    if ent.HALOARMORY_Ships_Presets then
        // Set the "ship" convar
        --print("Ship selected", ent)
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Ship selected: ", Color(159,241,255), ent:GetClass(), Color(255,255,255), ".")
        self:SetObject( 1, ent )
    end
end



