local PANEL = {}

function PANEL:Init()
    self.IsEditing = false
    self.IsNewNote = true -- Track if this is a new note
    self.IsUnsaved = true -- Track if note hasn't been saved yet
    self.HasUnsavedChanges = false
    self.LastSavedContent = ""
    self.OriginalContentChecksum = nil -- Checksum of original content when loaded
    self.Window = nil -- Reference to parent window for title updates
    self.NoteId = nil -- Will be set when saved
    
    -- Create the toolbar
    self.Toolbar = vgui.Create("DPanel", self)
    self.Toolbar:Dock(TOP)
    self.Toolbar:SetTall(30)
    self.Toolbar:DockMargin(0, 0, 0, 5)
    self.Toolbar.Paint = function(s, w, h)
        surface.SetDrawColor(35, 35, 40)
        surface.DrawRect(0, 0, w, h)
    end

    -- Add File menu button
    self.FileBtn = vgui.Create("DButton", self.Toolbar)
    self.FileBtn:Dock(LEFT)
    self.FileBtn:SetWide(80)
    self.FileBtn:SetText("File")
    self.FileBtn:DockMargin(5, 3, 0, 3)
    self.FileBtn.DoClick = function()
        local menu = DermaMenu()
        menu:AddOption("Rename", function()
            -- TODO: Implement rename
        end)
        menu:AddOption("Save", function()
            self:PromptSave(false)
        end)
        menu:AddOption("Save As", function()
            self:PromptSave(true)
        end)
        menu:AddSpacer()
        menu:AddOption("Delete", function()
            if self.OnDelete then
                self.OnDelete()
            end
        end)
        menu:AddOption("Close", function()
            if self.OnClose then
                self.OnClose()
            end
        end)
        menu:Open()
    end

    -- Add Save button
    self.SaveBtn = vgui.Create("DButton", self.Toolbar)
    self.SaveBtn:Dock(LEFT)
    self.SaveBtn:SetWide(80)
    self.SaveBtn:SetText("Save")
    self.SaveBtn:DockMargin(5, 3, 0, 3)
    self.SaveBtn.DoClick = function(s)
        -- Prevent any event bubbling
        -- Just save, don't close the window
        self:PromptSave(false)
        return true -- Return true to indicate we handled the click
    end

    -- Add Edit/Preview button
    self.EditBtn = vgui.Create("DButton", self.Toolbar)
    self.EditBtn:Dock(LEFT)
    self.EditBtn:SetWide(80)
    self.EditBtn:SetText("Edit")
    self.EditBtn:DockMargin(5, 3, 0, 3)
    self.EditBtn.DoClick = function()
        self:ToggleEditMode()
    end

    -- Create the content area
    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content.Paint = function(s, w, h)
        surface.SetDrawColor(35, 35, 40)
        surface.DrawRect(0, 0, w, h)
    end

    -- Create the HTML viewer
    self.Viewer = vgui.Create("DHTML", self.Content)
    self.Viewer:Dock(FILL)
    self.Viewer:SetVisible(true)

    -- Create the editor
    self.Editor = vgui.Create("DTextEntry", self.Content)
    self.Editor:Dock(FILL)
    self.Editor:SetMultiline(true)
    self.Editor:SetVisible(false)
    self.Editor:SetFont("DermaDefault")
    self.Editor.Paint = function(s, w, h)
        surface.SetDrawColor(45, 45, 50)
        surface.DrawRect(0, 0, w, h)
        s:DrawTextEntryText(
            Color(200, 200, 200),
            Color(30, 130, 255),
            Color(200, 200, 200)
        )
    end

    -- Track changes in the editor using checksums
    self.Editor.OnChange = function()
        self:CheckForChanges()
    end

    -- Set default content
    self:SetContent([[
# New Note
Start writing your note here...

## Markdown Support
- **Bold text**
- *Italic text*
- Lists
- And more!
    ]])

    -- If it's a new note, start in edit mode
    if self.IsNewNote then
        self:ToggleEditMode()
    end
end

function PANEL:ToggleEditMode()
    self.IsEditing = not self.IsEditing
    
    if self.IsEditing then
        self.EditBtn:SetText("Preview")
        self.Editor:SetVisible(true)
        self.Viewer:SetVisible(false)
    else
        self.EditBtn:SetText("Edit")
        self.Editor:SetVisible(false)
        self.Viewer:SetVisible(true)
        self:UpdateViewer()
    end
end

function PANEL:UpdateViewer()
    local content = self.Editor:GetValue()
    self.Viewer:SetHTML(
        HALOARMORY.Markdown.HTMLHeader ..
        HALOARMORY.Markdown.Parse(content) ..
        HALOARMORY.Markdown.HTMLFooter
    )
end

