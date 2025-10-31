AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Hackable Console"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.Editable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.DeviceType = "hack_console"

--ENT.Model = 4
ENT.SelectedModel = 4




function ENT:CustomDataTables()

end

function ENT:SetupDataTables()

    // SCREEN WINDOW
    self:NetworkVar( "String", 0, "ScreenWindow", { KeyName = "ScreenWindow",	Edit = { type = "Generic", order = 1 } } )

    if SERVER then
        self:SetScreenWindow( "Standby" )
    end

    // PASSWORD
    self:NetworkVar( "Int", 1, "PasswordLength", { KeyName = "PasswordLength",	Edit = { type = "Int", order = 2, min = 4, max = 7 } } )

    if SERVER then
        self:SetPasswordLength( 4 )
    end

    self:NetworkVar( "String", 1, "Password", { KeyName = "Password",	Edit = { type = "Generic", order = 3 } } )
    if SERVER then
        self:SetRandomPassword()
    end

    // GUESSES
    self:NetworkVar( "Int", 2, "MaxGuesses", { KeyName = "MaxGuesses",	Edit = { type = "Int", order = 4, min = 3, max = 100 } } )

    if SERVER then
        self:SetMaxGuesses( 15 )
    end

    self:NetworkVar( "Int", 3, "Guesses", { KeyName = "Guesses",	Edit = { type = "Int", order = 5, min = 0, max = 100 } } )
    if SERVER then
        self:SetGuesses( 0 )
    end

    // Current Password Guess
    self:NetworkVar( "String", 2, "CurrentGuess", { KeyName = "CurrentGuess",	Edit = { type = "Generic", order = 6 } } )
    if SERVER then
        self:SetCurrentGuess( "" )
    end

    // Only One Attempt - Make it explode on failure
    self:NetworkVar( "Bool", 3, "OnlyOneAttempt", { KeyName = "OnlyOneAttempt",	Edit = { type = "Bool", order = 7 } } )
    if SERVER then
        self:SetOnlyOneAttempt( false )
    end

    // NOTIFY
    if SERVER then
        // Set new password if lenght changed
        self:NetworkVarNotify( "PasswordLength", function( name, old, new )
            self:SetRandomPassword()
        end )
    end

    // Custom Data Tables
    self:CustomDataTables()

end

ENT.NetworkActions = {
    ["ChangeScreenWindow"] = true,
    ["UploadCode"] = true,
    ["PerformLoggedInAction"] = true,
}

if SERVER then

    function ENT:SetRandomPassword()
        local len = self:GetPasswordLength() or 4
        len = math.Clamp(len, 4, 7)
        local str = ""
        for i = 1, len do
            str = str .. string.char(math.random(65, 90)) -- ASCII A-Z
        end
        self:SetPassword(str)
    end

    util.AddNetworkString("halo_hack_console")

    ENT.NetworkActions["ChangeScreenWindow"] = function( self, net )
        local window = net.ReadString()
        if not window then return end
        self:SetScreenWindow( window )

        if window == "Hack" then
            self:SetCurrentGuess( "" )
            self:SetGuesses( 0 )
            self:SetRandomPassword()
        end
    end

    ENT.NetworkActions["UploadCode"] = function( self, net )
        local code = net.ReadString()
        if not code then return end
        code = string.upper(code)
        code = string.sub(code, 1, self:GetPasswordLength())

        self:SetCurrentGuess( code )

        if code == self:GetPassword() then
            timer.Simple(3, function()
                self:SetScreenWindow( "LoggedIn" )
            end)
        else
            self:SetGuesses( self:GetGuesses() + 1 )

            if self:GetGuesses() >= self:GetMaxGuesses() then
                self:SetScreenWindow( "LockedOut" )
                
                // Make it explode. Optional feature to be implemented.
                if self:GetOnlyOneAttempt() then
                    local explosion = ents.Create( "env_explosion" ) -- The explosion entity
                    explosion:SetPos( self:GetPos() ) -- Put the position of the explosion at the position of the entity
                    explosion:Spawn() -- Spawn the explosion
                    explosion:SetKeyValue( "iMagnitude", "100" ) -- the magnitude of the explosion
                    explosion:Fire( "Explode", 200, 0 ) -- explode

                    timer.Simple(0.1, function()
                        self:Remove()
                    end)

                else
                    timer.Simple(6, function()
                        self:SetScreenWindow( "Standby" )
                    end)

                end
            end
        end
    end

    ENT.NetworkActions["PerformLoggedInAction"] = function( self, net, ply )
        
        if not ply and not IsValid(ply) then return end
        
        // Send a message to the whole server that the user has accessed the console.
        for i, plya in ipairs( player.GetAll() ) do
            plya:ChatPrint( "[HALOARMORY] " .. ply:Nick() .. " has successfully hacked and accessed the console." )
        end
    end

    net.Receive("halo_hack_console", function( len, ply )
        local ent = net.ReadEntity()
        local action = net.ReadString()
        
        if not IsValid( ent ) then return end

        if not ent.NetworkActions[action] then return end

        ent.NetworkActions[action]( ent, net, ply )
    end)


    function ENT:Think()
        if self:GetScreenWindow() == "Hack" then
            // If there are no users in range, change the screen window to Standby
            if not self:GetUsersInRange() then
                self:SetScreenWindow( "Standby" )
            else
                self:NextThink( CurTime() + 10 )
                return true
            end
        end
    end

    function ENT:GetUsersInRange()
        local users = ents.FindInSphere( self:GetPos(), 100 )
        for k, v in pairs( users ) do
            if IsValid( v ) and v:IsPlayer() then
                return true
            end
        end
        return false
    end

