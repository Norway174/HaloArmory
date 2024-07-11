HALOARMORY.MsgC("Client HALO DOOR Loadout GUI Loading.")


HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.ACCESS = HALOARMORY.INTERFACE.ACCESS or {}
HALOARMORY.INTERFACE.ACCESS.GUI = HALOARMORY.INTERFACE.ACCESS.GUI or {}


local ScrWi, ScrHe = math.min(ScrW() - 10, 350), math.min(ScrH() - 10, 550)
--ScrWi, ScrHe = 800, 600

hook.Add( "OnScreenSizeChanged", "HALOARMORY.INTERFACE.ACCESS.OnSizeChange", function( oldWidth, oldHeight )
    ScrWi, ScrHe = math.min(ScrW() - 10, 350), math.min(ScrH() - 10, 550)
end )

local ICON_ENABLED = "icon16/accept.png"
local ICON_DISABLED = "icon16/cross.png"
local ICON_SOME = "icon16/asterisk_yellow.png"

local AccessList = {}

--[[ 
################################
||                            ||
||            TAB:            ||
||           DarkRP           ||
||                            ||
################################
 ]]

local NodesList = {}

local function DarkRP_JobCat( instance, AccessListDarkRP )

    local tab_panel = {}
    tab_panel[instance] = vgui.Create( "DPanel" )

    local nodeTree  = vgui.Create( "DTree", tab_panel[instance] )
    nodeTree:Dock( FILL )
    nodeTree:SetClickOnDragHover( true )

    NodesList[instance] = {}


    for key, cat in pairs( DarkRP.getCategories().jobs ) do
        local cat_name = cat.name

        NodesList[instance][cat_name] = nodeTree:AddNode( cat.name )

        NodesList[instance][cat.name]["jobs"] = {}
        NodesList[instance][cat.name]["on_click"] = {
            ["type"] = "category",
            ["name"] = cat.name,
        }

        for key2, job in pairs(cat.members) do

            local job_name = job.name
            
            NodesList[instance][cat.name]["jobs"][job_name] = NodesList[instance][cat_name]:AddNode( job.name )
            NodesList[instance][cat.name]["jobs"][job_name]["on_click"] = {
                ["type"] = "job",
                ["name"] = job.name,
            }

        end

    end

    local function UpdateTree()
        for _, node_cat in pairs( NodesList[instance] ) do
            --print( node_cat )
            --PrintTable( node_cat["on_click"] )

            AccessListDarkRP = AccessListDarkRP or {}
            AccessListDarkRP["categories"] = AccessListDarkRP["categories"] or {}
            AccessListDarkRP["jobs"] = AccessListDarkRP["jobs"] or {}

            local node_name = node_cat["on_click"]["name"]
            local node_type = node_cat["on_click"]["type"]

            local cat_icon = ICON_DISABLED
            if AccessListDarkRP["categories"][node_name] then
                cat_icon = ICON_ENABLED
            end

            node_cat:SetIcon( cat_icon )

            for _, node_job in pairs( node_cat["jobs"] ) do
                --PrintTable( node_job["on_click"] )

                local job_name = node_job["on_click"]["name"]
                local job_icon = ICON_DISABLED

                if node_cat:GetIcon() == ICON_ENABLED then
                    job_icon = ICON_ENABLED
                elseif AccessListDarkRP["jobs"][job_name] then
                    job_icon = ICON_ENABLED
                    node_cat:SetIcon( ICON_SOME )
                end
                
                node_job:SetIcon( job_icon )

            end
        end
    end

    UpdateTree()


    function nodeTree:OnNodeSelected( node )
        --print( node["on_click"]["name"] )
        --print("---------------------")
        --PrintTable( node["on_click"] )

        local node_data = node["on_click"]
        local node_type = node_data["type"]
        local node_name = node_data["name"]

        local node_action = nil

        if node:GetIcon() == ICON_DISABLED or node:GetIcon() == ICON_SOME then
            node_action = true
        end

        if node_type == "category" then
            
            AccessListDarkRP["categories"][node_name] = node_action

        elseif node_type == "job" then
            AccessListDarkRP["jobs"][node_name] = node_action

        end

        --PrintTable( AccessList )

        UpdateTree()

    end


    return tab_panel[instance]

