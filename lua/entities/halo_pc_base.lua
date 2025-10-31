AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Personal Computer"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.DeviceType = "pc_base"

--ENT.Model = 4
ENT.SelectedModel = 4

ENT.Editable = true

// DO NOT CALL Initialize. Call this instead.
function ENT:PreInit()
    if SERVER then
        self.PC_Files = {}

        if self:GetPC_ID() == "" then
            if isfunction(HALOARMORY.COMPUTER.InitializeFiles) then
                HALOARMORY.COMPUTER.InitializeFiles(self)
            end
        end
    end
end

function ENT:CustomDataTables()
    -- Add any custom data tables here
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "PC_ID", { KeyName = "PC_ID", Edit = { type = "Generic", order = 1 } })
    self:NetworkVar("String", 1, "ScreenWindow", { KeyName = "ScreenWindow", Edit = { type = "Generic", order = 1 } })

    if SERVER then
        self:SetPC_ID("")
        self:SetScreenWindow("Standby")
    end

    self:CustomDataTables()
end

if SERVER then


    concommand.Add("halo_computer_login", function(ply, cmd, args)
        local ent = Entity(tonumber(args[1]))
        if not IsValid(ent) or not ent.IsHALOARMORY then return end
        
        if isfunction(ent.SetScreenWindow) then
            ent:SetScreenWindow("LoggedIn")
        end
    end)

    concommand.Add("halo_computer_logout", function(ply, cmd, args)
        local ent = Entity(tonumber(args[1]))
        if not IsValid(ent) or not ent.IsHALOARMORY then return end
        
        if isfunction(ent.SetScreenWindow) then
            ent:SetScreenWindow("Standby")
        end
    end)
end

if CLIENT then
    function ENT:DrawStandby()
        // Draw a red box in the inter, make it centered.
        local outline = 35
        local boxW, boxH = 1300, 650
        boxW, boxH = boxW+outline, boxH+outline
        boxW, boxH = boxW-outline, boxH-outline

        // Draw the label
        draw.SimpleText("// PERSONAL COMPUTER //", "HK_QuanticoLabel", self.frameW * .5, (self.frameH * .5)-(boxH * .4), Color(0, 255, 42), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        // Draw the button
        local btnOutline = 30
        local btnW, btnH = 500, 160
        btnW, btnH = btnW+btnOutline, btnH+btnOutline
        draw.RoundedBox(0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH, Color(0, 255, 34))
        btnW, btnH = btnW-btnOutline, btnH-btnOutline
        
        local btnColor = Color(27, 27, 27)
        if ui3d2d.isHovering((self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH) then
            btnColor = Color(92, 92, 92)
            if ui3d2d.isPressed() then
                HALOARMORY.COMPUTER.OpenInterace(self, self:GetPC_ID())
            end
        end
        draw.RoundedBox(0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3), btnW, btnH, btnColor)

        // Draw the button label
        draw.SimpleText("LOGIN", "HK_QuanticoHeader", self.frameW * .5, (self.frameH * .5)-(btnH * -.8), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function ENT:DrawLoggedIn()
        // Draw a simple logout button
        local btnOutline = 30
        local btnW, btnH = 500, 160
        btnW, btnH = btnW+btnOutline, btnH+btnOutline

        draw.RoundedBox(0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH, Color(255, 0, 0))
        btnW, btnH = btnW-btnOutline, btnH-btnOutline

        local btnColor = Color(27, 27, 27)
        if ui3d2d.isHovering((self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3)-25, btnW, btnH) then
            btnColor = Color(92, 92, 92)
            if ui3d2d.isPressed() then
                RunConsoleCommand("halo_computer_logout", self:EntIndex())
            end
        end

        draw.RoundedBox(0, (self.frameW * .5)-(btnW * .5), (self.frameH * .5)-(btnH * -.3), btnW, btnH, btnColor)

        // Draw the button label
        draw.SimpleText("LOGOUT", "HK_QuanticoHeader", self.frameW * .5, (self.frameH * .5)-(btnH * -.8), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function ENT:DrawScreen()
        local model_table = self.ScreenModels[self.Model]

        self.frameW = model_table["frameW"]
        self.frameH = model_table["frameH"]

        local DrawScreenWindow = self["Draw"..self:GetScreenWindow()]
        if isfunction(DrawScreenWindow) then
            local succ, err = pcall(DrawScreenWindow, self)
            if not succ then
                print("Error from Supply Point Base Function related to device:", self)
                print(err)
            end
        else
            print("Error from Supply Point Base Function related to device:", self)
            print("No Draw Function for Screen Window: "..self:GetScreenWindow())
        end
    end
end