HALOARMORY.MsgC("HALO LOGISTICS TRANSFER GUI Loading.")


HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Main_GUI = HALOARMORY.Logistics.Main_GUI or {}
HALOARMORY.Logistics.Main_GUI.Transfer = HALOARMORY.Logistics.Main_GUI.Transfer or {}


local SelectedPallet = SelectedPallet or nil

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



local function GetCargoPallets()

        // Get all the cargo boxes
        local Tmp_CargoPallet = {}
        if SelectedPallet == nil then
            Tmp_CargoPallet = ents.FindByClass( "halo_sp_cargo_access" )
        else
            Tmp_CargoPallet = { SelectedPallet }
        end
    
        local CargoPallets = {}
        // Remove all pallets that are not in the same network.
        for _, Pallet in pairs(Tmp_CargoPallet) do
            if not IsValid(Pallet) then continue end
            if controller_network.Name ~= Pallet:GetNetworkID() then continue end
    
            table.insert( CargoPallets, Pallet )
        end

        return CargoPallets
end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



local function VariableFillCargo_Slider( parent, box, cargo_pallet_ent )

        if !IsValid( box ) then return end
        if !IsValid( parent ) then return end

        // Create a new VGUI at the mouse position
        local CustomizeMenu_Container = vgui.Create( "DFrame" )
        CustomizeMenu_Container:SetSize( ScrW(), ScrH() )
        CustomizeMenu_Container:SetPos( 0, 0 )
        CustomizeMenu_Container:SetTitle( "" )
        CustomizeMenu_Container:SetVisible( true )
        CustomizeMenu_Container:SetDraggable( false )
        CustomizeMenu_Container:ShowCloseButton( false )
        CustomizeMenu_Container:MakePopup()

        

        CustomizeMenu_Container.Paint = function(self, w, h)
            // Blur only behind the frame
            --HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
            --draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )
        end

        local CustomizeMenu = vgui.Create( "DFrame", CustomizeMenu_Container )
        CustomizeMenu:SetSize( 300, 110 )
        CustomizeMenu:SetPos( gui.MouseX(), gui.MouseY() )
        CustomizeMenu:SetTitle( "" )
        CustomizeMenu:SetVisible( true )
        CustomizeMenu:SetDraggable( false )
        CustomizeMenu:ShowCloseButton( false )


        function CustomizeMenu:Init()
            self.startTime = SysTime()
        end

        CustomizeMenu.Paint = function(self, w, h)
            if not IsValid( parent ) then CustomizeMenu_Container:Close() end

            // Blur only behind the frame
            HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

            --draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )
        end
        
        function CustomizeMenu_Container:OnMousePressed()
            CustomizeMenu_Container:Close()
            --CustomizeMenu:Close()
        end


        // Create a slider to select the amount of supplies to take
        CustomizeMenu.Slider = vgui.Create( "DNumSlider", CustomizeMenu )
        CustomizeMenu.Slider:SetPos( 10, 0 )
        CustomizeMenu.Slider:SetSize( 280, 50 )
        CustomizeMenu.Slider:SetText( "Supplies" )
        --CustomizeMenu.Slider:SetMin( 0 )
        --CustomizeMenu.Slider:SetMax( math.min(box:GetMaxCapacity(), controller_network.Supplies ) )
        CustomizeMenu.Slider:SetDecimals( 0 )
        --CustomizeMenu.Slider:SetValue( box:GetStored() )
        CustomizeMenu.Slider:SetMin( -box:GetStored() )
        CustomizeMenu.Slider:SetMax( math.min(box:GetMaxCapacity() - box:GetStored(), controller_network.Supplies ) )
        CustomizeMenu.Slider:SetValue( 0 )


        CustomizeMenu.Slider.Label:SetFont( "SP_QuanticoNormal" )
        CustomizeMenu.Slider.Label:SetTextColor( Color( 255, 255, 255, 255 ) )

        // Create an apply button
        CustomizeMenu.ApplyButton = vgui.Create( "DButton", CustomizeMenu )
        CustomizeMenu.ApplyButton:SetPos( 10, 50 )
        CustomizeMenu.ApplyButton:SetSize( 280, 50 )
        CustomizeMenu.ApplyButton:SetText( "" )

        CustomizeMenu.ApplyButton.Paint = function(self, w, h)
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 116, 6, 210) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 80, 11, 156) )
            end

            draw.SimpleText( "Apply", "HudHintTextLarge", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end

        CustomizeMenu.ApplyButton.DoClick = function()
            if not IsValid( box ) then CustomizeMenu_Container:Close() return end

            local getStored = 0
            local getMaxCapacity = 0

            getStored = box.GetStored and box:GetStored() or 0
            getMaxCapacity = box.GetMaxCapacity and box:GetMaxCapacity() or 0

            local value = CustomizeMenu.Slider:GetValue()

            if value == 0 then return end

            if value > 0 then
                if value > controller_network.Supplies then return end
                if value > (getMaxCapacity - getStored) then return end
            else
                if math.abs(value) > getStored then return end
            end

            print( "Transfering " .. value .. " supplies" )

            net.Start( "HALOARMORY.Logistics.ACCESS.TransferSupplies" )
                net.WriteEntity( cargo_pallet_ent )
                net.WriteEntity( box )
                net.WriteInt( -value, 32 ) // Plus number to add to network
            net.SendToServer()

            CustomizeMenu_Container:Close()
        end

end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



local function CargoBoxPanel_Item( cargo_box, cargo_pallet_ent )
    
    local ListItem = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
    ListItem:SetSize( 330, 100 ) -- Set the size of it

    ListItem.CargoBox = cargo_box

    ListItem.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
    end

    // Create a dModelPanel to show the cargo box
    ListItem.Model = vgui.Create( "DModelPanel", ListItem )
    ListItem.Model:SetPos( 5, 5 )
    ListItem.Model:SetSize( 90, 90 )
    ListItem.Model:SetModel( ListItem.CargoBox:GetModel() )
    ListItem.Model:SetCamPos( Vector( 50, 100, 100 ) )
    ListItem.Model:SetLookAt( Vector( 0, 0, 18 ) )
    ListItem.Model:SetFOV( 35 )
    ListItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
    ListItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
    ListItem.Model:SetMouseInputEnabled( false )

    -- ListItem.Model.Paint_org = ListItem.Model.Paint
    -- ListItem.Model.Paint = function(self, w, h)
    --     draw.RoundedBox( 0, 0, 0, w, h, Color( 12, 12, 12, 157) )
    --     ListItem.Model.Paint_org(self, w, h)
    -- end

    // Create a label for the cargo boxes name
    ListItem.Name = vgui.Create( "DLabel", ListItem )
    ListItem.Name:SetPos( 100, 5 )
    ListItem.Name:SetSize( 250, 30 )
    ListItem.Name:SetText( ListItem.CargoBox:GetBoxName() )
    ListItem.Name:SetFont( "SP_QuanticoNormal" )
    ListItem.Name:SetTextColor( Color( 255, 255, 255, 255 ) )

    // Create a label for the cargo boxes stored cargo
    ListItem.Stored = vgui.Create( "DLabel", ListItem )
    ListItem.Stored:SetPos( 100, 35 )
    ListItem.Stored:SetSize( 250, 30 )
    ListItem.Stored:SetText( ListItem.CargoBox:GetStored() .. " / " .. ListItem.CargoBox:GetMaxCapacity())
    ListItem.Stored:SetFont( "SP_QuanticoSmall" )
    ListItem.Stored:SetTextColor( Color( 126, 126, 126) )

    ListItem.Stored.Think = function(self)
        if not IsValid(ListItem.CargoBox) then return end

        local getStored = 0
        local getMaxCapacity = 0

        getStored = ListItem.CargoBox.GetStored and ListItem.CargoBox:GetStored() or 0
        getMaxCapacity = ListItem.CargoBox.GetMaxCapacity and ListItem.CargoBox:GetMaxCapacity() or 0

        self:SetText( HALOARMORY.INTERFACE.PrettyFormatNumber(getStored) .. " / " .. HALOARMORY.INTERFACE.PrettyFormatNumber(getMaxCapacity))
    end

    // Create a label for the cargo boxes max cargo
    ListItem.Max = vgui.Create( "DLabel", ListItem )
    ListItem.Max:SetPos( 100, 65 )
    ListItem.Max:SetSize( 250, 30 )
    ListItem.Max:SetText( "" )
    ListItem.Max:SetFont( "SP_QuanticoSmall" )
    ListItem.Max:SetTextColor( Color( 126, 126, 126) )


    // Create a button to take all supplies
    ListItem.TakeAllButtonMain = vgui.Create( "DButton", ListItem )
    ListItem.TakeAllButtonMain:SetPos( 100, 65 )
    ListItem.TakeAllButtonMain:SetSize( 70, 30 )
    ListItem.TakeAllButtonMain:SetText( "" )
    
    ListItem.TakeAllButtonMain.Paint = function(self, w, h)
        local getStored = 0
        local getMaxCapacity = 0

        if IsValid(ListItem.CargoBox) then
            getStored = ListItem.CargoBox.GetStored and ListItem.CargoBox:GetStored() or 0
            getMaxCapacity = ListItem.CargoBox.GetMaxCapacity and ListItem.CargoBox:GetMaxCapacity() or 0
        end

        if getStored == 0 then
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 116, 0, 0, 210) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 0, 0, 156) )
            end

            draw.SimpleText( "Remove", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        else
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 21, 116, 210) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 37, 80, 156) )
            end

            draw.SimpleText( "Empty", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end
    end

    ListItem.TakeAllButtonMain.DoClick = function()
        if ListItem.CargoBox:GetStored() <= 0 then
            // Todo: Remove the cargo box
            net.Start( "HALOARMORY.Logistics.ACCESS.DeleteCargoBox" )
                net.WriteEntity( ListItem.CargoBox )
                net.WriteBool( false )
            net.SendToServer()
        else
            
            net.Start( "HALOARMORY.Logistics.ACCESS.TransferSupplies" )
                net.WriteEntity( cargo_pallet_ent )
                net.WriteEntity( ListItem.CargoBox )
                net.WriteInt( ListItem.CargoBox:GetStored(), 32 ) // Plus number to add to network
            net.SendToServer()

        end
    end

    // Create a button to take a variable amount of supplies
    ListItem.TakeVariableButtonMain = vgui.Create( "DButton", ListItem )
    ListItem.TakeVariableButtonMain:SetPos( 177, 65 )
    ListItem.TakeVariableButtonMain:SetSize( 71, 30 )
    ListItem.TakeVariableButtonMain:SetText( "" )

    ListItem.TakeVariableButtonMain.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 21, 116, 210) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 37, 80, 156) )
        end

        draw.SimpleText( "#", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    ListItem.TakeVariableButtonMain.DoClick = function()
        VariableFillCargo_Slider( ListItem.TakeVariableButtonMain, ListItem.CargoBox, cargo_pallet_ent )
    end

    // Create a button to fill the cargo boxes
    ListItem.FillButtonMain = vgui.Create( "DButton", ListItem )
    ListItem.FillButtonMain:SetPos( 255, 65 )
    ListItem.FillButtonMain:SetSize( 70, 30 )
    ListItem.FillButtonMain:SetText( "" )

    ListItem.FillButtonMain.Paint = function(self, w, h)
        local getStored = 0
        local getMaxCapacity = 0

        if IsValid(ListItem.CargoBox) then
            getStored = ListItem.CargoBox.GetStored and ListItem.CargoBox:GetStored() or 0
            getMaxCapacity = ListItem.CargoBox.GetMaxCapacity and ListItem.CargoBox:GetMaxCapacity() or 0
        end

        if getStored == getMaxCapacity or controller_network.Supplies <= 0 then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 80, 80, 210) )
        elseif self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 21, 116, 210) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 37, 80, 156) )
        end

        draw.SimpleText( "Fill", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    ListItem.FillButtonMain.DoClick = function()
        if ListItem.CargoBox:GetStored() == ListItem.CargoBox:GetMaxCapacity() then return end

        net.Start( "HALOARMORY.Logistics.ACCESS.TransferSupplies" )
            net.WriteEntity( cargo_pallet_ent )
            net.WriteEntity( ListItem.CargoBox )
            net.WriteInt( -(ListItem.CargoBox:GetMaxCapacity() - ListItem.CargoBox:GetStored()), 32 ) // Plus number to add to network
        net.SendToServer()
    end

    return ListItem

end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



local function FillCargoList_GUI( ent, network )

    if !IsValid( HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout ) then return end

    local childs = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:GetChildren()
    for k, v2 in pairs(childs) do
        if v2 then
            v2:Remove()
        end
    end

    // Add an - ALL - option to the top of the list
    local AllListCargoBoxItem = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
    AllListCargoBoxItem:SetSize( 330, 100 ) -- Set the size of it

    AllListCargoBoxItem.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        --draw.SimpleText( "- ALL -", "SP_QuanticoNormal", 50, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    // Create a model panel to show the controller model.
    AllListCargoBoxItem.Model = vgui.Create( "DModelPanel", AllListCargoBoxItem )
    AllListCargoBoxItem.Model:SetPos( 5, 5 )
    AllListCargoBoxItem.Model:SetSize( 90, 90 )
    --AllListCargoBoxItem.Model:SetEntity( "halo_sp_controller" )
    AllListCargoBoxItem.Model:SetModel( "models/valk/h4/unsc/props/terminal/terminal_small.mdl" )
    AllListCargoBoxItem.Model:SetCamPos( Vector( 40, 100, 100 ) )
    AllListCargoBoxItem.Model:SetLookAt( Vector( 0, 0, 25 ) )
    AllListCargoBoxItem.Model:SetFOV( 45 )
    AllListCargoBoxItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
    AllListCargoBoxItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
    AllListCargoBoxItem.Model:SetMouseInputEnabled( false )


    // Create a label for the network name
    AllListCargoBoxItem.Name = vgui.Create( "DLabel", AllListCargoBoxItem )
    AllListCargoBoxItem.Name:SetPos( 100, 5 )
    AllListCargoBoxItem.Name:SetSize( 250, 30 )
    AllListCargoBoxItem.Name:SetText( ent:GetDeviceName() )
    AllListCargoBoxItem.Name:SetFont( "SP_QuanticoNormal" )
    AllListCargoBoxItem.Name:SetTextColor( Color( 255, 255, 255, 255 ) )

    // Create a label for the supplies amount
    AllListCargoBoxItem.Stored = vgui.Create( "DLabel", AllListCargoBoxItem )
    AllListCargoBoxItem.Stored:SetPos( 100, 35 )
    AllListCargoBoxItem.Stored:SetSize( 250, 30 )
    AllListCargoBoxItem.Stored:SetText( controller_network.Supplies .. " / " .. controller_network.MaxSupplies )
    AllListCargoBoxItem.Stored:SetFont( "SP_QuanticoSmall" )
    AllListCargoBoxItem.Stored:SetTextColor( Color( 126, 126, 126) )

    AllListCargoBoxItem.Stored.Think = function(self)
        self:SetText( HALOARMORY.INTERFACE.PrettyFormatNumber(controller_network.Supplies) .. " / " .. HALOARMORY.INTERFACE.PrettyFormatNumber(controller_network.MaxSupplies) )
    end


    // Create a button to take all supplies
    AllListCargoBoxItem.TakeAllButtonMain = vgui.Create( "DButton", AllListCargoBoxItem )
    AllListCargoBoxItem.TakeAllButtonMain:SetPos( 100, 65 )
    AllListCargoBoxItem.TakeAllButtonMain:SetSize( 70, 30 )
    AllListCargoBoxItem.TakeAllButtonMain:SetText( "" )

    AllListCargoBoxItem.TakeAllButtonMain.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 21, 116, 210) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 37, 80, 156) )
        end

        draw.SimpleText( "Empty All", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    AllListCargoBoxItem.TakeAllButtonMain.DoClick = function()
        // Get all the cargo boxes
        local CargoPallet = GetCargoPallets()

        // Add all cargo boxes that are not in the list
        for _, Pallet in pairs(CargoPallet) do

            local CargoBoxes = Pallet:ScanPad()

            for _, box in pairs(CargoBoxes) do

                net.Start( "HALOARMORY.Logistics.ACCESS.TransferSupplies" )
                    net.WriteEntity( Pallet )
                    net.WriteEntity( box )
                    net.WriteInt( box:GetStored(), 32 ) // Plus number to add to network
                net.SendToServer()

            end

        end

    end

    // Create a button to take a variable amount of supplies
    AllListCargoBoxItem.TakeVariableButtonMain = vgui.Create( "DButton", AllListCargoBoxItem )
    AllListCargoBoxItem.TakeVariableButtonMain:SetPos( 177, 65 )
    AllListCargoBoxItem.TakeVariableButtonMain:SetSize( 71, 30 )
    AllListCargoBoxItem.TakeVariableButtonMain:SetText( "" )

    AllListCargoBoxItem.TakeVariableButtonMain.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 116, 0, 0, 210) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 0, 0, 156) )
        end

        draw.SimpleText( "Remove All", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    AllListCargoBoxItem.TakeVariableButtonMain.DoClick = function()
        // Get all the cargo boxes
        local CargoPallet = GetCargoPallets()

        // Add all cargo boxes that are not in the list
        for _, Pallet in pairs(CargoPallet) do

            local CargoBoxes = Pallet:ScanPad()

            for _, box in pairs(CargoBoxes) do

                if box:GetStored() != 0 then continue end

                net.Start( "HALOARMORY.Logistics.ACCESS.DeleteCargoBox" )
                    net.WriteEntity( box )
                    net.WriteBool( false )
                net.SendToServer()

            end

        end

    end

    // Create a button to fill the cargo boxes
    AllListCargoBoxItem.FillButtonMain = vgui.Create( "DButton", AllListCargoBoxItem )
    AllListCargoBoxItem.FillButtonMain:SetPos( 255, 65 )
    AllListCargoBoxItem.FillButtonMain:SetSize( 70, 30 )
    AllListCargoBoxItem.FillButtonMain:SetText( "" )

    AllListCargoBoxItem.FillButtonMain.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 21, 116, 210) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 37, 80, 156) )
        end

        draw.SimpleText( "Fill All", "default", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    AllListCargoBoxItem.FillButtonMain.DoClick = function()
        // Get all the cargo boxes
        local CargoPallet = GetCargoPallets()

        // Add all cargo boxes that are not in the list
        for _, Pallet in pairs(CargoPallet) do

            local CargoBoxes = Pallet:ScanPad()

            for _, box in pairs(CargoBoxes) do

                net.Start( "HALOARMORY.Logistics.ACCESS.TransferSupplies" )
                    net.WriteEntity( Pallet )
                    net.WriteEntity( box )
                    net.WriteInt( -(box:GetMaxCapacity() - box:GetStored()), 32 ) // Plus number to add to network
                net.SendToServer()

            end

        end

    end


    // Get all the cargo boxes
    local CargoPallet = GetCargoPallets()

    // Create a list of all the cargo boxes
    local addedCargoBoxes = {}

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout.Think = function(self)
        local panel_items = self:GetChildren()

        // Remove first entry from panel_items, because it's the - ALL - entry
        table.remove(panel_items, 1)
    
        // Remove all invalid cargo boxes
        for key, value in pairs(panel_items) do
            if not IsValid(value.CargoBox) then
                value:Remove()
            end
        end


        // Add all cargo boxes that are not in the list
        for _, Pallet in pairs(CargoPallet) do
            if not IsValid(Pallet) then continue end

            local CargoBoxes = Pallet:ScanPad()

            for _, box in pairs(CargoBoxes) do

                local found = false
                for k, v2 in pairs(panel_items) do
                    if v2.CargoBox == box then
                        found = true
                        break
                    end
                end

                if not found then
                    CargoBoxPanel_Item( box, Pallet )
                end
            end

        end

        // Remove all cargo boxes that are not on the pallet
        for key, value in pairs(panel_items) do

            local notFound = false
            for _, Pallet in pairs(CargoPallet) do
                if not IsValid(Pallet) then continue end
                --if notFound then break end

                local CargoBoxes = Pallet:ScanPad()

                for k, v2 in pairs(CargoBoxes) do
                    if value.CargoBox == v2 then
                        notFound = true
                        break 
                    end
                end

            end

            if not notFound then
                value:Remove()
            end

        end

    end
    

end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



local function FillPalletList_GUI( ent, network )

    // Check if HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout is valid, if not return
    if !IsValid( HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout ) then return end


    local childs = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:GetChildren()
    for k, child in pairs(childs) do
        if child then
            child:Remove()
        end
    end
    

    // Add an - ALL - option to the top of the list
    local AllListItem = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
    AllListItem:SetSize( 100, 100 ) -- Set the size of it

    AllListItem.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        if SelectedPallet == nil then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 5, 41, 82, 241) )
        end
        draw.SimpleText( "- ALL -", "SP_QuanticoNormal", w * .5, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    // Create an invisible button to select the pallet
    AllListItem.Button = vgui.Create( "DButton", AllListItem )
    AllListItem.Button:SetPos( 0, 0 )
    AllListItem.Button:SetSize( 100, 100 )
    AllListItem.Button:SetText( "" )

    AllListItem.Button.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 63, 63, 63, 26) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 0) )
        end
    end

    AllListItem.Button.DoClick = function()
        SelectedPallet = nil
        FillCargoList_GUI( ent, network )
    end

    // Get all Pallets
    local Pallets = ents.FindByClass( "halo_sp_cargo_access" )

    // Add each pallet to the list
    for key, value in pairs(Pallets) do
        
        if controller_network.Name ~= value:GetNetworkID() then continue end

        local ListItem = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:Add( "DPanel" ) -- Add DPanel to the DIconLayout
        ListItem:SetSize( 100, 100 ) -- Set the size of it

        ListItem.Paint = function(self, w, h)
            draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
            if SelectedPallet == value then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 5, 41, 82, 241) )
            end
        end

        // Create a dModelPanel to show the pallet
        ListItem.Model = vgui.Create( "DModelPanel", ListItem )
        ListItem.Model:SetPos( 5, 5 )
        ListItem.Model:SetSize( 90, 90 )
        ListItem.Model:SetModel( value:GetModel() )
        ListItem.Model:SetCamPos( Vector( 50, 100, 100 ) )
        ListItem.Model:SetLookAt( Vector( 0, 0, 10 ) )
        ListItem.Model:SetFOV( 50 )
        ListItem.Model:SetAmbientLight( Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255, 255 ) )
        ListItem.Model:SetMouseInputEnabled( false )

        // Create an invisible button to select the pallet
        ListItem.Button = vgui.Create( "DButton", ListItem )
        ListItem.Button:SetPos( 0, 0 )
        ListItem.Button:SetSize( 100, 100 )
        ListItem.Button:SetText( "" )

        ListItem.Button.Paint = function(self, w, h)
            if self:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, Color( 63, 63, 63, 26) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 54, 116, 0) )
            end

            draw.SimpleText( value:GetDeviceName(), "SP_QuanticoSmall", w * .5, 3, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
        end

        ListItem.Button.DoClick = function()
            SelectedPallet = value

            FillCargoList_GUI( ent, network )
        end

    end


end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



function HALOARMORY.Logistics.Main_GUI.Transfer.TransferGUI( ent, _network )
    // Create a new VGUI element to transfer the supplies into storage

    HALOARMORY.Logistics.Main_GUI.Menu:Hide()

    SelectedPallet = nil

    controller_ent = ent

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu = vgui.Create( "DFrame" )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:SetSize( 500, 500 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:Center()
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:SetTitle( "" )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:SetVisible( true )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:SetDraggable( true )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:ShowCloseButton( true )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:MakePopup()

    function HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:Init()
        self.startTime = SysTime()
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Paint = function(self, w, h)
        // Blur only behind the frame
        HALOARMORY.Logistics.Main_GUI.RenderBlur( self, 1, 3, 250 )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 241) )

        draw.RoundedBox( 0, 0, 0, w, 25, Color( 0, 0, 0, 241) )

        draw.SimpleText( "Transfer Supplies", "default", 10, 12, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.OnClose = function()
        HALOARMORY.Logistics.Main_GUI.Menu:Show()
    end

    local think = HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Think
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Think = function(self)
        think(self)
        // Update the network table
        controller_network = util.JSONToTable( ent:GetNetworkTable() )
    end

    // Add a label above the pallet list
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label = vgui.Create( "DLabel", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetPos( 10, 30 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetSize( 120, 30 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetText( "" )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        draw.SimpleText( "Pallet:", "SP_QuanticoNormal", 3, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    // Create a dIcon layout to show the pallets
    // Start with a scroll bar
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll = vgui.Create( "DScrollPanel", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll:SetPos( 10, 65 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll:SetSize( 120, 425 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar:SetHideButtons( true )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 39, 167, 167, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 112, 112, 112, 241) )
    end


    // Create a dIcon layout to show the pallets
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout = vgui.Create( "DIconLayout", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:SetPos( 0, 0 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:SetSize( 100, 455 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:SetSpaceX( 5 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout:SetSpaceY( 5 )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.PalletsIconLayout.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 124, 31, 31, 241) )
    end

    // Create a new collumn for the cargo boxes
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn = vgui.Create( "DPanel", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn:SetPos( 140, 30 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn:SetSize( 350, 460 )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 124, 31, 31, 241) )
    end

    // Add a label above the cargo list
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label = vgui.Create( "DLabel", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetPos( 0, 0 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetSize( 380, 30 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label:SetText( "" )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Label.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
        draw.SimpleText( "Cargo:", "SP_QuanticoNormal", 3, h * .5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    // Create a dIcon layout to show the cargo
    // Start with a scroll bar
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll = vgui.Create( "DScrollPanel", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoCollumn )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll:SetPos( 0, 35 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll:SetSize( 350, 425 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar:SetHideButtons( true )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 39, 167, 167, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 29, 29, 29, 241) )
    end

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll.VBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color( 112, 112, 112, 241) )
    end


    // Create a dIcon layout to show the cargo
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout = vgui.Create( "DIconLayout", HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.Scroll )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:SetPos( 0, 0 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:SetSize( 330, 425 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:SetSpaceX( 5 )
    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout:SetSpaceY( 5 )

    HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu.CargoListIconLayout.Paint = function(self, w, h)
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 124, 31, 31, 241) )
    end


    FillPalletList_GUI( ent, _network )

    FillCargoList_GUI( ent, _network )


end



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
]]
-- local function OpenDebugMenuByLooking()
--     if HALOARMORY.Logistics.Main_GUI.Menu then HALOARMORY.Logistics.Main_GUI.Menu:Remove() end
--     if HALOARMORY.Logistics.Main_GUI.CreateCargoMenu then HALOARMORY.Logistics.Main_GUI.CreateCargoMenu:Remove() end
--     if HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu then HALOARMORY.Logistics.Main_GUI.Transfer.TransferSuppliesMenu:Remove() end

--     local trace_ent = LocalPlayer():GetEyeTrace().Entity
--     if not IsValid( trace_ent ) then return end
--     --print( "Opening Debug Menu", trace_ent, trace_ent.DeviceType )
--     if trace_ent.DeviceType ~= "controller" then return end

--     --local network = trace_ent:GetNetworkTable()
--     --network = util.JSONToTable( network )

--     controller_network = util.JSONToTable( trace_ent:GetNetworkTable() )

--     HALOARMORY.Logistics.Main_GUI.LoadAccessGUI( trace_ent, controller_network )

--     --CreateANewShipmentGUI_SelectPallet( trace_ent, network )
--     HALOARMORY.Logistics.Main_GUI.Transfer.TransferGUI( trace_ent )
-- end
-- OpenDebugMenuByLooking()