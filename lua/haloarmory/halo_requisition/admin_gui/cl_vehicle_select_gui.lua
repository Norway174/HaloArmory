HALOARMORY.MsgC("VEHICLE Selection GUI Loaded")

HALOARMORY.VEHICLES = HALOARMORY.VEHICLES or {}
HALOARMORY.VEHICLES.ADMIN_GUI = HALOARMORY.VEHICLES.ADMIN_GUI or {}

local NewVehicle = true

local NewTemplateVehicle = {
    ["filename"] = "my_vehicle",
    ["entity"] = "sim_fphys_halo_warthog_chaingun",
    ["name"] = "",
    ["cost"] = 5000,
    ["sizes"] = {
        ["small"] = true,
        ["large"] = false,
        ["air"] = true,
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

local VehicleBeingEdited = NewTemplateVehicle



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
    local center = (mins + maxs) / 2
    local distance = mins:Distance(maxs)
    
    VehicleModelPreview:SetLookAt(center)
    
    -- Initialize the camera distance and angles
    local camDistance = distance * 2.5
    local pitch = 15
    local yaw = 45

    VehicleModelPreview.FarZ = (distance * 10 + 1000)
    
    -- Hold to rotate
    function VehicleModelPreview:DragMousePress()
        self.PressX, self.PressY = input.GetCursorPos()
        self.Pressed = true
    end
    
    function VehicleModelPreview:DragMouseRelease()
        self.Pressed = false
    end
    
    function VehicleModelPreview:OnMouseWheeled(delta)
        local speed = 50
        // Increase the speed the higher the distance
        speed = speed * (distance / 1000)
        camDistance = math.Clamp(camDistance - delta * speed, 50, distance * 10)
        //print(camDistance)
    end

    function VehicleModelPreview:LayoutEntity(ent)
        if (self.bAnimated) then self:RunAnimation() end
    
        if (self.Pressed) then
            local mx, my = input.GetCursorPos()
    
            -- Update the pitch and yaw angles based on mouse movement
            yaw = yaw + ((self.PressX or mx) - mx) * 0.8 -- Invert left-right control and increase sensitivity
            pitch = math.Clamp(pitch - ((self.PressY or my) - my) * 0.8, -89, 89) -- Normal up-down control and increase sensitivity
    
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
            VehicleModelPreview:SetColor( VehicleBeingEdited["colors"][VehicleBeingEdited["defaults"]["color"]] )
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

            local BodyGroup_ID = VehicleModelPreview.Entity:FindBodygroupByName( key )

            --print( "Key;", key, "Value:", value, "ID:", BodyGroup_ID )
            --PrintTable( value )

            for i = 0, #value - 1 do

                local BodygroupSubPanel = vgui.Create("DButton", BodygroupTileLayout)
                local size = BodygroupTileLayout:GetBaseSize()
                BodygroupSubPanel:SetSize( size, size )
                BodygroupSubPanel:SetText( "" )



                BodygroupSubPanel.Paint = function( self, w, h )
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 187) )

                    if VehicleModelPreview.Entity:GetBodygroup( BodyGroup_ID ) == value[i + 1] then
                        draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 0, 255, 0, 70) )
                    end

                    draw.SimpleText( value[i + 1], "DermaDefault", size / 2, size / 2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                end

                local DoClickBackup = BodygroupSubPanel.DoClick
                BodygroupSubPanel.DoClick = function( self )
                    DoClickBackup( self )

                    VehicleModelPreview.Entity:SetBodygroup( BodyGroup_ID, value[i + 1] )
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
                local ColorPickerWindow = vgui.Create( "DFrame" )
                ColorPickerWindow:SetSize( 220, 280 )
                ColorPickerWindow:Center()
                ColorPickerWindow:SetTitle( "Vehicle Color Picker" )
                ColorPickerWindow:SetVisible( true )
                ColorPickerWindow:SetDraggable( true )
                ColorPickerWindow:ShowCloseButton( true )
                ColorPickerWindow:MakePopup()

                local colorPicker = vgui.Create( "DColorMixer", ColorPickerWindow )
                colorPicker:SetPalette( true )
                colorPicker:SetAlphaBar( false )
                colorPicker:SetWangs( true )
                colorPicker:SetColor( VehicleBeingEdited["colors"][key] or Color( 255, 255, 255) )
                colorPicker:SetPos( 10, 35 )
                colorPicker:SetSize( 200, 200 )
                colorPicker:SetAlpha( 255 )

                colorPicker.ValueChanged = function( self, newColor )
                    newColor = Color( newColor.r, newColor.g, newColor.b, 255 )
                    VehicleModelPreview:SetColor( newColor )
                end
                
                local colorSaveButton = vgui.Create( "DButton", ColorPickerWindow )
                colorSaveButton:SetText( "Save Color" )
                colorSaveButton:SetPos( 10, 240 )
                colorSaveButton:SetSize( 200, 30 )
                colorSaveButton.DoClick = function()

                    local selectedColor = colorPicker:GetColor()

                    selectedColor = Color( selectedColor.r, selectedColor.g, selectedColor.b, 255 )
                    VehicleBeingEdited["colors"][key] = selectedColor
                    
                    RefreshPreviewControls()
                    ColorPickerWindow:Close()

                end

                ColorPickerWindow.OnClose = function()
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
            print( "Removed bodygroup:", key )
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



function HALOARMORY.VEHICLES.ADMIN_GUI.OpenVehicleEditor( The_Vehicle )

    if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame then
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame:Remove()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame = nil
    end

    if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor then
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Remove()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = nil
    end

    The_Vehicle = The_Vehicle or VehicleBeingEdited

    VehicleBeingEdited = The_Vehicle

    local MainFrame = vgui.Create("DFrame")
    MainFrame:SetSize(300, 350)
    MainFrame:Center()
    MainFrame:SetTitle("HALOARMORY.VEHICLES.EDITOR")
    MainFrame:MakePopup()

    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = MainFrame

    MainFrame.OnClose = function()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = nil
    end
    
    local LabelWith = 75

    // VEHICLE FILENAME
    local VehicleFileNameRow = vgui.Create("DPanel", MainFrame)
    VehicleFileNameRow:Dock( TOP )
    VehicleFileNameRow:DockMargin( 0, 0, 2, 5 )
    VehicleFileNameRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleFileNameLabel = vgui.Create("DLabel", VehicleFileNameRow)
    VehicleFileNameLabel:Dock( LEFT )
    VehicleFileNameLabel:SetWide( LabelWith )
    VehicleFileNameLabel:SetText("Filename:" )

    local VehicleFileNameTextEntry = vgui.Create("DTextEntry", VehicleFileNameRow)
    VehicleFileNameTextEntry:Dock( FILL )
    VehicleFileNameTextEntry:SetValue( tostring( VehicleBeingEdited["filename"] ) )

    if NewVehicle then
        VehicleBeingEdited["old_filename"] = nil
    else
        VehicleBeingEdited["old_filename"] = VehicleBeingEdited["filename"]
    end
    

    // DIVIDER
    local Divider = vgui.Create("DPanel", MainFrame)
    Divider:Dock( TOP )
    Divider:DockMargin( 0, 0, 2, 5 )
    Divider:SetTall( 1 )
    Divider.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 40) )
    end

    // VEHICLE ENTITY CLASS
    local VehicleClassRow = vgui.Create("DPanel", MainFrame)
    VehicleClassRow:Dock( TOP )
    VehicleClassRow:DockMargin( 0, 0, 2, 5 )
    VehicleClassRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleClassLabel = vgui.Create("DLabel", VehicleClassRow)
    VehicleClassLabel:Dock( LEFT )
    VehicleClassLabel:SetWide( LabelWith )
    VehicleClassLabel:SetText("Entity Class:" )

    local VehicleClassTextEntry = vgui.Create("DTextEntry", VehicleClassRow)
    VehicleClassTextEntry:Dock( FILL )
    VehicleClassTextEntry:SetValue( tostring( VehicleBeingEdited["entity"] ) )


    // VEHICLE NAME
    local VehicleNameRow = vgui.Create("DPanel", MainFrame)
    VehicleNameRow:Dock( TOP )
    VehicleNameRow:DockMargin( 0, 0, 2, 5 )
    VehicleNameRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleNameLabel = vgui.Create("DLabel", VehicleNameRow)
    VehicleNameLabel:Dock( LEFT )
    VehicleNameLabel:SetWide( LabelWith )
    VehicleNameLabel:SetText("Vehicle Name:" )

    local VehicleNameTextEntry = vgui.Create("DTextEntry", VehicleNameRow)
    VehicleNameTextEntry:Dock( FILL )
    VehicleNameTextEntry:SetValue( tostring( VehicleBeingEdited["name"] ) )

    local VehicleClassButton = vgui.Create("DButton", VehicleNameRow)
    VehicleClassButton:Dock( RIGHT )
    VehicleClassButton:SetWide( 25 )
    VehicleClassButton:SetText("")
    VehicleClassButton:SetIcon("icon16/car.png")

    // VEHICLE MODEL
    -- local VehicleModelRow = vgui.Create("DPanel", MainFrame)
    -- VehicleModelRow:Dock( TOP )
    -- VehicleModelRow:DockMargin( 0, 0, 2, 5 )
    -- VehicleModelRow.Paint = function( self, w, h )
    --     --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    -- end

    -- local VehicleModelLabel = vgui.Create("DLabel", VehicleModelRow)
    -- VehicleModelLabel:Dock( LEFT )
    -- VehicleModelLabel:SetWide( LabelWith )
    -- VehicleModelLabel:SetText("Model:" )

    -- local VehicleModelTextEntry = vgui.Create("DTextEntry", VehicleModelRow)
    -- VehicleModelTextEntry:Dock( FILL )
    -- VehicleModelTextEntry:SetValue( tostring(The_Vehicle.Model or "") )

    // VEHICLE COST
    local VehicleCostRow = vgui.Create("DPanel", MainFrame)
    VehicleCostRow:Dock( TOP )
    VehicleCostRow:DockMargin( 0, 0, 2, 5 )
    VehicleCostRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleCostLabel = vgui.Create("DLabel", VehicleCostRow)
    VehicleCostLabel:Dock( LEFT )
    VehicleCostLabel:SetWide( LabelWith )
    VehicleCostLabel:SetText("Cost:" )

    local VehicleCostTextEntry = vgui.Create("DNumberWang", VehicleCostRow)
    VehicleCostTextEntry:Dock( FILL )
    VehicleCostTextEntry:SetMax( 2147483647 )
    VehicleCostTextEntry:SetValue( tonumber( VehicleBeingEdited["cost"] ) )


    // VEHICLE SIZE (Three checkboces; Small, Large, Air)
    local VehicleSizeRow = vgui.Create("DPanel", MainFrame)
    VehicleSizeRow:Dock( TOP )
    VehicleSizeRow:DockMargin( 0, 0, 2, 5 )
    VehicleSizeRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleSizeLabel = vgui.Create("DLabel", VehicleSizeRow)
    VehicleSizeLabel:Dock( LEFT )
    VehicleSizeLabel:SetWide( LabelWith )
    VehicleSizeLabel:SetText("Sizes:" )

    local VehicleSizeSmall = vgui.Create("DCheckBoxLabel", VehicleSizeRow)
    VehicleSizeSmall:Dock( LEFT )
    VehicleSizeSmall:SetText("Small")
    VehicleSizeSmall:SetValue( VehicleBeingEdited["sizes"]["small"] )

    local VehicleSizeLarge = vgui.Create("DCheckBoxLabel", VehicleSizeRow)
    VehicleSizeLarge:Dock( LEFT )
    VehicleSizeLarge:DockMargin( 30, 0, 30, 0 )
    VehicleSizeLarge:SetText("Large")
    VehicleSizeLarge:SetValue( VehicleBeingEdited["sizes"]["large"] )

    local VehicleSizeAir = vgui.Create("DCheckBoxLabel", VehicleSizeRow)
    VehicleSizeAir:Dock( LEFT )
    VehicleSizeAir:SetText("Air")
    VehicleSizeAir:SetValue( VehicleBeingEdited["sizes"]["air"] )

    // VEHICLE EDIT Loadouts Button
    local VehicleLoadoutsRow = vgui.Create("DPanel", MainFrame)
    VehicleLoadoutsRow:Dock( TOP )
    VehicleLoadoutsRow:SetTall( 35 )
    VehicleLoadoutsRow:DockMargin( 0, 15, 2, 0 )
    VehicleLoadoutsRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleLoadoutsButton = vgui.Create("DButton", VehicleLoadoutsRow)
    VehicleLoadoutsButton:Dock( FILL )
    VehicleLoadoutsButton:SetText("Edit Loadouts...")
    VehicleLoadoutsButton:SetIcon("icon16/bricks.png")

    VehicleLoadoutsButton:SetDisabled( true )

    VehicleLoadoutsButton.DoClick = function()

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenLoadoutEditor()

    end

    // VEHICLE SET ACCESS Button
    local VehicleSetAccessRow = vgui.Create("DPanel", MainFrame)
    VehicleSetAccessRow:Dock( TOP )
    VehicleSetAccessRow:SetTall( 35 )
    VehicleSetAccessRow:DockMargin( 0, 10, 2, 0 )
    VehicleSetAccessRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    local VehicleSetAccessButton = vgui.Create("DButton", VehicleSetAccessRow)
    VehicleSetAccessButton:Dock( FILL )
    VehicleSetAccessButton:SetText("Set Access...")
    VehicleSetAccessButton:SetIcon("icon16/user.png")

    VehicleSetAccessButton.DoClick = function()

        // Open the access editor.
        HALOARMORY.INTERFACE.ACCESS.Open( The_Vehicle.AccessList, function( NewAccessList ) 
        
            The_Vehicle.AccessList = NewAccessList

            --PrintTable( The_Vehicle.AccessList )

        end, "Authorization")

    end


    // VEHICLE SAVE Button
    local VehicleSaveRow = vgui.Create("DPanel", MainFrame)
    VehicleSaveRow:Dock( BOTTOM )
    VehicleSaveRow:SetTall( 35 )
    VehicleSaveRow:DockMargin( 0, 0, 2, 5 )
    VehicleSaveRow.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
    end

    VehicleSaveRow:InvalidateParent( true )

    local VehicleSaveButton = vgui.Create("DButton", VehicleSaveRow)
    VehicleSaveButton:Dock( LEFT )
    VehicleSaveButton:SetWide( VehicleSaveRow:GetWide() / 2 )
    VehicleSaveButton:SetText("Save")
    VehicleSaveButton:SetIcon("icon16/disk.png")

    VehicleSaveButton:SetDisabled( true )

    VehicleSaveButton.DoClick = function()

        --print( "Done! Save this vehicle:" )
        --PrintTable( VehicleBeingEdited )

        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Remove()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = nil

        HALOARMORY.VEHICLES.ADMIN_GUI.VehicleList = nil

        net.Start("HALOARMORY.VEHICLES.ADMIN")
            net.WriteString("SAVEVEHICLE")
            net.WriteTable( VehicleBeingEdited )
        net.SendToServer()

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI()

        VehicleBeingEdited = NewTemplateVehicle

    end

    local VehicleCancelButton = vgui.Create("DButton", VehicleSaveRow)
    VehicleCancelButton:Dock( RIGHT )
    VehicleCancelButton:SetWide( VehicleSaveRow:GetWide() / 2 )
    VehicleCancelButton:SetText("Cancel")
    VehicleCancelButton:SetIcon("icon16/cancel.png")

    VehicleCancelButton.DoClick = function()

        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Remove()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = nil

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI()

    end

    
    // DIVIDER 2
    local Divider2 = vgui.Create("DPanel", MainFrame)
    Divider2:Dock( BOTTOM )
    Divider2:DockMargin( 0, 0, 2, 5 )
    Divider2:SetTall( 1 )
    Divider2.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 40) )
    end




    local function UpdateAndCheckVehicleClass()
        local VehicleClass = VehicleClassTextEntry:GetValue()

        local Vehicle_Ent, VehicleModel, VehiclePrintName = HALOARMORY.Requisition.GetModelAndNameFromVehicle( VehicleBeingEdited["entity"] )

        if not Vehicle_Ent then
            VehicleClassButton:SetDisabled( true )
            VehicleSaveButton:SetDisabled( true )
            VehicleLoadoutsButton:SetDisabled( true )
        else
            VehicleClassButton:SetDisabled( false )
            VehicleSaveButton:SetDisabled( false )
            VehicleLoadoutsButton:SetDisabled( false )
        end

        local Filaneme = VehicleFileNameTextEntry:GetValue() ~= ""
        local VehicleName = VehicleNameTextEntry:GetValue() ~= ""
        local VehicleCost = VehicleCostTextEntry:GetValue() ~= ""

        if Filaneme and VehicleName and VehicleCost then
            --VehicleSaveButton:SetDisabled( false )
        else
            VehicleSaveButton:SetDisabled( true )
        end

    end


    local CursorPosSaved = VehicleFileNameTextEntry:GetCaretPos()
    VehicleFileNameTextEntry.OnChange = function( self )
        local newName = self:GetValue():lower():gsub( "[^%w_]", "_" )

        CursorPosSaved = self:GetCaretPos()
        self:SetText( newName )
        self:SetCaretPos( CursorPosSaved )

        VehicleBeingEdited["filename"] = newName

        UpdateAndCheckVehicleClass()
    end

    // Vehicle Class button
    VehicleClassButton.DoClick = function()

        local VehicleClass = VehicleClassTextEntry:GetValue()
        local Vehicle_Ent, VehicleModel, VehiclePrintName = HALOARMORY.Requisition.GetModelAndNameFromVehicle( VehicleClass )

        if VehiclePrintName then
            VehicleNameTextEntry:SetValue( tostring( VehiclePrintName ) )

            VehicleNameTextEntry:OnChange()
        end

        UpdateAndCheckVehicleClass()

    end

    VehicleClassTextEntry.OnChange = function( self )

        local VehicleClass = self:GetValue()
        VehicleBeingEdited["entity"] = VehicleClass

        UpdateAndCheckVehicleClass()

    end

    VehicleNameTextEntry.OnChange = function( self )

        local VehicleName = self:GetValue()
        VehicleBeingEdited["name"] = VehicleName

        UpdateAndCheckVehicleClass()

    end

    VehicleCostTextEntry.OnChange = function( self )

        local VehicleCost = VehicleCostTextEntry:GetValue()
        VehicleBeingEdited["cost"] = VehicleCost

        UpdateAndCheckVehicleClass()

    end

    VehicleSizeSmall.OnChange = function( self )

        local VehicleSizeSmallCheck = VehicleSizeSmall:GetChecked()
        VehicleBeingEdited["sizes"]["small"] = VehicleSizeSmallCheck

        UpdateAndCheckVehicleClass()

    end

    VehicleSizeLarge.OnChange = function( self )

        local VehicleSizeLargeCheck = VehicleSizeLarge:GetChecked()
        VehicleBeingEdited["sizes"]["large"] = VehicleSizeLargeCheck

        UpdateAndCheckVehicleClass()

    end

    VehicleSizeAir.OnChange = function( self )

        local VehicleSizeAirCheck = VehicleSizeAir:GetChecked()
        VehicleBeingEdited["sizes"]["air"] = VehicleSizeAirCheck

        UpdateAndCheckVehicleClass()

    end

    UpdateAndCheckVehicleClass()

