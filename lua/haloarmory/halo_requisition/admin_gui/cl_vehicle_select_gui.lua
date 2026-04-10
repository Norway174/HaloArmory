HALOARMORY.MsgC("VEHICLE Selection GUI Loaded")

HALOARMORY.VEHICLES = HALOARMORY.VEHICLES or {}
HALOARMORY.VEHICLES.ADMIN_GUI = HALOARMORY.VEHICLES.ADMIN_GUI or {}

local NewVehicle = true

// Constants for camera and model preview
local CAMERA_DISTANCE_MULTIPLIER = 2.5
local CAMERA_MIN_DISTANCE = 50
local CAMERA_FAR_Z_MULTIPLIER = 10
local CAMERA_FAR_Z_BASE = 1000
local MOUSE_SENSITIVITY = 0.8
local ZOOM_SPEED_BASE = 50
local ZOOM_SPEED_SCALING = 1000

local BaseTemplateVehicle = {
    ["filename"] = "my_vehicle",
    ["entity"] = "sim_fphys_halo_warthog_chaingun",
    ["name"] = "",
    ["cost"] = 5000,
    ["categories"] = {
        ["default"] = true,
    },
    ["defaults"] = {
        ["color"] = "UNSC Green",
        ["skin"] = "Default",
    },
    ["colors"] = {
        ["UNSC Green"] = Color( 76, 85, 63 ),
    },
    ["skins"] = {
        ["Default"] = 0,
    },
    ["bodygroups"] = {
        ["FogLights"] = { 0, },
        ["Armor"] = { 0, },
        ["Bars"] = { 0, },
        ["Windshield"] = { 0, },
        ["Trunk"] = { 0, },
        ["Decals"] = { 0, },
        ["Wheel Front Left"] = { 0, },
        ["Wheel Front Right"] = { 0, },
        ["Wheel Rear Left"] = { 0, },
        ["Wheel Rear Right"] = { 0, },
    },
    ["AccessList"] = {
    },
}

local function NewTemplateVehicle()
    return HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( BaseTemplateVehicle ) )
end

local VehicleBeingEdited = NewTemplateVehicle()



function HALOARMORY.VEHICLES.ADMIN_GUI.OpenLoadoutEditor()

    local Vehicle_Ent, VehicleModel, VehiclePrintName = HALOARMORY.Requisition.GetModelAndNameFromVehicle( VehicleBeingEdited["entity"] )

    if not Vehicle_Ent then return end

    --print( VehiclePrintName, VehicleModel )


    if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor then
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Hide()
    end

    local MainLoadoutWindow = vgui.Create("DFrame")
    MainLoadoutWindow:SetSize(800, 600)
    MainLoadoutWindow:Center()
    MainLoadoutWindow:SetTitle("HALOARMORY.VEHICLES.LOADOUTS_EDITOR")
    MainLoadoutWindow:MakePopup()

    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameLoadoutEditor = MainLoadoutWindow

    MainLoadoutWindow.OnClose = function()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameLoadoutEditor = nil
        if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor then
            HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Show()
        end
    end

    // Top half of the loadout window.
    local LoadoutTop = vgui.Create("DPanel", MainLoadoutWindow)


    // Bottom half of the loadout window.
    local LoadoutBottom = vgui.Create("DPanel", MainLoadoutWindow)



    // Split the Loadout window into two halves, top and bottom.
    local LoadoutSplitter = vgui.Create("DVerticalDivider", MainLoadoutWindow)
    LoadoutSplitter:Dock( FILL )
    LoadoutSplitter:SetTopHeight( MainLoadoutWindow:GetTall() / 2.1 - 4 )
    LoadoutSplitter:SetDividerHeight( 4 )

    LoadoutSplitter:SetTop( LoadoutTop )

    LoadoutSplitter:SetBottom( LoadoutBottom )

    --LoadoutSplitter:InvalidateParent( true )


    LoadoutTop.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
    end

    LoadoutBottom.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 128, 20, 20, 187) )
    end


    -- Draw a model panel
    local VehicleModelPreview = vgui.Create("DModelPanel", LoadoutTop)
    VehicleModelPreview:Dock(FILL)
    //VehicleModelPreview:SetSize(SelectedVehicleContainer:GetWide(), SelectedVehicleContainer:GetTall())
    //VehicleModelPreview:DockMargin(5, 5, 5, 5)
    
    VehicleModelPreview:SetFOV(30)
    VehicleModelPreview:SetDirectionalLight(BOX_RIGHT, Color(255, 189, 135))
    VehicleModelPreview:SetDirectionalLight(BOX_LEFT, Color(125, 182, 252))
    VehicleModelPreview:SetAmbientLight(Vector(-64, -64, -64))
    VehicleModelPreview:SetAnimated(true)
    --VehicleModelPreview:SetCursor("arrow")
    VehicleModelPreview.Angles = Angle(0, 0, 0)

    
    // Set the model - required
    VehicleModelPreview:SetModel(VehicleModel)
    
    -- Calculate the center of the model
    local mins, maxs = VehicleModelPreview.Entity:GetModelBounds()
    if not mins or not maxs then
        notification.AddLegacy( "Failed to load vehicle model.", NOTIFY_ERROR, 5 )
        MainLoadoutWindow:Close()
        return
    end
    local center = (mins + maxs) / 2
    local distance = mins:Distance(maxs)
    
    VehicleModelPreview:SetLookAt(center)
    
    -- Initialize the camera distance and angles
    local camDistance = distance * CAMERA_DISTANCE_MULTIPLIER
    local pitch = 15
    local yaw = 45

    VehicleModelPreview.FarZ = (distance * CAMERA_FAR_Z_MULTIPLIER + CAMERA_FAR_Z_BASE)
    
    -- Hold to rotate
    function VehicleModelPreview:DragMousePress()
        self.PressX, self.PressY = input.GetCursorPos()
        self.Pressed = true
    end
    
    function VehicleModelPreview:DragMouseRelease()
        self.Pressed = false
    end
    
    function VehicleModelPreview:OnMouseWheeled(delta)
        local speed = ZOOM_SPEED_BASE
        // Increase the speed the higher the distance
        speed = speed * (distance / ZOOM_SPEED_SCALING)
        camDistance = math.Clamp(camDistance - delta * speed, CAMERA_MIN_DISTANCE, distance * CAMERA_FAR_Z_MULTIPLIER)
        //print(camDistance)
    end

    function VehicleModelPreview:LayoutEntity(ent)
        if (self.bAnimated) then self:RunAnimation() end
    
        if (self.Pressed) then
            local mx, my = input.GetCursorPos()
    
            -- Update the pitch and yaw angles based on mouse movement
            yaw = yaw + ((self.PressX or mx) - mx) * MOUSE_SENSITIVITY -- Invert left-right control and increase sensitivity
            pitch = math.Clamp(pitch - ((self.PressY or my) - my) * MOUSE_SENSITIVITY, -89, 89) -- Normal up-down control and increase sensitivity
    
            self.PressX, self.PressY = mx, my
        end
    
        -- Calculate the camera position using spherical coordinates
        local radiansPitch = math.rad(pitch)
        local radiansYaw = math.rad(yaw)
        
        local x = camDistance * math.cos(radiansPitch) * math.cos(radiansYaw)
        local y = camDistance * math.cos(radiansPitch) * math.sin(radiansYaw)
        local z = camDistance * math.sin(radiansPitch)
    
        VehicleModelPreview:SetCamPos(center + Vector(x, y, z))
        VehicleModelPreview:SetLookAt(center)

    end




