AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Timer Screen"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.DeviceType = "timer_screen"

ENT.Editable = false

ENT.Model = 1

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "TimerTitle" )
    self:NetworkVar( "Float", 0, "Start" )
    self:NetworkVar( "Float", 1, "Stop" )
    self:NetworkVar( "Bool", 0, "Active" )

    if SERVER then
        self:SetTimerTitle( "TIMER" )
        self:SetStart( 0 )
        self:SetStop( 0 )
        self:SetActive( false )
    end


end

if SERVER then

    function ENT:StartTimer()
        self:SetStart( CurTime() )
        self:SetStop( 0 )
        self:SetActive( true )
    end

    function ENT:StopTimer()
        self:SetStop( CurTime() )
        self:SetActive( false )
    end

    function ENT:ResetTimer()
        self:SetStart( 0 )
        self:SetStop( 0 )
        self:SetActive( false )
    end

    function ENT:ResumeTimer()
        self:SetStart( CurTime() - (self:GetStop() - self:GetStart()) )
        self:SetStop( 0 )
        self:SetActive( true )
    end

    concommand.Add( "halo_tv_timer_start", function( ply, cmd, args )
        local ent = Entity(args[1])

        if not IsValid( ent ) or not ent.IsHALOARMORY then return end
        if ent:GetClass() != "halo_tv_timer" then return end

        ent:StartTimer()
    end )

    concommand.Add( "halo_tv_timer_stop", function( ply, cmd, args )
        local ent = Entity(args[1])

        if not IsValid( ent ) or not ent.IsHALOARMORY then return end
        if ent:GetClass() != "halo_tv_timer" then return end

        ent:StopTimer()
    end )

    concommand.Add( "halo_tv_timer_reset", function( ply, cmd, args )
        local ent = Entity(args[1])

        if not IsValid( ent ) or not ent.IsHALOARMORY then return end
        if ent:GetClass() != "halo_tv_timer" then return end

        ent:ResetTimer()
    end )

    concommand.Add( "halo_tv_timer_resume", function( ply, cmd, args )
        local ent = Entity(args[1])

        if not IsValid( ent ) or not ent.IsHALOARMORY then return end
        if ent:GetClass() != "halo_tv_timer" then return end

        ent:ResumeTimer()
    end )


end

function ENT:GetTimeElapsed()
    if self:GetActive() then
        return CurTime() - self:GetStart()
    else
        return self:GetStop() - self:GetStart()
    end
end





if not CLIENT then return end


local ply = LocalPlayer()

local SoundClick = "buttons/lightswitch2.wav"


local function draw_button( ent )
    if not IsValid( ply ) then return end

    if ent:GetPos():Distance( ply:GetPos() ) >= 150 then return end

    local Timer_active = ent:GetActive()


    --Draw the button to start/stop the timer
    local btn_w = 400
    local btn_h = 100

    local btn_x = (ent.frameW * .28) - (btn_w * .5)
    local btn_y = ent.frameH * .7

    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

                if Timer_active then
                    surface.PlaySound(SoundClick)
                    RunConsoleCommand( "halo_tv_timer_stop", ent:EntIndex() )
                else
                    surface.PlaySound(SoundClick)
                    RunConsoleCommand( "halo_tv_timer_resume", ent:EntIndex() )
                end

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end

    local text = "Resume"

    if ent:GetTimeElapsed() <= 0 then
        text = "Start"
    elseif Timer_active then
        text = "Stop"
    end

    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    draw.SimpleText( text, "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )


    --Draw the button to reset the timer
    --btn_w = 500
    --btn_h = 100

    btn_x = (ent.frameW * .28) - (btn_w * .5) + btn_w + 25
    btn_y = ent.frameH * .7

    surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_click"])

            surface.PlaySound(SoundClick)
            RunConsoleCommand( "halo_tv_timer_reset", ent:EntIndex() )

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_default"]["btn_hover"])
        end
    end

    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    draw.SimpleText( "Reset", "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

end



function ENT:DrawScreen()

    local model_table = self.ScreenModels[self.Model]

    self.frameW = model_table["frameW"]
    self.frameH = model_table["frameH"]

    --surface.SetDrawColor( Color( 255, 0, 0) )
    --surface.DrawRect( 0, 0, self.frameW, self.frameH )

    --surface.SetMaterial( unsc_logo )
    --surface.SetDrawColor( Color( 0, 0, 0, 79) )
    --surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )

    --Draw the title
    draw.SimpleText( self:GetTimerTitle(), "SP_QuanticoHeader", self.frameW * .5, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

    

    --Draw seperator
    surface.SetDrawColor( Color( 255, 255, 255, 42) )
    surface.DrawRect( 20, 100, self.frameW - 40, 2 )

    if not ply or not ply:IsPlayer() then ply = LocalPlayer() end
    if not ply or not ply:IsPlayer() then return end

    // Stop drawing if the player is too far away
    if self:GetPos():Distance( ply:GetPos() ) >= 3000 then return end


    --Draw the text

    local time_elapsed = self:GetTimeElapsed()

    local minutes = math.floor(time_elapsed / 60)
    local seconds = math.floor(time_elapsed % 60)
    local milliseconds = math.floor((time_elapsed - math.floor(time_elapsed)) * 1000)

    local time_str
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        time_str = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
        time_str = string.format("%02d:%02d", minutes, seconds)
    end

    local posX = self.frameW * .5
    local posY = self.frameH * .22
    local text_align = TEXT_ALIGN_CENTER

    draw.DrawText( time_str, "SP_QuanticoPad", posX, posY, self.Theme["colors"]["text_default"], text_align, text_align )

    // Draw Miliseconds differntly
    draw.DrawText( string.format(".%03d", milliseconds), "SP_QuanticoRate", posX + 300, posY + 150, Color( 163, 163, 163), text_align, text_align )

    --Draw the button
    draw_button( self )

end
