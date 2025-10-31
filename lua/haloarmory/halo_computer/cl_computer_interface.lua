HALOARMORY.MsgC("Client HALO Computer Interface Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.PROGRAMS = HALOARMORY.COMPUTER.PROGRAMS or {}
HALOARMORY.COMPUTER.FILES = HALOARMORY.COMPUTER.FILES or {}

HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}
if not IsValid(HALOARMORY.COMPUTER.INTERFACE) then
	HALOARMORY.COMPUTER.INTERFACE = {}
end
HALOARMORY.COMPUTER.INTERFACE.PANEL = HALOARMORY.COMPUTER.INTERFACE.PANEL or {}
if not IsValid(HALOARMORY.COMPUTER.INTERFACE.PANEL) then
	HALOARMORY.COMPUTER.INTERFACE.PANEL = {}
end

-- Create a custom desktop panel that supports right-click menus
local DESKTOP_PANEL = {}

function DESKTOP_PANEL:Init()
	self:SetPaintBackground(false)
end

function DESKTOP_PANEL:OnMouseReleased(mouseCode)
	if mouseCode == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu:AddOption("New Note", function()
			-- Use the global interface variable which is set up in OpenInterace
			if IsValid(HALOARMORY.COMPUTER.INTERFACE) then
				HALOARMORY.COMPUTER.INTERFACE:CreateNewNote(true)
			end
		end)
		menu:Open()
	end
end

vgui.Register("HALODesktopPanel", DESKTOP_PANEL, "DPanel")

-- Main computer interface panel
local PANEL = {}
HALOARMORY.COMPUTER.INTERFACE.PANEL = PANEL

-- Constants
local TASKBAR_HEIGHT = 40
local TITLE_BAR_HEIGHT = 24 -- Standard DFrame title bar height
local START_MENU_WIDTH = 200
local START_MENU_HEIGHT = 250
local START_MENU_MARGIN = 5

function PANEL:Init()
	-- Initialize storage
	self.ActivePrograms = {}
	self.Notes = {}
	self.Entity = nil
	self.PC_ID = nil
	self.IsPersistent = false
	
	-- Set up main window
	self:SetSize(ScrW() - 150, ScrH() - 150)
	self:Center()
	self:MakePopup()
	self:SetTitle("Personal Computer") -- Default title, will be updated in OpenInterace
	self:ShowCloseButton(true)
	self:SetDraggable(true)
	self:SetSizable(true)

	-- Create content area
	self.Content = vgui.Create("DPanel", self)
	self.Content:Dock(FILL)
	self.Content:DockMargin(0, 0, 0, 0)

	-- Create taskbar
	self:CreateTaskbar()
	
	-- Show desktop by default
	self:ShowDesktop()
end

function PANEL:CreateTaskbar()
	-- Create taskbar panel
	self.Taskbar = vgui.Create("DPanel", self)
	self.Taskbar:Dock(BOTTOM)
	self.Taskbar:SetTall(TASKBAR_HEIGHT)
	self.Taskbar.Paint = function(s, w, h)
		surface.SetDrawColor(30, 30, 35)
		surface.DrawRect(0, 0, w, h)
	end

	-- Add Windows button
	self:CreateWindowsButton()

	-- Add separator
	local separator = vgui.Create("DPanel", self.Taskbar)
	separator:Dock(LEFT)
	separator:SetWide(1)
	separator.Paint = function(s, w, h)
		surface.SetDrawColor(50, 50, 55)
		surface.DrawRect(0, 0, w, h)
	end

	-- Add clock
	self:CreateClock()
end

function PANEL:CreateWindowsButton()
	self.WindowsBtn = vgui.Create("DButton", self.Taskbar)
	self.WindowsBtn:Dock(LEFT)
	self.WindowsBtn:SetWide(40)
	self.WindowsBtn:SetText("")

	local logo = Material("gui/info")
	self.WindowsBtn.Paint = function(s, w, h)
		surface.SetDrawColor(40, 40, 45)
		if s:IsHovered() then
			surface.SetDrawColor(50, 50, 55)
		end
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(200, 200, 200)
		local margin = 8
		local size = h - (margin * 2)
		surface.SetMaterial(logo)
		surface.DrawTexturedRect(margin, margin, size, size)
	end

	-- Handle clicks
	local function ToggleStartMenu()
		if IsValid(self.StartMenu) and self.StartMenu:IsVisible() then
			self.StartMenu:SetVisible(false)
		else
			self:ShowStartMenu()
		end
	end

	self.WindowsBtn.DoClick = ToggleStartMenu
	self.WindowsBtn.DoRightClick = ToggleStartMenu
end

