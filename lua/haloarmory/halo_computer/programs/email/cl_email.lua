local PANEL = {}

function PANEL:Init()
    -- Create the main layout
    self.Layout = vgui.Create("DPanel", self)
    self.Layout:Dock(FILL)
    self.Layout.Paint = function() end

    -- Create the sidebar for email list
    self.Sidebar = vgui.Create("DPanel", self.Layout)
    self.Sidebar:Dock(LEFT)
    self.Sidebar:SetWide(200)
    self.Sidebar:DockMargin(0, 0, 5, 0)
    self.Sidebar.Paint = function(s, w, h)
        surface.SetDrawColor(45, 45, 50)
        surface.DrawRect(0, 0, w, h)
    end

    -- Create new email button
    self.NewEmail = vgui.Create("DButton", self.Sidebar)
    self.NewEmail:Dock(TOP)
    self.NewEmail:SetTall(30)
    self.NewEmail:SetText("New Email")
    self.NewEmail.DoClick = function()
        self:CreateNewEmail()
    end

    -- Create email list
    self.EmailList = vgui.Create("DListView", self.Sidebar)
    self.EmailList:Dock(FILL)
    self.EmailList:AddColumn("From")
    self.EmailList:AddColumn("Subject")

    -- Add some placeholder emails
    self.EmailList:AddLine("System", "Welcome to HALO Email")
    self.EmailList:AddLine("Admin", "Important Notice")
    self.EmailList:AddLine("User123", "Hello World")

    -- Create the email content area
    self.Content = vgui.Create("DPanel", self.Layout)
    self.Content:Dock(FILL)

    -- Add placeholder content
    self.EmailTitle = vgui.Create("DLabel", self.Content)
    self.EmailTitle:Dock(TOP)
    self.EmailTitle:SetTall(30)
    self.EmailTitle:SetText("Welcome to HALO Email")
    self.EmailTitle:SetFont("DermaLarge")
    self.EmailTitle:DockMargin(5, 5, 5, 5)

    self.EmailBody = vgui.Create("DLabel", self.Content)
    self.EmailBody:Dock(FILL)
    self.EmailBody:SetText([[
Welcome to the HALO Email System!

This is a secure communication system for all HALO personnel. 
You can use this system to:
- Send messages to other users
- Receive important notifications
- Share files and documents

For assistance, contact your system administrator.
    ]])
    self.EmailBody:SetWrap(true)
    self.EmailBody:DockMargin(5, 5, 5, 5)

    -- Handle email list selection
    self.EmailList.OnRowSelected = function(_, _, row)
        self:LoadEmail(row:GetValue(1), row:GetValue(2))
    end
end

function PANEL:LoadEmail(from, subject)
    self.EmailTitle:SetText(subject)
    self.EmailBody:SetText("From: " .. from .. "\n\nThis is a placeholder email content for the selected email.")
end

function PANEL:CreateNewEmail()
    local newEmail = vgui.Create("DFrame")
    newEmail:SetSize(500, 400)
    newEmail:Center()
    newEmail:SetTitle("New Email")
    newEmail:MakePopup()

    local to = vgui.Create("DTextEntry", newEmail)
    to:Dock(TOP)
    to:SetTall(30)
    to:SetPlaceholderText("To: (SteamID or Name)")
    to:DockMargin(5, 5, 5, 0)

    local subject = vgui.Create("DTextEntry", newEmail)
    subject:Dock(TOP)
    subject:SetTall(30)
    subject:SetPlaceholderText("Subject")
    subject:DockMargin(5, 5, 5, 5)

    local body = vgui.Create("DTextEntry", newEmail)
    body:Dock(FILL)
    body:SetMultiline(true)
    body:SetPlaceholderText("Write your message here...")
    body:DockMargin(5, 0, 5, 5)

    local send = vgui.Create("DButton", newEmail)
    send:Dock(BOTTOM)
    send:SetTall(30)
    send:SetText("Send")
    send:DockMargin(5, 5, 5, 5)
    send.DoClick = function()
        LocalPlayer():ChatPrint("Email sending functionality not implemented yet")
        newEmail:Close()
    end
end

vgui.Register("HALOARMORY.EmailProgram", PANEL, "DPanel") 