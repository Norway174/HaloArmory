HALOARMORY.MsgC("Client HALO SUPPLY Manage GUI Loading.")


HALOARMORY.Logistics = HALOARMORY.Logistics or {}
HALOARMORY.Logistics.Manager_GUI = HALOARMORY.Logistics.Manager_GUI or {}

local networks = {}




local function EditNetworkButton()
    local selected = HALOARMORY.Logistics.Manager_GUI.NetworkList:GetSelectedLine()
    if not selected then return end

    local NetworkName = HALOARMORY.Logistics.Manager_GUI.NetworkList:GetLine( selected ):GetValue( 1 )

    net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT" )
        net.WriteString( NetworkName )
    net.SendToServer()
end

local function DeleteNetworkButton()
    local selected = HALOARMORY.Logistics.Manager_GUI.NetworkList:GetSelectedLine()
    if not selected then return end

    local NetworkName = HALOARMORY.Logistics.Manager_GUI.NetworkList:GetLine( selected ):GetValue( 1 )

    Derma_Query(
        "Are you sure you want to delete the Network: \"" .. NetworkName .. "\"?\n(This cannot be undone!)",
        "Delete Network",
        "Yes, delete!",
        function() 
        
            net.Start( "HALOARMORY.Logistics.NETWORKS.REMOVE" )
            net.WriteString( NetworkName )
            net.SendToServer()

        end,
        "No, don't delete!"
    )
end