function PANEL:ShowStartMenu()
	-- Remove existing start menu if present
	if IsValid(self.StartMenu) then
		self.StartMenu:Remove()
	end

	-- Create start menu panel
	self.StartMenu = vgui.Create("DPanel", self)
	self.StartMenu:SetSize(START_MENU_WIDTH, START_MENU_HEIGHT)
	self.StartMenu:SetMouseInputEnabled(true)
	self.StartMenu:SetKeyboardInputEnabled(false)
	
	-- Track last frame size for repositioning optimization
	self.StartMenu.LastFrameSize = nil
	self.StartMenu.WasMouseDown = false
	
	-- Position the menu relative to frame dimensions
	local function PositionMenu()
		if not IsValid(self.StartMenu) or not IsValid(self.Taskbar) then 
			return 
		end
		
		local frameW, frameH = self:GetSize()
		
		-- Calculate position: bottom-left, just above the taskbar
		local menuX = START_MENU_MARGIN
		local menuY = frameH - TASKBAR_HEIGHT - START_MENU_HEIGHT - START_MENU_MARGIN
		
		-- Ensure menu doesn't go above the content area (below title bar)
		menuY = math.max(menuY, TITLE_BAR_HEIGHT)
		
		self.StartMenu:SetPos(menuX, menuY)
	end
	
	-- Handle window resizing and click-outside detection
	self.StartMenu.Think = function(s)
		if not IsValid(s) then return end
		
		-- Reposition only if frame size changed
		local frameW, frameH = self:GetSize()
		local lastSize = s.LastFrameSize
		if not lastSize or lastSize.w ~= frameW or lastSize.h ~= frameH then
			PositionMenu()
			s.LastFrameSize = { w = frameW, h = frameH }
		end
		
		-- Handle click-outside detection
		local isMouseDown = input.IsMouseDown(MOUSE_LEFT)
		
		if isMouseDown and not s.WasMouseDown then
			local mx, my = input.GetCursorPos()
			local sX, sY = s:LocalToScreen(0, 0)
			local w, h = s:GetSize()
			
			-- Check if click is outside the menu bounds
			if mx < sX or mx > sX + w or my < sY or my > sY + h then
				s:SetVisible(false)
			end
		end
		
		s.WasMouseDown = isMouseDown
	end
	
	-- Position initially
	PositionMenu()
	
	-- Style the panel
	self.StartMenu.Paint = function(s, w, h)
		-- Draw background
		surface.SetDrawColor(35, 35, 40)
		surface.DrawRect(0, 0, w, h)
		
		-- Draw border
		surface.SetDrawColor(60, 60, 65)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	-- Create scrollable content
	local scrollPanel = vgui.Create("DScrollPanel", self.StartMenu)
	scrollPanel:Dock(FILL)
	scrollPanel:DockMargin(5, 5, 5, 5)

	-- Helper function to add menu items
	local function AddMenuItem(text, callback)
		local btn = vgui.Create("DButton", scrollPanel)
		btn:SetTall(35)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, 2)
		btn:SetText("  " .. text)
		btn:SetTextColor(Color(255, 255, 255))
		btn:SetContentAlignment(4) -- Left aligned
		btn:SetFont("DermaDefault")
		
		btn.Paint = function(s, w, h)
			local color = s:IsHovered() and Color(50, 50, 55) or Color(45, 45, 50)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
		end
		
		btn.DoClick = function()
			if callback then callback() end
			if IsValid(self.StartMenu) then
				self.StartMenu:SetVisible(false)
			end
		end
		
		return btn
	end
	
	-- Helper function to add separator
	local function AddSeparator()
		local sep = vgui.Create("DPanel", scrollPanel)
		sep:SetTall(5)
		sep:Dock(TOP)
		sep:DockMargin(0, 5, 0, 5)
		sep.Paint = function() end
		return sep
	end

	-- Add program shortcuts
	AddMenuItem("New Note", function()
			self:CreateNewNote(true)
		end)
	
	AddSeparator()

	-- Add programs
	for programId, programInfo in pairs(HALOARMORY.COMPUTER.Programs or {}) do
		if programId == "email" or programId == "external_drive" then
			AddMenuItem(programInfo.name, function()
				self:OpenProgram(programId)
			end)
		end
	end

	AddSeparator()

	-- Add system actions
	AddMenuItem("Log Out", function()
			if IsValid(self) then
				self:Remove()
			end
		end)

end

function PANEL:CreateClock()
	self.Clock = vgui.Create("DPanel", self.Taskbar)
	self.Clock:Dock(RIGHT)
	self.Clock:DockMargin(10, 0, 10, 0)
	self.Clock:SetWide(70)
	self.Clock.Paint = function(s, w, h)
		surface.SetFont("ChatFont")
		surface.SetTextColor(200, 200, 200)
		local time = os.date("%H:%M:%S")
		local tw, th = surface.GetTextSize(time)
		surface.SetTextPos(w/2 - tw/2, h/2 - th/2)
		surface.DrawText(time)
	end

	self.Clock.Think = function(s)
		if (s.NextUpdate or 0) <= CurTime() then
			s.NextUpdate = CurTime() + 1
			s:InvalidateLayout()
		end
	end
