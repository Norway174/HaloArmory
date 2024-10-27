AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Timer Screen"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true
ENT.DeviceType = "timer_screen"
ENT.Editable = true
ENT.Model = 1

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "TimerTitle", { KeyName = "Timer Title", Edit = { type = "Generic", order = 1 } })
    self:NetworkVar("Bool", 0, "Active", { KeyName = "Active", Edit = { type = "Boolean", order = 1 } })
    self:NetworkVar("Bool", 1, "IsStopwatch", { KeyName = "IsStopwatch", Edit = { type = "Boolean", order = 2 } })

    // Countdown timer
    self:NetworkVar( "Float", 0, "Start" )
    self:NetworkVar( "Float", 1, "Stop" )

    // Stopwatch
    self:NetworkVar("Int", 0, "CountdownTime", { KeyName = "Countdown Time", Edit = { type = "Int", order = 2, category = "Timer", min = 0, max = 9999 } })
    self:NetworkVar("Float", 2, "StartTime")
    self:NetworkVar("Float", 3, "PauseTime")
    self:NetworkVar("Int", 1, "InitialTime") -- New variable to track initial/default time

    if SERVER then
        self:SetTimerTitle("TIMER")

        self:SetIsStopwatch( true )
        
        self:SetStart( 0 )
        self:SetStop( 0 )

        self:SetCountdownTime(10 * 60) -- Default 10 minutes
        self:SetInitialTime(10 * 60)
        self:SetStartTime(0)

        self:SetActive( false )
    end

end

if SERVER then
    function ENT:StartTimer(extraTime)
        if self:GetIsStopwatch() then

            self:SetStart( CurTime() )
            self:SetStop( 0 )

        else
            
            local currentCountdown = self:GetCountdownTime()

            -- Set a new timer if extraTime is provided
            if extraTime then
                self:SetCountdownTime(currentCountdown + extraTime)
            end

            if not self:GetActive() then
                -- Start from the original set time or resume
                local startTime = self:GetStartTime() > 0 and self:GetStartTime() or CurTime()
                self:SetStartTime(startTime + self:GetCountdownTime())
            else
                -- If already active, just add extra time
                self:SetStartTime(self:GetStartTime() + extraTime)
            end

        end

        self:SetActive(true)
    end

    function ENT:StopTimer()
        if self:GetIsStopwatch() then
            self:SetStop( CurTime() )
        else
            -- Save the remaining time before pausing
            self:SetPauseTime(self:GetStartTime() - CurTime())
        end

        self:SetActive(false)
    end

    function ENT:ResetTimer()
        if self:GetIsStopwatch() then
            -- Reset to initial/default time
            self:SetStart(0)
            self:SetStop(0)
        else
            -- Reset to initial/default time
            self:SetCountdownTime(self:GetInitialTime())
            self:SetStartTime(0)
            self:SetPauseTime(0)
        end

        self:SetActive(false)
    end

    function ENT:ResumeTimer()
        if self:GetIsStopwatch() then

            self:SetStart( CurTime() - (self:GetStop() - self:GetStart()) )
            self:SetStop( 0 )
            self:SetActive( true )
        else

            if self:GetPauseTime() > 0 then
                -- Resume with the remaining time saved in PauseTime
                self:SetStartTime(CurTime() + self:GetPauseTime())
                self:SetPauseTime(0)
                self:SetActive(true)
            end

        end

    end

    concommand.Add("halo_tv_timer_start", function(ply, cmd, args)
        local ent = Entity(args[1])
        local extraTime = tonumber(args[2])

        if not IsValid(ent) or not ent.IsHALOARMORY or ent:GetClass() != "halo_tv_timer" then return end
        ent:StartTimer(extraTime)
    end)

    concommand.Add("halo_tv_timer_stop", function(ply, cmd, args)
        local ent = Entity(args[1])

        if not IsValid(ent) or not ent.IsHALOARMORY or ent:GetClass() != "halo_tv_timer" then return end
        ent:StopTimer()
    end)

    concommand.Add("halo_tv_timer_reset", function(ply, cmd, args)
        local ent = Entity(args[1])

        if not IsValid(ent) or not ent.IsHALOARMORY or ent:GetClass() != "halo_tv_timer" then return end
        ent:ResetTimer()
    end)

    concommand.Add("halo_tv_timer_resume", function(ply, cmd, args)
        local ent = Entity(args[1])

        if not IsValid(ent) or not ent.IsHALOARMORY or ent:GetClass() != "halo_tv_timer" then return end
        ent:ResumeTimer()
    end)

    function ENT:Think()
        if self:GetActive() and self:GetTimeLeft() <= 0 then
            self:SetActive(false)
            -- Play a sound or perform an action when timer ends
            -- self:EmitSound("halo/timer_end.wav")
        end
    end
end

function ENT:GetTimeLeft()
    if self:GetIsStopwatch() then
        if self:GetActive() then
            return CurTime() - self:GetStart()
        else
            return self:GetStop() - self:GetStart()
        end
    else

        if self:GetActive() then
            return math.max(0, self:GetStartTime() - CurTime())
        elseif self:GetPauseTime() > 0 then
            return self:GetPauseTime()
        else
            return self:GetCountdownTime()
        end

    end
end




if not CLIENT then return end


ENT.Theme = {
    ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
    ["colors"] = {
        ["background_color"] = Color( 168, 168, 168 ),
        ["text_color"] = Color( 255, 255, 255 ),
        ["buttons_default"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_resume"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_stop"] = {
            ["btn_normal"] = Color(16, 51, 102, 128),
            ["btn_hover"] = Color(22, 53, 99),
            ["btn_click"] = Color(7, 20, 41),
        },
        ["buttons_reset"] = {
            ["btn_normal"] = Color(102, 16, 16, 128),
            ["btn_hover"] = Color(99, 22, 22),
            ["btn_click"] = Color(41, 7, 7),
        },
    },
}



