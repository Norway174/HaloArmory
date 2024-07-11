
include('shared.lua')

function ENT:Draw3D2D( ent )
    local ply = ply or LocalPlayer()
    if not IsValid( ply ) then return end

    //draw.RoundedBox( 0, 0, 0, self.frameW, self.frameH, Color( 219, 23, 23) )

    // Draw a header that says "UNSC Vehicle Requesition"
    local headerText = "UNSC Vehicle Requesition"
    if self.GetConsoleName then
        headerText = self:GetConsoleName()
    end

    draw.DrawText( headerText, "HK_QuanticoHeader", self.frameW * .5, self.frameH * .15, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )

    // Distance check
    if self:GetPos():Distance( ply:GetPos() ) >= 100 then return end
    --if true then return end

    // Draw a large button that says "Request Vehicle"
    local btnOutline = 30
    local btnW, btnH = 1000, 300
    btnW, btnH = btnW+btnOutline, btnH+btnOutline
    draw.RoundedBox( 0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * .5), btnW, btnH, Color( 9, 255, 0) )
    btnW, btnH = btnW-btnOutline, btnH-btnOutline
    
    local btnColor = Color( 27, 27, 27)
    if ui3d2d.isHovering( (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * .5), btnW, btnH ) then
        if ui3d2d.isPressing() then
            btnColor = Color( 53, 53, 53)
            if ui3d2d.isPressed() then
                // Open the GUI to request a vehicle
                --HALOARMORY.Requisition.Open( self:GetPadID() )
                if HALOARMORY.Requisition.GUI.Pad_Menu then
                    return
                end
                
                if self:GetConsoleID() ~= "" then
                    // Loop through all the pads and find the one that matches the console ID
                    local pads = {}

                    if ents.Iterator then
                        for _, the_ent in ents.Iterator() do
                            if ( the_ent.VehiclePad ) then
                                table.insert(pads, the_ent)
                            end
                        end
        
                    else // Compatibility mode if no pads are found
                        for _, the_ent in pairs(ents.GetAll()) do
                            if ( the_ent.VehiclePad ) then
                                table.insert(pads, the_ent)
                            end
                        end
                    end

                    //print("Found "..#pads.." pads")

                    for _, pad in pairs(pads) do
                        if pad:GetPadID() == self:GetConsoleID() then
                            HALOARMORY.Requisition.OpenVehiclePad( pad )
                            return
                        end
                    end

                    HALOARMORY.Requisition.OpenPadSelector()
                else
                    HALOARMORY.Requisition.OpenPadSelector()
                end
            end
        else
            btnColor = Color( 92, 92, 92)
        end
    end
    draw.RoundedBox( 0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * .5), btnW, btnH, btnColor )
    draw.DrawText( "Request Vehicle", "HK_QuanticoHeader",self.frameW * .5, (self.frameH * .5)-(btnH * .3), Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

end