end

function PANEL:RefreshDesktopIcons()
	-- Refresh desktop icons without recreating the whole desktop
	-- This is safe to call when windows are open
	if IsValid(self.DesktopView) and IsValid(self.IconLayout) then
		self.IconLayout:Clear()
		
		-- Add programs from shared config
		for programId, programInfo in pairs(HALOARMORY.COMPUTER.Programs or {}) do
			if programId == "email" or programId == "external_drive" then
				self:AddDesktopIcon(programInfo.name, programInfo.icon, function()
					self:OpenProgram(programId)
				end, true, nil, programId)
			end
		end
		
		-- Add notes to desktop
		local noteIcon = HALOARMORY.COMPUTER.Programs["note"].icon
		for noteId, noteData in pairs(self.Notes) do
			self:AddDesktopIcon(noteData.title, noteIcon, function()
				self:OpenFile(noteId)
			end, false, noteId, nil)
		end
	end
end

function PANEL:ShowDesktop()
	-- Don't show desktop if there are open windows - hide it behind them instead
	local hasVisibleWindows = false
	for _, prog in pairs(self.ActivePrograms) do
		if IsValid(prog.window) and prog.window:IsVisible() then
			hasVisibleWindows = true
			break
		end
	end
	
	-- If windows are open, remove desktop view but don't recreate it
	-- It will be recreated when all windows are closed
	if hasVisibleWindows then
		if IsValid(self.DesktopView) then
			self.DesktopView:Remove()
		end
		return
	end
	
	-- No windows open - create/recreate desktop view
	if IsValid(self.DesktopView) then
		self.DesktopView:Remove()
	end

	-- Create desktop
	self.DesktopView = vgui.Create("HALODesktopPanel", self.Content)
	self.DesktopView:Dock(FILL)
	self.DesktopView.Paint = function(s, w, h)
		surface.SetDrawColor(40, 40, 45)
		surface.DrawRect(0, 0, w, h)
	end
	
	-- Right-click menu on desktop background (empty space)
	self.DesktopView.DoRightClick = function()
		local menu = DermaMenu()
		menu:AddOption("Add New Note", function()
			if IsValid(self) then
				self:CreateNewNote(true)
			end
		end)
		menu:AddOption("Personalize", function()
			-- TODO: Open personalize menu/settings
			LocalPlayer():ChatPrint("Personalize feature coming soon!")
		end)
		menu:Open()
	end

	-- Create icon layout
	self.IconLayout = vgui.Create("DIconLayout", self.DesktopView)
	self.IconLayout:Dock(FILL)
	self.IconLayout:SetSpaceY(10)
	self.IconLayout:SetSpaceX(10)
	self.IconLayout:DockMargin(10, 10, 10, 10)

	self.IconLayout:SetLayoutDir(LEFT)

	-- Add programs and notes
	self:RefreshDesktopIcons()
end