function PANEL:PromptSave(isSaveAs)
    -- If note is unsaved or Save As, prompt for file name
    if self.IsUnsaved or isSaveAs then
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 150)
        frame:Center()
        frame:SetTitle("Save Note")
        frame:MakePopup()
        frame:SetDeleteOnClose(true)
        
        local label = vgui.Create("DLabel", frame)
        label:SetText("Enter note name:")
        label:SetPos(20, 35)
        label:SizeToContents()
        
        local entry = vgui.Create("DTextEntry", frame)
        entry:SetPos(20, 55)
        entry:SetSize(360, 25)
        entry:SetValue(self:GetTitle() or "New Note")
        entry:RequestFocus()
        entry:SelectAllOnFocus(true)
        
        local saveBtn = vgui.Create("DButton", frame)
        saveBtn:SetText("Save")
        saveBtn:SetSize(100, 30)
        saveBtn:SetPos(280, 90)
        saveBtn.DoClick = function(s)
            -- Isolate the click - only close the dialog, not the main window
            local noteName = entry:GetValue()
            if noteName and noteName ~= "" then
                noteName = string.Trim(noteName)
                if noteName ~= "" then
                    -- Save the note (this should NOT close the main window)
                    self:SaveContent(noteName)
                    -- Only close the save dialog
                    frame:Close()
                    return true
                end
            end
            return false
        end
        
        local cancelBtn = vgui.Create("DButton", frame)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetSize(100, 30)
        cancelBtn:SetPos(170, 90)
        cancelBtn.DoClick = function()
            frame:Close()
        end
        
        -- Allow Enter key to save
        entry.OnEnter = function()
            saveBtn:DoClick()
        end
    else
        -- Note is already saved - just save content (no dialog needed)
        -- This should NOT close the window, just save
        self:SaveContent(nil)
    end
end

function PANEL:GetTitle()
    -- Try to get title from content (first line, remove markdown)
    local content = self.Editor:GetValue()
    if content and content ~= "" then
        local firstLine = string.match(content, "^([^\n]+)")
        if firstLine then
            firstLine = string.gsub(firstLine, "^#+%s*", "") -- Remove markdown headers
            firstLine = string.Trim(firstLine)
            if firstLine ~= "" then
                return firstLine
            end
        end
    end
    return "New Note"
end

function PANEL:CheckForChanges()
    local currentContent = self.Editor:GetValue()
    local currentChecksum = util.CRC(currentContent)
    
    -- Compare with original checksum (if saved) or last saved content
    local hasChanges = false
    if self.OriginalContentChecksum then
        hasChanges = currentChecksum ~= self.OriginalContentChecksum
    else
        hasChanges = currentContent ~= self.LastSavedContent
    end
    
    if self.HasUnsavedChanges ~= hasChanges then
        self.HasUnsavedChanges = hasChanges
        self:UpdateWindowTitle()
    end
end

function PANEL:UpdateWindowTitle()
    if not IsValid(self.Window) then return end
    
    local baseTitle = self:GetDisplayTitle() or "New Note"
    if self.HasUnsavedChanges then
        self.Window:SetTitle(baseTitle .. "*")
    else
        self.Window:SetTitle(baseTitle)
    end
end

function PANEL:GetDisplayTitle()
    -- Try to get title from interface if note is saved
    if self.NoteId and self.OnGetNoteTitle then
        local title = self.OnGetNoteTitle(self.NoteId)
        if title then return title end
    end
    -- Otherwise get from content
    return self:GetTitle()
end

function PANEL:SaveContent(noteName)
    local currentContent = self.Editor:GetValue()
    
    -- If this is Save As (noteName provided and note is already saved)
    if noteName and not self.IsUnsaved then
        local title = noteName or self:GetTitle()
        if self.OnSaveAs then
            self.OnSaveAs(title, currentContent)
        end
    -- If this is a new note (first save)
    elseif self.IsUnsaved then
        local title = noteName or self:GetTitle()
        if self.OnSaveNew then
            self.OnSaveNew(title, currentContent)
        end
    else
        -- Update existing note
        self.LastSavedContent = currentContent
        self.OriginalContentChecksum = util.CRC(currentContent)
        self.HasUnsavedChanges = false
        self:UpdateWindowTitle()
        if self.OnContentChanged then
            self.OnContentChanged()
        end
    end
end

function PANEL:SetContent(content)
    self.Editor:SetValue(content)
    self.LastSavedContent = content
    self.OriginalContentChecksum = util.CRC(content)
    self.HasUnsavedChanges = false
    self:UpdateWindowTitle()
    self:UpdateViewer()
end

function PANEL:GetContent()
    return self.Editor:GetValue()
end

function PANEL:SetNewNote(isNew)
    self.IsNewNote = isNew
    self.IsUnsaved = isNew
    if isNew then
        self.IsEditing = true
        self.EditBtn:SetText("Preview")
        self.Editor:SetVisible(true)
        self.Viewer:SetVisible(false)
        self.OriginalContentChecksum = nil
    else
        self.IsEditing = false
        self.EditBtn:SetText("Edit")
        self.Editor:SetVisible(false)
        self.Viewer:SetVisible(true)
        self.IsUnsaved = false
    end
    self:UpdateWindowTitle()
end

function PANEL:SetNoteId(noteId)
    self.NoteId = noteId
    self.IsUnsaved = false
    self:UpdateWindowTitle()
end

function PANEL:SetWindow(window)
    self.Window = window
    self:UpdateWindowTitle()
end

PANEL.Paint = function(s, w, h)
	surface.SetDrawColor(35, 35, 40)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("HALOARMORY.NoteProgram", PANEL, "DPanel") 