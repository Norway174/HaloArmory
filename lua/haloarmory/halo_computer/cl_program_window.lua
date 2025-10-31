local PANEL = {}

function PANEL:Init()
    -- Create the header
    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(30)
    self.Header.Paint = function(s, w, h)
        surface.SetDrawColor(35, 35, 40)
        surface.DrawRect(0, 0, w, h)
    end

    -- Add title
    self.Title = vgui.Create("DLabel", self.Header)
    self.Title:SetText("Program")
    self.Title:SetFont("DermaLarge")
    self.Title:SizeToContents()
    self.Title:Dock(LEFT)
    self.Title:DockMargin(5, 0, 0, 0)
    self.Title:SetTextColor(Color(255, 255, 255))

    -- Create window controls container
    self.WindowControls = vgui.Create("DPanel", self.Header)
    self.WindowControls:Dock(RIGHT)
    self.WindowControls:SetWide(80)
    self.WindowControls.Paint = function(s, w, h)
        surface.SetDrawColor(35, 35, 40)
        surface.DrawRect(0, 0, w, h)
    end

    -- Add minimize button
    self.MinBtn = vgui.Create("DButton", self.WindowControls)
    self.MinBtn:Dock(LEFT)
    self.MinBtn:SetWide(40)
    self.MinBtn:SetText("")
    self.MinBtn.Paint = function(s, w, h)
        surface.SetDrawColor(40, 40, 45)
        if s:IsHovered() then
            surface.SetDrawColor(50, 50, 55)
        end
        surface.DrawRect(0, 0, w, h)
        
        -- Draw minimize icon
        surface.SetDrawColor(200, 200, 200)
        surface.DrawRect(w/4, h/2, w/2, 2)
    end
    self.MinBtn.DoClick = function()
        if self.OnMinimize then
            self:OnMinimize()
        end
    end

    -- Add close button
    self.CloseBtn = vgui.Create("DButton", self.WindowControls)
    self.CloseBtn:Dock(RIGHT)
    self.CloseBtn:SetWide(40)
    self.CloseBtn:SetText("✕")
    self.CloseBtn:SetFont("DermaDefault")
    self.CloseBtn:SetTextColor(Color(200, 200, 200))
    self.CloseBtn.Paint = function(s, w, h)
        surface.SetDrawColor(40, 40, 45)
        if s:IsHovered() then
            surface.SetDrawColor(180, 40, 40)
            s:SetTextColor(Color(255, 255, 255))
        else
            s:SetTextColor(Color(200, 200, 200))
        end
        surface.DrawRect(0, 0, w, h)
    end
    self.CloseBtn.DoClick = function()
        if self.OnClose then
            self:OnClose()
        end
    end

    -- Create content area
    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content:DockMargin(5, 5, 5, 5)
    self.Content.Paint = function(s, w, h)
        surface.SetDrawColor(50, 50, 55)
        surface.DrawRect(0, 0, w, h)
    end
end

function PANEL:SetTitle(title)
    self.Title:SetText(title)
    self.Title:SizeToContents()
end

function PANEL:GetContent()
    return self.Content
end

vgui.Register("HALOARMORY.ProgramWindow", PANEL, "DPanel") 