function PANEL:AddDesktopIcon(name, icon, clickFunc, isProgram, noteId, programId)
	local iconPanel = self.IconLayout:Add("DButton")
	iconPanel:SetSize(80, 80)
	iconPanel:SetCursor("hand")
	iconPanel:SetText("")
	iconPanel.Paint = function(s, w, h)
		if s:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 10)
			surface.DrawRect(0, 0, w, h)
		end
	end

	local iconBtn = vgui.Create("DImage", iconPanel)
	iconBtn:SetSize(32, 32)
	iconBtn:SetPos(24, 10)
	iconBtn:SetImage(icon)

	local label = vgui.Create("DLabel", iconPanel)
	label:SetText(name)
	label:SetTextColor(color_white)
	label:SetContentAlignment(5)
	label:SetPos(0, 45)
	label:SetSize(80, 20)

	iconPanel.DoClick = clickFunc

	-- Store noteId or programId for right-click menu
	iconPanel.NoteId = noteId
	iconPanel.ProgramId = programId

	if not isProgram and noteId then
		-- Notes right-click menu
		iconPanel.DoRightClick = function()
			local menu = DermaMenu()
			
			-- Open option
			menu:AddOption("Open", function()
				if IsValid(self) and noteId and self.Notes[noteId] then
					self:OpenFile(noteId)
				end
			end)
			
			-- Edit option (opens in edit mode)
			menu:AddOption("Edit", function()
				if IsValid(self) and noteId and self.Notes[noteId] then
					-- Check if already open
					if self.ActivePrograms[noteId] then
						local existingWindow = self.ActivePrograms[noteId].window
						if IsValid(existingWindow) then
							existingWindow:SetVisible(true)
							existingWindow:MoveToFront()
							if IsValid(self.DesktopView) then
								self.DesktopView:Remove()
							end
							-- Switch to edit mode
							if IsValid(self.ActivePrograms[noteId].content) then
								self.ActivePrograms[noteId].content:SetNewNote(false)
								self.ActivePrograms[noteId].content.EditBtn:DoClick()
							end
							return
						end
					end
					-- Open note
					self:OpenFile(noteId)
					-- Switch to edit mode after opening
					timer.Simple(0.1, function()
						if IsValid(self) and self.ActivePrograms[noteId] and IsValid(self.ActivePrograms[noteId].content) then
							self.ActivePrograms[noteId].content.EditBtn:DoClick()
						end
					end)
				end
			end)
			
			menu:AddSpacer()
			
			menu:AddOption("Move to ExternalDrive:/", function()
				if IsValid(self) and noteId and self.Notes[noteId] then
					-- Find ExternalDrive program if open
					local externalDriveProg = self.ActivePrograms["external_drive"]
					if externalDriveProg and IsValid(externalDriveProg.content) then
						externalDriveProg.content:MoveNoteToExternal(noteId, self.Notes[noteId], true)
					else
						-- Open ExternalDrive first
						self:OpenProgram("external_drive")
						timer.Simple(0.1, function()
							local externalDriveProg2 = self.ActivePrograms["external_drive"]
							if externalDriveProg2 and IsValid(externalDriveProg2.content) then
								externalDriveProg2.content:MoveNoteToExternal(noteId, self.Notes[noteId], true)
							end
						end)
					end
				end
			end)
			menu:AddOption("Copy to ExternalDrive:/", function()
				if IsValid(self) and noteId and self.Notes[noteId] then
					-- Find ExternalDrive program if open
					local externalDriveProg = self.ActivePrograms["external_drive"]
					if externalDriveProg and IsValid(externalDriveProg.content) then
						externalDriveProg.content:MoveNoteToExternal(noteId, self.Notes[noteId], false)
					else
						-- Open ExternalDrive first
						self:OpenProgram("external_drive")
						timer.Simple(0.1, function()
							local externalDriveProg2 = self.ActivePrograms["external_drive"]
							if externalDriveProg2 and IsValid(externalDriveProg2.content) then
								externalDriveProg2.content:MoveNoteToExternal(noteId, self.Notes[noteId], false)
							end
						end)
					end
				end
			end)
			menu:AddSpacer()
			menu:AddOption("Delete", function()
				if IsValid(self) and noteId and self.Notes[noteId] then
					self:DeleteNote(noteId)
				end
			end)
			menu:Open()
		end
	elseif isProgram and programId then
		-- Programs right-click menu
		iconPanel.DoRightClick = function()
			local menu = DermaMenu()
			menu:AddOption("Open", function()
				if IsValid(self) then
					self:OpenProgram(programId)
				end
			end)
			menu:Open()
		end
	end

	return iconPanel
end

function PANEL:CreateProgramWindow(title)
	local window = vgui.Create("HALOARMORY.ProgramWindow", self.Content)
	window:Dock(FILL)
	window:SetTitle(title)
	window.Paint = function(s, w, h)
		surface.SetDrawColor(35, 35, 40)
		surface.DrawRect(0, 0, w, h)
	end
	return window
end

function PANEL:CreateTaskbarButton(window, title)
	local taskButton = vgui.Create("DButton", self.Taskbar)
	taskButton:Dock(LEFT)
	taskButton:SetWide(100)
	taskButton:SetText(title)
	taskButton:SetTextColor(Color(255, 255, 255))
	taskButton.Paint = function(s, w, h)
		surface.SetDrawColor(40, 40, 45)
		if s:IsHovered() then
			surface.SetDrawColor(50, 50, 55)
		end
		if IsValid(window) and window:IsVisible() then
			surface.SetDrawColor(60, 60, 65)
		end
		surface.DrawRect(0, 0, w, h)
	end

	taskButton.DoClick = function()
		if IsValid(window) then
			if window:IsVisible() then
				window:SetVisible(false)
				self:ShowDesktop()
			else
				window:SetVisible(true)
				if IsValid(self.DesktopView) then
					self.DesktopView:Remove()
				end
			end
		end
	end

	return taskButton
end

function PANEL:CloseProgram(programName)
	if self.ActivePrograms[programName] then
		if IsValid(self.ActivePrograms[programName].window) then
			self.ActivePrograms[programName].window:Remove()
		end
		if IsValid(self.ActivePrograms[programName].taskButton) then
			self.ActivePrograms[programName].taskButton:Remove()
		end
		self.ActivePrograms[programName] = nil
	end
	self:ShowDesktop()
end