--[[     // Top is a model preview of the vehicle.
    -- Draw a model panel
    local ModelPanel = vgui.Create("DAdjustableModelPanel", LoadoutTop)
    ModelPanel:Dock(FILL)
    ModelPanel:SetModel(VehicleModel)
    --ModelPanel:SetColor(SelectedVehicle["color"])

    ModelPanel:SetCamPos( Vector( 134, 100, 100) )
    ModelPanel:SetLookAng( Angle( 25, -140, 0 ) )
    ModelPanel:SetFOV( 120 )

    function ModelPanel:LayoutEntity( Entity )
    end

    function ModelPanel:OnMousePressed( mousecode )

        self:SetCursor( "none" )
        self:MouseCapture( true )
        self.Capturing = true
        self.MouseKey = mousecode

        if ( self.MouseKey ~= MOUSE_LEFT ) then return end
        self:SetFirstPerson( true )
        self:CaptureMouse()
    
        -- Helpers for the orbit movement
        local mins, maxs = self.Entity:GetModelBounds()
        local center = ( mins + maxs ) / 2
    
        self.OrbitPoint = center
        self.OrbitDistance = ( self.OrbitPoint - self.vCamPos ):Length()
    end
    

    function ModelPanel:FirstPersonControls()
        local x, y = self:CaptureMouse()
        local scale = self:GetFOV() / 180
        x = x * -0.5 * scale
        y = y * 0.5 * scale
    
        if ( self.MouseKey ~= MOUSE_LEFT ) then return end
        if ( input.IsShiftDown() ) then y = 0 end

        self.aLookAngle = self.aLookAngle + Angle( y * 4, x * 4, 0 )
        self.vCamPos = self.OrbitPoint - self.aLookAngle:Forward() * self.OrbitDistance
    end ]]

    // Create a DVerticalDivider to split the bottom half into two halves.
    local LoadoutBottomSplitter = vgui.Create("DHorizontalDivider", LoadoutBottom)
    LoadoutBottomSplitter:Dock( FILL )
    LoadoutBottomSplitter:SetLeftWidth( MainLoadoutWindow:GetWide() / 1.5 - 4 )
    LoadoutBottomSplitter:SetDividerWidth( 4 )

    // Top half of the loadout window.
    local LoadoutLeft = vgui.Create("DPanel", MainLoadoutWindow)


    // Bottom half of the loadout window.
    local LoadoutRight = vgui.Create("DPanel", MainLoadoutWindow)

    LoadoutBottomSplitter:SetLeft( LoadoutLeft )
    LoadoutBottomSplitter:SetRight( LoadoutRight )




    // Create a tab panel; Colors, Skins and Bodygroups.
    local LoadoutTabPanel = vgui.Create("DPropertySheet", LoadoutLeft)
    LoadoutTabPanel:Dock( FILL )
    LoadoutTabPanel:DockMargin( 2, 2, 2, 2 )
    LoadoutTabPanel:DockPadding( 4, 0, 3 ,0 )

    // Create a tab for colors.
    local LoadoutTabColors = vgui.Create("DPanel", LoadoutTabPanel)
    LoadoutTabColors:Dock( FILL )
    LoadoutTabColors.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
    end

    LoadoutTabPanel:AddSheet( "Colors", LoadoutTabColors, "icon16/color_wheel.png" )

    // Create a tab for skins.
    local LoadoutTabSkins = vgui.Create("DPanel", LoadoutTabPanel)
    LoadoutTabSkins:Dock( FILL )
    LoadoutTabSkins.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
    end

    LoadoutTabPanel:AddSheet( "Skins", LoadoutTabSkins, "icon16/palette.png" )

    // Create a tab for bodygroups.
    local LoadoutTabBodygroups = vgui.Create("DPanel", LoadoutTabPanel)
    LoadoutTabBodygroups:Dock( FILL )
    LoadoutTabBodygroups.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
    end

    LoadoutTabPanel:AddSheet( "Bodygroups", LoadoutTabBodygroups, "icon16/bricks.png" )

    --LoadoutTabPanel:SetActiveTab( LoadoutTabPanel:GetItems()[3].Tab )


    // RIGHT SIDE PREVIEW CONTROLS
    local RightSidePreviewControls = vgui.Create("DPanel", LoadoutRight)
    RightSidePreviewControls:Dock( FILL )
    RightSidePreviewControls:DockMargin( 2, 2, 2, 2 )

    RightSidePreviewControls.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
    end

    local selectedPreviewColor = nil
    local selectedPreviewSkin = nil

    local function RefreshPreviewControls()

        // Remove all children from the panel.
        RightSidePreviewControls:Clear()

        // Add a label to the top of the panel.
        local PreviewControlsLabel = vgui.Create("DLabel", RightSidePreviewControls)
        PreviewControlsLabel:Dock( TOP )
        PreviewControlsLabel:SetTall( 25 )
        PreviewControlsLabel:SetText( "Preview Controls" )
        PreviewControlsLabel:SetFont( "DermaDefaultBold" )
        PreviewControlsLabel:SetColor( Color( 0, 0, 0) )
        PreviewControlsLabel:SetContentAlignment( 5 )


        // A label for the color picker.
        local ColorPickerLabel = vgui.Create("DLabel", RightSidePreviewControls)
        ColorPickerLabel:Dock( TOP )
        ColorPickerLabel:SetTall( 25 )
        ColorPickerLabel:SetText( "Color Picker" )
        ColorPickerLabel:SetFont( "DermaDefault" )
        ColorPickerLabel:SetColor( Color( 0, 0, 0) )

        // Select a DropDown menu for the color list. With the default color selected.
        local ColorPickerDropDown = vgui.Create("DComboBox", RightSidePreviewControls)
        ColorPickerDropDown:Dock( TOP )
        ColorPickerDropDown:SetTall( 25 )
        ColorPickerDropDown:SetValue( selectedPreviewColor or VehicleBeingEdited["defaults"]["color"] )

        // Update the Model Preview with the new color.
        if VehicleBeingEdited["colors"][ColorPickerDropDown:GetValue()] and IsColor( VehicleBeingEdited["colors"][ColorPickerDropDown:GetValue()] ) then
            VehicleModelPreview:SetColor( VehicleBeingEdited["colors"][ColorPickerDropDown:GetValue()] )
        end

        //ColorPickerDropDown:Clear()

        for key, value in pairs( VehicleBeingEdited["colors"] ) do
            ColorPickerDropDown:AddChoice( key )
        end

        ColorPickerDropDown.OnSelect = function( self, index, value, data )

            // Update the Model Preview with the new color.
            if VehicleBeingEdited["colors"][value] and IsColor( VehicleBeingEdited["colors"][value] ) then
                VehicleModelPreview:SetColor( VehicleBeingEdited["colors"][value] )

                if VehicleBeingEdited["defaults"]["color"] == value then
                    selectedPreviewColor = nil
                else
                    selectedPreviewColor = value
                end
            end

        end

        // A label for the skin picker.
        local SkinPickerLabel = vgui.Create("DLabel", RightSidePreviewControls)
        SkinPickerLabel:Dock( TOP )
        SkinPickerLabel:SetTall( 25 )
        SkinPickerLabel:SetText( "Skin Picker" )
        SkinPickerLabel:SetFont( "DermaDefault" )
        SkinPickerLabel:SetColor( Color( 0, 0, 0) )

        // Select a DropDown menu for the skin list. With the default skin selected.
        local SkinPickerDropDown = vgui.Create("DComboBox", RightSidePreviewControls)
        SkinPickerDropDown:Dock( TOP )
        SkinPickerDropDown:SetTall( 25 )
        SkinPickerDropDown:SetValue( selectedPreviewSkin or VehicleBeingEdited["defaults"]["skin"] )

        if VehicleBeingEdited["skins"][SkinPickerDropDown:GetValue()] and isnumber( VehicleBeingEdited["skins"][SkinPickerDropDown:GetValue()] ) then
            VehicleModelPreview.Entity:SetSkin( VehicleBeingEdited["skins"][SkinPickerDropDown:GetValue()] )
        end

        for key, value in pairs( VehicleBeingEdited["skins"] ) do
            SkinPickerDropDown:AddChoice( key )
        end

        SkinPickerDropDown.OnSelect = function( self, index, value, data )

            // Update the Model Preview with the new skin.
            if VehicleBeingEdited["skins"][value] and isnumber( VehicleBeingEdited["skins"][value] ) then
                VehicleModelPreview.Entity:SetSkin( VehicleBeingEdited["skins"][value] )

                if VehicleBeingEdited["defaults"]["skin"] == value then
                    selectedPreviewSkin = nil
                else
                    selectedPreviewSkin = value
                end
            end

        end

        // A label for the bodygroup picker.
        local BodygroupPickerLabel = vgui.Create("DLabel", RightSidePreviewControls)
        BodygroupPickerLabel:Dock( TOP )
        BodygroupPickerLabel:SetTall( 25 )
        BodygroupPickerLabel:SetText( "Bodygroup Picker" )
        BodygroupPickerLabel:SetFont( "DermaDefault" )
        BodygroupPickerLabel:SetColor( Color( 0, 0, 0) )

        local BodygroupPickerScroll = vgui.Create("DScrollPanel", RightSidePreviewControls)
        BodygroupPickerScroll:Dock( FILL )

        // Available bodygroups for the vehicle.
        local VehicleBodygroups = VehicleBeingEdited["bodygroups"]

        --print( "VehicleBodygroups" )
        --PrintTable( VehicleBodygroups )

        // Create a Loop for each bodygroup, and add a DTileLayout with a button for each bodygroup number from the list. 
        for key, value in pairs( VehicleBodygroups ) do


            local BodygroupLabel = vgui.Create("DLabel", BodygroupPickerScroll)
            BodygroupLabel:Dock( TOP )
            BodygroupLabel:SetTall( 15 )
            BodygroupLabel:SetText( " " .. tostring( key ) )
            BodygroupLabel:SetFont( "DermaDefault" )
            BodygroupLabel:SetColor( Color( 0, 0, 0) )


            local BodygroupTileLayout = vgui.Create("DTileLayout", BodygroupPickerScroll)
            BodygroupTileLayout:Dock( TOP )
            BodygroupTileLayout:DockMargin( 5, 0, 0, 0 )
            BodygroupTileLayout:SetBaseSize( 35 )

            BodygroupTileLayout:SetSpaceX( 2 )
            BodygroupTileLayout:SetSpaceY( 2 )

            local BodyGroup_ID = VehicleModelPreview.Entity and VehicleModelPreview.Entity:FindBodygroupByName( key ) or -1

            if BodyGroup_ID < 0 then continue end

            --print( "Key;", key, "Value:", value, "ID:", BodyGroup_ID )
            --PrintTable( value )

            for i = 1, #value do

                local BodygroupSubPanel = vgui.Create("DButton", BodygroupTileLayout)
                local size = BodygroupTileLayout:GetBaseSize()
                BodygroupSubPanel:SetSize( size, size )
                BodygroupSubPanel:SetText( "" )



                BodygroupSubPanel.Paint = function( self, w, h )
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )

                    if VehicleModelPreview.Entity:GetBodygroup( BodyGroup_ID ) == value[i] then
                        draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 0, 255, 0, 70) )
                    end

                    draw.SimpleText( value[i], "DermaDefault", size / 2, size / 2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                end

                local DoClickBackup = BodygroupSubPanel.DoClick
                BodygroupSubPanel.DoClick = function( self )
                    DoClickBackup( self )

                    VehicleModelPreview.Entity:SetBodygroup( BodyGroup_ID, value[i] )
                end

            end

        end

    end


    // COLORS TAB

    local LoadoutColorsScrollbar = vgui.Create("DScrollPanel", LoadoutTabColors)
    LoadoutColorsScrollbar:Dock( FILL )



    local function PopulateColors()

        LoadoutColorsScrollbar:Clear()

        // Add a panel to add a new color.
        local AddColorPanel = vgui.Create("DPanel", LoadoutColorsScrollbar)
        AddColorPanel:Dock( TOP )
        AddColorPanel:DockMargin( 0, 0, 2, 5 )
        AddColorPanel:SetSize( 0, 30 )
        
        local AddColorButton = vgui.Create("DButton", AddColorPanel)
        AddColorButton:Dock( FILL )
        AddColorButton:SetText("Add Color")
        AddColorButton:SetIcon("icon16/add.png")

        AddColorButton.DoClick = function()

            local ColorName = "New Color"

            for i = 1, 100 do
                if VehicleBeingEdited["colors"][ColorName] then
                    ColorName = "New Color " .. tostring( i )
                else
                    break
                end
            end


            VehicleBeingEdited["colors"][ColorName] = Color( 255, 255, 255 )
            PopulateColors()

            RefreshPreviewControls()
        end

        for key, value in pairs( VehicleBeingEdited["colors"] ) do

            local ColorPanel = vgui.Create("DPanel", LoadoutColorsScrollbar)
            ColorPanel:Dock( TOP )
            ColorPanel:DockMargin( 0, 5, 2, 5 )
            ColorPanel:SetSize( 0, 25 )

            local topPanel = vgui.Create("DPanel", ColorPanel)
            topPanel:Dock( FILL )
            topPanel:SetTall( 25 )

            local ColorLabel = vgui.Create("DTextEntry", topPanel)
            ColorLabel:Dock( LEFT )
            ColorLabel:SetWide( 250 )
            ColorLabel:SetText( tostring(key) )

            --ColorLabel:SetUpdateOnType( false )

            ColorLabel.OnChange = function( )

                local ColorName = ColorLabel:GetValue()
                if ColorName == "" then return end

                local ColorValue = VehicleBeingEdited["colors"][key]
                --print( "Color:", ColorName, ColorValue, type(ColorValue), IsColor(ColorValue) )
                if not ColorValue and not IsColor(ColorValue) then return end

                VehicleBeingEdited["colors"][key] = nil
                VehicleBeingEdited["colors"][ColorName] = ColorValue


                if VehicleBeingEdited["defaults"]["color"] == key then
                    VehicleBeingEdited["defaults"]["color"] = ColorName
                end

                key = ColorName

                RefreshPreviewControls()

            end


            local ColorRemoveButton = vgui.Create("DButton", topPanel)
            ColorRemoveButton:Dock( RIGHT )
            ColorRemoveButton:SetText("")
            ColorRemoveButton:SetIcon("icon16/delete.png")
            ColorRemoveButton:SetWide( 26 )

            ColorRemoveButton.DoClick = function()

                VehicleBeingEdited["colors"][key] = nil
                ColorPanel:Remove()

                RefreshPreviewControls()

                PopulateColors()

            end

            if table.Count( VehicleBeingEdited["colors"] ) <= 1 then
                ColorRemoveButton:SetDisabled( true )
            else 
                ColorRemoveButton:SetDisabled( false )
            end

            local SetAsDefaultButton = vgui.Create("DButton", topPanel)
            SetAsDefaultButton:Dock( RIGHT )
            SetAsDefaultButton:SetText("")
            SetAsDefaultButton:SetIcon("icon16/star.png")
            SetAsDefaultButton:SetWide( 26 )

            SetAsDefaultButton.DoClick = function()

                VehicleBeingEdited["defaults"]["color"] = key
                PopulateColors()

                RefreshPreviewControls()

            end

            SetAsDefaultButton:SetDisabled( VehicleBeingEdited["defaults"]["color"] == key )

            // AI Color
            // Display a color box with the current color of the AI. Then you can click the box to open a color picker window.
            local AIColor_Box = vgui.Create( "DButton", topPanel )
            AIColor_Box:Dock( FILL )
            AIColor_Box:SetText( "" )
            --AIColor_Box.Color = VehicleBeingEdited["colors"][key] or Color( 255, 255, 255)
            AIColor_Box.Paint = function( self, w, h )
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
                draw.RoundedBox( 0, 1, 1, w-2, h-2, VehicleBeingEdited["colors"][key] )
            end

            AIColor_Box.DoClick = function()
                local originalColor = VehicleBeingEdited["colors"][key] or Color( 255, 255, 255)
                local colorApplied = false
                
                // Ensure the model preview shows the correct color when opening
                VehicleModelPreview:SetColor( originalColor )
                
                local colorPickerWindow = vgui.Create( "DFrame" )
                colorPickerWindow:SetSize( 220, 280 )
                colorPickerWindow:Center()
                colorPickerWindow:SetTitle( "Vehicle Color Picker" )
                colorPickerWindow:SetVisible( true )
                colorPickerWindow:SetDraggable( true )
                colorPickerWindow:ShowCloseButton( true )
                colorPickerWindow:MakePopup()

                local colorPicker = vgui.Create( "DColorMixer", colorPickerWindow )
                colorPicker:SetPalette( true )
                colorPicker:SetAlphaBar( false )
                colorPicker:SetWangs( true )
                colorPicker:SetColor( originalColor )
                colorPicker:SetPos( 10, 35 )
                colorPicker:SetSize( 200, 200 )
                colorPicker:SetAlpha( 255 )

                colorPicker.ValueChanged = function( self, newColor )
                    newColor = Color( newColor.r, newColor.g, newColor.b, 255 )
                    VehicleModelPreview:SetColor( newColor )
                end
                
                local colorApplyButton = vgui.Create( "DButton", colorPickerWindow )
                colorApplyButton:SetText( "Apply" )
                colorApplyButton:SetPos( 10, 240 )
                colorApplyButton:SetSize( 200, 30 )
                colorApplyButton.DoClick = function()
                    local selectedColor = colorPicker:GetColor()
                    selectedColor = Color( selectedColor.r, selectedColor.g, selectedColor.b, 255 )
                    VehicleBeingEdited["colors"][key] = selectedColor
                    colorApplied = true
                    RefreshPreviewControls()
                    colorPickerWindow:Close()
                end

                // Close and reset when window loses focus
                colorPickerWindow.OnFocusChanged = function( self, gained )
                    if not gained and not colorApplied then
                        VehicleModelPreview:SetColor( originalColor )
                        self:Close()
                    end
                end

                colorPickerWindow.OnClose = function()
                    if not colorApplied then
                        VehicleModelPreview:SetColor( originalColor )
                    end
                    RefreshPreviewControls()
                end

            end




        end



    end

    PopulateColors()

    // SKINS Tab

    local LoadoutSkinsScrollbar = vgui.Create("DScrollPanel", LoadoutTabSkins)
    LoadoutSkinsScrollbar:Dock( FILL )

    local function PopulateSkins()

        LoadoutSkinsScrollbar:Clear()

        // Add a panel to add a new skin.
        local AddSkinPanel = vgui.Create("DPanel", LoadoutSkinsScrollbar)
        AddSkinPanel:Dock( TOP )
        AddSkinPanel:DockMargin( 0, 0, 2, 5 )
        AddSkinPanel:SetSize( 0, 30 )
        
        local AddSkinButton = vgui.Create("DButton", AddSkinPanel)
        AddSkinButton:Dock( FILL )
        AddSkinButton:SetText("Add Skin")
        AddSkinButton:SetIcon("icon16/add.png")

        AddSkinButton.DoClick = function()

            local SkinName = "New Skin"

            for i = 1, 100 do
                if VehicleBeingEdited["skins"][SkinName] then
                    SkinName = "New Skin " .. tostring( i )
                else
                    break
                end
            end

            VehicleBeingEdited["skins"][SkinName] = 0
            PopulateSkins()

            RefreshPreviewControls()
        end

        for key, value in pairs( VehicleBeingEdited["skins"] ) do

            local SkinPanel = vgui.Create("DPanel", LoadoutSkinsScrollbar)
            SkinPanel:Dock( TOP )
            SkinPanel:DockMargin( 0, 5, 2, 5 )
            SkinPanel:SetSize( 0, 25 )

            local topPanel = vgui.Create("DPanel", SkinPanel)
            topPanel:Dock( FILL )
            topPanel:SetTall( 25 )

            local SkinLabel = vgui.Create("DTextEntry", topPanel)
            SkinLabel:Dock( LEFT )
            SkinLabel:SetWide( 250 )
            SkinLabel:SetText( tostring(key) )

            local NumberOfSkins = VehicleModelPreview.Entity:SkinCount() - 1

            local SkinNumberWang = vgui.Create("DNumberWang", topPanel)
            SkinNumberWang:Dock( FILL )
            SkinNumberWang:SetMax( NumberOfSkins )
            SkinNumberWang:SetValue( value )

            SkinNumberWang.OnValueChanged = function( self, value2 )

                VehicleBeingEdited["skins"][key] = value2

                RefreshPreviewControls()

            end


            local SkinRemoveButton = vgui.Create("DButton", topPanel)
            SkinRemoveButton:Dock( RIGHT )
            SkinRemoveButton:SetText("")
            SkinRemoveButton:SetIcon("icon16/delete.png")
            SkinRemoveButton:SetWide( 26 )

            SkinRemoveButton.DoClick = function()

                VehicleBeingEdited["skins"][key] = nil
                SkinPanel:Remove()

                RefreshPreviewControls()

                PopulateSkins()

            end

            if table.Count( VehicleBeingEdited["skins"] ) <= 1 then
                SkinRemoveButton:SetDisabled( true )
            else 
                SkinRemoveButton:SetDisabled( false )
            end

            SkinLabel.OnChange = function( self )

                local SkinName = SkinLabel:GetValue()
                if SkinName == "" then return end

                local SkinValue = VehicleBeingEdited["skins"][key]
                --print( "Color:", SkinName, SkinValue, type(SkinValue), IsColor(SkinValue) )
                if not SkinValue and not isnumber(SkinValue) then return end

                VehicleBeingEdited["skins"][key] = nil
                VehicleBeingEdited["skins"][SkinName] = SkinValue

                if VehicleBeingEdited["defaults"]["skin"] == key then
                    VehicleBeingEdited["defaults"]["skin"] = SkinName
                end

                key = SkinName



                RefreshPreviewControls()

            end


            local DefaultSkinButton = vgui.Create("DButton", topPanel)
            DefaultSkinButton:Dock( RIGHT )
            DefaultSkinButton:SetText("")
            DefaultSkinButton:SetIcon("icon16/star.png")
            DefaultSkinButton:SetWide( 26 )

            DefaultSkinButton.DoClick = function()

                VehicleBeingEdited["defaults"]["skin"] = key
                PopulateSkins()

                RefreshPreviewControls()

            end

            DefaultSkinButton:SetDisabled( VehicleBeingEdited["defaults"]["skin"] == key )

        end

    end

    PopulateSkins()


    // BODYGROUPS TAB

    local LoadoutBodygroupsScrollbar = vgui.Create("DScrollPanel", LoadoutTabBodygroups)
    LoadoutBodygroupsScrollbar:Dock( FILL )

    local ListOfBodygroups = VehicleModelPreview.Entity:GetBodyGroups()

    // Remove any bodygroups from the VehicleBeingEdited["bodygroups"] table that are not in the ListOfBodygroups table.
    for key, value in pairs( VehicleBeingEdited["bodygroups"] ) do
        if not ListOfBodygroups[key] then
            VehicleBeingEdited["bodygroups"][key] = nil
        end
    end

    for key, value in pairs( ListOfBodygroups ) do
        local BodygroupNumber = value["num"] - 1

        if BodygroupNumber <= 0 then continue end

        BodygroupNumber = BodygroupNumber + 1

        local BodygroupPanel = vgui.Create("DPanel", LoadoutBodygroupsScrollbar)
        BodygroupPanel:Dock( TOP )
        BodygroupPanel:DockMargin( 0, 0, 2, 5 )
        BodygroupPanel:SetSize( 0, 60 )

        BodygroupPanel.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )
        end

        local BodygroupLabel = vgui.Create("DLabel", BodygroupPanel)
        BodygroupLabel:Dock( TOP )
        BodygroupLabel:SetWide( 250 )
        BodygroupLabel:SetText( " " .. tostring(value["name"]) )

        
        // Use DTileLayout with MakeDroppable to allow for reordering of bodygroups.
        local BodygroupTileLayout = vgui.Create("DTileLayout", BodygroupPanel)
        BodygroupTileLayout:Dock( FILL )
        BodygroupTileLayout:DockMargin( 5, 0, 0, 0 )
        BodygroupTileLayout:SetBaseSize( 35 )

        BodygroupTileLayout:SetSpaceX( 2 )
        BodygroupTileLayout:SetSpaceY( 2 )

        BodygroupTileLayout:MakeDroppable( "Bodygroup-"..tostring(key) )


        

        --print( value["name"], key, value, BodygroupNumber )
        --PrintTable( value )

        local function UpdateSelectedBodygroups( self )
            local BodygroupTable = {}

            local BodyGroupCheckboxes = BodygroupTileLayout:GetChildren()

            --table.SortByMember( BodyGroupCheckboxes, "BodygroupNumber", true )

            for k, v in pairs( BodyGroupCheckboxes ) do
                if v:GetChecked() then
                    table.insert( BodygroupTable, v.BodygroupNumber )
                end
            end

            VehicleBeingEdited["bodygroups"][value["name"]] = BodygroupTable

            RefreshPreviewControls()
        end

        BodygroupTileLayout.OnModified = function( self )
            UpdateSelectedBodygroups( self )
        end


        for i = 1, BodygroupNumber do

            local BodygroupSubPanel = vgui.Create("DCheckBox", BodygroupTileLayout)
            local size = BodygroupTileLayout:GetBaseSize()
            BodygroupSubPanel:SetSize( size, size )

            if not VehicleBeingEdited["bodygroups"][value["name"]] then
                VehicleBeingEdited["bodygroups"][value["name"]] = { 0 }
            end

            BodygroupSubPanel:SetChecked( table.HasValue(VehicleBeingEdited["bodygroups"][value["name"]], i - 1) or false )

            BodygroupSubPanel.BodygroupNumber = i - 1

            BodygroupSubPanel.Paint = function( self, w, h )
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )

                if self:GetChecked() then
                    draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 0, 255, 0, 70) )
                end

                draw.SimpleText( BodygroupSubPanel.BodygroupNumber, "DermaDefault", size / 2, size / 2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
            end
            local DoClickBackup = BodygroupSubPanel.DoClick
            BodygroupSubPanel.DoClick = function(self)
                if #VehicleBeingEdited["bodygroups"][value["name"]] <= 1 and self:GetChecked() then
                    self:SetChecked( true )
                    return
                end

                DoClickBackup( self )
                UpdateSelectedBodygroups( BodygroupTileLayout )
            end

        end

    end


    RefreshPreviewControls()


end

HALOARMORY.VEHICLES.ADMIN_GUI.NewTemplateVehicle = NewTemplateVehicle
HALOARMORY.VEHICLES.ADMIN_GUI.GetVehicleBeingEdited = function()
    return VehicleBeingEdited
end
HALOARMORY.VEHICLES.ADMIN_GUI.SetVehicleBeingEdited = function( vehicle_table )
    VehicleBeingEdited = vehicle_table
end
HALOARMORY.VEHICLES.ADMIN_GUI.GetNewVehicle = function()
    return NewVehicle
end
HALOARMORY.VEHICLES.ADMIN_GUI.SetNewVehicle = function( is_new_vehicle )
    NewVehicle = is_new_vehicle == true
end

local GUI = HALOARMORY.VEHICLES.ADMIN_GUI

local function new_template_vehicle()
    return GUI.NewTemplateVehicle()
end

local function get_vehicle_being_edited()
    return GUI.GetVehicleBeingEdited()
end

local function set_vehicle_being_edited( vehicle_table )
    GUI.SetVehicleBeingEdited( vehicle_table )
end

local function get_new_vehicle()
    return GUI.GetNewVehicle()
end

local function set_new_vehicle( is_new_vehicle )
    GUI.SetNewVehicle( is_new_vehicle )
end

local function sort_strings( values )
    table.sort( values, function( a, b )
        return tostring( a ) < tostring( b )
    end )
end

local function sanitize_vehicle_filename( filename )
    return tostring( filename or "" ):lower():gsub( "[^%w_]", "_" )
end

local function normalize_vehicle_list( vehicle_list )
    local normalized_list = {}

    for vehicle_key, vehicle_table in pairs( vehicle_list or {} ) do
        if not istable( vehicle_table ) then continue end

        local normalized = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_table ) )
        normalized.filename = sanitize_vehicle_filename( normalized.filename ~= "" and normalized.filename or vehicle_key )
        normalized_list[normalized.filename] = normalized
    end

    return normalized_list