function HALOARMORY.Logistics.OpenNetworkEditorGUI( network )

        // Create a new VGUI
        HALOARMORY.Logistics.Manager_GUI.Edit = vgui.Create( "DFrame" )
        HALOARMORY.Logistics.Manager_GUI.Edit:SetSize( 250, 210 )
        HALOARMORY.Logistics.Manager_GUI.Edit:Center()
        HALOARMORY.Logistics.Manager_GUI.Edit:SetTitle( "SUPPLY EDITOR" )
        HALOARMORY.Logistics.Manager_GUI.Edit:SetVisible( true )
        HALOARMORY.Logistics.Manager_GUI.Edit:SetDraggable( true )
        HALOARMORY.Logistics.Manager_GUI.Edit:ShowCloseButton( true )
        HALOARMORY.Logistics.Manager_GUI.Edit:MakePopup()

        local old_network = table.Copy( network )

        local NetworkNameLabel = vgui.Create( "DLabel", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkNameLabel:Dock( TOP )
        NetworkNameLabel:SetText( "Network Name:" )

        local NetworkName = vgui.Create( "DTextEntry", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkName:Dock( TOP )
        NetworkName:SetUpdateOnType( true )
        NetworkName:SetText( network.Name )

        local MapOnlyLabel = vgui.Create( "DLabel", HALOARMORY.Logistics.Manager_GUI.Edit )
        MapOnlyLabel:Dock( TOP )
        MapOnlyLabel:SetText( "Only enable for ".. game.GetMap() ..":" )

        local MapOnlyPanel = vgui.Create( "DPanel", HALOARMORY.Logistics.Manager_GUI.Edit )
        MapOnlyPanel:Dock( TOP )
        MapOnlyPanel:SetTall( 20 )

        MapOnlyPanel.Paint = function( self, w, h )
        end

        local MapOnly = vgui.Create( "DCheckBox", MapOnlyPanel )
        MapOnly:SetValue( network.MapOnly )

        -- local NetworkMaxSuppliesEntry = vgui.Create( "DNumSlider", HALOARMORY.Logistics.Manager_GUI.Edit )
        -- NetworkMaxSuppliesEntry:Dock( TOP )
        -- NetworkMaxSuppliesEntry:SetText( "Max Supplies" )
        -- NetworkMaxSuppliesEntry:SetMin( 0 )
        -- NetworkMaxSuppliesEntry:SetMax( 999999999999 )
        -- NetworkMaxSuppliesEntry:SetDecimals( 0 )
        -- NetworkMaxSuppliesEntry:SetValue( network.MaxSupplies or 1000 )

        local NetworkMaxSuppliesLabel = vgui.Create( "DLabel", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkMaxSuppliesLabel:Dock( TOP )
        --NetworkMaxSuppliesLabel:SetText( "Max Supplies:" )


        local NetworkMaxSuppliesEntry = vgui.Create( "DNumberWang", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkMaxSuppliesEntry:Dock( TOP )
        // max 64 bit int is 9,223,372,036,854,775,808
        NetworkMaxSuppliesEntry:SetMinMax( 0, (1.7976931348623157 * 10^308) - 2 )
        NetworkMaxSuppliesEntry:SetMin( 0 )
        NetworkMaxSuppliesEntry:SetMax( (1.7976931348623157 * 10^308) - 2 )
        NetworkMaxSuppliesEntry:SetDecimals( 0 )
        NetworkMaxSuppliesEntry:SetValue( network.MaxSupplies or 1000 )

        NetworkMaxSuppliesLabel:SetText( "Max Supplies: " .. HALOARMORY.INTERFACE.PrettyFormatNumber( NetworkMaxSuppliesEntry:GetValue() ) )

        local NetworkSuppliesEntry = vgui.Create( "DNumSlider", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkSuppliesEntry:Dock( TOP )
        NetworkSuppliesEntry:SetText( "Supplies" )
        NetworkSuppliesEntry:SetMin( 0 )
        NetworkSuppliesEntry:SetMax( NetworkMaxSuppliesEntry:GetValue() )
        NetworkSuppliesEntry:SetDecimals( 0 )
        NetworkSuppliesEntry:SetValue( network.Supplies or 0 )

        MapOnly.OnChange = function( self, value )
            network.MapOnly = value
        end

        NetworkMaxSuppliesEntry.OnValueChanged = function( self, value )
            value = math.Round( value )
            value = math.Clamp( value, 0, self:GetMax() )
            NetworkSuppliesEntry:SetMax( value )
            NetworkSuppliesEntry:SetValue( math.Clamp( NetworkSuppliesEntry:GetValue(), 0, value ) )
            NetworkSuppliesEntry:ValueChanged( NetworkSuppliesEntry:GetValue() )

            NetworkMaxSuppliesLabel:SetText( "Max Supplies: " .. HALOARMORY.INTERFACE.PrettyFormatNumber( value ) )

            network.MaxSupplies = value
            return value
        end

        NetworkSuppliesEntry.OnValueChanged = function( self, value )
            value = math.Round( value )
            if ( value > NetworkMaxSuppliesEntry:GetValue() ) then
                self:SetValue( NetworkMaxSuppliesEntry:GetValue() )
            end
            network.Supplies = value
        end

        local NetworkSaveButton = vgui.Create( "DButton", HALOARMORY.Logistics.Manager_GUI.Edit )
        NetworkSaveButton:Dock( BOTTOM )
        NetworkSaveButton:SetText( "Save" )
        NetworkSaveButton.DoClick = function()
            local network_to_save = {}

            network_to_save.old_network = old_network
            network_to_save.new_network = network

            net.Start( "HALOARMORY.Logistics.NETWORKS.EDIT.SAVE" )
                net.WriteTable( network_to_save )
            net.SendToServer()

            HALOARMORY.Logistics.Manager_GUI.Edit:Close()
        end

        NetworkName.OnValueChange = function( self, value )
            if ( networks[value] ) then
                NetworkName:SetTextColor( Color( 255, 0, 0 ) )
                NetworkSaveButton:SetDisabled( true )
                return
            else
                NetworkName:SetTextColor( Color( 0, 0, 0) )
                NetworkSaveButton:SetDisabled( false )
            end

            // Set value to lowercase
            value = string.lower( value )

            // Replace spaces with underscores
            value = string.Replace( value, " ", "_" )

            network.Name = value
        end

end

function HALOARMORY.Logistics.OpenNetworkManagerGUI()

    // Create a new VGUI
    HALOARMORY.Logistics.Manager_GUI.Main = vgui.Create( "DFrame" )
    HALOARMORY.Logistics.Manager_GUI.Main:SetSize( 250, 350 )
    HALOARMORY.Logistics.Manager_GUI.Main:Center()
    HALOARMORY.Logistics.Manager_GUI.Main:SetTitle( "SUPPLY MANAGER" )
    HALOARMORY.Logistics.Manager_GUI.Main:SetVisible( true )
    HALOARMORY.Logistics.Manager_GUI.Main:SetDraggable( true )
    HALOARMORY.Logistics.Manager_GUI.Main:ShowCloseButton( true )
    HALOARMORY.Logistics.Manager_GUI.Main:MakePopup()

    net.Start( "HALOARMORY.Logistics.NETWORKS.GET" )
    net.SendToServer()

    HALOARMORY.Logistics.Manager_GUI.NetworkList = vgui.Create( "DListView", HALOARMORY.Logistics.Manager_GUI.Main )
    HALOARMORY.Logistics.Manager_GUI.NetworkList:Dock( FILL )
    HALOARMORY.Logistics.Manager_GUI.NetworkList:SetMultiSelect( false )
    HALOARMORY.Logistics.Manager_GUI.NetworkList:AddColumn( "Networks" )

    for k, v in pairs( networks ) do
        HALOARMORY.Logistics.Manager_GUI.NetworkList:AddLine( k )
    end

    local AddNetworkButton = vgui.Create( "DButton", HALOARMORY.Logistics.Manager_GUI.Main )
    AddNetworkButton:Dock( BOTTOM )
    AddNetworkButton:SetText( "Add Network" )

    AddNetworkButton.DoClick = function()
        local NetworkName = Derma_StringRequest( "Add Network", "Enter the name of the network you want to add.", "", function( text )
            if text == "" then return end
            if networks[ text ] then
                Derma_Message("The NetworkID has to be unique.", "Error creating Network", "OK")
                return
            end

            // Set value to lowercase
            text = string.lower( text )

            // Replace spaces with underscores
            text = string.Replace( text, " ", "_" )

            --HALOARMORY.Logistics.Manager_GUI.NetworkList:AddLine( text )
            
            net.Start( "HALOARMORY.Logistics.NETWORKS.ADD" )
                net.WriteString( text )
            net.SendToServer()

        end )
    end


    HALOARMORY.Logistics.Manager_GUI.NetworkList.OnRowRightClick = function( panel, line )
        // Add a right click menu
        local NetworkMenu = DermaMenu()

        local editNetwork = NetworkMenu:AddOption( "Edit Network", EditNetworkButton )
        editNetwork:SetIcon( "icon16/pencil.png" )

        NetworkMenu:AddSpacer()

        local deleteNetwork = NetworkMenu:AddOption( "Delete Network", DeleteNetworkButton )
        deleteNetwork:SetIcon( "icon16/delete.png" )

        NetworkMenu:Open()
    end

    function HALOARMORY.Logistics.Manager_GUI.NetworkList:DoDoubleClick( lineID, line )
        EditNetworkButton()
    end


end

net.Receive( "HALOARMORY.Logistics.NETWORKS.GET", function()
    if not HALOARMORY.Logistics.Manager_GUI.NetworkList then return end

    networks = net.ReadTable()

    // For each HALOARMORY.Logistics.Manager_GUI.NetworkList lines, remove them
    for k, v in pairs( HALOARMORY.Logistics.Manager_GUI.NetworkList:GetLines() ) do
        HALOARMORY.Logistics.Manager_GUI.NetworkList:RemoveLine( k )
    end

    for k, v in pairs( networks ) do
        HALOARMORY.Logistics.Manager_GUI.NetworkList:AddLine( k )
    end
end )

net.Receive( "HALOARMORY.Logistics.NETWORKS.ADD", function()
    if not HALOARMORY.Logistics.Manager_GUI.Main then return end

    networks = net.ReadTable()

    // For each HALOARMORY.Logistics.Manager_GUI.NetworkList lines, remove them
    for k, v in pairs( HALOARMORY.Logistics.Manager_GUI.NetworkList:GetLines() ) do
        HALOARMORY.Logistics.Manager_GUI.NetworkList:RemoveLine( k )
    end

    for k, v in pairs( networks ) do
        HALOARMORY.Logistics.Manager_GUI.NetworkList:AddLine( k )
    end
end )


net.Receive( "HALOARMORY.Logistics.NETWORKS.EDIT", function()
    local the_network = net.ReadTable()

    // Remove the devices from the network
    the_network.Devices = nil

    HALOARMORY.Logistics.OpenNetworkEditorGUI( the_network )
end )



--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]

-- if HALOARMORY.Logistics.Manager_GUI.Main then HALOARMORY.Logistics.Manager_GUI.Main:Remove() end

-- HALOARMORY.Logistics.OpenNetworkManagerGUI()