function PANEL:OpenProgram(programName)
	if programName ~= "email" and programName ~= "external_drive" then return end

	-- Check if program is already running
	if self.ActivePrograms[programName] then
		if IsValid(self.ActivePrograms[programName].window) then
			if self.ActivePrograms[programName].window:IsVisible() then
				self.ActivePrograms[programName].window:SetVisible(false)
				self:ShowDesktop()
			else
				self.ActivePrograms[programName].window:SetVisible(true)
				if IsValid(self.DesktopView) then
					self.DesktopView:Remove()
				end
			end
		else
			self:CloseProgram(programName)
			self:OpenProgram(programName)
		end
		return
	end

	local programInfo = HALOARMORY.COMPUTER.Programs[programName]
	
	-- Create window and content
	local window = self:CreateProgramWindow(programInfo.name)
	local programContent
	
	if programName == "email" then
		programContent = vgui.Create("HALOARMORY.EmailProgram", window:GetContent())
	elseif programName == "external_drive" then
		programContent = vgui.Create("HALOARMORY.ExternalDriveProgram", window:GetContent())
		programContent:SetInterface(self)
	end
	
	if programContent then
	programContent:Dock(FILL)
	end
	
	-- Create taskbar button
	local taskButton = self:CreateTaskbarButton(window, programInfo.name)
	
	-- Store program state
	self.ActivePrograms[programName] = {
		window = window,
		taskButton = taskButton,
		content = programContent
	}
	
	-- Handle window events
	window.OnClose = function()
		self:CloseProgram(programName)
	end

	window.OnMinimize = function()
		window:SetVisible(false)
		self:ShowDesktop()
	end

	-- Remove desktop view
	if IsValid(self.DesktopView) then
		self.DesktopView:Remove()
	end
end

function PANEL:SaveNote(noteId)
	if not self.Notes[noteId] then return end

	-- Always save to server
	HALOARMORY.COMPUTER.UpdateServerNote(self.Entity, self.PC_ID, noteId, self.Notes[noteId])
end

function PANEL:DeleteNote(noteId)
	if not self.Notes[noteId] then return end

	-- Remove from memory
	self.Notes[noteId] = nil

	-- Remove from storage on server
	HALOARMORY.COMPUTER.DeleteServerNote(self.Entity, self.PC_ID, noteId)

	-- Refresh desktop
	self:ShowDesktop()
end

function PANEL:UpdateNote(noteId, noteData)
	self.Notes[noteId] = noteData
	
	-- Update window if note is open
	if self.ActivePrograms[noteId] then
		local window = self.ActivePrograms[noteId].window
		local taskButton = self.ActivePrograms[noteId].taskButton
		local programContent = self.ActivePrograms[noteId].content

		if IsValid(window) and IsValid(taskButton) and IsValid(programContent) then
			window:SetTitle(noteData.title)
			taskButton:SetText(noteData.title)
			programContent:SetContent(noteData.content)
		end
	end

	-- Refresh desktop icons to show updated notes (only if desktop is visible)
	-- Don't recreate desktop if windows are open
	self:RefreshDesktopIcons()
end