end


if not CLIENT then return end

--[[

How the console works:

    1. Start by default on the standby screen. If the user presses the button, it will change to the hack screen.
    2. This is the main hacking screen minigame interface.
    2a. The user clicks on a button to open a GUI that gives hacking controls.
    2b. The user completes the hacking minigame, and the console will change to the logged in screen.
    3. The login screen should have a Unlock button and a Logout button.
    3a. The unlock button will trigger whatever settings the GM as set up.
    3b. The logout button will change the screen window to the standby screen.

The minigame: 

    No idea????
    Maybe something Wordle inspired? The user has to guess a randomly generated string of letters.
    Correct letters in the correct position are green.
    Correct letters in the wrong position are yellow.
    Incorrect letters are gray.

    Customizeable lenght of guesses by the GM. Fewer guesses, more difficult.
    [ Default: 5, Min Guesses: 3, Max Guesses: 10 ]

    Customizeable length of the string to guess by the GM. Longer string, more difficult.
    [ Default: 4, Min String Length: 3, Max String Length: 7 ]

Special SWEP tool called; Hacking Tool.
    The Hacking Tool gives more gusses? Used to reveal a list of possible strings to guess.
    Or maybe it can be activated the reset the number of guesses without restarting the minigame.

]]

ENT.NetworkActions["ChangeScreenWindow"] = function( self, window )
    net.Start("halo_hack_console")
        net.WriteEntity( self )
        net.WriteString( "ChangeScreenWindow" )
        net.WriteString( window )
    net.SendToServer()
end

ENT.NetworkActions["PerformLoggedInAction"] = function( self, action )
    net.Start("halo_hack_console")
        net.WriteEntity( self )
        net.WriteString( "PerformLoggedInAction" )
        net.WriteString( action )
    net.SendToServer()
end

