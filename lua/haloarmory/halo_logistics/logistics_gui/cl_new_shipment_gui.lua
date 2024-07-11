HALOARMORY.MsgC("HALO LOGISTICS NEW_SHIPMENT GUI Loading.")


HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Main_GUI = HALOARMORY.Logistics.Main_GUI or {}
HALOARMORY.Logistics.Main_GUI.NewShipment = HALOARMORY.Logistics.Main_GUI.NewShipment or {}

// Get all valid box entities
local BoxEnts = {
    "halo_sp_crate"
}

local controller_ent = controller_ent or nil
local controller_network = controller_network or {
    Name = "",
    Supplies = 0,
    MaxSupplies = 0,
    MapOnly = false,
}



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



function HALOARMORY.Logistics.Main_GUI.NewShipment.SelectCargo( ent, network, pallet )

    HALOARMORY.Logistics.Main_GUI.Menu:Hide()

    controller_ent = ent
    controller_network = network

    // Create a new VGUI element, to select a Pallet
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu = vgui.Create( "DFrame" )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetSize( 500, 500 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Center()
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetTitle( "" )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetVisible( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetDraggable( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:ShowCloseButton( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:MakePopup()

    function HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Init()
        self.startTime = SysTime()
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Paint = function(self, w, h)
        // Blur only behind the frame
        HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

        draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )

        draw.SimpleText( "Select a Cargo Box:", "default", 10, 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.OnClose = function()
        HALOARMORY.Logistics.Main_GUI.Menu:Show()
    end

    local think = HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Think
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Think = function(self)
        think(self)
        // Update the network table
        controller_network = util.JSONToTable( controller_ent:GetNetworkTable() )
    end


    // Create a dIcon layout to show the pallets
    // Start with a scroll bar
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll = vgui.Create( "DScrollPanel", HALOARMORY.Logistics.Main_GUI.CreateCargoMenu )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll:SetPos( 10, 35 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll:SetSize( 480, 455 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar:SetHideButtons( true )

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 112, 112, 112, 241) )
    end


    // Create a dIcon layout to show the pallets
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout = vgui.Create( "DIconLayout", HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetPos( 0, 0 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSize( 480, 455 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSpaceX( 5 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSpaceY( 5 )

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
    end



    // Create a button for each pallet
    for key, value in pairs(BoxEnts) do

        local ListItem = HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
        ListItem:SetSize( 450, 150 ) -- Set the size of it
        
        ListItem.Paint = function(self, w, h)
            draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        end

        ListItem.TheEntity = ents.CreateClientside( value )

        print( "Creating", value, ListItem.TheEntity, table.Random( ListItem.TheEntity.DeviceModelAlts ) )

        local randModel, ModelPath = table.Random( ListItem.TheEntity.DeviceModelAlts )

        // Create a dModelPanel to show the pallet
        ListItem.Model = vgui.Create( "DModelPanel", ListItem )
        ListItem.Model:SetPos( 5, 5 )
        ListItem.Model:SetSize( 110, 110 )
        ListItem.Model:SetModel( tostring(randModel and ModelPath or ListItem.TheEntity.DeviceModel) )
        ListItem.Model:SetCamPos( Vector( 50, 100, 100 ) )
        ListItem.Model:SetLookAt( Vector( 0, 0, 10 ) )
        ListItem.Model:SetFOV( 40 )
        ListItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetMouseInputEnabled( false )
        

        // Get the pallets name
        --local PalletName = value.GetDeviceName and value:GetDeviceName() or "Unknown"

        --PalletName = PalletName .. " \n" .. value:GetDeviceName()

        // Create a label for the pallets name
        ListItem.Name = vgui.Create( "DTextEntry", ListItem )
        ListItem.Name:SetPos( 125, 5 )
        ListItem.Name:SetSize( 320, 30 )
        ListItem.Name:SetText( ListItem.TheEntity.DeviceName )
        ListItem.Name:SetFont( "SP_QuanticoNormal" )
        ListItem.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
        ListItem.Name:SetPaintBackground( false )
        ListItem.Name:SetCursorColor( Color( 250, 250, 250) )

        local NamePaint = ListItem.Name.Paint
        ListItem.Name.Paint = function(self, w, h)
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
            NamePaint(self, w, h)
        end

        // Create a label for the pallets device name
        ListItem.DeviceName = vgui.Create( "DLabel", ListItem )
        ListItem.DeviceName:SetPos( 125, 35 )
        ListItem.DeviceName:SetSize( 325, 30 )
        ListItem.DeviceName:SetText( "Max Capacity: " .. HALOARMORY.INTERFACE.PrettyFormatNumber(ListItem.TheEntity.MaxCapacity) )
        ListItem.DeviceName:SetFont( "SP_QuanticoSmall" )
        ListItem.DeviceName:SetTextColor( Color( 87, 87, 87) )

        // Create a label for the pallets stored cargo
        -- ListItem.Stored = vgui.Create( "DLabel", ListItem )
        -- ListItem.Stored:SetPos( 110, 80 )
        -- ListItem.Stored:SetSize( 325, 30 )
        -- ListItem.Stored:SetText( "" )
        -- ListItem.Stored:SetFont( "SP_QuanticoSmall" )
        -- ListItem.Stored:SetTextColor( Color( 126, 126, 126) )
        -- ListItem.Stored:SetContentAlignment( 6 )

        // OnThink function to update the stored cargo
        -- ListItem.Think = function(self)

        -- end
        
        // Add a DNumSlider to select the amount of cargo to transfer
        ListItem.Slider = vgui.Create( "DNumSlider", ListItem )
        ListItem.Slider:SetPos( 125, 68 )
        ListItem.Slider:SetSize( 240, 30 )
        ListItem.Slider:SetText( "Amount to take:" )
        ListItem.Slider:SetMin( 0 )
        ListItem.Slider:SetMax( math.min(controller_network.Supplies, ListItem.TheEntity.MaxCapacity) )
        ListItem.Slider:SetDecimals( 0 )
        ListItem.Slider:SetValue( math.min(controller_network.Supplies, ListItem.TheEntity.MaxCapacity) )

        ListItem.Slider.Think = function(self)
            self:SetMax( math.min(controller_network.Supplies, ListItem.TheEntity.MaxCapacity) )
        end



        // Create a customize box button
        ListItem.Customize = vgui.Create( "DButton", ListItem )
        ListItem.Customize:SetPos( 5, 100 )
        ListItem.Customize:SetSize( 115, 45 )
        ListItem.Customize:SetText( "" )

        ListItem.Customize.Paint = function(self, w, h)
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 70, 70, 70, 210) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 37, 37, 37, 210) )
            end
            draw.SimpleText( "Customize", "SP_QuanticoSmall", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end

        ListItem.Customize.DoClick = function()
            // Create a new VGUI at the mouse position
            local CustomizeMenu_Container = vgui.Create( "DFrame" )
            CustomizeMenu_Container:SetSize( ScrW(), ScrH() )
            CustomizeMenu_Container:SetPos( 0, 0 )
            CustomizeMenu_Container:SetTitle( "" )
            CustomizeMenu_Container:SetVisible( true )
            CustomizeMenu_Container:SetDraggable( false )
            CustomizeMenu_Container:ShowCloseButton( false )
            CustomizeMenu_Container:MakePopup()

            function CustomizeMenu_Container:OnMousePressed()
                CustomizeMenu_Container:Close()
            end

            CustomizeMenu_Container.Paint = function(self, w, h)
                // Blur only behind the frame
                --HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
                --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
            end

            local CustomizeMenu = vgui.Create( "DFrame", CustomizeMenu_Container )
            CustomizeMenu:SetSize( 365, 350 )
            CustomizeMenu:SetPos( gui.MouseX(), gui.MouseY() )
            CustomizeMenu:SetTitle( "" )
            CustomizeMenu:SetVisible( true )
            CustomizeMenu:SetDraggable( false )
            CustomizeMenu:ShowCloseButton( false )


            function CustomizeMenu:Init()
                self.startTime = SysTime()
            end

            CustomizeMenu.Paint = function(self, w, h)
                // Blur only behind the frame
                HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

                --draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )
            end

            // Create a dIcon layout to show the box models
            // Start with a scroll bar

            CustomizeMenu.Scroll = vgui.Create( "DScrollPanel", CustomizeMenu )
            CustomizeMenu.Scroll:SetPos( 10, 10 )
            CustomizeMenu.Scroll:SetSize( CustomizeMenu:GetWide() - 20, CustomizeMenu:GetTall() - 20 )
            CustomizeMenu.Scroll.VBar:SetHideButtons( true )

            CustomizeMenu.Scroll.Paint = function(self, w, h)
                --draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 139, 241) )
            end

            CustomizeMenu.Scroll.VBar.Paint = function(self, w, h)
                draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
            end

            CustomizeMenu.Scroll.VBar.btnGrip.Paint = function(self, w, h)
                draw.RoundedBox( 0, 0, 0, w, h, Color( 112, 112, 112, 241) )
            end


            // Create a dIcon layout to show the pallets
            CustomizeMenu.IconLayout = vgui.Create( "DIconLayout", CustomizeMenu.Scroll )
            CustomizeMenu.IconLayout:SetPos( 0, 0 )
            CustomizeMenu.IconLayout:SetSize( CustomizeMenu:GetSize() )
            CustomizeMenu.IconLayout:SetSpaceX( 10 )
            CustomizeMenu.IconLayout:SetSpaceY( 10 )

            CustomizeMenu.IconLayout.Paint = function(self, w, h)
                --draw.RoundedBox( 0, 0, 0, w, h, Color( 192, 5, 5, 241) )
            end

            // Get all the boxes
            local boxModels = ListItem.TheEntity.DeviceModelAlts

            local sizeBox = 100

            // Create a button icon for each model
            for box_key, box_value in pairs(boxModels) do
                --print( "Creating", box_key )

                // box_key is the model path

                local BoxModelItem = CustomizeMenu.IconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
                BoxModelItem:SetSize( sizeBox, sizeBox ) -- Set the size of it

                BoxModelItem.Paint = function(self, w, h)
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
                end

                // Create a dModelPanel to show the pallet
                BoxModelItem.Model = vgui.Create( "DModelPanel", BoxModelItem )
                BoxModelItem.Model:SetPos( 0, 0 )
                BoxModelItem.Model:SetSize( sizeBox, sizeBox )
                BoxModelItem.Model:SetModel( box_key )
                BoxModelItem.Model:SetCamPos( Vector( 50, 100, 100 ) )
                BoxModelItem.Model:SetLookAt( Vector( 0, 0, 15 ) )
                BoxModelItem.Model:SetFOV( 40 )
                BoxModelItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
                --BoxModelItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
                --BoxModelItem.Model:SetMouseInputEnabled( false )

                // Create an invisible button to select the box
                BoxModelItem.Button = vgui.Create( "DButton", BoxModelItem )
                BoxModelItem.Button:SetPos( 0, 0 )
                BoxModelItem.Button:SetSize( sizeBox, sizeBox )
                BoxModelItem.Button:SetText( "" )

                BoxModelItem.Button.Paint = function(self, w, h)
                    if self:IsHovered() then
                        draw.RoundedBox( 0, 0, 0, w, h, Color( 63, 63, 63, 26) )
                    else
                        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 0) )
                    end
                end

                BoxModelItem.Button.DoClick = function()
                    ListItem.Model:SetModel( box_key )
                    ListItem.TheEntity.DeviceModel = box_key

                    CustomizeMenu_Container:Close()
                end

            end


        end


        // Create the spawn button
        ListItem.Button = vgui.Create( "DButton", ListItem )
        ListItem.Button:SetPos( 125, 100 )
        ListItem.Button:SetSize( 320, 45 )
        ListItem.Button:SetText( "" )
        
        ListItem.Button.Paint = function(self, w, h)
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 38, 76, 119, 210) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 210) )
            end
            draw.SimpleText( "Spawn Shipment!", "SP_QuanticoSmall", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end

        ListItem.Button.DoClick = function()
            
            local Pallet = pallet
            local CrateName = ListItem.Name:GetValue()
            local CrateModel = ListItem.Model:GetModel()
            local CrateAmount = ListItem.Slider:GetValue()


            print( "Creating", Pallet, CrateName, CrateModel, CrateAmount )

            net.Start( "HALOARMORY.Logistics.ACCESS.TakeSupplies" )
                net.WriteEntity( Pallet )
                net.WriteString( CrateName )
                net.WriteString( CrateModel )
                net.WriteInt( CrateAmount, 32 )
            net.SendToServer()

            HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Close()
            HALOARMORY.Logistics.Main_GUI.Menu:Show()
        end


    end

end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



function HALOARMORY.Logistics.Main_GUI.NewShipment.SelectPallet( ent, network )

    HALOARMORY.Logistics.Main_GUI.Menu:Hide()

    controller_ent = ent
    controller_network = network

    // Create a new VGUI element, to select a Pallet
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu = vgui.Create( "DFrame" )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetSize( 500, 500 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Center()
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetTitle( "" )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetVisible( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:SetDraggable( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:ShowCloseButton( true )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:MakePopup()

    function HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Init()
        self.startTime = SysTime()
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Paint = function(self, w, h)
        // Blur only behind the frame
        HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

        draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )

        draw.SimpleText( "Select a Cargo Pallet:", "default", 10, 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.OnClose = function()
        HALOARMORY.Logistics.Main_GUI.Menu:Show()
    end

    local think = HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Think
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Think = function(self)
        think(self)
        // Update the network table
        controller_network = util.JSONToTable( controller_ent:GetNetworkTable() )
    end

    // Create a dIcon layout to show the pallets
    // Start with a scroll bar
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll = vgui.Create( "DScrollPanel", HALOARMORY.Logistics.Main_GUI.CreateCargoMenu )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll:SetPos( 10, 35 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll:SetSize( 480, 455 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar:SetHideButtons( true )

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll.VBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 112, 112, 112, 241) )
    end


    // Create a dIcon layout to show the pallets
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout = vgui.Create( "DIconLayout", HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.Scroll )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetPos( 0, 0 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSize( 480, 455 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSpaceX( 5 )
    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:SetSpaceY( 5 )

    HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
    end

    // Get all the pallets
    local Pallets = ents.FindByClass( "halo_sp_cargo_access" )

    // Create a button for each pallet
    for key, value in pairs(Pallets) do
        if controller_network.Name ~= value:GetNetworkID() then continue end

        local ListItem = HALOARMORY.Logistics.Main_GUI.CreateCargoMenu.IconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
        ListItem:SetSize( 450, 120 ) -- Set the size of it
        
        ListItem.Paint = function(self, w, h)
            draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        end

        // Create a dModelPanel to show the pallet
        ListItem.Model = vgui.Create( "DModelPanel", ListItem )
        ListItem.Model:SetPos( 5, 5 )
        ListItem.Model:SetSize( 110, 110 )
        ListItem.Model:SetModel( value:GetModel() )
        ListItem.Model:SetCamPos( Vector( 50, 100, 100 ) )
        ListItem.Model:SetLookAt( Vector( 0, 0, 0 ) )
        ListItem.Model:SetFOV( 50 )
        ListItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetMouseInputEnabled( false )

        // Get the pallets name
        local PalletName = value.GetDeviceName and value:GetDeviceName() or "Unknown"

        --PalletName = PalletName .. " \n" .. value:GetDeviceName()

        // Create a label for the pallets name
        ListItem.Name = vgui.Create( "DLabel", ListItem )
        ListItem.Name:SetPos( 125, 5 )
        ListItem.Name:SetSize( 325, 30 )
        ListItem.Name:SetText( PalletName )
        ListItem.Name:SetFont( "SP_QuanticoNormal" )
        ListItem.Name:SetTextColor( Color( 255, 255, 255, 255 ) )

        // Create a label for the pallets device name
        ListItem.DeviceName = vgui.Create( "DLabel", ListItem )
        ListItem.DeviceName:SetPos( 125, 35 )
        ListItem.DeviceName:SetSize( 325, 30 )
        ListItem.DeviceName:SetText( value:GetNetworkID() )
        ListItem.DeviceName:SetFont( "SP_QuanticoSmall" )
        ListItem.DeviceName:SetTextColor( Color( 87, 87, 87) )

        // Create a label for the pallets stored cargo
        ListItem.Stored = vgui.Create( "DLabel", ListItem )
        ListItem.Stored:SetPos( 110, 80 )
        ListItem.Stored:SetSize( 325, 30 )
        ListItem.Stored:SetText( "" )
        ListItem.Stored:SetFont( "SP_QuanticoSmall" )
        ListItem.Stored:SetTextColor( Color( 126, 126, 126) )
        ListItem.Stored:SetContentAlignment( 6 )

        // OnThink function to update the stored cargo
        ListItem.Think = function(self)
            if tobool(#value:ScanPad()) then
                ListItem.Stored:SetText( "Spawn blocked!" )
                ListItem.Stored:SetTextColor( Color( 158, 0, 0) )
            else
                ListItem.Stored:SetText( "Spawn clear!" )
                ListItem.Stored:SetTextColor( Color( 0, 158, 0) )
            end
        end
        


        // Create an invisible button to select the pallet
        ListItem.Button = vgui.Create( "DButton", ListItem )
        ListItem.Button:SetPos( 0, 0 )
        ListItem.Button:SetSize( 450, 120 )
        ListItem.Button:SetText( "" )
        
        ListItem.Button.Paint = function(self, w, h)
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 63, 63, 63, 26) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 0) )
            end
        end

        ListItem.Button.DoClick = function()
            HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Remove()
            HALOARMORY.Logistics.Main_GUI.NewShipment.SelectCargo( controller_ent, controller_network, value )
        end


    end

end