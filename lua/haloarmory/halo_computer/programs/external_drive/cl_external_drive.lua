local PANEL = {}

function PANEL:Init()
    self.Interface = nil
    self.ExternalNotes = {}
    
    -- Create the main layout
    self.Layout = vgui.Create("DPanel", self)
    self.Layout:Dock(FILL)
    self.Layout.Paint = function() end

    -- Create the sidebar for note list
    self.Sidebar = vgui.Create("DPanel", self.Layout)
    self.Sidebar:Dock(LEFT)
    self.Sidebar:SetWide(200)
    self.Sidebar:DockMargin(0, 0, 5, 0)
    self.Sidebar.Paint = function(s, w, h)
        surface.SetDrawColor(45, 45, 50)
        surface.DrawRect(0, 0, w, h)
    end

    -- Create note list
    self.NoteList = vgui.Create("DListView", self.Sidebar)
    self.NoteList:Dock(FILL)
    self.NoteList:AddColumn("Notes")

    -- Create the content area
    self.Content = vgui.Create("DPanel", self.Layout)
    self.Content:Dock(FILL)
    self.Content.Paint = function(s, w, h)
        surface.SetDrawColor(40, 40, 45)
        surface.DrawRect(0, 0, w, h)
    end

    -- Add info text
    self.InfoLabel = vgui.Create("DLabel", self.Content)
    self.InfoLabel:Dock(FILL)
    self.InfoLabel:SetText([[
ExternalDrive:/

This is your personal external drive. 
Notes moved here are saved to your local DATA folder.

You can access these notes across different servers.
    ]])
    self.InfoLabel:SetWrap(true)
    self.InfoLabel:SetContentAlignment(5)
    self.InfoLabel:DockMargin(20, 20, 20, 20)

    -- Handle note list selection
    self.NoteList.OnRowSelected = function(_, _, row)
        local noteId = row:GetValue(1)
        self:LoadNote(noteId)
    end

    -- Handle right-click on note list
    self.NoteList.DoRightClick = function(_, _, row)
        if not row then return end
        local noteId = row:GetValue(1)
        
        local menu = DermaMenu()
        menu:AddOption("Copy to Desktop", function()
            self:CopyNoteToDesktop(noteId, false)
        end)
        menu:AddOption("Move to Desktop", function()
            self:CopyNoteToDesktop(noteId, true)
        end)
        menu:AddSpacer()
        menu:AddOption("Delete", function()
            HALOARMORY.COMPUTER.DeleteExternalNote(noteId)
            self:RefreshNotes()
        end)
        menu:AddOption("Open", function()
            self:LoadNote(noteId)
        end)
        menu:Open()
    end

    -- Load initial notes
    self:RefreshNotes()
end

function PANEL:SetInterface(interface)
    self.Interface = interface
end

function PANEL:RefreshNotes()
    -- Clear list
    self.NoteList:Clear()

    -- Load notes from ExternalDrive
    self.ExternalNotes = HALOARMORY.COMPUTER.LoadExternalDrive()
    
    if self.ExternalNotes and self.ExternalNotes.notes then
        for noteId, noteData in pairs(self.ExternalNotes.notes) do
            self.NoteList:AddLine(noteId)
        end
    end
end

function PANEL:LoadNote(noteId)
    if not self.ExternalNotes.notes or not self.ExternalNotes.notes[noteId] then return end
    
    local noteData = self.ExternalNotes.notes[noteId]
    
    -- Clear content area
    if IsValid(self.InfoLabel) then
        self.InfoLabel:Remove()
    end
    
    -- Create note viewer
    if IsValid(self.NoteViewer) then
        self.NoteViewer:Remove()
    end
    
    self.NoteTitle = vgui.Create("DLabel", self.Content)
    self.NoteTitle:Dock(TOP)
    self.NoteTitle:SetTall(30)
    self.NoteTitle:SetText(noteData.title or noteId)
    self.NoteTitle:SetFont("DermaLarge")
    self.NoteTitle:DockMargin(10, 10, 10, 5)
    
    self.NoteViewer = vgui.Create("DHTML", self.Content)
    self.NoteViewer:Dock(FILL)
    self.NoteViewer:DockMargin(10, 5, 10, 10)
    
    -- Parse markdown and display
    self.NoteViewer:SetHTML(
        HALOARMORY.Markdown.HTMLHeader ..
        HALOARMORY.Markdown.Parse(noteData.content or "") ..
        HALOARMORY.Markdown.HTMLFooter
    )
end

-- Function to move/copy note from Desktop to ExternalDrive
function PANEL:MoveNoteToExternal(noteId, noteData, shouldMove)
    shouldMove = shouldMove or false
    if not self.Interface then return end
    
    -- Check if we have content
    if noteData and noteData.content then
        -- Save to ExternalDrive
        HALOARMORY.COMPUTER.SaveExternalNote(noteId, noteData)
        
        -- Remove from server only if moving
        if shouldMove then
            self.Interface:DeleteNote(noteId)
        end
        
        -- Refresh displays
        self:RefreshNotes()
        if shouldMove then
            self.Interface:ShowDesktop()
        end
    else
        -- Request content from server if not available
        -- Store callback in interface for when content arrives
        if IsValid(self.Interface.Entity) then
            -- Create temporary callback
            self.Interface.PendingExternalMove = {
                noteId = noteId,
                title = noteData and noteData.title or noteId,
                panel = self,
                shouldMove = shouldMove
            }
            
            -- Request content
            net.Start("HALOARMORY_RequestFileContent")
            net.WriteEntity(self.Interface.Entity)
            net.WriteString(noteId)
            net.SendToServer()
        end
    end
end

-- Function to move/copy note from ExternalDrive to Desktop
function PANEL:CopyNoteToDesktop(noteId, shouldMove)
    shouldMove = shouldMove or false
    if not self.Interface then return end
    
    -- Get note from ExternalDrive
    local externalNotes = HALOARMORY.COMPUTER.LoadExternalDrive()
    if not externalNotes.notes or not externalNotes.notes[noteId] then return end
    
    local noteData = externalNotes.notes[noteId]
    
    -- Add to desktop
    self.Interface.Notes[noteId] = {
        title = noteData.title or noteId,
        content = noteData.content or ""
    }
    
    -- Save to server
    self.Interface:SaveNote(noteId)
    
    -- Remove from ExternalDrive only if moving
    if shouldMove then
        HALOARMORY.COMPUTER.DeleteExternalNote(noteId)
    end
    
    -- Refresh displays
    self:RefreshNotes()
    self.Interface:ShowDesktop()
end

PANEL.Paint = function(s, w, h)
    surface.SetDrawColor(35, 35, 40)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("HALOARMORY.ExternalDriveProgram", PANEL, "DPanel")