function PANEL:OpenFile(fileName)
	-- Check if this is a note (exists in our notes table)
	if self.Notes[fileName] then
		local noteId = fileName
		
		-- Check if this note is already open
		if self.ActivePrograms[noteId] then
			local existingWindow = self.ActivePrograms[noteId].window
			if IsValid(existingWindow) then
				-- Window is already open - just show it and bring to front
				existingWindow:SetVisible(true)
				existingWindow:MoveToFront()
				if IsValid(self.DesktopView) then
					self.DesktopView:Remove()
				end
				return
			else
				-- Window was removed but entry exists - clean it up
				self:CloseProgram(noteId)
			end
		end
		
		local window = self:CreateProgramWindow(self.Notes[fileName].title)
			local programContent = vgui.Create("HALOARMORY.NoteProgram", window:GetContent())
			programContent:Dock(FILL)
			
			-- Set the note ID so the program knows it's a saved note
			programContent:SetNoteId(noteId)
			programContent:SetWindow(window)
			
			-- Set up callback to get note title
			programContent.OnGetNoteTitle = function(nid)
				if self.Notes[nid] then
					return self.Notes[nid].title
				end
				return nil
			end
			
			-- Set up save callback
			programContent.OnContentChanged = function()
				-- Update note in interface
				local content = programContent:GetContent()
				if self.Notes[noteId] then
					self.Notes[noteId].content = content
					-- Save to server
					self:SaveNote(noteId)
				end
			end
			
			-- Set up Save As callback for existing notes
			programContent.OnSaveAs = function(newTitle, content)
				-- Generate a unique note ID based on the new title
				local newNoteId = self:GenerateNoteId(newTitle)
				
				-- Create the new note in memory
				self.Notes[newNoteId] = {
					title = newTitle,
					content = content
				}
				
				-- Update the current program content to track the new note ID
				programContent:SetNoteId(newNoteId)
				
				-- Update window and taskbar button
				if IsValid(window) then
					window:SetTitle(newTitle)
				end
				if self.ActivePrograms[noteId] and IsValid(self.ActivePrograms[noteId].taskButton) then
					self.ActivePrograms[noteId].taskButton:SetText(newTitle)
				end
				
				-- Move from old ID to new ID
				if self.ActivePrograms[noteId] then
					self.ActivePrograms[newNoteId] = self.ActivePrograms[noteId]
					self.ActivePrograms[noteId] = nil
				end
				
				-- Save to server (Save As creates a new note, doesn't close window)
				self:SaveNote(newNoteId)
				
				-- Refresh desktop icons to show the new note (only if desktop is visible)
				-- This won't affect open windows
				self:RefreshDesktopIcons()
			end
			
			-- Set up delete callback
			programContent.OnDelete = function()
				self:DeleteNote(noteId)
			end
			
			-- Create taskbar button
			local taskButton = self:CreateTaskbarButton(window, self.Notes[fileName].title)
			
			-- Store program state
			self.ActivePrograms[noteId] = {
				window = window,
				taskButton = taskButton,
				content = programContent
			}
			
			-- Handle window events
			window.OnClose = function()
				self:CloseProgram(noteId)
			end

			window.OnMinimize = function()
				window:SetVisible(false)
				self:ShowDesktop()
			end

			-- Remove desktop view
			if IsValid(self.DesktopView) then
				self.DesktopView:Remove()
			end

			-- Request file content if not loaded
			if not self.Notes[fileName].content then
				net.Start("HALOARMORY_RequestFileContent")
				net.WriteEntity(self.Entity)
				net.WriteString(fileName)
				net.SendToServer()
			else
				-- Set content if we have it
				programContent:SetContent(self.Notes[fileName].content)
			end

		-- Start in preview mode
		programContent:SetNewNote(false)
	else
		-- Note doesn't exist - create a new one
		self:CreateNewNote(true)
	end
end

function PANEL:GenerateNoteId(title)
	-- Convert title to lowercase and replace spaces/special chars with underscores
	local baseId = string.lower(title or "new_note")
	baseId = string.gsub(baseId, "[^%w]", "_")
	baseId = string.gsub(baseId, "^_+", "") -- Remove leading underscores
	baseId = string.gsub(baseId, "_+$", "") -- Remove trailing underscores
	baseId = string.gsub(baseId, "_+", "_") -- Replace multiple underscores with single

	-- If base ID exists, append a number
	local noteId = baseId
	local counter = 1
	while self.Notes[noteId] do
		noteId = baseId .. "_" .. counter
		counter = counter + 1
	end

	return noteId
end

function PANEL:CreateNewNote(isNew)
	-- Don't create note ID yet - will be created when user saves

	-- Create window and content
	local window = self:CreateProgramWindow("New Note")
	local programContent = vgui.Create("HALOARMORY.NoteProgram", window:GetContent())
	programContent:Dock(FILL)
	programContent:SetNewNote(true)
	
	-- Track temporary note ID for unsaved notes
	local tempNoteId = "temp_" .. CurTime()
	
	-- Set window reference for title updates
	programContent:SetWindow(window)
	
	-- Set up callback to get note title
	programContent.OnGetNoteTitle = function(nid)
		if self.Notes[nid] then
			return self.Notes[nid].title
		end
		return nil
	end
	
	-- Set up save new note callback (when first saving an unsaved note)
	programContent.OnSaveNew = function(title, content)
		-- Generate a unique note ID based on the title
		local noteId = self:GenerateNoteId(title)
		
		-- Create the note in memory
		self.Notes[noteId] = {
			title = title,
			content = content
		}
		
		-- Update the program content to track this note ID
		programContent:SetNoteId(noteId)
		programContent:SetNewNote(false)
		
		-- Update window and taskbar button (Save doesn't close the window)
		if IsValid(window) then
			window:SetTitle(title)
		end
		if self.ActivePrograms[tempNoteId] and IsValid(self.ActivePrograms[tempNoteId].taskButton) then
			self.ActivePrograms[tempNoteId].taskButton:SetText(title)
		end
		
		-- Move from temp ID to actual ID
		if self.ActivePrograms[tempNoteId] then
			self.ActivePrograms[noteId] = self.ActivePrograms[tempNoteId]
			self.ActivePrograms[tempNoteId] = nil
		end
		
		-- Save to server (Save doesn't close the window)
		self:SaveNote(noteId)
		
		-- Refresh desktop icons to show the new note (only if desktop is visible)
		-- This won't affect open windows
		self:RefreshDesktopIcons()
	end
	
	-- Set up save callback for existing notes
	programContent.OnContentChanged = function()
		-- Update note in interface (only for saved notes)
		local noteId = programContent.NoteId
		if noteId and self.Notes[noteId] then
			local content = programContent:GetContent()
			self.Notes[noteId].content = content
			-- Save to server
			self:SaveNote(noteId)
		end
	end
	
	-- Set up Save As callback (create new note with different name)
	programContent.OnSaveAs = function(newTitle, content)
		-- Generate a unique note ID based on the new title
		local newNoteId = self:GenerateNoteId(newTitle)
		
		-- Create the new note in memory
		self.Notes[newNoteId] = {
			title = newTitle,
			content = content
		}
		
		-- Update the current program content to track the new note ID
		programContent:SetNoteId(newNoteId)
		
		-- Update window and taskbar button
		if IsValid(window) then
			window:SetTitle(newTitle)
		end
		if self.ActivePrograms[tempNoteId] and IsValid(self.ActivePrograms[tempNoteId].taskButton) then
			self.ActivePrograms[tempNoteId].taskButton:SetText(newTitle)
		end
		
		-- Move from temp ID to new ID (or keep existing ID and just update)
		if self.ActivePrograms[tempNoteId] then
			-- If we had a real note ID before, keep the window reference but update the note ID
			local oldNoteId = programContent.NoteId
			if oldNoteId and oldNoteId ~= tempNoteId then
				-- Update the reference
				if self.ActivePrograms[oldNoteId] then
					self.ActivePrograms[newNoteId] = self.ActivePrograms[oldNoteId]
					self.ActivePrograms[oldNoteId] = nil
				end
			else
				-- Was a temp note, move to new ID
				self.ActivePrograms[newNoteId] = self.ActivePrograms[tempNoteId]
				self.ActivePrograms[tempNoteId] = nil
			end
		end
		
		-- Save to server
		self:SaveNote(newNoteId)
		
		-- Refresh desktop icons to show the new note (only if desktop is visible)
		-- This won't affect open windows
		self:RefreshDesktopIcons()
	end
	
	-- Set up delete callback
	programContent.OnDelete = function()
		local noteId = programContent.NoteId or tempNoteId
		if noteId and self.Notes[noteId] then
			self:DeleteNote(noteId)
		else
			-- Unsaved note - just close the window
			self:CloseProgram(tempNoteId)
		end
	end
	
	-- Set up close callback
	programContent.OnClose = function()
		local noteId = programContent.NoteId or tempNoteId
		self:CloseProgram(noteId)
	end

	-- Create taskbar button
	local taskButton = self:CreateTaskbarButton(window, "New Note")

	-- Store program state with temp ID
	self.ActivePrograms[tempNoteId] = {
		window = window,
		taskButton = taskButton,
		content = programContent
	}

	-- Handle window events
	window.OnClose = function()
		local noteId = programContent.NoteId or tempNoteId
		self:CloseProgram(noteId)
	end

	window.OnMinimize = function()
		window:SetVisible(false)
		self:ShowDesktop()
	end

	-- Remove desktop view
	if IsValid(self.DesktopView) then
		self.DesktopView:Remove()
	end

	return tempNoteId
end

function PANEL:LoadState()
	if not IsValid(self.Entity) then return end
	
	local pc_id = self.PC_ID or ""
	if IsValid(self.Entity) and self.Entity:GetPC_ID() ~= "" then
		pc_id = self.Entity:GetPC_ID()
	end
	
	-- Always request data from server
		net.Start("HALOARMORY_RequestComputer")
	net.WriteString(pc_id)
		net.WriteEntity(self.Entity)
		net.SendToServer()
end

function PANEL:UpdateData(data)
	if data and data.notes then
		-- Merge sync data with existing notes instead of replacing
		-- This preserves all notes when server only sends updated ones
		for noteId, noteData in pairs(data.notes) do
			self.Notes[noteId] = noteData
		end
		
		-- Refresh desktop icons without recreating the desktop
		-- This preserves open windows
		self:RefreshDesktopIcons()
		
		-- Request content for any notes that don't have it
		for noteId, noteData in pairs(self.Notes) do
			if not noteData.content then
				net.Start("HALOARMORY_RequestFileContent")
				net.WriteEntity(self.Entity)
				net.WriteString(noteId)
				net.SendToServer()
			end
		end
	end
end

function PANEL:OnRemove()
	self:SaveState()
end

vgui.Register("HALOARMORY.ComputerInterface", PANEL, "DFrame")

function PANEL:UpdateTitle()
	local title = "Personal Computer - "
	if self.IsPersistent and self.PC_ID then
		title = title .. string.format("Persistent [%s]", self.PC_ID)
		else
		title = title .. "Non-Persistent"
	end
	self:SetTitle(title)
end

function HALOARMORY.COMPUTER.OpenInterace(ent, pc_id)
	if IsValid(HALOARMORY.COMPUTER.INTERFACE) then
		HALOARMORY.COMPUTER.INTERFACE:Remove()
	end

	local computerInterface = vgui.Create("HALOARMORY.ComputerInterface")
	HALOARMORY.COMPUTER.INTERFACE = computerInterface

	-- Set up computer type and load data
	computerInterface.Entity = ent
	if IsValid(ent) then
		local ent_pc_id = ent:GetPC_ID()
		computerInterface.PC_ID = ent_pc_id ~= "" and ent_pc_id or nil
		computerInterface.IsPersistent = ent_pc_id ~= ""
	else
		computerInterface.PC_ID = nil
		computerInterface.IsPersistent = false
	end

	-- Update window title
	computerInterface:UpdateTitle()

	-- Load initial state
	computerInterface:LoadState()

	if IsValid(ent) then
		RunConsoleCommand("halo_computer_login", ent:EntIndex())
		computerInterface.OnRemove = function()
			RunConsoleCommand("halo_computer_logout", ent:EntIndex())
		end
	end
end

concommand.Add("halo_computer_open", HALOARMORY.COMPUTER.OpenInterace)

-- Refresh existing interface if it exists
if IsValid(HALOARMORY.COMPUTER.INTERFACE) then
	local ent = HALOARMORY.COMPUTER.INTERFACE.Entity
	local pc_id = HALOARMORY.COMPUTER.INTERFACE.PC_ID
	HALOARMORY.COMPUTER.OpenInterace(ent, pc_id)
end

-- Handle default notes from server
net.Receive("HALOARMORY_ReceiveDefaultNotes", function()
	local ent = net.ReadEntity()
	local defaultFiles = net.ReadTable()

	if IsValid(HALOARMORY.COMPUTER.INTERFACE) and HALOARMORY.COMPUTER.INTERFACE.Entity == ent then
		-- Convert default files to notes
		local notes = {}
		for fileId, fileInfo in pairs(defaultFiles) do
			notes[fileId] = {
				title = fileInfo.name,
				content = fileInfo.content or "Error: Could not load file content"
			}
		end

		-- Update interface with default notes
		HALOARMORY.COMPUTER.INTERFACE.Notes = notes
		-- Refresh desktop icons (won't affect open windows)
		HALOARMORY.COMPUTER.INTERFACE:RefreshDesktopIcons()
	end
end)

function PANEL:SaveState()
	if not self.Notes then return end

	-- Always save to server
		for noteId, noteData in pairs(self.Notes) do
			self:SaveNote(noteId)
	end
end

-- Handle file content reception
net.Receive("HALOARMORY_ReceiveFileContent", function()
	local ent = net.ReadEntity()
	local fileId = net.ReadString()
	local content = net.ReadString()

	if IsValid(HALOARMORY.COMPUTER.INTERFACE) and HALOARMORY.COMPUTER.INTERFACE.Entity == ent then
		-- Check if this is a pending external drive move/copy
		if HALOARMORY.COMPUTER.INTERFACE.PendingExternalMove and HALOARMORY.COMPUTER.INTERFACE.PendingExternalMove.noteId == fileId then
			local pending = HALOARMORY.COMPUTER.INTERFACE.PendingExternalMove
			HALOARMORY.COMPUTER.INTERFACE.PendingExternalMove = nil
			
			-- Save to ExternalDrive
			if IsValid(pending.panel) then
				HALOARMORY.COMPUTER.SaveExternalNote(pending.noteId, {
					title = pending.title,
					content = content
				})
				
				-- Remove from server only if moving
				if pending.shouldMove then
					HALOARMORY.COMPUTER.INTERFACE:DeleteNote(pending.noteId)
				end
				
				-- Refresh displays
				pending.panel:RefreshNotes()
				if pending.shouldMove then
					HALOARMORY.COMPUTER.INTERFACE:ShowDesktop()
				end
			end
		else
			-- Normal content update
		HALOARMORY.COMPUTER.INTERFACE:UpdateNoteContent(fileId, content)
		end
	end
end)

function PANEL:UpdateNoteContent(fileId, content)
	if not self.Notes[fileId] then return end
	
	self.Notes[fileId].content = content
	
	-- Update window if note is open
	if self.ActivePrograms[fileId] then
		local window = self.ActivePrograms[fileId].window
		local programContent = self.ActivePrograms[fileId].content

		if IsValid(window) and IsValid(programContent) then
			programContent:SetContent(content)
		end
	end
end

-- Handle server sync
net.Receive("HALOARMORY_SyncComputer", function()
	local ent = net.ReadEntity()
	local data = net.ReadTable()

	-- Update local data if we have the computer open
	if IsValid(HALOARMORY.COMPUTER.INTERFACE) and HALOARMORY.COMPUTER.INTERFACE.Entity == ent then
		HALOARMORY.COMPUTER.INTERFACE:UpdateData(data)
	end
end)