local function DrawButton( self, x, y, w, h, outline, outline_color, background_color, text, txt_color, font, callback )
    -- Universal button drawing and interaction function for 3D2D UI
    -- x, y: top-left position
    -- w, h: width and height
    -- outline: outline thickness (pixels)
    -- outline_color: Color for the outline
    -- background_color: Color for the button background
    -- text: button label
    -- txt_color: color for the label
    -- font: font for the label
    -- callback: function to call if button is pressed (optional)

    -- Draw outline (4 rectangles)
    if outline and outline > 0 then
        surface.SetDrawColor(outline_color or Color(255,255,255))
        -- Top
        surface.DrawRect(x, y, w, outline)
        -- Bottom
        surface.DrawRect(x, y + h - outline, w, outline)
        -- Left
        surface.DrawRect(x, y, outline, h)
        -- Right
        surface.DrawRect(x + w - outline, y, outline, h)
    end

    -- Draw background
    draw.RoundedBox(0, x + outline, y + outline, w - 2*outline, h - 2*outline, background_color or Color(27,27,27))

    -- Detect hover and press
    if ui3d2d and ui3d2d.isHovering then
        local hovered = ui3d2d.isHovering(x + outline, y + outline, w - 2*outline, h - 2*outline)
        if hovered then
            -- Optionally, brighten background on hover
            draw.RoundedBox(0, x + outline, y + outline, w - 2*outline, h - 2*outline, Color(151,151,151,17, background_color and background_color.a or 255))
            if ui3d2d.isPressed and ui3d2d.isPressed() then
                if callback then callback() end
            end
        end
    end

    -- Draw label centered
    if text and txt_color then
        draw.SimpleText(text, font or "HK_QuanticoSubHeader", x + w/2, y + h/2, txt_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

end

function ENT:DrawStandby()
        // Draw a red box in the inter, make it centered.
        local outline = 35
        local boxW, boxH = 1300, 650
        boxW, boxH = boxW+outline, boxH+outline
        --draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5), boxW, boxH, Color( 43, 255, 0) )
        boxW, boxH = boxW-outline, boxH-outline
        --draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5), boxW, boxH, Color( 27, 27, 27) )

        local ColorScheme = Color( 192, 190, 54)

        // Draw the label
        draw.SimpleText( "// CONSOLE //", "HK_QuanticoSubHeader", self.frameW * .5, (self.frameH * .5)-(boxH * .4), ColorScheme, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
        // Draw the header
        --draw.SimpleText( "Please Log in", "HK_QuanticoHeader", self.frameW * .5, (self.frameH * .5)-(boxH * .2), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
        // Draw the button
        local btnWdt = 800
        local btnHgt = 160
        DrawButton( self, (self.frameW * .5)-(btnWdt * .5), (self.frameH * .65)-(btnHgt * .5), btnWdt, btnHgt, 3, ColorScheme, Color( 20, 20, 20), "ATTEMPT LOGIN", Color( 255, 255, 255 ), "HK_QuanticoSubHeader", function()
            self.NetworkActions["ChangeScreenWindow"]( self, "Hack" )
        end)
end

local CORRECT_COLOR = Color(35, 104, 35)
local WRONG_COLOR = Color(60, 60, 60)
local WRONG_POSITION_COLOR = Color(104, 99, 35)

-- Function to analyze password guess and return color for each position
function ENT:AnalyzePasswordGuess(guess, correctPassword)
    local guessLen = #guess
    local correctLen = #correctPassword
    local colors = {}
    
    -- Initialize all positions as gray (wrong)
    for i = 1, guessLen do
        colors[i] = WRONG_COLOR -- Gray for wrong letters
    end
    
    -- Track which letters in the correct password have been matched
    local correctMatched = {}
    for i = 1, correctLen do
        correctMatched[i] = false
    end
    
    -- First pass: Check for exact matches (green)
    for i = 1, math.min(guessLen, correctLen) do
        local guessChar = string.upper(string.sub(guess, i, i))
        local correctChar = string.upper(string.sub(correctPassword, i, i))
        
        if guessChar == correctChar then
            colors[i] = CORRECT_COLOR -- Green for correct position
            correctMatched[i] = true
        end
    end
    
    -- Second pass: Check for letters that exist but are in wrong position (yellow)
    for i = 1, guessLen do
        if colors[i] ~= CORRECT_COLOR then -- Skip already green letters
            local guessChar = string.upper(string.sub(guess, i, i))
            
            -- Look for this letter in the correct password (not already matched)
            for j = 1, correctLen do
                if not correctMatched[j] then
                    local correctChar = string.upper(string.sub(correctPassword, j, j))
                    if guessChar == correctChar then
                        colors[i] = WRONG_POSITION_COLOR -- Yellow for wrong position
                        correctMatched[j] = true
                        break
                    end
                end
            end
        end
    end
    
    return colors
end

function ENT:DrawHack()

    // Draw a red box in the inter, make it centered.
    local outline = 35
    local boxW, boxH = 800, 600
    boxW, boxH = boxW+outline, boxH+outline
    draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5) - 35, boxW, boxH, Color( 255, 0, 0 ) )
    boxW, boxH = boxW-outline, boxH-outline
    draw.RoundedBox( 0, (self.frameW * .5)-(boxW * .5), (self.frameH * .5)-(boxH * .5) - 35, boxW, boxH, Color( 27, 27, 27) )

    // Draw the label
    draw.SimpleText( "// SYSTEM LOCKDOWN //", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(boxH * .4) - 35, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    // Draw the attempts label
    local maxAttempts = self:GetMaxGuesses() or 0
    local attemptsLeft = math.max(0, maxAttempts - self:GetGuesses())
    draw.SimpleText( "// ATTEMPTS: "..attemptsLeft.." //", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(boxH * .3), Color(161, 161, 161), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    -- Draw the password input boxes as a single line, one for each letter in the password (between 4 and 7)
    local password = self:GetCurrentGuess()
    local correctPassword = self:GetPassword()
    local pwLen = self:GetPasswordLength()
    pwLen = math.Clamp(pwLen, 4, 7)
    local boxSize = 100
    local boxSpacing = 10
    local totalWidth = pwLen * boxSize + (pwLen - 1) * boxSpacing
    local startX = (self.frameW * 0.5) - (totalWidth * 0.5)
    local y = (self.frameH * 0.5) - (boxH * 0.1) - 75

    -- Analyze the password guess to get colors for each position
    local boxColors = self:AnalyzePasswordGuess(password, correctPassword)

    for i = 1, pwLen do
        local x = startX + (i - 1) * (boxSize + boxSpacing)
        local boxColor = boxColors[i] or Color(60, 60, 60) -- Default to gray if no color assigned
        draw.RoundedBox(8, x, y, boxSize, boxSize, boxColor)
        draw.SimpleText(string.upper(string.sub(password, i, i)), "HK_QuanticoHeader", x + boxSize * 0.5, y + boxSize * 0.5, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    // Draw the button
    if self:GetPassword() ~= self:GetCurrentGuess() then
        local btnWdt = 500
        local btnHgt = 125
        DrawButton( self, (self.frameW * .5)-(btnWdt * .5), (self.frameH * .65)-(btnHgt * .5), btnWdt, btnHgt, 3, Color( 255, 0, 0 ), Color( 20, 20, 20), "HACK", Color( 255, 255, 255 ), "HK_QuanticoSubHeader", function()
            self:OpenPasswordInputGUI()
        end)
    end

end

function ENT:DrawLoggedIn()

    // Draw the Notice button
    DrawButton( self, (self.frameW * .5)-(500 * .5), self.frameH * .3, 500, 150, 3, Color( 145, 255, 0), Color( 20, 20, 20), "NOTICE", Color( 255, 255, 255 ), "HK_QuanticoSubHeader", function()
        self.NetworkActions["PerformLoggedInAction"]( self, "Notice" )
    end)

    // Draw the logout button
    DrawButton( self, (self.frameW * .5)-(500 * .5), self.frameH * .7, 500, 100, 3, Color( 255, 0, 0 ), Color( 20, 20, 20), "LOGOUT", Color( 255, 255, 255 ), "HK_QuanticoSubHeader", function()
        self.NetworkActions["ChangeScreenWindow"]( self, "Standby" )
    end)

end

function ENT:DrawLockedOut()

    local btnOutline = 30
    local btnW, btnH = 500, 160
    btnW, btnH = btnW+btnOutline, btnH+btnOutline

    // Draw the label
    draw.SimpleText( "// SYSTEM LOCKOUT //", "HK_QuanticoSubHeader", self.frameW * .5, (self.frameH * .5)-(btnH * .85) - 35, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    // Add a generic locked message, and to wait a bit
    draw.SimpleText( "Please wait while the", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(btnH * -.6), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    draw.SimpleText( "system is rebooting...", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(btnH * -.85), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end


function ENT:DrawScreen()

    local model_table = self.ScreenModels[self.Model]

    self.frameW = model_table["frameW"]
    self.frameH = model_table["frameH"]

    //draw.RoundedBox( 0, 0, 0, self.frameW, self.frameH, Color( 219, 23, 23) )

    // Draw the background
    --surface.SetMaterial( self.Theme.background )
    --surface.SetDrawColor( Color( 255, 255, 255) )
    --surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )


    local DrawScreenWindow = self["Draw"..self:GetScreenWindow()]
    if isfunction(DrawScreenWindow) then
        local succ, err = pcall(DrawScreenWindow, self)
        if not succ then
            print("Error from Supply Point Base Function related to device:", self )
            print(err)
        end
    else
        print("Error from Supply Point Base Function related to device:", self )
        print("No Draw Function for Screen Window: "..self:GetScreenWindow())
    end

end


HALOARMORY.HackConsole_GUI = HALOARMORY.HackConsole_GUI or {}

function ENT:OpenPasswordInputGUI()

    // Remove the old GUI if it exists
    if IsValid(self.HackConsoleGUI) then
        self.HackConsoleGUI:Remove()
    end

    // Create a new GUI
    local gui = vgui.Create("DFrame")
    self.HackConsoleGUI = gui

    // Set the self entity as the global GUI
    timer.Simple(0.1, function()
        HALOARMORY.HackConsole_GUI = self
    end)

    // Remove the global GUI if the GUI is removed
    gui.OnRemove = function()
        HALOARMORY.HackConsole_GUI = nil
    end

    gui.Think = function()
        if not IsValid(self) then
            gui:Remove()
            return
        end

        if self:GetScreenWindow() == "LockedOut" then
            gui:Remove()
            return
        end

        if self:GetCurrentGuess() == self:GetPassword() then
            gui:Remove()
            return
        end
    end

    gui:SetSize(600, 300)
    -- Center horizontally, position at the middle of the bottom half of the screen
    local scrW, scrH = ScrW(), ScrH()
    local guiW, guiH = gui:GetWide(), gui:GetTall()
    local x = (scrW - guiW) / 2
    local y = (scrH / 2) + ((scrH / 2) - guiH) / 2
    gui:SetPos(x, y)
    gui:MakePopup()
    gui:SetTitle("")
    gui:ShowCloseButton(true)
    gui:SetDraggable(true)
    
    -- Custom Paint function with blur, custom title, and custom X button
    local blur = Material("pp/blurscreen")
    local TITLE = "// UNSC O.N.I. HACKING SOFTWARE 3.45-682 //"
    local TITLE_FONT = "HK_GUI_QuanticoHeader" -- Change as needed
    local X_SIZE = 28
    local X_MARGIN = 12

    gui.Paint = function(self, w, h)
        -- Blur background
        local x, y = self:LocalToScreen(0, 0)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(blur)
        for i = 1, 6 do
            blur:SetFloat("$blur", i * 1.5)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
        end

        -- Main background
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.9))

        -- Draw corner edges
        local edgeLen = 40
        local edgeThick = 2
        local edgeColor = Color(0, 200, 255, 255 * 0.7)

        -- Top-left
        surface.SetDrawColor(edgeColor)
        surface.DrawRect(0, 0, edgeLen, edgeThick) -- horizontal
        surface.DrawRect(0, 0, edgeThick, edgeLen) -- vertical

        -- Top-right
        surface.DrawRect(w - edgeLen, 0, edgeLen, edgeThick) -- horizontal
        surface.DrawRect(w - edgeThick, 0, edgeThick, edgeLen) -- vertical

        -- Bottom-left
        surface.DrawRect(0, h - edgeThick, edgeLen, edgeThick) -- horizontal
        surface.DrawRect(0, h - edgeLen, edgeThick, edgeLen) -- vertical

        -- Bottom-right
        surface.DrawRect(w - edgeLen, h - edgeThick, edgeLen, edgeThick) -- horizontal
        surface.DrawRect(w - edgeThick, h - edgeLen, edgeThick, edgeLen) -- vertical

        -- Draw custom title
        surface.SetFont(TITLE_FONT)
        local tw, th = surface.GetTextSize(TITLE)
        draw.SimpleText(TITLE, TITLE_FONT, w/2, 5, Color(0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)   
    end

    -- Password input field in its own container docked to the top
    local PASSWORD_LENGTH = self:GetPasswordLength() or 4 -- fallback if not set elsewhere

    local passwordContainer = vgui.Create("DPanel", gui)
    passwordContainer:Dock(TOP)
    passwordContainer:DockMargin(20, 30, 20, 0)
    passwordContainer:SetTall(90)
    passwordContainer:SetWide(gui:GetWide())
    passwordContainer:SetBackgroundColor(Color(0,0,0,0))
    passwordContainer:SetCursor("beam")

    passwordContainer.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.9))
        --derma.SkinHook( "Paint", "TextEntry", self, w, h )
    end


    -- The width of the password entry should match the password length (each char ~48px wide, min 120px)
    local charWidth = 40
    local minWidth = 120
    local passwordWidth = math.max(minWidth, PASSWORD_LENGTH * charWidth)

    local passwordEntry = vgui.Create("DTextEntry", passwordContainer)
    passwordEntry:SetFont("HK_QuanticoLabel")
    passwordEntry:SetUpdateOnType(true)
    passwordEntry:SetDrawLanguageID(false)
    passwordEntry:SetText( self:GetCurrentGuess() or "" )
    passwordEntry:SetAllowNonAsciiCharacters(false)
    passwordEntry:SetPaintBackground(false)
    passwordEntry:SetTextColor(Color(0, 200, 255))
    passwordEntry:SetCursorColor(Color(0, 200, 255))
    passwordEntry:SetHighlightColor(Color(0, 200, 255, 80))
    passwordEntry:SetPlaceholderText("")
    passwordEntry:SetTall(75)
    passwordEntry:SetWide(passwordWidth)
    passwordEntry:SetContentAlignment(5) -- center

    -- Center the passwordEntry horizontally in the container
    -- Use manual positioning after layout
    passwordEntry:Dock(NODOCK)
    passwordContainer.PerformLayout = function(pnl, w, h)
        local pw, ph = passwordEntry:GetWide(), passwordEntry:GetTall()
        passwordEntry:SetPos((w - pw) / 2, (h - ph) / 2)
    end

    -- Custom Paint to center the text
    passwordEntry.Paint = function(self, w, h)
        --draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.9))
        derma.SkinHook( "Paint", "TextEntry", self, w, h )
    end

    -- Only allow letters, convert to uppercase, and limit length
    passwordEntry.AllowInput = function(self, char)
        if #self:GetText() >= PASSWORD_LENGTH then return true end
        if not char:match("[A-Za-z]") then return true end
        return false
    end

    passwordEntry.OnChange = function(self)
        local txt = self:GetText()
        -- Remove non-letters and convert to uppercase
        local filtered = txt:gsub("[^A-Za-z]", ""):upper()
        if #filtered > PASSWORD_LENGTH then
            filtered = filtered:sub(1, PASSWORD_LENGTH)
        end
        if filtered ~= txt then
            self:SetText(filtered)
            self:SetCaretPos(#filtered)
        end
    end

    -- Optionally, focus the entry on open
    passwordEntry:RequestFocus()

    passwordContainer.OnMousePressed = function(self, code)
        if code == MOUSE_LEFT then
            passwordEntry:RequestFocus()
        end
    end



    local attemptsLabel = vgui.Create("DLabel", gui)
    attemptsLabel:SetFont("HK_GUI_QuanticoHeader")
    attemptsLabel:SetText("")
    attemptsLabel:SetTextColor(Color(161, 161, 161))
    attemptsLabel:SetContentAlignment(5) -- center
    attemptsLabel:Dock(FILL)
    attemptsLabel:DockMargin(20, 0, 20, 0)
    attemptsLabel:SetTall(48)

    attemptsLabel.Paint = function(self2, w, h)
        -- Show the amount of attempts done, and attempts left.
        local attemptsDone = self:GetGuesses() or 0
        local maxAttempts = self:GetMaxGuesses() or 3
        local attemptsLeft = math.max(0, maxAttempts - attemptsDone)

        --draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.5))
        draw.SimpleText(string.format("// ATTEMPTS: %d //", attemptsLeft), self2:GetFont(), 10, 10, self2:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    // Add a Button to cancel on the left, with a red outline.
    // And another button to Upload Code in a green outline on the right.
    // Make a container docked to the bottom, with the two buttons.

    local bottomPanel = vgui.Create("DPanel", gui)
    bottomPanel:Dock(BOTTOM)
    bottomPanel:DockMargin(20, 25, 20, 20)
    bottomPanel:SetTall(50)
    bottomPanel:SetWide(gui:GetWide())
    bottomPanel:SetBackgroundColor(Color(0, 0, 0, 0))
    
    local cancelButton = vgui.Create("DButton", bottomPanel)
    cancelButton:SetText("")
    cancelButton:SetTextColor(Color(255, 80, 80))
    cancelButton:SetContentAlignment(5) -- center
    cancelButton:Dock(LEFT)
    cancelButton:DockMargin(0, 0, 0, 0)
    cancelButton:SetTall(48)
    cancelButton:SetWide(gui:GetWide() / 2 - 40)

    cancelButton.Paint = function(self, w, h)
        -- Draw a red outline using 4 rectangles (top, bottom, left, right)
        local outlineColor = Color(255, 80, 80, 255)
        local outlineWidth = 2

        -- Top edge
        draw.RoundedBox(0, 0, 0, w, outlineWidth, outlineColor)
        -- Bottom edge
        draw.RoundedBox(0, 0, h - outlineWidth, w, outlineWidth, outlineColor)
        -- Left edge
        draw.RoundedBox(0, 0, 0, outlineWidth, h, outlineColor)
        -- Right edge
        draw.RoundedBox(0, w - outlineWidth, 0, outlineWidth, h, outlineColor)

        -- Draw a semi transparent black overlay
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.9))

        // On Hover, draw a semi transparent red overlay
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(255, 80, 80, 255 * 0.01))
        end

        -- Draw the text in the center of the button
        draw.SimpleText("CLOSE", "HK_GUI_QuanticoLabel", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local uploadButton = vgui.Create("DButton", bottomPanel)
    uploadButton:SetText("")
    uploadButton:SetTextColor(Color(255, 255, 255))
    uploadButton:SetContentAlignment(5) -- center
    uploadButton:Dock(RIGHT)
    uploadButton:DockMargin(0, 0, 0, 0)
    uploadButton:SetTall(48)
    uploadButton:SetWide(gui:GetWide() / 2 - 40)

    uploadButton.Paint = function(self, w, h)
        -- Draw a red outline using 4 rectangles (top, bottom, left, right)
        local outlineColor = Color(80, 255, 80, 255)
        local outlineWidth = 2

        -- Top edge
        draw.RoundedBox(0, 0, 0, w, outlineWidth, outlineColor)
        -- Bottom edge
        draw.RoundedBox(0, 0, h - outlineWidth, w, outlineWidth, outlineColor)
        -- Left edge
        draw.RoundedBox(0, 0, 0, outlineWidth, h, outlineColor)
        -- Right edge
        draw.RoundedBox(0, w - outlineWidth, 0, outlineWidth, h, outlineColor)

        -- Draw a semi transparent black overlay
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255 * 0.9))

        // On Hover, draw a semi transparent green overlay
        if not self:IsEnabled() then
            draw.RoundedBox(0, 0, 0, w, h, Color(146, 146, 146, 255 * 0.01))
        elseif self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(80, 255, 80, 255 * 0.01))
        end

        -- Draw the text in the center of the button
        draw.SimpleText("UPLOAD CODE", "HK_GUI_QuanticoLabel", w / 2, h / 2, self:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    cancelButton.DoClick = function()
        gui:Remove()
    end

    uploadButton.DoClick = function()
        
        uploadButton:SetEnabled(false)
        uploadButton:SetTextColor(Color(161, 161, 161))

        net.Start("halo_hack_console")
            net.WriteEntity( self )
            net.WriteString( "UploadCode" )
            net.WriteString( passwordEntry:GetText() )
        net.SendToServer()

        timer.Simple(0.2, function()
            if not IsValid(uploadButton) then return end
            uploadButton:SetEnabled(true)
            uploadButton:SetTextColor(Color(255, 255, 255))

            if passwordEntry:GetText() == self:GetPassword() then
                gui:Remove()
            end
        end)



    end
end

-- Check if there's a valid entity in the global table and refresh its GUI
timer.Simple(0.1, function()
    if IsValid(HALOARMORY.HackConsole_GUI) then
        HALOARMORY.HackConsole_GUI:OpenPasswordInputGUI()
    end
end)
