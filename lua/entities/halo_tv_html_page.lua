AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
ENT.PrintName = "Web Page Screen"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true
ENT.DeviceType = "web_screen"
ENT.Editable = true
ENT.SelectedModel = 1

ENT.WebPage = nil
ENT.InteractionFrame = nil

-- Constants
local HEIGHT_ADJUSTMENT = 55
local DEFAULT_WIDTH = 1024
local DEFAULT_HEIGHT = 576
local MIN_GUI_HEIGHT = 400
local MAX_GUI_HEIGHT = 1200
local GUI_WIDTH_PADDING = 16
local GUI_HEIGHT_PADDING = 38

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "PageURL", {
        KeyName = "URL",
        Edit = { type = "String", order = 1, waitforenter = true }
    })

    if SERVER then
        self:SetPageURL("https://google.com")
    end

    if CLIENT then
        self:NetworkVarNotify("PageURL", function(ent, name, old, new)
            if IsValid(ent.WebPage) then
                ent.WebPage:OpenURL(new)
            end
        end)
    end
end

if CLIENT then
    function ENT:PreInit()
        self:InitializeDisplayState()
        self.HoldStartTime = 0
        self.IsHolding = false
    end

    function ENT:InitializeDisplayState()
        self.OriginalX = 0
        self.OriginalY = 0
        self.OriginalParent = nil
        self.Rendering3D = false
        self.originalFrameW = DEFAULT_WIDTH
        self.originalFrameH = DEFAULT_HEIGHT
        self.adjustedFrameH = DEFAULT_HEIGHT - HEIGHT_ADJUSTMENT
    end

    function ENT:CalculateDimensions()
        local model_table = self.ScreenModels[self.Model]
        if model_table then
            self.originalFrameW = model_table.frameW or DEFAULT_WIDTH
            self.originalFrameH = model_table.frameH or DEFAULT_HEIGHT
            self.adjustedFrameH = self.originalFrameH - HEIGHT_ADJUSTMENT
        end
        return self.originalFrameW / self.adjustedFrameH
    end

    function ENT:CreateWebPage()
        if IsValid(self.WebPage) then return end

        self:CalculateDimensions()
        self.WebPage = vgui.Create("DHTML")
        
        -- Configure WebPage dimensions
        self.WebPage:SetSize(self.originalFrameW, self.adjustedFrameH)
        self.WebPage:OpenURL(self:GetPageURL())
        self.WebPage:SetPaintedManually(true)
        self.WebPage:SetMouseInputEnabled(false)
        self.WebPage:SetKeyboardInputEnabled(false)
        
        -- Store original state
        self.OriginalParent = self.WebPage:GetParent()
        self.OriginalX, self.OriginalY = self.WebPage:GetPos()
        
        -- Custom paint handling
        self.OriginalPaint = self.WebPage.Paint
        self.WebPage.Paint = function(panel, w, h)
            panel:SetAlpha(self.Rendering3D and 255 or 0)
            self.OriginalPaint(panel, w, h)
        end
    end

    function ENT:Think()
        if not self:GetPageURL() then return end
        if not self.ScreenModels[self.Model] then return end
        self:CreateWebPage()
    end

    function ENT:DrawScreen()
        local model_table = self.ScreenModels[self.Model]
        if not model_table then return end
    
        local screenPos = model_table.pos
        local screenAng = model_table.ang
        local screenScale = model_table.scale
    
        if not screenPos or not screenAng then return end
    
        local pos = self:LocalToWorld(screenPos - Vector(0, 0, 2))
        local ang = self:LocalToWorldAngles(screenAng)
    
        cam.Start3D2D(pos, ang, screenScale)
            self.Rendering3D = true
            
            if IsValid(self.WebPage) then
                -- Enforce final size before drawing
                self.WebPage:SetSize(self.originalFrameW, self.adjustedFrameH)
                self.WebPage:PaintManual()
            end
            
            self.Rendering3D = false
        cam.End3D2D()
    
    end

    function ENT:OpenInteractionGUI()
        if IsValid(self.InteractionFrame) then return end
    
        -- Calculate GUI dimensions
        local aspect = self.originalFrameW / self.originalFrameH
        local screenH = math.Clamp(ScrH() * 0.6, MIN_GUI_HEIGHT, MAX_GUI_HEIGHT)
        local screenW = screenH * aspect
        
        -- Create interaction window
        self.InteractionFrame = vgui.Create("DFrame")
        self.InteractionFrame:SetSize(screenW + GUI_WIDTH_PADDING, screenH + GUI_HEIGHT_PADDING)
        self.InteractionFrame:Center()
        self.InteractionFrame:SetTitle(string.format("Web Screen - %s", self:GetPageURL()))
        self.InteractionFrame:MakePopup()
        self.InteractionFrame:SetSizable(true)
        
        -- Create HTML container
        local htmlContainer = vgui.Create("DPanel", self.InteractionFrame)
        htmlContainer:Dock(FILL)
        
        -- Configure WebPage for GUI
        self.WebPage:SetParent(htmlContainer)
        self.WebPage:SetPos(0, 0)
        self.WebPage:SetSize(self.originalFrameW, self.originalFrameH)
        self.WebPage:SetMouseInputEnabled(true)
        self.WebPage:SetKeyboardInputEnabled(true)
        self.WebPage:SetPaintedManually(false)
        self.WebPage:InvalidateLayout(true)
    
        -- Window close handler
        self.InteractionFrame.OnClose = function()
            if IsValid(self.WebPage) then
                -- Restore 3D display settings
                self.WebPage:SetParent(self.OriginalParent)
                self.WebPage:SetPos(self.OriginalX, self.OriginalY)
                
                -- Critical sizing fix
                self.WebPage:SetSize(self.originalFrameW, self.adjustedFrameH)
                self.WebPage:InvalidateLayout(true)
                self.WebPage:UpdateHTMLTexture()
                
                -- Force immediate resize
                timer.Simple(0, function()
                    if IsValid(self.WebPage) then
                        self.WebPage:SetSize(self.originalFrameW, self.adjustedFrameH)
                        self.WebPage:InvalidateLayout(true)
                    end
                end)
    
                self.WebPage:SetMouseInputEnabled(false)
                self.WebPage:SetKeyboardInputEnabled(false)
                self.WebPage:SetPaintedManually(true)
            end
            self.InteractionFrame = nil
        end
    end

    function ENT:OnRemove()
        if IsValid(self.WebPage) then self.WebPage:Remove() end
        if IsValid(self.InteractionFrame) then self.InteractionFrame:Remove() end
    end

    properties.Add("open_webpage", {
        MenuLabel = "Open Webpage",
        Order = -99999,
        MenuIcon = "icon16/computer_edit.png",
        PrependSpacer = true,

        Filter = function(_, ent, ply)
            return IsValid(ent) 
                and ent.DeviceType == "web_screen"
                and not ent:IsPlayer()
        end,

        Action = function(_, ent)
            if IsValid(ent.WebPage) then
                ent:OpenInteractionGUI()
            end
        end
    })

    properties.Add("refresh_webpage", {
        MenuLabel = "Refresh",
        Order = -99998,
        MenuIcon = "icon16/arrow_refresh.png",
        PrependSpacer = false,

        Filter = function(_, ent, ply)
            return IsValid(ent) 
                and ent.DeviceType == "web_screen"
                and not ent:IsPlayer()
        end,

        Action = function(_, ent)
            if IsValid(ent.WebPage) then
                ent.WebPage:OpenURL(ent:GetPageURL())
            end
        end
    })
end