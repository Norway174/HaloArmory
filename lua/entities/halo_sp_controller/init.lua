
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")



ENT.NextSuppliesProcessTick = CurTime() + 60
function ENT:Think()
    // Every minute, increase or decrease the Supplies based on the RateM.
    if ( CurTime() > self.NextSuppliesProcessTick ) then
        self.NextSuppliesProcessTick = CurTime() + 60

        if self:GetRateM() == 0 then return end

        local name = self:GetNetworkID()

        HALOARMORY.Logistics.AddNetworkSupplies( name, self:GetRateM() )
    end
end