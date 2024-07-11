

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_get_relative_pos.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.halo_get_relative_pos.name","Get Relative Position")
    local ent = tostring( TOOL:GetEnt( 1 ) ) 
    language.Add("tool.halo_get_relative_pos.desc","Right Click to select. Left Click to get Position.")
    language.Add("tool.halo_get_relative_pos.left","Get Relative Position")
    language.Add("tool.halo_get_relative_pos.right","Set Source Position")
    language.Add("tool.halo_get_relative_pos.reload","Toggle between Entity and Vector Source")
end

TOOL.VectorSource = false

TOOL.SourceTarget = nil
TOOL.RelativeTarget = nil



function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "Spawner", Description = [[
This tool can get the relative position of an entity to another entity or a vector.
    ]]})
end


function TOOL:GetEntPos( ent )
    if isvector( ent ) then
        return ent
    elseif IsValid( ent ) then
        return ent:GetPos()
    else 
        return Vector(0,0,0)
    end
end

function TOOL:GetEntAng( ent )
    if isvector( ent ) then
        return Angle(0,0,0)
    elseif IsValid( ent ) then
        return ent:GetAngles()
    else 
        return Angle(0,0,0)
    end
end

function TOOL:GetLocalPos( ent, pos )
    if isvector( ent ) then
        return pos - ent
    elseif IsValid( ent ) then
        return ent:WorldToLocal( pos )
    else 
        return Vector(0,0,0)
    end
end

function TOOL:GetLocalAng( ent, ang )
    if isvector( ent ) then
        return ang
    elseif IsValid( ent ) then
        return ent:WorldToLocalAngles( ang )
    else 
        return Angle(0,0,0)
    end
end

function TOOL:Think()
end

function TOOL:LeftClick( trace )
    
    if self.SourceTarget == nil then
        if CLIENT then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You need to select a Source first.")
        end
        return
    end


    local ent = trace.Entity
    local pos = trace.HitPos

    local rel_pos = self:GetLocalPos( self.SourceTarget, pos )
    local rel_ang = self:GetLocalAng( self.SourceTarget, trace.HitNormal:Angle() )

    if not self.VectorSource and IsValid( trace.Entity ) then
        rel_pos = self:GetLocalPos( self.SourceTarget, trace.Entity:GetPos() )
        rel_ang = self:GetLocalAng( self.SourceTarget, trace.Entity:GetAngles() )
    end


    if CLIENT then
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", "------------------------------------------------------")
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Relative Position: ", Color(159,241,255), rel_pos, Color(255,255,255), "")
        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Relative Angle: ", Color(159,241,255), rel_ang, Color(255,255,255), "")
    end

    self.SourceTarget = nil
    
end

function TOOL:RightClick( trace )
    local ent = trace.Entity

    
    --self:SetObject( 1, ent, trace.HitPos, trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )

    if !self.VectorSource and IsValid( ent ) then
        self.SourceTarget = ent
    else
        self.SourceTarget = trace.HitPos
    end


    if CLIENT then
        --chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Selected: ", Color(159,241,255), ent:GetClass(), Color(255,255,255), " / ", Color(159,241,255), trace.HitPos, Color(255,255,255), ".")
    end

end

function TOOL:Reload( trace )
    self.VectorSource = not self.VectorSource
end


function TOOL:DrawHUD()
    local trace = LocalPlayer():GetEyeTrace()

    local ModeText = "Entity"
    if self.VectorSource then
        ModeText = "Vector"
    end
    draw.DrawText( "Mode: " .. ModeText, "Trebuchet24", 50, 220, Color(255,255,255), TEXT_ALIGN_LEFT )


    // Draw the global position of the trace
    draw.DrawText( "Global Pos", "Trebuchet24", 50, 250, Color(255,255,255), TEXT_ALIGN_LEFT )
    local pos = trace.HitPos
    draw.DrawText( tostring( pos ), "Trebuchet24", 50, 270, Color(255,255,255), TEXT_ALIGN_LEFT )


    // Draw a line between the two points
    if self.SourceTarget != nil then
        local spos = self:GetEntPos( self.SourceTarget )
        local wpos = spos:ToScreen()

        local tpos = trace.HitPos:ToScreen()
        if not self.VectorSource and IsValid( trace.Entity ) then
            tpos = trace.Entity:GetPos():ToScreen()
        end

        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.DrawLine( wpos.x, wpos.y, tpos.x, tpos.y )


        draw.DrawText( "Source - " .. tostring( self.SourceTarget ) , "Trebuchet24", 50, 300, Color(255,255,255), TEXT_ALIGN_LEFT )
        draw.DrawText( tostring( spos ), "Trebuchet24", 50, 320, Color(255,255,255), TEXT_ALIGN_LEFT )

        draw.DrawText( tostring( self.SourceTarget ), "Trebuchet24", wpos.x, wpos.y + 20, Color(255,255,255), TEXT_ALIGN_CENTER )
        if IsValid( self.SourceTarget ) then
            draw.DrawText( tostring( self.SourceTarget:GetPos() ), "Trebuchet24", wpos.x, wpos.y, Color(255,255,255), TEXT_ALIGN_CENTER )
        end

        
        // Draw the local position of the trace
        draw.DrawText( "Local Pos", "Trebuchet24", 50, 350, Color(255,255,255), TEXT_ALIGN_LEFT )
        local lpos = self:GetLocalPos( self.SourceTarget, pos )
        if not self.VectorSource and IsValid( trace.Entity ) then
            lpos = self:GetLocalPos( self.SourceTarget, trace.Entity:GetPos() )
        end
        draw.DrawText( tostring( lpos ), "Trebuchet24", 50, 370, Color(255,255,255), TEXT_ALIGN_LEFT )
    end

end