end

local function sorted_vehicle_keys( vehicle_list )
    local keys = {}

    for vehicle_key in pairs( vehicle_list or {} ) do
        table.insert( keys, vehicle_key )
    end

    sort_strings( keys )

    return keys
end

local function get_vehicle_categories( vehicle_table )
    vehicle_table = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_table or {} ) )

    local categories = {}
    for category_id, enabled in pairs( vehicle_table.categories or {} ) do
        if enabled then
            table.insert( categories, HALOARMORY.Requisition.NormalizeCategory( category_id ) )
        end
    end

    if #categories <= 0 then
        table.insert( categories, HALOARMORY.Requisition.GetDefaultCategory() )
    end

    sort_strings( categories )

    return categories
end

local function count_bodygroups( vehicle_table )
    local count = 0

    for _ in pairs( vehicle_table.bodygroups or {} ) do
        count = count + 1
    end

    return count
end

local function serialize_vehicle( vehicle_table )
    return util.TableToJSON( HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_table or {} ) ), true ) or ""
end

local function create_editor_row( parent, label_text, row_height )
    local row = vgui.Create( "DPanel", parent )
    row:Dock( TOP )
    row:SetTall( row_height or 28 )
    row:DockMargin( 8, 0, 8, 6 )
    row.Paint = nil

    local label = vgui.Create( "DLabel", row )
    label:Dock( LEFT )
    label:SetWide( 110 )
    label:SetText( label_text )

    return row
