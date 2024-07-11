include('shared.lua')

--[[ 
        -- Create a scanner effect beam
        self.ScannerBeam = ents.Create( "prop_dynamic" )
        self.ScannerBeam:SetModel( "models/squad/sf_plates/sf_plate3x6.mdl" )
        --self.ScannerBeam:SetColor( Color( 255, 255, 255, 255 ) )
        self.ScannerBeam:SetMaterial( "Models/effects/comball_sphere" )
        self.ScannerBeam:SetPos( self:LocalToWorld(Vector(-18,36,31)) )
        self.ScannerBeam:SetAngles( self:LocalToWorldAngles(Angle(0,-90,0)) )
        self.ScannerBeam:SetNoDraw( true )

        self.ScannerBeam:Spawn()
        self.ScannerBeam:SetParent( self )
        self:DeleteOnRemove(self.ScannerBeam)
 ]]

function ENT:Initialize()

    self.scanBeam = ClientsideModel("models/squad/sf_plates/sf_plate3x6.mdl")
    self.scanBeam:SetMaterial( "Models/effects/comball_sphere" )

end

function ENT:Draw()

    self:DrawModel()
    
    if not IsValid( self.scanBeam ) then
        self.scanBeam = ClientsideModel("models/squad/sf_plates/sf_plate3x6.mdl")
        self.scanBeam:SetMaterial( "Models/effects/comball_sphere" )
    end

    if self.scanBeam and self:GetDoScan() then

        local beamHeight = (math.sin(CurTime() * 3) * 5.5) + 5.5

        self.scanBeam:SetNoDraw( false )
        self.scanBeam:SetPos( self:LocalToWorld(Vector(-18,36, beamHeight + 31)) )
        self.scanBeam:SetAngles( self:LocalToWorldAngles(Angle(0,-90,0)) )
    
    else
        self.scanBeam:SetNoDraw( true )
    end

end

function ENT:OnRemove()

    if self.scanBeam then
        self.scanBeam:Remove()
    end

end