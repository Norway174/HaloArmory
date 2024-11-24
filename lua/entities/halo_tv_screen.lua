AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName = "Screen Base"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = false

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.IsHALOARMORY = true

ENT.DeviceType = "generic_screen"

ENT.CanDrag = false // Perfect Hands support to remove the hand icon over screens.

ENT.PanelPos = Vector(-2.5, 30.8, 21)
ENT.PanelAng = Angle(0, -90, 90)
ENT.PanelScale = .07

ENT.frameW, ENT.frameH = 946, 600

ENT.ScreenModels = {
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_sm.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.5, 30.8, 21),
        ["ang"] = Angle(0, -90, 90),
        ["scale"] = .07,
        ["frameW"] = 946,
        ["frameH"] = 600,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = function( self, background_img )
            surface.SetMaterial( background_img )
            surface.SetDrawColor( Color( 0, 0, 0, 79) )
            surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )
        end,
    },
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_med.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.4, 64.8, 43),
        ["ang"] = Angle(0, -90, 90),
        ["scale"] = .141,
        ["frameW"] = 946,
        ["frameH"] = 600,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = function( self, background_img )
            surface.SetMaterial( background_img )
            surface.SetDrawColor( Color( 0, 0, 0, 79) )
            surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )
        end,
    },
    {
        ["model"] = "models/valk/halo3/unsc/props/military/monitor_default.mdl", -- Halo UNSC Prop Pack - Halo 3
        ["model_func"] = function(self)
            self:SetColor(Color(37, 37, 37))
            self:SetSubMaterial(0, "model_color")
            self:SetSubMaterial(2, "null")
        end,
        ["pos"] = Vector(-2.4, 131.8, 81),
        ["ang"] = Angle(0, -90, 90),
        ["scale"] = .279,
        ["frameW"] = 946,
        ["frameH"] = 600,
        ["background"] = "vgui/character_creator/unsc_logo_white.png",
        ["draw_bg"] = function( self, background_img )
            surface.SetMaterial( background_img )
            surface.SetDrawColor( Color( 0, 0, 0, 79) )
            surface.DrawTexturedRect( (self.frameW/2)-(380/2), 75, 380, 500 )
        end,
    },
    {
        ["model"] = "models/ishi/halo_rebirth/props/human/tech_console_b.mdl",
        ["model_func"] = function(self)
            self:SetSubMaterial( 4, "Models/effects/vol_light001" )
            --self:SetAngles( self:GetAngles() + Angle(0, 180, 0) )
        end,
        ["pos"] = Vector(-0.63, -10.1, 24.8), --Vector(-1, -10.5, 26.8),
        ["ang"] = Angle(0, 90, 80),
        ["scale"] = .0215,
        ["frameW"] = 946,
        ["frameH"] = 765,
        ["background"] = "vgui/haloarmory/pc/pc_bg.png",
        ["draw_bg"] = function( self, background_img )
            surface.SetMaterial( background_img )
            surface.SetDrawColor( Color( 255, 255, 255) )
            surface.DrawTexturedRect( 0, -100, self.frameW, self.frameH + 205 )
        end,
    },
    {
        ["model"] = "models/nirrti/tablet/tablet_sfm.mdl",
        ["model_func"] = function(self)
            --self:SetAngles( self:GetAngles() + Angle(0, -90, 90) )
        end,
        ["pos"] = Vector(-5, 3.5, 1.2),
        ["ang"] = Angle(0, 0, 0),
        ["scale"] = .0264,
        ["frameW"] = 357,
        ["frameH"] = 265,
        ["background"] = "vgui/haloarmory/frigate_doors/control_panel/background.png",
        ["draw_bg"] = function( self, background_img )
            surface.SetMaterial( background_img )
            surface.SetDrawColor( Color( 255, 255, 255) )
            surface.DrawTexturedRect( 0, 0, self.frameW, self.frameH )
        end,
    }
}



ENT.SelectedModel = 1

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
    },
}

if SERVER then
    function ENT:Initialize()

        // Get the model, and if it's blank or invalid, set it to the first model in the table
        local old_model = self:GetModel()

        if old_model == "" or old_model == "models/error.mdl" then
            self:SetModel(self.ScreenModels[self.SelectedModel]["model"])
        end

        // Reset the color and submaterials
        self:SetColor(Color(255, 255, 255))
        self:SetSubMaterial(nil, nil)

        // Custom model setup
        if istable(self.ScreenModels[self.SelectedModel]) and isfunction(self.ScreenModels[self.SelectedModel]["model_func"]) then
            self.ScreenModels[self.SelectedModel]["model_func"](self)
        end

        -- Physics stuff
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        -- Init physics only on the server, so it doesn't mess up physgun beam
        if SERVER then
            self:PhysicsInit(SOLID_VPHYSICS)
        end

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false)
        end

        self:PreInit()
    end

    ENT.SpawnAngles = Angle(0,0,0)
    function ENT:SpawnFunction( ply, tr, ClassName )

        if ( !tr.Hit ) then return end
        
        local SpawnPos = tr.HitPos + tr.HitNormal
        local SpawnAng = ply:EyeAngles()
        
        local ent = ents.Create( ClassName )
    
        local SpawnOff = ent.SpawnAngles
        SpawnAng.p = 0
        SpawnAng.p = SpawnAng.p + SpawnOff.p
        SpawnAng.y = SpawnAng.y + SpawnOff.y
        SpawnAng.z = SpawnAng.z + SpawnOff.z
    
        ent:SetPos( SpawnPos )
        ent:SetAngles( SpawnAng )
        ent:Spawn()
        ent:Activate()
    
        return ent
    
    end