end

function GUI.OpenVehicleEditor( vehicle_table )
    local normalized = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_table or get_vehicle_being_edited() or new_template_vehicle() ) )
    local is_new_vehicle = vehicle_table == nil and get_new_vehicle() or not istable( vehicle_table )

    normalized.filename = sanitize_vehicle_filename( normalized.filename )
    set_vehicle_being_edited( normalized )

    GUI.PendingEditVehicle = table.Copy( normalized )
    GUI.PendingSelection = normalized.filename
    GUI.PendingStartEdit = true
    GUI.PendingNewVehicle = is_new_vehicle

    if IsValid( GUI.MainFrame ) and isfunction( GUI.MainFrame.LoadVehicleIntoEditor ) then
        GUI.MainFrame:LoadVehicleIntoEditor( normalized, {
            is_new = is_new_vehicle,
            source_filename = normalized.old_filename or normalized.filename,
            force = true,
        } )
        GUI.MainFrame:Show()
        GUI.MainFrame:MakePopup()
        return
    end

    GUI.OpenGUI( GUI.VehicleList )
end

function GUI.OpenGUI( vehicle_list )
    local has_access = true
    if CAMI then
        has_access = CAMI.PlayerHasAccess( LocalPlayer(), "HALOARMORY.Vehicle Editor" )
    elseif IsValid( LocalPlayer() ) then
        has_access = LocalPlayer():IsSuperAdmin()
    end

    if not has_access then
        chat.AddText( Color( 255, 0, 0 ), "You do not have access to this command!" )
        return "No Access!"
    end

    if IsValid( GUI.MainFrame ) then
        GUI.MainFrame:Remove()
        GUI.MainFrame = nil
    end

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 1280, 760 )
    frame:Center()
    frame:SetTitle( "HALOARMORY.VEHICLES.EDITOR" )
    frame:SetSizable( true )
    frame:SetMinWidth( 1100 )
    frame:SetMinHeight( 640 )
    frame:MakePopup()

    GUI.MainFrame = frame
    GUI.MainFrameEditor = frame

    frame.OnClose = function()
        GUI.MainFrame = nil
        GUI.MainFrameEditor = nil

        net.Start( "HALOARMORY.VEHICLES.ADMIN" )
            net.WriteString( "MENUCLOSED" )
        net.SendToServer()
    end

    if not istable( vehicle_list ) then
        local loading_label = vgui.Create( "DLabel", frame )
        loading_label:Dock( FILL )
        loading_label:SetContentAlignment( 5 )
        loading_label:SetText( "Loading vehicles..." )

        net.Start( "HALOARMORY.VEHICLES.ADMIN" )
            net.WriteString( "GETVEHICLES" )
        net.SendToServer()

        return
    end

    vehicle_list = normalize_vehicle_list( vehicle_list )
    GUI.VehicleList = vehicle_list
    HALOARMORY.VEHICLES.LIST = table.Copy( vehicle_list )

    local selected_filename = GUI.PendingSelection
    local active_vehicle_key = nil
    local editor_baseline = nil
    local vehicle_list_view
    local vehicle_rows = {}
    local right_panel
    local category_list
    local remove_category_button
    local save_button
    local loadout_button
    local delete_button
    local dirty_status_label
    local validation_label
    local current_category_selection = nil
    local refresh_list_view
    local load_vehicle_into_editor

    local function current_vehicle()
        return get_vehicle_being_edited()
    end

    local function editor_dirty()
        local vehicle_table = current_vehicle()
        if not vehicle_table or not editor_baseline then return false end

        return serialize_vehicle( vehicle_table ) ~= editor_baseline
    end

    local function validate_vehicle()
        local vehicle_table = current_vehicle() or {}
        local filename = sanitize_vehicle_filename( vehicle_table.filename )
        local name = string.Trim( tostring( vehicle_table.name or "" ) )
        local cost = tonumber( vehicle_table.cost )
        local vehicle_ent, _, vehicle_print_name = HALOARMORY.Requisition.GetModelAndNameFromVehicle( vehicle_table.entity or "" )

        if filename == "" then return false, "Filename is required." end
        if name == "" then return false, "Vehicle name is required." end
        if cost == nil then return false, "Vehicle cost must be numeric." end
        if not vehicle_ent then return false, "Entity class was not found." end

        return true, "Entity resolved as " .. tostring( vehicle_print_name or filename ) .. "."
    end

    local function update_status()
        local vehicle_table = current_vehicle()
        if not IsValid( dirty_status_label ) or not IsValid( validation_label ) or not vehicle_table then return end

        dirty_status_label:SetText( editor_dirty() and "Unsaved changes" or "Up to date" )

        local can_save, validation_text = validate_vehicle()
        validation_label:SetText( validation_text )
        validation_label:SetTextColor( can_save and Color( 80, 170, 80 ) or Color( 210, 120, 80 ) )

        if IsValid( save_button ) then
            save_button:SetEnabled( can_save )
        end

        if IsValid( loadout_button ) then
            loadout_button:SetEnabled( select( 1, HALOARMORY.Requisition.GetModelAndNameFromVehicle( vehicle_table.entity or "" ) ) ~= nil )
        end

        if IsValid( delete_button ) then
            delete_button:SetEnabled( not get_new_vehicle() and active_vehicle_key ~= nil )
        end

        if IsValid( remove_category_button ) then
            remove_category_button:SetEnabled( current_category_selection ~= nil )
        end
    end

    local function confirm_discard( on_accept )
        if not isfunction( on_accept ) then return end

        if not editor_dirty() then
            on_accept()
            return
        end

        Derma_Query(
            "Discard the current unsaved vehicle changes?",
            "Unsaved Changes",
            "Discard",
            on_accept,
            "Keep Editing"
        )
    end

    local function select_vehicle_row( vehicle_key )
        if not IsValid( vehicle_list_view ) then return end

        local line = vehicle_rows[vehicle_key]
        if not IsValid( line ) then return end

        vehicle_list_view:ClearSelection()
        line:SetSelected( true )
        vehicle_list_view:OnRowSelected( line:GetID(), line )
    end

    local function sync_category_list()
        if not IsValid( category_list ) then return end

        category_list:Clear()
        current_category_selection = nil

        for _, category_id in ipairs( get_vehicle_categories( current_vehicle() ) ) do
            local line = category_list:AddLine( category_id )
            line.CategoryID = category_id
        end

        update_status()
    end

    local function request_refresh( selection_key, start_edit )
        GUI.PendingSelection = selection_key
        GUI.PendingStartEdit = start_edit == true
        GUI.PendingEditVehicle = nil
        GUI.PendingNewVehicle = false

        net.Start( "HALOARMORY.VEHICLES.ADMIN" )
            net.WriteString( "GETVEHICLES" )
        net.SendToServer()
    end

    local function remove_vehicle( vehicle_key )
        if not isstring( vehicle_key ) or vehicle_key == "" then return end

        Derma_Query(
            "Delete vehicle '" .. vehicle_key .. "'?",
            "Delete Vehicle",
            "Delete",
            function()
                GUI.PendingSelection = nil
                GUI.PendingStartEdit = false
                GUI.PendingEditVehicle = nil
                GUI.PendingNewVehicle = false

                net.Start( "HALOARMORY.VEHICLES.ADMIN" )
                    net.WriteString( "REMOVEVEHICLE" )
                    net.WriteString( vehicle_key )
                net.SendToServer()
            end,
            "Cancel"
        )
    end

    local function save_vehicle()
        local vehicle_table = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( current_vehicle() ) )
        vehicle_table.filename = sanitize_vehicle_filename( vehicle_table.filename )
        set_vehicle_being_edited( vehicle_table )

        local save_filename = vehicle_table.filename
        local overwrite_other = vehicle_list[save_filename] ~= nil and active_vehicle_key ~= save_filename

        local function do_save()
            GUI.PendingSelection = save_filename
            GUI.PendingStartEdit = true
            GUI.PendingEditVehicle = nil
            GUI.PendingNewVehicle = false

            net.Start( "HALOARMORY.VEHICLES.ADMIN" )
                net.WriteString( "SAVEVEHICLE" )
                net.WriteTable( vehicle_table )
            net.SendToServer()
        end

        if overwrite_other then
            Derma_Query(
                "A vehicle with that filename already exists. Overwrite it?",
                "Overwrite Vehicle",
                "Overwrite",
                do_save,
                "Cancel"
            )
            return
        end

        do_save()
    end

    local function available_category_choices()
        local active = {}
        local choices = {}

        for _, category_id in ipairs( get_vehicle_categories( current_vehicle() ) ) do
            active[category_id] = true
        end

        for _, category_data in ipairs( HALOARMORY.Requisition.GetCategories( get_vehicle_categories( current_vehicle() ) ) ) do
            if not active[category_data.id] then
                table.insert( choices, category_data.id )
            end
        end

        sort_strings( choices )

        return choices
    end

    local function rebuild_editor()
        right_panel:Clear()
        category_list = nil
        remove_category_button = nil
        current_category_selection = nil

        local vehicle_table = current_vehicle()
        if not vehicle_table then return end

        local scroll = vgui.Create( "DScrollPanel", right_panel )
        scroll:Dock( FILL )

        local action_row = vgui.Create( "DPanel", right_panel )
        action_row:Dock( BOTTOM )
        action_row:SetTall( 68 )
        action_row:DockMargin( 8, 8, 8, 8 )
        action_row.Paint = nil

        local header = vgui.Create( "DLabel", scroll )
        header:Dock( TOP )
        header:DockMargin( 8, 8, 8, 4 )
        header:SetFont( "DermaLarge" )
        header:SetTall( 28 )
        header:SetText( get_new_vehicle() and "New Vehicle" or tostring( vehicle_table.name ~= "" and vehicle_table.name or vehicle_table.filename ) )

        dirty_status_label = vgui.Create( "DLabel", scroll )
        dirty_status_label:Dock( TOP )
        dirty_status_label:DockMargin( 8, 0, 8, 2 )

        validation_label = vgui.Create( "DLabel", scroll )
        validation_label:Dock( TOP )
        validation_label:DockMargin( 8, 0, 8, 8 )

        local filename_row = create_editor_row( scroll, "Filename:" )
        local filename_entry = vgui.Create( "DTextEntry", filename_row )
        filename_entry:Dock( FILL )
        filename_entry:SetValue( tostring( vehicle_table.filename or "" ) )

        local entity_row = create_editor_row( scroll, "Entity Class:" )
        local guess_name_button = vgui.Create( "DButton", entity_row )
        guess_name_button:Dock( RIGHT )
        guess_name_button:SetWide( 28 )
        guess_name_button:SetText( "" )
        guess_name_button:SetIcon( "icon16/car.png" )

        local entity_entry = vgui.Create( "DTextEntry", entity_row )
        entity_entry:Dock( FILL )
        entity_entry:SetValue( tostring( vehicle_table.entity or "" ) )

        local name_row = create_editor_row( scroll, "Vehicle Name:" )
        local name_entry = vgui.Create( "DTextEntry", name_row )
        name_entry:Dock( FILL )
        name_entry:SetValue( tostring( vehicle_table.name or "" ) )

        local cost_row = create_editor_row( scroll, "Cost:" )
        local cost_entry = vgui.Create( "DNumberWang", cost_row )
        cost_entry:Dock( FILL )
        cost_entry:SetMin( 0 )
        cost_entry:SetMax( 2147483647 )
        cost_entry:SetValue( tonumber( vehicle_table.cost ) or 0 )

        local category_header = vgui.Create( "DLabel", scroll )
        category_header:Dock( TOP )
        category_header:DockMargin( 8, 8, 8, 4 )
        category_header:SetFont( "DermaDefaultBold" )
        category_header:SetText( "Categories" )

        local category_help = vgui.Create( "DLabel", scroll )
        category_help:Dock( TOP )
        category_help:DockMargin( 8, 0, 8, 6 )
        category_help:SetWrap( true )
        category_help:SetAutoStretchVertical( true )
        category_help:SetText( "Add a new category id or select one already used by another vehicle." )

        local category_add_row = vgui.Create( "DPanel", scroll )
        category_add_row:Dock( TOP )
        category_add_row:SetTall( 28 )
        category_add_row:DockMargin( 8, 0, 8, 6 )
        category_add_row.Paint = nil

        local add_category_button = vgui.Create( "DButton", category_add_row )
        add_category_button:Dock( RIGHT )
        add_category_button:SetWide( 92 )
        add_category_button:SetText( "Add" )
        add_category_button:SetIcon( "icon16/add.png" )

        local category_combo = vgui.Create( "DComboBox", category_add_row )
        category_combo:Dock( RIGHT )
        category_combo:SetWide( 170 )
        category_combo:SetValue( "" )

        local category_entry = vgui.Create( "DTextEntry", category_add_row )
        category_entry:Dock( FILL )
        category_entry:SetPlaceholderText( "new_category_id" )

        local category_holder = vgui.Create( "DPanel", scroll )
        category_holder:Dock( TOP )
        category_holder:SetTall( 180 )
        category_holder:DockMargin( 8, 0, 8, 8 )
        category_holder.Paint = nil

        category_list = vgui.Create( "DListView", category_holder )
        category_list:Dock( FILL )
        category_list:SetMultiSelect( false )
        category_list:AddColumn( "Current Categories" )

        remove_category_button = vgui.Create( "DButton", category_holder )
        remove_category_button:Dock( BOTTOM )
        remove_category_button:SetTall( 28 )
        remove_category_button:SetText( "Remove Selected Category" )
        remove_category_button:SetIcon( "icon16/delete.png" )

        local action_header = vgui.Create( "DLabel", scroll )
        action_header:Dock( TOP )
        action_header:DockMargin( 8, 8, 8, 4 )
        action_header:SetFont( "DermaDefaultBold" )
        action_header:SetText( "Vehicle Actions" )

        local action_buttons = vgui.Create( "DPanel", scroll )
        action_buttons:Dock( TOP )
        action_buttons:SetTall( 32 )
        action_buttons:DockMargin( 8, 0, 8, 8 )
        action_buttons.Paint = nil

        loadout_button = vgui.Create( "DButton", action_buttons )
        loadout_button:Dock( LEFT )
        loadout_button:SetWide( 170 )
        loadout_button:SetText( "Edit Loadouts..." )
        loadout_button:SetIcon( "icon16/bricks.png" )

        local access_button = vgui.Create( "DButton", action_buttons )
        access_button:Dock( RIGHT )
        access_button:SetWide( 170 )
        access_button:SetText( "Set Access..." )
        access_button:SetIcon( "icon16/user.png" )

        save_button = vgui.Create( "DButton", action_row )
        save_button:Dock( LEFT )
        save_button:SetWide( 160 )
        save_button:SetText( "Save Vehicle" )
        save_button:SetIcon( "icon16/disk.png" )

        local revert_button = vgui.Create( "DButton", action_row )
        revert_button:Dock( LEFT )
        revert_button:DockMargin( 8, 0, 0, 0 )
        revert_button:SetWide( 160 )
        revert_button:SetText( "Revert Changes" )
        revert_button:SetIcon( "icon16/arrow_undo.png" )

        delete_button = vgui.Create( "DButton", action_row )
        delete_button:Dock( RIGHT )
        delete_button:SetWide( 160 )
        delete_button:SetText( "Delete Vehicle" )
        delete_button:SetIcon( "icon16/delete.png" )

        local function refresh_category_choices()
            local previous_value = category_combo:GetValue()
            category_combo:Clear()

            for _, category_id in ipairs( available_category_choices() ) do
                category_combo:AddChoice( category_id )
            end

            category_combo:SetValue( previous_value ~= "" and previous_value or "" )
        end

        local function refresh_header()
            header:SetText( get_new_vehicle() and "New Vehicle" or tostring( vehicle_table.name ~= "" and vehicle_table.name or vehicle_table.filename ) )
            update_status()
        end

        local function add_category()
            local typed_value = HALOARMORY.Requisition.SanitizeCategory( category_entry:GetValue() )
            local selected_value = HALOARMORY.Requisition.SanitizeCategory( category_combo:GetValue() )
            local category_id = typed_value ~= "" and typed_value or selected_value

            if category_id == "" then
                notification.AddLegacy( "Enter or select a category first.", NOTIFY_ERROR, 3 )
                return
            end

            vehicle_table.categories[category_id] = true
            vehicle_table.categories = HALOARMORY.Requisition.NormalizeVehicleCategories( vehicle_table.categories )

            category_entry:SetValue( "" )
            category_combo:SetValue( "" )

            sync_category_list()
            refresh_category_choices()
            refresh_header()
        end

        filename_entry.OnChange = function( self )
            local caret_pos = self:GetCaretPos()
            local new_filename = sanitize_vehicle_filename( self:GetValue() )

            if self:GetValue() ~= new_filename then
                self:SetText( new_filename )
                self:SetCaretPos( math.min( caret_pos, string.len( new_filename ) ) )
            end

            vehicle_table.filename = new_filename
            refresh_header()
        end

        entity_entry.OnChange = function( self )
            vehicle_table.entity = self:GetValue()
            refresh_header()
        end

        name_entry.OnChange = function( self )
            vehicle_table.name = self:GetValue()
            refresh_header()
        end

        local function update_cost()
            vehicle_table.cost = tonumber( cost_entry:GetValue() ) or 0
            refresh_header()
        end

        cost_entry.OnValueChanged = update_cost
        cost_entry.OnChange = update_cost

        guess_name_button.DoClick = function()
            local _, _, vehicle_print_name = HALOARMORY.Requisition.GetModelAndNameFromVehicle( entity_entry:GetValue() )
            if not vehicle_print_name then return end

            name_entry:SetValue( tostring( vehicle_print_name ) )
            vehicle_table.name = tostring( vehicle_print_name )
            refresh_header()
        end

        add_category_button.DoClick = add_category
        category_entry.OnEnter = add_category

        category_list.OnRowSelected = function( _, _, line )
            current_category_selection = IsValid( line ) and line.CategoryID or nil
            update_status()
        end

        category_list.DoDoubleClick = function( _, _, line )
            if not IsValid( line ) then return end

            vehicle_table.categories[line.CategoryID] = nil
            vehicle_table.categories = HALOARMORY.Requisition.NormalizeVehicleCategories( vehicle_table.categories )
            sync_category_list()
            refresh_category_choices()
            refresh_header()
        end

        remove_category_button.DoClick = function()
            if not current_category_selection then return end

            vehicle_table.categories[current_category_selection] = nil
            vehicle_table.categories = HALOARMORY.Requisition.NormalizeVehicleCategories( vehicle_table.categories )
            sync_category_list()
            refresh_category_choices()
            refresh_header()
        end

        loadout_button.DoClick = function()
            GUI.OpenLoadoutEditor()
        end

        access_button.DoClick = function()
            HALOARMORY.INTERFACE.ACCESS.Open( vehicle_table.AccessList or {}, function( new_access_list )
                vehicle_table.AccessList = new_access_list or {}
                refresh_header()
            end, "Authorization" )
        end

        save_button.DoClick = function()
            local can_save, validation_text = validate_vehicle()
            if not can_save then
                notification.AddLegacy( validation_text, NOTIFY_ERROR, 4 )
                return
            end
            save_vehicle()
        end

        revert_button.DoClick = function()
            confirm_discard( function()
                if get_new_vehicle() then
                    load_vehicle_into_editor( new_template_vehicle(), {
                        is_new = true,
                        force = true,
                    } )
                    return
                end

                if active_vehicle_key and vehicle_list[active_vehicle_key] then
                    load_vehicle_into_editor( vehicle_list[active_vehicle_key], {
                        is_new = false,
                        source_filename = active_vehicle_key,
                        force = true,
                    } )
                    return
                end

                request_refresh( active_vehicle_key, true )
            end )
        end

        delete_button.DoClick = function()
            if active_vehicle_key then
                remove_vehicle( active_vehicle_key )
            end
        end

        sync_category_list()
        refresh_category_choices()
        update_status()
    end

    load_vehicle_into_editor = function( vehicle_table, options )
        options = options or {}

        if not options.force then
            confirm_discard( function()
                load_vehicle_into_editor( vehicle_table, {
                    is_new = options.is_new,
                    source_filename = options.source_filename,
                    force = true,
                } )
            end )
            return
        end

        local normalized = HALOARMORY.Requisition.NormalizeVehicleTable( table.Copy( vehicle_table or new_template_vehicle() ) )
        normalized.filename = sanitize_vehicle_filename( normalized.filename )
        normalized.AccessList = normalized.AccessList or {}

        set_vehicle_being_edited( normalized )
        set_new_vehicle( options.is_new == true )

        active_vehicle_key = not get_new_vehicle() and sanitize_vehicle_filename( options.source_filename or normalized.old_filename or normalized.filename ) or nil
        if get_new_vehicle() then
            normalized.old_filename = nil
            selected_filename = nil
        else
            normalized.old_filename = active_vehicle_key
            selected_filename = active_vehicle_key
        end

        editor_baseline = serialize_vehicle( normalized )
        rebuild_editor()
        select_vehicle_row( selected_filename )
    end

    refresh_list_view = function()
        vehicle_rows = {}
        vehicle_list_view:Clear()

        for _, vehicle_key in ipairs( sorted_vehicle_keys( vehicle_list ) ) do
            local vehicle_data = vehicle_list[vehicle_key]
            local line = vehicle_list_view:AddLine(
                vehicle_data.filename or vehicle_key,
                vehicle_data.name or "",
                vehicle_data.entity or "",
                tostring( math.Round( tonumber( vehicle_data.cost ) or 0 ) ),
                table.concat( get_vehicle_categories( vehicle_data ), ", " ),
                tostring( table.Count( vehicle_data.colors or {} ) ),
                tostring( table.Count( vehicle_data.skins or {} ) ),
                tostring( count_bodygroups( vehicle_data ) )
            )

            line.VehicleFilename = vehicle_key
            vehicle_rows[vehicle_key] = line
        end

        if selected_filename then
            select_vehicle_row( selected_filename )
        end
    end

    local toolbar = vgui.Create( "DPanel", frame )
    toolbar:Dock( TOP )
    toolbar:SetTall( 36 )
    toolbar:DockMargin( 8, 4, 8, 8 )
    toolbar.Paint = nil

    local add_vehicle_button = vgui.Create( "DButton", toolbar )
    add_vehicle_button:Dock( LEFT )
    add_vehicle_button:SetWide( 130 )
    add_vehicle_button:SetText( "Add Vehicle" )
    add_vehicle_button:SetIcon( "icon16/add.png" )

    local duplicate_button = vgui.Create( "DButton", toolbar )
    duplicate_button:Dock( LEFT )
    duplicate_button:DockMargin( 8, 0, 0, 0 )
    duplicate_button:SetWide( 150 )
    duplicate_button:SetText( "Duplicate Selected" )
    duplicate_button:SetIcon( "icon16/page_copy.png" )

    local refresh_button = vgui.Create( "DButton", toolbar )
    refresh_button:Dock( LEFT )
    refresh_button:DockMargin( 8, 0, 0, 0 )
    refresh_button:SetWide( 120 )
    refresh_button:SetText( "Refresh List" )
    refresh_button:SetIcon( "icon16/arrow_refresh.png" )

    local hint_label = vgui.Create( "DLabel", toolbar )
    hint_label:Dock( FILL )
    hint_label:DockMargin( 12, 0, 12, 0 )
    hint_label:SetText( "Double-click a row to load it into the editor panel." )
    hint_label:SetContentAlignment( 4 )

    local splitter = vgui.Create( "DHorizontalDivider", frame )
    splitter:Dock( FILL )
    splitter:SetLeftWidth( 720 )
    splitter:SetDividerWidth( 4 )

    local left_panel = vgui.Create( "DPanel", frame )
    left_panel.Paint = nil

    right_panel = vgui.Create( "DPanel", frame )
    right_panel.Paint = nil

    splitter:SetLeft( left_panel )
    splitter:SetRight( right_panel )

    local table_header = vgui.Create( "DLabel", left_panel )
    table_header:Dock( TOP )
    table_header:DockMargin( 8, 8, 8, 4 )
    table_header:SetFont( "DermaDefaultBold" )
    table_header:SetText( "Vehicle Table" )

    vehicle_list_view = vgui.Create( "DListView", left_panel )
    vehicle_list_view:Dock( FILL )
    vehicle_list_view:DockMargin( 8, 0, 8, 8 )
    vehicle_list_view:SetMultiSelect( false )
    vehicle_list_view:AddColumn( "Filename" )
    vehicle_list_view:AddColumn( "Name" )
    vehicle_list_view:AddColumn( "Entity" )
    vehicle_list_view:AddColumn( "Cost" )
    vehicle_list_view:AddColumn( "Categories" )
    vehicle_list_view:AddColumn( "Colors" )
    vehicle_list_view:AddColumn( "Skins" )
    vehicle_list_view:AddColumn( "Bodygroups" )

    vehicle_list_view.OnRowSelected = function( _, _, line )
        if not IsValid( line ) then return end
        selected_filename = line.VehicleFilename
    end

    vehicle_list_view.DoDoubleClick = function( _, _, line )
        if not IsValid( line ) then return end

        local vehicle_key = line.VehicleFilename
        local vehicle_table = vehicle_list[vehicle_key]
        if not vehicle_table then return end

        load_vehicle_into_editor( vehicle_table, {
            is_new = false,
            source_filename = vehicle_key,
        } )
    end

    add_vehicle_button.DoClick = function()
        confirm_discard( function()
            load_vehicle_into_editor( new_template_vehicle(), {
                is_new = true,
                force = true,
            } )
        end )
    end

    duplicate_button.DoClick = function()
        if not selected_filename or not vehicle_list[selected_filename] then
            notification.AddLegacy( "Select a vehicle to duplicate first.", NOTIFY_ERROR, 3 )
            return
        end

        confirm_discard( function()
            local source_vehicle = table.Copy( vehicle_list[selected_filename] )
            // Generate a new unique filename
            local base_name = source_vehicle.filename or "vehicle"
            local new_name = base_name .. "_copy"
            local counter = 1
            while vehicle_list[new_name] do
                new_name = base_name .. "_copy" .. tostring( counter )
                counter = counter + 1
            end
            source_vehicle.filename = new_name
            source_vehicle.name = (source_vehicle.name or "") .. " (Copy)"
            source_vehicle.old_filename = nil
            
            load_vehicle_into_editor( source_vehicle, {
                is_new = true,
                force = true,
            } )
        end )
    end

    refresh_button.DoClick = function()
        confirm_discard( function()
            request_refresh( selected_filename, false )
        end )
    end

    frame.LoadVehicleIntoEditor = function( _, vehicle_table, options )
        load_vehicle_into_editor( vehicle_table, options )
    end

    refresh_list_view()

    local pending_vehicle = GUI.PendingEditVehicle
    local pending_selection = GUI.PendingSelection
    local pending_start_edit = GUI.PendingStartEdit == true
    local pending_new_vehicle = GUI.PendingNewVehicle == true

    GUI.PendingEditVehicle = nil
    GUI.PendingSelection = nil
    GUI.PendingStartEdit = nil
    GUI.PendingNewVehicle = nil

    if istable( pending_vehicle ) then
        load_vehicle_into_editor( pending_vehicle, {
            is_new = pending_new_vehicle,
            source_filename = pending_vehicle.old_filename or pending_vehicle.filename,
            force = true,
        } )
    elseif pending_start_edit and pending_selection and vehicle_list[pending_selection] then
        load_vehicle_into_editor( vehicle_list[pending_selection], {
            is_new = false,
            source_filename = pending_selection,
            force = true,
        } )
    else
        if pending_selection and vehicle_list[pending_selection] then
            selected_filename = pending_selection
            select_vehicle_row( pending_selection )
        end

        local empty_title = vgui.Create( "DLabel", right_panel )
        empty_title:Dock( TOP )
        empty_title:DockMargin( 8, 16, 8, 0 )
        empty_title:SetFont( "DermaLarge" )
        empty_title:SetTall( 28 )
        empty_title:SetText( "Vehicle Editor" )

        local empty_help = vgui.Create( "DLabel", right_panel )
        empty_help:Dock( TOP )
        empty_help:DockMargin( 8, 4, 8, 0 )
        empty_help:SetWrap( true )
        empty_help:SetAutoStretchVertical( true )
        empty_help:SetText( "Double-click a row to edit it here. Categories are derived from the vehicle data instead of a separate stored list." )
    end