local ply = LocalPlayer()
local SoundClick = "buttons/lightswitch2.wav"

local function draw_button_countdown(ent)
    if not IsValid(ply) then return end
    if ent:GetPos():Distance(ply:GetPos()) >= 150 then return end

    local TimerActive = ent:GetActive()
    local timeLeft = ent:GetTimeLeft()

    -- Determine button text based on timer state
    local buttonText = "Start"
    local buttonStyle = "buttons_default"
    if TimerActive then
        buttonText = "Stop"
        buttonStyle = "buttons_stop"
    elseif timeLeft < ent:GetCountdownTime() then
        buttonText = "Resume"
        buttonStyle = "buttons_resume"
    end

    -- Button dimensions
    local btn_w, btn_h = 400, 100
    local btn_x, btn_y = (ent.frameW * .28) - (btn_w * .5), ent.frameH * .7

    -- Draw the button to start/stop/resume the timer
    surface.SetDrawColor(ent.Theme["colors"][buttonStyle]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then
        if ui3d2d.isPressed() then
            surface.SetDrawColor(ent.Theme["colors"][buttonStyle]["btn_click"])
            surface.PlaySound(SoundClick)

            if TimerActive then
                RunConsoleCommand("halo_tv_timer_stop", ent:EntIndex())
            elseif timeLeft < ent:GetCountdownTime() then
                RunConsoleCommand("halo_tv_timer_resume", ent:EntIndex())
            else
                RunConsoleCommand("halo_tv_timer_start", ent:EntIndex())
            end
        else
            surface.SetDrawColor(ent.Theme["colors"][buttonStyle]["btn_hover"])
        end
    end

    surface.DrawRect(btn_x, btn_y, btn_w, btn_h)
    draw.SimpleText(buttonText, "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Draw the reset button
    btn_x = (ent.frameW * .28) - (btn_w * .5) + btn_w + 25
    surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then
        if ui3d2d.isPressed() then
            surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_click"])
            surface.PlaySound(SoundClick)
            RunConsoleCommand("halo_tv_timer_reset", ent:EntIndex())
        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_hover"])
        end
    end

    surface.DrawRect(btn_x, btn_y, btn_w, btn_h)
    draw.SimpleText("Reset", "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end




local function draw_button_stopwatch( ent )
    if not IsValid( ply ) then return end

    if ent:GetPos():Distance( ply:GetPos() ) >= 150 then return end

    local Timer_active = ent:GetActive()

    -- Determine button text based on timer state
    local text = "Resume"
    local buttonStyle = "buttons_default"

    if ent:GetTimeLeft() <= 0 then
        text = "Start"
        buttonStyle = "buttons_resume"
    elseif Timer_active then
        text = "Stop"
        buttonStyle = "buttons_stop"
    end

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


    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    draw.SimpleText( text, "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )


    --Draw the button to reset the timer
    --btn_w = 500
    --btn_h = 100

    btn_x = (ent.frameW * .28) - (btn_w * .5) + btn_w + 25
    btn_y = ent.frameH * .7

    surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_normal"])
    if ui3d2d.isHovering(btn_x, btn_y, btn_w, btn_h) then --Check if the box is being hovered
        if ui3d2d.isPressed() then --Check if input is being held
            surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_click"])

            surface.PlaySound(SoundClick)
            RunConsoleCommand( "halo_tv_timer_reset", ent:EntIndex() )

        else
            surface.SetDrawColor(ent.Theme["colors"]["buttons_reset"]["btn_hover"])
        end
    end

    surface.DrawRect( btn_x, btn_y, btn_w, btn_h )
    draw.SimpleText( "Reset", "SP_QuanticoRate", btn_x + (btn_w * .5), btn_y + (btn_h * .2), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

end


function ENT:DrawScreen()
    local model_table = self.ScreenModels[self.Model]
    self.frameW, self.frameH = model_table["frameW"], model_table["frameH"]

    -- Draw timer title
    draw.SimpleText(self:GetTimerTitle(), "SP_QuanticoHeader", self.frameW * .5, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Draw separator line
    surface.SetDrawColor(Color(255, 255, 255, 42))
    surface.DrawRect(20, 100, self.frameW - 40, 2)

    -- Verify player is valid and in range
    if not ply or not ply:IsPlayer() then ply = LocalPlayer() end
    if not ply or not ply:IsPlayer() or self:GetPos():Distance(ply:GetPos()) >= 3000 then return end

    -- Draw the timer countdown
    local timeLeft = self:GetTimeLeft()
    local minutes, seconds = math.floor(timeLeft / 60), math.floor(timeLeft % 60)
    local milliseconds = math.floor((timeLeft - math.floor(timeLeft)) * 1000)
    local time_str = string.format("%02d:%02d", minutes, seconds)

    -- Adjust for hours if necessary
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        time_str = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end

    local posX, posY = self.frameW * .5, self.frameH * .22
    draw.DrawText(time_str, "SP_QuanticoPad", posX, posY, self.Theme["colors"]["text_default"], TEXT_ALIGN_CENTER)
    draw.DrawText(string.format(".%03d", milliseconds), "SP_QuanticoRate", posX + 300, posY + 150, Color(163, 163, 163), TEXT_ALIGN_CENTER)

    -- Draw the interactive buttons
    if self:GetIsStopwatch() then
        draw_button_stopwatch(self)
    else
        draw_button_countdown(self)
    end
end
