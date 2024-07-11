AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_pc_base"
 
ENT.PrintName = "Hackable Control Panel"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true



function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "ScreenWindow", { KeyName = "ScreenWindow",	Edit = { type = "Generic", order = 1 } } )

    if SERVER then
        self:SetScreenWindow( "Standby" )
    end

end



if not CLIENT then return end

function ENT:Draw3D2D( ent )
    local ply = ply or LocalPlayer()
    if not IsValid( ply ) then return end

    // Distance check
    if self:GetPos():Distance( ply:GetPos() ) >= 100 then return end

    // Get the screen window
    local screenWindow = self:GetScreenWindow()

    // Draw the screen window
    if screenWindow == "Standby" then

        // Draw a red box in the inter, make it centered.
        local outline = 35
        local boxW, boxH = 1300, 650
        boxW, boxH = boxW+outline, boxH+outline
        draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5), boxW, boxH, Color( 255, 0, 0 ) )
        boxW, boxH = boxW-outline, boxH-outline
        draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5), boxW, boxH, Color( 27, 27, 27) )

        // Draw the label
        draw.SimpleText( "// WARNING // SYSTEM LOCKDOWN // WARNING //", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(boxH * .4), Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
        // Draw the header
        draw.SimpleText( "OVERRIDE REQUIRED", "HK_QuanticoHeader", self.frameW * .5, (self.frameH * .5)-(boxH * .2), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
        // Draw the button
        local btnOutline = 30
        local btnW, btnH = 500, 160
        btnW, btnH = btnW+btnOutline, btnH+btnOutline
        draw.RoundedBox( 0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH, Color( 255, 0, 0 ) )
        btnW, btnH = btnW-btnOutline, btnH-btnOutline
        
        local btnColor = Color( 27, 27, 27)
        if ui3d2d.isHovering( (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH ) then
            btnColor = Color( 92, 92, 92)
        end
        draw.RoundedBox( 0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3), btnW, btnH, btnColor )

        // Draw the button label
        draw.SimpleText( "HACK", "HK_QuanticoHeader", self.frameW * .5, (self.frameH * .5)-(btnH * -.8), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

end