end

net.Receive( "HALOARMORY.VEHICLES.ADMIN", function()
    local message_type = net.ReadString()

    if message_type == "GETVEHICLES" then
        local payload_len = net.ReadUInt( 32 )
        local payload = net.ReadData( payload_len )
        local vehicle_list = util.JSONToTable( util.Decompress( payload ) or "" ) or {}

        GUI.VehicleList = vehicle_list
        HALOARMORY.VEHICLES.LIST = table.Copy( vehicle_list )

        GUI.OpenGUI( vehicle_list )

    elseif message_type == "EDITVEHICLE" then
        set_new_vehicle( false )
        GUI.OpenVehicleEditor( net.ReadTable() )
    end
end )

concommand.Add( "HALOARMORY.ManageVehicles", GUI.OpenGUI )

list.Set( "DesktopWindows", "HALOARMORY.VEHICLES.ADMIN", {
    title = "Vehicles Editor",
    icon = "vgui/haloarmory/icons/anchor.png",
    init = function()
        GUI.OpenGUI()
    end,
} )

if IsValid( GUI.MainFrameLoadoutEditor ) then
    GUI.MainFrameLoadoutEditor:Remove()
    GUI.MainFrameLoadoutEditor = nil
    GUI.OpenLoadoutEditor()
end

if IsValid( GUI.MainFrame ) then
    GUI.MainFrame:Remove()
    GUI.MainFrame = nil
    GUI.MainFrameEditor = nil
    GUI.OpenGUI( nil )
elseif IsValid( GUI.MainFrameEditor ) then
    GUI.MainFrameEditor:Remove()
    GUI.MainFrameEditor = nil
    GUI.OpenGUI( nil )
end