end


function HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI( VehicleList )

    if not CAMI.PlayerHasAccess( LocalPlayer(), "HALOARMORY.Vehicle Editor" ) then
        chat.AddText( Color( 255, 0, 0 ), "You do not have access to this command!" )
        return "No Access!"
    end

    if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame then
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame:Remove()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame = nil
    end

    //VehicleList = VehicleList or {}

    local MainFrame = vgui.Create("DFrame")
    MainFrame:SetSize(300, 400)
    MainFrame:Center()
    MainFrame:SetTitle("HALOARMORY.VEHICLES.SELECTOR")
    MainFrame:MakePopup()

    MainFrame.OnClose = function()
        HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame = nil
        net.Start("HALOARMORY.VEHICLES.ADMIN")
            net.WriteString("MENUCLOSED")
        net.SendToServer()
    end

    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame = MainFrame

    if VehicleList == nil or not istable(VehicleList) then
        // Add a DLabel saying "Loading"
        local LoadingLabel = vgui.Create("DLabel", MainFrame)
        LoadingLabel:Dock( FILL )
        LoadingLabel:SetContentAlignment( 5 )
        LoadingLabel:SetText("Loading...")

        // Send net message to get all the vehicles.
        net.Start("HALOARMORY.VEHICLES.ADMIN")
            net.WriteString("GETVEHICLES")
        net.SendToServer()

        return

    end

    // List of all the vehicles on the left.
    local VehicleListScroll = vgui.Create("DScrollPanel", MainFrame)
    VehicleListScroll:Dock( FILL )
    --VehicleListScroll:SetWide( 250 )

    HALOARMORY.VEHICLES.ADMIN_GUI.VehicleListScroll = VehicleListScroll

    // Add a panel to add a new vehicle.
    local AddVehiclePanel = vgui.Create("DPanel", VehicleListScroll)
    AddVehiclePanel:Dock( TOP )
    AddVehiclePanel:DockMargin( 0, 0, 2, 5 )
    AddVehiclePanel:SetSize( 0, 30 )

    local AddVehicleButton = vgui.Create("DButton", AddVehiclePanel)
    AddVehicleButton:Dock( FILL )
    AddVehicleButton:SetText("Add Vehicle")
    AddVehicleButton:SetIcon("icon16/add.png")

    AddVehicleButton.DoClick = function()

        NewVehicle = true

        VehicleBeingEdited = NewTemplateVehicle

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenVehicleEditor()

    end

    for key, value in pairs(VehicleList) do
        
        local VehiclePanel = vgui.Create("DPanel", VehicleListScroll)
        VehiclePanel:Dock( TOP )
        VehiclePanel:DockMargin( 0, 0, 2, 5 )
        VehiclePanel:SetSize( 0, 30 )

        local VehicleEditButton = vgui.Create("DButton", VehiclePanel)
        VehicleEditButton:Dock( FILL )
        VehicleEditButton:SetText( tostring( value ) )
        VehicleEditButton:SetIcon("icon16/pencil.png")

        VehicleEditButton.DoClick = function()

            --HALOARMORY.VEHICLES.ADMIN_GUI.OpenVehicleEditor( value )

            NewVehicle = false

            net.Start("HALOARMORY.VEHICLES.ADMIN")
                net.WriteString("EDITVEHICLE")
                net.WriteString( value )
            net.SendToServer()

        end

        local VehicleRemoveButton = vgui.Create("DButton", VehiclePanel)
        VehicleRemoveButton:Dock( RIGHT )
        VehicleRemoveButton:SetText("")
        VehicleRemoveButton:SetIcon("icon16/delete.png")
        VehicleRemoveButton:SetWide( 30 )

        VehicleRemoveButton.DoClick = function()

            --HALOARMORY.VEHICLES.ADMIN_GUI.RemoveVehicle( value )

            net.Start("HALOARMORY.VEHICLES.ADMIN")
                net.WriteString("REMOVEVEHICLE")
                net.WriteString( value )
            net.SendToServer()

        end


        //print( value )

    end


