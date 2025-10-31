HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}

-- Handle player login/logout
local function HandleComputerLogin(ply, cmd, args)
    local entIndex = tonumber(args[1])
    if not entIndex then return end
    
    local ent = Entity(entIndex)
    if not IsValid(ent) or not ent.IsHALOARMORY then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end -- 500 units squared
    
    -- Initialize files if needed
    if ent:GetPC_ID() == "" and not ent.PC_Files then
        HALOARMORY.COMPUTER.InitializeFiles(ent)
    end
end

local function HandleComputerLogout(ply, cmd, args)
    local entIndex = tonumber(args[1])
    if not entIndex then return end
    
    local ent = Entity(entIndex)
    if not IsValid(ent) or not ent.IsHALOARMORY then return end
end

concommand.Add("halo_computer_login", HandleComputerLogin)
concommand.Add("halo_computer_logout", HandleComputerLogout) 