end

if CLIENT then
    local Error_StopDraw = false
    function ENT:Draw()
        --render.SuppressEngineLighting(true)
        self:DrawModel()
        --render.SuppressEngineLighting(false)

        --if Error_StopDraw then return end

        --if self.ScreenModels[self.Model]["model"] ~= self:GetModel() then
        Error_StopDraw = true
        for k, v in pairs(self.ScreenModels) do
            if v["model"] == self:GetModel() then
                self.Model = k
                Error_StopDraw = false
                break
            end
        end
        --end

        local model_table = self.ScreenModels[self.Model]

        if not istable(model_table) then return end

        if isstring(model_table["background"]) then
            model_table["background"] = Material( model_table["background"], "smooth" )
        end

        --PrintTable(model_table)


        if not ui3d2d.startDraw(self:LocalToWorld(model_table["pos"]), self:LocalToWorldAngles(model_table["ang"]), model_table["scale"], self) then return end

            --print("Drawing Screen")
            self.frameW = model_table["frameW"]
            self.frameH = model_table["frameH"]
        
            if isfunction( model_table["draw_bg"] ) then
                model_table["draw_bg"]( self, model_table["background"] )
            else
                surface.SetDrawColor( Color( 0, 0, 0, 79) )
                surface.DrawRect( 0, 0, self.frameW, self.frameH )
            end

            local succ, err = pcall(self.DrawScreen, self) --Call the draw function
            if not succ then
                print("Error from Supply Point Base Function related to device:", self )
                print(err)
                --Error_StopDraw = true
            end

            self:DrawCursor( ui3d2d )

        ui3d2d.endDraw() --Finish the UI render
    end

    function ENT:DrawScreen()
        // Draw Custom screens here
    end

    ENT.DrawCursor = false
    //ENT.CursorIcon = Material("icon16/cursor.png")
    ENT.CursorIcon = Material("icon16/bullet_white.png")
    function ENT:DrawCursor( ui )
        if self.DrawCursor then return end

        if not ui then return end

        local mouseX, mouseY = ui.getCursorPos()
        local cursor_size = 16

        if not mouseX or not mouseY then return end
        if not ui.isHovering(0, 0, self.frameW, self.frameH) then return end

        surface.SetDrawColor( Color( 255, 255, 255) )
        surface.SetMaterial( self.CursorIcon )
        surface.DrawTexturedRect( mouseX - cursor_size / 2, mouseY - cursor_size / 2, cursor_size, cursor_size )
    end

    function ENT:Initialize()
        self:PreInit()
    end


end

function ENT:PreInit()
end





properties.Add( "set_screen_model", {
    MenuLabel = "Set Screen Model", -- Name to display on the context menu
    Order = -100, -- The order to display this property relative to other properties
    MenuIcon = "icon16/computer_edit.png", -- The icon to display next to the property
    PrependSpacer = false,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( !gamemode.Call( "CanProperty", ply, "bodygroups", ent ) ) then return false end
        if ( not istable( ent.ScreenModels ) ) then return false end

        return true
    end,

    MenuOpen = function( self, option, ent, tr )
        local submenu = option:AddSubMenu()
        for k, v in pairs( ent.ScreenModels ) do
            local smnu = submenu:AddOption( v["model"])
            smnu:SetRadio( true )
            smnu:SetChecked( ent:GetModel() == v["model"] )
            smnu:SetIsCheckable( true )
            smnu.OnChecked = function()
                self:SetModelScreen( ent, k )
            end
        end
    end,

    Action = function( self, ent )
        // Nothing
    end,

    SetModelScreen = function( self, ent, model )
        self:MsgStart()
            net.WriteEntity( ent )
            net.WriteUInt( model, 8 )
        self:MsgEnd()
    end,

    Receive = function( self, length, player )
        local ent = net.ReadEntity()
        local model = net.ReadUInt( 8 )

        if not IsValid( ent ) then return end

        ent:SetModel(ent.ScreenModels[model]["model"])
        ent.SelectedModel = model
        
        ent:Initialize()
    end
} )