end


net.Receive("HALOARMORY.VEHICLES.ADMIN", function( len )

    local Type = net.ReadString()

    if Type == "GETVEHICLES" then

        local VehicleList = net.ReadTable()

        HALOARMORY.VEHICLES.ADMIN_GUI.VehicleList = VehicleList

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI( VehicleList )

    elseif Type == "EDITVEHICLE" then

        --local VehicleName = net.ReadString()
        local VehicleTable = net.ReadTable()

        NewVehicle = false

        HALOARMORY.VEHICLES.ADMIN_GUI.OpenVehicleEditor( VehicleTable )

    end

end)


if CLIENT then
    concommand.Add("HALOARMORY.ManageVehicles", HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI )
end

list.Set( "DesktopWindows", "HALOARMORY.VEHICLES.ADMIN", {
    title = "Vehicles Editor",
    icon = "vgui/haloarmory/icons/anchor.png",
    init = function( icon, window )
        HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI()
    end,
})

if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame then
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame:Remove()
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrame = nil
    HALOARMORY.VEHICLES.ADMIN_GUI.OpenGUI( nil )
end

if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor then
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor:Remove()
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameEditor = nil
    HALOARMORY.VEHICLES.ADMIN_GUI.OpenVehicleEditor()
end

if HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameLoadoutEditor then
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameLoadoutEditor:Remove()
    HALOARMORY.VEHICLES.ADMIN_GUI.MainFrameLoadoutEditor = nil
    HALOARMORY.VEHICLES.ADMIN_GUI.OpenLoadoutEditor()
end