
include('shared.lua')

function ENT:DrawTranslucent()
    self:DrawModel()


    --local pos = self:GetPos() + self.VehicleSpawnPos

    --render.DrawWireframeSphere( pos, self.VehicleSpawnRadius, 10, 10, Color( 9, 177, 255), true)
end