end


--[[ 
################################
||                            ||
||            TAB:            ||
||            MRS             ||
||                            ||
################################
 ]]

 local function UpdateList( AppList )

    local AccessListMRS_2 = {}


    local lines = AppList:GetLines() or {}

    for k, line in pairs( lines ) do
        AccessListMRS_2[line:GetValue( 1 )] = line:GetValue( 2 )
    end

    return AccessListMRS_2

end

local AppList = {}

local function MRS_Groups( instance, AccessListMRS )
    -- MRS.Ranks

    -- Build the GUI

    local tab_panel = {}
    tab_panel[instance] = vgui.Create( "DPanel" )

    AppList[instance] = vgui.Create( "DListView", tab_panel[instance] )
    AppList[instance]:Dock( FILL )
    AppList[instance]:SetMultiSelect( true )
    AppList[instance]:AddColumn( "Branch" )
    AppList[instance]:AddColumn( "Rank" )


    local AddItemPanel = vgui.Create( "DPanel", tab_panel[instance] )
    AddItemPanel:Dock( BOTTOM )

    local AddBranchCombo = vgui.Create( "DComboBox", AddItemPanel )
    AddBranchCombo:Dock( LEFT )
    AddBranchCombo:SetWidth( ScrWi * .4)
    AddBranchCombo:SetValue( "Select..." )

    local Wang = vgui.Create( "DNumberWang", AddItemPanel )
    Wang:Dock( LEFT )
    Wang:SetWidth( ScrWi * .2)
    Wang:SetMin( 0 )
    Wang:SetMax( 1 )
    Wang:SetEnabled( false )


    local add_button = vgui.Create( "DButton", AddItemPanel )
    add_button:SetText( "Add" )
    add_button:Dock(FILL)
    add_button:SetEnabled( false )


    local delete_button = vgui.Create( "DButton", AddItemPanel )
    delete_button:SetText( "" )
    delete_button:SetImage( "icon16/bin.png" )
    delete_button:Dock(RIGHT)
    delete_button:SetWidth( 30 )
    delete_button:SetEnabled( false )


    -- Populate the GUI with the ranks

    local ranks = table.Copy(AccessListMRS["group"] or {})

    for branch, rank in pairs( ranks ) do
        AppList[instance]:AddLine( branch, rank )
    end
    for branch, rank in pairs( MRS.Ranks ) do
        ranks[branch] = #rank.ranks
    end


    for key, branch in pairs( ranks ) do
        AddBranchCombo:AddChoice( key, branch )
    end

    -- GUI Functions


    function add_button:DoClick()

        local ValueExists = nil
        local ValueLine = 0

        if IsValid(AppList[instance]) and AppList[instance]:GetSelectedLine() then
            AppList[instance]:ClearSelection()
        end

        local lines = AppList[instance]:GetLines() or {}

        for k, line in ipairs( lines ) do
            if not IsValid( line ) then continue end

            if line:GetValue( 1 ) == AddBranchCombo:GetValue() then
                ValueExists = line
                ValueLine = line:GetValue( 2 )

                AppList[instance]:SelectItem( line )
            end
        end

        if ValueExists then
            ValueExists:SetColumnText( 2, Wang:GetValue() )
        else
            local line = AppList[instance]:AddLine( AddBranchCombo:GetValue(), Wang:GetValue() )

            line:SetSelected( true )
        end

        delete_button:SetEnabled( true )
        add_button:SetText( "Update" )

        AccessListMRS["group"] = UpdateList( AppList[instance] )

    end



    AddBranchCombo.OnSelect = function( self, index, value, data )

        local ValueExists = false
        local ValueLine = 0

        // Fucking dumb. I hate this function.
        local succ, err = pcall(function() AppList[instance]:ClearSelection() end)


        local lines = AppList[instance]:GetLines() or {}

        for k, line in pairs( lines ) do
            if line:GetValue( 1 ) == value then
                ValueExists = true
                ValueLine = line:GetValue( 2 )

                AppList[instance]:SelectItem( line )
            end
        end

        if ValueExists then
            delete_button:SetEnabled( true )
            add_button:SetText( "Update" )
        else
            delete_button:SetEnabled( false )
            add_button:SetText( "Add" )
        end

        Wang:SetMax( isnumber(data) and data or 100 )
        Wang:SetValue( ValueLine )
        Wang:SetEnabled( true )
        add_button:SetEnabled( true )

        AccessListMRS["group"] = UpdateList( AppList[instance] )

        --print( " Test" )
        --PrintTable( AccessListMRS )
    end


    function delete_button:DoClick()

        local toDelete = AppList[instance]:GetSelected()

        for _, value in pairs(toDelete) do
            AppList[instance]:RemoveLine( value:GetID() )
        end

        if #AppList[instance]:GetSelected() >= 0 then
            Wang:SetValue( 0 )
            Wang:SetEnabled( false )
            add_button:SetEnabled( false )
            add_button:SetText( "Add" )

            delete_button:SetEnabled( false )
        end

        if AddBranchCombo:GetSelected() then
            Wang:SetValue( 0 )
            Wang:SetMax( 10 )
            Wang:SetEnabled( true )
            add_button:SetEnabled( true )
        end

        AccessListMRS["group"] = UpdateList( AppList[instance] )
        
    end


    AppList[instance].DoDoubleClick = function( panel, rowIndex, row )

        AddBranchCombo:SetValue( row:GetValue( 1 ) )
        Wang:SetMax( #MRS.Ranks[row:GetValue( 1 )].ranks or 100 )
        Wang:SetValue( row:GetValue( 2 ) )
        Wang:SetEnabled( true )
        add_button:SetEnabled( true )
        add_button:SetText( "Update" )

        delete_button:SetEnabled( true )

        AccessListMRS["group"] = UpdateList( AppList[instance] )
    end

    AccessListMRS["group"] = UpdateList( AppList[instance] )

    return tab_panel[instance]

end


--[[ 
################################
||                            ||
||            TAB:            ||
||          Sandbox           ||
||                            ||
################################
 ]]

local function Sandbox_tab( instance, AccessListDarkRP )

    local tab_panel = {}
    
    tab_panel[instance] = vgui.Create( "DPanel" )

    local textLabelSandbox = vgui.Create( "DLabel", tab_panel[instance] )
    textLabelSandbox:SetColor( Color(0, 0, 0) )
    textLabelSandbox:SetText( "Sandbox is not supported yet." )
    textLabelSandbox:SizeToContents()
    textLabelSandbox:SetPos( 50, 50 )

    return tab_panel[instance]

end

--[[ 
################################
||                            ||
||            TAB:            ||
||          Override          ||
||                            ||
################################
 ]]

local function OverrideGroup(AccessList_Override)

    local override_tabs = vgui.Create( "DPropertySheet" )
    override_tabs:Dock( FILL )

    --AccessList["_Override"] = AccessList["_Override"] or {}

    if DarkRP then
        if AccessList_Override["DarkRP"] == nil then AccessList_Override["DarkRP"] = {} end
        override_tabs:AddSheet( "DarkRP", DarkRP_JobCat( 2, AccessList_Override["DarkRP"] ), "icon16/user.png", false, false )
    end

    if MRS then
        if AccessList_Override["MRS"] == nil then AccessList_Override["MRS"] = {} end
        override_tabs:AddSheet( "MRS Ranks", MRS_Groups( 2, AccessList_Override["MRS"] ), "icon16/award_star_gold_2.png", false, false )
    end

    return override_tabs

end

--[[ 
################################
||                            ||
||       Initialize GUI       ||
||                            ||
################################
 ]]

function HALOARMORY.INTERFACE.ACCESS.Open( CurrentAccess, callback, _override )

    HALOARMORY.INTERFACE.ACCESS.GUI.Menu = vgui.Create( "DFrame" )
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:SetSize( ScrWi, ScrHe ) 
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:Center()
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:SetTitle( "Access Configurator" ) 
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:SetVisible( true ) 
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:SetDraggable( true ) 
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:ShowCloseButton( true ) 
    HALOARMORY.INTERFACE.ACCESS.GUI.Menu:MakePopup()


    local tabs = vgui.Create( "DPropertySheet", HALOARMORY.INTERFACE.ACCESS.GUI.Menu )
    tabs:Dock( FILL )

    AccessList = table.Copy(CurrentAccess) or {
        ["DarkRP"] = {},
        ["MRS"] = {},
        ["_Override"] = {
            ["DarkRP"] = {},
            ["MRS"] = {},
        },
    }

    --PrintTable( AccessList )

    if engine.ActiveGamemode() == "sandbox" then
        tabs:AddSheet( "Sandbox", Sandbox_tab( 1 ), "icon16/box.png", false, false )
    end
    
    if DarkRP then
        if AccessList["DarkRP"] == nil then AccessList["DarkRP"] = {} end
        tabs:AddSheet( "DarkRP", DarkRP_JobCat( 1, AccessList["DarkRP"] ), "icon16/user.png", false, false )
    end

    if MRS then
        if AccessList["MRS"] == nil then AccessList["MRS"] = {} end
        tabs:AddSheet( "MRS Ranks", MRS_Groups( 1, AccessList["MRS"] ), "icon16/award_star_gold_2.png", false, false )
    end

    _override = _override or "Override"

    if AccessList["_Override"] == nil then AccessList["_Override"] = {} end
    tabs:AddSheet( _override, OverrideGroup(AccessList["_Override"] ), "icon16/key.png", false, false )


    
    
    local bottom_panel = vgui.Create( "DPanel", HALOARMORY.INTERFACE.ACCESS.GUI.Menu )
    bottom_panel:Dock( BOTTOM )
    function bottom_panel:Paint( w, h )
    end
    
    local save_button = vgui.Create( "DButton", bottom_panel )
    save_button:SetText( "Save" )
    save_button:Dock(FILL)
    save_button:SetColor( Color(255, 255, 255) )
    function save_button:Paint( w, h )
        draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 20, 117, 0) )
    end

    function save_button:DoClick()
        //ent:SetAccessTable( AccessList )

        if callback and isfunction(callback) then
            callback( AccessList )
        end

        print("Saved access list:")
        PrintTable( AccessList )

        AccessList = {}
        NodesList = {}
        if HALOARMORY.INTERFACE.ACCESS.GUI.Menu then HALOARMORY.INTERFACE.ACCESS.GUI.Menu:Remove() end
    end


    
    local cancel_button = vgui.Create( "DButton", bottom_panel )
    cancel_button:SetText( "Cancel" )
    cancel_button:Dock(RIGHT)
    cancel_button:SetWidth( ScrWi * .4)
    cancel_button:SetColor( Color(255, 255, 255) )

    function cancel_button:Paint( w, h )
        draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 117, 0, 0) )
    end

    function cancel_button:DoClick()
        AccessList = {}
        NodesList = {}
        if HALOARMORY.INTERFACE.ACCESS.GUI.Menu then HALOARMORY.INTERFACE.ACCESS.GUI.Menu:Remove() end
    end

end

--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]

-- if HALOARMORY.INTERFACE.ACCESS.GUI.Menu then HALOARMORY.INTERFACE.ACCESS.GUI.Menu:Remove() end
-- AccessList = {}
-- NodesList = {}
-- HALOARMORY.INTERFACE.ACCESS.Open( ents.FindByClass( "frigate_door" )[1] )
