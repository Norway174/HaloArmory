HALOARMORY.MsgC("Client HALO Computer Email Toasts Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.EMAIL = HALOARMORY.COMPUTER.EMAIL or {}
HALOARMORY.COMPUTER.EMAIL_TOASTS = HALOARMORY.COMPUTER.EMAIL_TOASTS or {}

local EMAIL = HALOARMORY.COMPUTER.EMAIL
local TOASTS = HALOARMORY.COMPUTER.EMAIL_TOASTS

TOASTS.Active = TOASTS.Active or {}
TOASTS.Queue = TOASTS.Queue or {}

TOASTS.MaxActive = 3
TOASTS.Width = 360
TOASTS.Height = 78
TOASTS.Padding = 14
TOASTS.Gap = 12
TOASTS.RightMargin = 22
TOASTS.TopMargin = 70
TOASTS.EnterDuration = 0.22
TOASTS.LeaveDuration = 0.22
TOASTS.HoldDuration = tonumber(HALOARMORY.COMPUTER.EMAIL_Conf.ToastHoldSeconds) or 5
TOASTS.Sound = "friends/friend_online.wav"

surface.CreateFont("HALOARMORY.Computer.EmailToast.Header", {
    font = "Tahoma",
    size = 18,
    weight = 700,
    antialias = true
})

surface.CreateFont("HALOARMORY.Computer.EmailToast.Subtext", {
    font = "Tahoma",
    size = 15,
    weight = 500,
    antialias = true
})

surface.CreateFont("HALOARMORY.Computer.EmailToast.Icon", {
    font = "Tahoma",
    size = 26,
    weight = 700,
    antialias = true
})

local function EaseOutCubic(value)
    value = math.Clamp(value, 0, 1)
    return 1 - math.pow(1 - value, 3)
end

local function EaseInCubic(value)
    value = math.Clamp(value, 0, 1)
    return value * value * value
end

local function PromoteQueuedToasts()
    while #TOASTS.Active < TOASTS.MaxActive and #TOASTS.Queue > 0 do
        local nextToast = table.remove(TOASTS.Queue, 1)
        if nextToast then
            nextToast.state = "entering"
            nextToast.stateStartedAt = CurTime()
            table.insert(TOASTS.Active, nextToast)
            EmitSound( TOASTS.Sound, Vector(0,0,0), -2 )
        end
    end
end

function TOASTS.BuildToast(unreadCount)
    local numericCount = math.max(0, tonumber(unreadCount) or 0)
    local isSummary = numericCount > 0

    return {
        id = "toast_" .. tostring(SysTime()) .. "_" .. tostring(math.random(1000, 9999)),
        kind = isSummary and "summary" or "live",
        unreadCount = numericCount,
        header = isSummary and "Unread Mail" or "New Mail",
        subtext = isSummary
            and (numericCount == 1 and "You have 1 unread email." or ("You have " .. numericCount .. " unread emails."))
            or "You received a new email.",
        createdAt = CurTime(),
        state = "queued",
        stateStartedAt = CurTime()
    }
end

function TOASTS.Push(unreadCount)
    local toast = TOASTS.BuildToast(unreadCount)

    if #TOASTS.Active < TOASTS.MaxActive then
        toast.state = "entering"
        toast.stateStartedAt = CurTime()
        table.insert(TOASTS.Active, toast)
        EmitSound( TOASTS.Sound, Vector(0,0,0), -2 )
    else
        table.insert(TOASTS.Queue, toast)
    end
end

local function UpdateToastLifecycle(toast)
    if toast.state == "entering" then
        local progress = (CurTime() - toast.stateStartedAt) / TOASTS.EnterDuration
        if progress >= 1 then
            toast.state = "holding"
            toast.stateStartedAt = CurTime()
        end
        return
    end

    if toast.state == "holding" then
        if (CurTime() - toast.stateStartedAt) >= TOASTS.HoldDuration then
            toast.state = "leaving"
            toast.stateStartedAt = CurTime()
        end
        return
    end
end

local function CleanupFinishedToasts()
    local kept = {}

    for _, toast in ipairs(TOASTS.Active) do
        if toast.state == "leaving" then
            local progress = (CurTime() - toast.stateStartedAt) / TOASTS.LeaveDuration
            if progress < 1 then
                table.insert(kept, toast)
            end
        else
            table.insert(kept, toast)
        end
    end

    TOASTS.Active = kept
    PromoteQueuedToasts()
end

local function DrawToast(toast, slotIndex)
    local screenWidth = ScrW()
    local targetX = screenWidth - TOASTS.Width - TOASTS.RightMargin
    local hiddenX = screenWidth + TOASTS.Width
    local y = TOASTS.TopMargin + ((slotIndex - 1) * (TOASTS.Height + TOASTS.Gap))

    local alpha = 255
    local x = targetX

    if toast.state == "entering" then
        local progress = EaseOutCubic((CurTime() - toast.stateStartedAt) / TOASTS.EnterDuration)
        x = Lerp(progress, hiddenX, targetX)
        alpha = Lerp(progress, 0, 255)
    elseif toast.state == "leaving" then
        local progress = EaseInCubic((CurTime() - toast.stateStartedAt) / TOASTS.LeaveDuration)
        x = Lerp(progress, targetX, hiddenX)
        alpha = Lerp(progress, 255, 0)
    end

    local bgColor = Color(37, 37, 38, alpha)
    local borderColor = Color(55, 55, 61, alpha)
    local accentColor = Color(0, 122, 204, alpha)
    local primaryText = Color(212, 212, 212, alpha)
    local secondaryText = Color(157, 165, 180, alpha)
    local iconColor = Color(79, 193, 255, alpha)

    surface.SetDrawColor(borderColor)
    surface.DrawRect(x, y, TOASTS.Width, TOASTS.Height)

    surface.SetDrawColor(bgColor)
    surface.DrawRect(x + 1, y + 1, TOASTS.Width - 2, TOASTS.Height - 2)

    surface.SetDrawColor(accentColor)
    surface.DrawRect(x + 1, y + 1, 4, TOASTS.Height - 2)

    draw.SimpleText(utf8.char(0x2709), "HALOARMORY.Computer.EmailToast.Icon", x + 28, y + (TOASTS.Height * 0.5), iconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(toast.header, "HALOARMORY.Computer.EmailToast.Header", x + 52, y + 24, primaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(toast.subtext, "HALOARMORY.Computer.EmailToast.Subtext", x + 52, y + 49, secondaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

hook.Add("PostDrawHUD", "HALOARMORY.Computer.EmailToasts", function()
    if (#TOASTS.Active <= 0 and #TOASTS.Queue <= 0) then
        return
    end

    PromoteQueuedToasts()

    for _, toast in ipairs(TOASTS.Active) do
        UpdateToastLifecycle(toast)
    end

    CleanupFinishedToasts()

    if #TOASTS.Active <= 0 then
        return
    end

    cam.Start2D()
        for index, toast in ipairs(TOASTS.Active) do
            DrawToast(toast, index)
        end
    cam.End2D()
end)

concommand.Add(EMAIL.TOAST_COMMAND, function(_, _, args)
    local unreadCount = tonumber(args[1] or "0") or 0
    TOASTS.Push(unreadCount)
end)
