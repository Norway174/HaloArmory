HALOARMORY.MsgC("Client HALO AI Manager GUI Loading.")


HALOARMORY.AI = HALOARMORY.AI or {}
HALOARMORY.AI.Manager_GUI = HALOARMORY.AI.Manager_GUI or {}


// Design document and flowchart for the AI Manager GUI: 
// When you open the GUI, you will get presented with two options:
// - Edit the AI
// - Edit the Map Defintions

// When you click on "Edit the AI", you will get presented with a list of AI's that you can edit. Or make a new one.
// When you click on "Edit the Map Definitions", you will get presented with a list of maps that you can edit. Or make a new one. Or edit/make one for the current map.

// When you edit an AI, you will get a window with two tabs:

    // The AI TAB

    // We need the following options for the user to edit: 
    // - API Key.
    // - Toggle whether or not the AI is enabled.
    // - AI Name.
    // - AI Color. (Default to Red)
    // - Model. (Defaults to gpt-3.5-turbo)
    // - Token limit. (Default to 256)
    // - AI Global Prompt. (Default to "You are a Halo UNSC AI. Your name is {AI Name}. You are currently in the {map name} map.")
    // - List of Commands with the following options: 
    // - - Text input for the command.
    // - - Text field for the input prompt. (Default to "{player} says: {message}")
    // - - Toggle whether or not the command is shown publicly.


    // The AI History TAB

    // This will show a list of all the messages between the AI and the user.
    // The first entry in the list will always be the AI Global Prompt.
    // Messages will be shown in the following format:
    // [Role] | [Tokens] | [content]

    // The user will be able to edit the messages in the list;
    // The Role will be a drop-down menu with the following options: assistant, user.
    // The tokens will be a label with the amount of tokens this message would cost, using the EstimateTokens function.
    // The content will be a text input field with the message.


local the_AI_placeholder = {
    ["API"] = "secret key",
    ["enabled"] = true,
    ["name"] = "Aurora",
    ["color"] = Color( 255, 0, 0 ),
    ["model"] = "gpt-3.5-turbo",
    ["token_limit"] = 4096,
    ["global_prompt"] = [[You are an UNSC AI called {ai-name} in the Halo Universe.
Your task is to assist the UNSC personnel in whatever their task or mission may be.
{map-details}
There are several key personnel available: {players}

Please treat the person speaking with respect to their rank, and refer to them by their rank.
Always stay in character. Refrain from asking questions. Any information that isn't provided, make up with your knowledge of the halo universe.
-----------------]],
    ["commands"] = {
        ["!ai"] = {
            ["prompt"] = "{player} says: {message}",
            ["access"] = "public"
        },
        ["!gm-ai"] = {
            ["prompt"] = "Event: {message}",
            ["access"] = "gm"
        }
    },
    ["history"] = {
        { role = "user", content = "This is a sample sentence to estimate tokens." },
        { role = "user", content = "MCPO Zoey McKenzie: Hello Aurora. Status check?" },
        { role = "assistant", content = "Aurora: Hello MCPO McKenzie. All systems are functioning within normal parameters. Is there anything specific you would like me to check or assist you with?" },
        { role = "user", content = "Event: A ship is approaching. Likely hostile." },
        { role = "assistant", content = "Aurora: Attention crew. An unknown vessel is detected on course. Please be advised." },
        { role = "user", content = "MCPO Zoey McKenzie: Copy that, Aurora. Engage the self-defenses! Raise the alarm!" },
        { role = "assistant", content = "Aurora: Initiating ship-wide alarm and activating self-defense systems. All crew members, brace for potential combat. Implementing defensive measures now." },
        { role = "user", content = "Event: The hostile ship starts opening fire on you." },
        { role = "assistant", content = "Aurora: Red alert! Hostile ship has begun firing. Initiating evasive maneuvers and deploying countermeasures to minimize damage. Transmitting target data to our weapons systems for retaliatory action. All personnel, take cover and prepare for engagement." },
        { role = "user", content = "Event: The counter measures are successful. And the hostile ship is destroyed." },
        { role = "assistant", content = "Aurora: Situation update: Countermeasures successfully neutralized the hostile ship. Enemy vessel has been destroyed. Returning systems to normal operations. Assessing for potential remaining threats and damage to our ship. Stand by for further updates." },
    }
}


function HALOARMORY.AI.Manager_GUI.OpenAIGUI( the_AI )

    // Check if the user is an admin
    if !LocalPlayer():IsAdmin() then
        HALOARMORY.MsgC("You are not an admin, you cannot use this command.")
        chat.AddText( Color( 255, 0, 0 ), "You are not an admin, you cannot use this command." )
        return
    end

    
    the_AI = the_AI or {}


    // Create a new VGUI
    HALOARMORY.AI.Manager_GUI.MainWindow = vgui.Create( "DFrame" )
    HALOARMORY.AI.Manager_GUI.MainWindow:SetSize( 400, 400 )
    HALOARMORY.AI.Manager_GUI.MainWindow:Center()
    HALOARMORY.AI.Manager_GUI.MainWindow:SetTitle( "AI EDITOR" )
    HALOARMORY.AI.Manager_GUI.MainWindow:SetVisible( true )
    HALOARMORY.AI.Manager_GUI.MainWindow:SetDraggable( true )
    HALOARMORY.AI.Manager_GUI.MainWindow:ShowCloseButton( true )
    HALOARMORY.AI.Manager_GUI.MainWindow:MakePopup()

    // Add two panels and a tab to select between them. One tab is called "AI" and the is called "AI History".
    HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder = vgui.Create( "DPropertySheet", HALOARMORY.AI.Manager_GUI.MainWindow )
    HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder:SetPos( 10, 70 )
    HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder:SetSize( 380, 320 )

    HALOARMORY.AI.Manager_GUI.MainWindow.AI = vgui.Create( "DPanel", HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder )
    HALOARMORY.AI.Manager_GUI.MainWindow.AI:SetPos( 5, 5 )
    HALOARMORY.AI.Manager_GUI.MainWindow.AI:SetSize( 370, 290 )

    HALOARMORY.AI.Manager_GUI.MainWindow.AIHistory = vgui.Create( "DPanel", HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder )
    HALOARMORY.AI.Manager_GUI.MainWindow.AIHistory:SetPos( 5, 5 )
    HALOARMORY.AI.Manager_GUI.MainWindow.AIHistory:SetSize( 370, 290 )

    HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder:AddSheet( "AI", HALOARMORY.AI.Manager_GUI.MainWindow.AI, "icon16/user.png", false, false, "Manage AI" )
    HALOARMORY.AI.Manager_GUI.MainWindow.TabHolder:AddSheet( "AI History", HALOARMORY.AI.Manager_GUI.MainWindow.AIHistory, "icon16/comments.png", false, false, "Manage AI History" )

    // Add the AI options to the AI panel.

    // Scroll container
    local ScrollContainer = vgui.Create( "DScrollPanel", HALOARMORY.AI.Manager_GUI.MainWindow.AI )
    ScrollContainer:Dock( FILL )
    ScrollContainer:SetSize( 370, 290 )

    // API Key Label
    local APIKey_Label = vgui.Create( "DLabel", ScrollContainer )
    APIKey_Label:SetPos( 10, 10 )
    APIKey_Label:SetColor( Color( 0, 0, 0 ) )
    APIKey_Label:SetText( "API Key:" )

    // API Key
    local APIKey_TextInput = vgui.Create( "DTextEntry", ScrollContainer )
    APIKey_TextInput:SetPos( 60, 10 )
    APIKey_TextInput:SetSize( 280, 20 )
    APIKey_TextInput:SetText( the_AI.API or "" )

    // Enabled Label
    local Enabled_Label = vgui.Create( "DLabel", ScrollContainer )
    Enabled_Label:SetPos( 10, 33 )
    Enabled_Label:SetColor( Color( 0, 0, 0 ) )
    Enabled_Label:SetText( "Enabled:" )

    // Enabled checkbox
    local Enabled_Checkbox = vgui.Create( "DCheckBox", ScrollContainer )
    Enabled_Checkbox:SetPos( 60, 35 )
    Enabled_Checkbox:SetValue( the_AI.enabled or true )


    // AI Model Label
    local Model_Label = vgui.Create( "DLabel", ScrollContainer )
    Model_Label:SetPos( ScrollContainer:GetWide() - 150 - 30 - 50, 35 )
    Model_Label:SetColor( Color( 0, 0, 0 ) )
    Model_Label:SetText( "AI Model:" )

    // AI Model dropdown selector
    // Possible options: gpt-3.5-turbo
    local Model_Selector = vgui.Create( "DComboBox", ScrollContainer )
    Model_Selector:SetPos( ScrollContainer:GetWide() - 150 - 30, 35 )
    Model_Selector:SetSize( 150, 20 )
    Model_Selector:SetValue( the_AI.model or "gpt-3.5-turbo" )
    Model_Selector:AddChoice( "gpt-3.5-turbo" )

    // AI Token Limit
    local TokenLimiter_Input = vgui.Create( "DNumSlider", ScrollContainer )
    TokenLimiter_Input:SetPos( 10, 55 )
    TokenLimiter_Input:SetSize( 340, 20 )
    TokenLimiter_Input:SetText( "Token Limit" )
    TokenLimiter_Input:SetMin( 1 )
    TokenLimiter_Input:SetMax( 4096 )
    TokenLimiter_Input:SetDecimals( 0 )
    TokenLimiter_Input:SetValue( the_AI.token_limit or 256 )
    TokenLimiter_Input:SetDark( true )
    


    // AI Name Label
    local AIName_Label = vgui.Create( "DLabel", ScrollContainer )
    AIName_Label:SetPos( 10, 80 )
    AIName_Label:SetColor( Color( 0, 0, 0 ) )
    AIName_Label:SetText( "AI Name:" )

    // AI Name text entry
    local AIName_Input = vgui.Create( "DTextEntry", ScrollContainer )
    AIName_Input:SetPos( 60, 80 )
    AIName_Input:SetSize( 150, 20 )
    AIName_Input:SetText( the_AI.name or "" )

    // AI Color
    // Display a color box with the current color of the AI. Then you can click the box to open a color picker window.
    local AIColor_Box = vgui.Create( "DButton", ScrollContainer )
    AIColor_Box:SetPos( ScrollContainer:GetWide() - 20 - 30, 80 )
    AIColor_Box:SetSize( 20, 20 )
    AIColor_Box:SetText( "" )
    AIColor_Box.Color = the_AI.color or Color( 255, 0, 0 )
    AIColor_Box.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
        draw.RoundedBox( 0, 1, 1, w-2, h-2, AIColor_Box.Color )
    end

    AIColor_Box.DoClick = function()
        local ColorPickerWindow = vgui.Create( "DFrame" )
        ColorPickerWindow:SetSize( 220, 280 )
        ColorPickerWindow:Center()
        ColorPickerWindow:SetTitle( "AI Color Picker" )
        ColorPickerWindow:SetVisible( true )
        ColorPickerWindow:SetDraggable( true )
        ColorPickerWindow:ShowCloseButton( true )
        ColorPickerWindow:MakePopup()

        local colorPicker = vgui.Create( "DColorMixer", ColorPickerWindow )
        colorPicker:SetPalette( true )
        colorPicker:SetAlphaBar( false )
        colorPicker:SetWangs( true )
        colorPicker:SetColor( the_AI.color or Color( 255, 0, 0 ) )
        colorPicker:SetPos( 10, 35 )
        colorPicker:SetSize( 200, 200 )
        colorPicker:SetAlpha( 255 )
        
        local colorSaveButton = vgui.Create( "DButton", ColorPickerWindow )
        colorSaveButton:SetText( "Save Color" )
        colorSaveButton:SetPos( 10, 240 )
        colorSaveButton:SetSize( 200, 30 )
        colorSaveButton.DoClick = function()
            AIColor_Box.Color = colorPicker:GetColor()
            ColorPickerWindow:Close()
        end
    end

    // AI Global Prompt Label
    local AIGlobalPrompt_Label = vgui.Create( "DLabel", ScrollContainer )
    AIGlobalPrompt_Label:SetPos( 10, 110 )
    AIGlobalPrompt_Label:SetSize( 350, 20 )
    AIGlobalPrompt_Label:SetColor( Color( 0, 0, 0 ) )
    AIGlobalPrompt_Label:SetText( "AI Global Prompt:" )


    // AI Global Prompt
    local AIGlobalPrompt_Input = vgui.Create( "DTextEntry", ScrollContainer )
    AIGlobalPrompt_Input:SetPos( 10, 130 )
    AIGlobalPrompt_Input:SetSize( 330, 75 )
    AIGlobalPrompt_Input:SetMultiline( true )
    AIGlobalPrompt_Input:SetText( the_AI.global_prompt or "" )

    // AI Commands Label
    local AICommands_Label = vgui.Create( "DLabel", ScrollContainer )
    AICommands_Label:SetPos( 10, 210 )
    AICommands_Label:SetSize( 350, 20 )
    AICommands_Label:SetColor( Color( 0, 0, 0 ) )
    AICommands_Label:SetText( "AI Commands:" )

    // AI Commands
    local CommandsLayout = vgui.Create( "DIconLayout", ScrollContainer )
    CommandsLayout:SetPos( 10, 230 )
    CommandsLayout:SetSize( 330, 130 )
    CommandsLayout:SetSpaceX( 5 )
    CommandsLayout:SetSpaceY( 5 )

    CommandsLayout.Commands = the_AI.commands or {} 

    CommandsLayout.Init = function( self )
        self:Clear()

        for k, v in pairs( CommandsLayout.Commands ) do
            local CommandPanel = CommandsLayout:Add( "DPanel" )
            CommandPanel:SetSize( CommandsLayout:GetWide() * 1, 75 )
            CommandPanel.Paint = function( self2, w, h )
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
                draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 255, 255, 255 ) )
            end

            // Create a label that says "Command:"
            local CommandLabel = vgui.Create( "DLabel", CommandPanel )
            CommandLabel:SetPos( 10, 10 )
            CommandLabel:SetColor( Color( 0, 0, 0 ) )
            CommandLabel:SetText( "Command:" )

            local CommandText = vgui.Create( "DTextEntry", CommandPanel )
            CommandText:SetPos( 65, 10 )
            CommandText:SetSize( 80, 20 )
            CommandText:SetText( k )

            CommandText.OnTextChanged = function( self3 )
                CommandsLayout.Commands[self3:GetValue()] = CommandsLayout.Commands[k]
                CommandsLayout.Commands[k] = nil
                k = self3:GetValue()
            end

            // Create a label that says "Prompt:"
            local CommandPromptLabel = vgui.Create( "DLabel", CommandPanel )
            CommandPromptLabel:SetPos( 10, 35 )
            CommandPromptLabel:SetColor( Color( 0, 0, 0 ) )
            CommandPromptLabel:SetText( "Prompt:" )

            local CommandPrompt = vgui.Create( "DTextEntry", CommandPanel )
            CommandPrompt:SetPos( 65, 35 )
            CommandPrompt:SetSize( CommandPanel:GetWide() - 95, 35 )
            CommandPrompt:SetMultiline( true )
            CommandPrompt:SetText( v.prompt or "nil")

            CommandPrompt.OnTextChanged = function( self3 )
                CommandsLayout.Commands[k].prompt = self3:GetValue()
            end

            local CommandPublic = vgui.Create( "DComboBox", CommandPanel )
            CommandPublic:SetPos( 220, 10 )
            CommandPublic:SetSize( 80, 20 )
            CommandPublic:SetValue( v.access or "public" )
            CommandPublic:AddChoice( "public" )
            CommandPublic:AddChoice( "private" )
            CommandPublic:AddChoice( "gm" )
            CommandPublic:AddChoice( "admin" )

            CommandPublic.OnSelect = function( self3, index, value )
                CommandsLayout.Commands[k].access = value
            end

            // Create a Icon button with this icon: icon16/delete.png
            local CommandDelete = vgui.Create( "DButton", CommandPanel )
            CommandDelete:SetText( "" )
            CommandDelete:SetIcon( "icon16/delete.png" )
            // Set the position in the top right corner.
            CommandDelete:SetPos( CommandPanel:GetWide() - 25, 9 )
            CommandDelete:SetSize( 20, 20 )
            CommandDelete.Paint = function( self3, w, h )
                // If mouse hover
                if self3:IsHovered() then
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 138, 138, 138) )
                end
                --draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 255, 255, 255 ) )
            end
            CommandDelete.DoClick = function()
                CommandsLayout.Commands[k] = nil
                CommandPanel:Remove()
                ScrollContainer:InvalidateLayout()
            end
        end
    end

    CommandsLayout:Init()

    // AI Commands Add Button
    local AICommands_AddButton = vgui.Create( "DButton", ScrollContainer )
    AICommands_AddButton:SetText( "" )
    AICommands_AddButton:SetIcon( "icon16/add.png" )
    AICommands_AddButton:SetPos( 85, 210 )
    AICommands_AddButton:SetSize( 20, 20 )
    AICommands_AddButton.Paint = function( self, w, h )
        // If mouse hover
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 138, 138, 138) )
        end
        --draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 255, 255, 255 ) )
    end

    AICommands_AddButton.DoClick = function()

        // Check if the command already exists, if it does, then add _1 to the end of it. Increment the number until it doesn't exist. Max 99 times.
        local command_name = "!command"
        local command_name_exists = true
        local command_name_counter = 1
        while command_name_exists do
            if CommandsLayout.Commands[command_name] then
                command_name_counter = command_name_counter + 1
                command_name = "!command_" .. command_name_counter
            else
                command_name_exists = false
            end
            if command_name_counter > 99 then
                HALOARMORY.MsgC("ERROR: Could not create a new command. Too many commands already exist with the same name.")
                chat.AddText( Color( 255, 0, 0 ), "ERROR: Could not create a new command. Too many commands already exist with the same name." )
                return
            end
        end

        table.Merge( CommandsLayout.Commands, { [command_name] = { ["prompt"] = "{player} says: {message}", ["access"] = "public" } } )

        CommandsLayout:Init()
    end


    // Add a scrollbar in AI History
    local HistoryScrollContainer = vgui.Create( "DScrollPanel", HALOARMORY.AI.Manager_GUI.MainWindow.AIHistory )
    HistoryScrollContainer:Dock( FILL )
    HistoryScrollContainer:SetSize( 370, 290 )


    // Add a list of AI History to the window.
    local HistoryView = vgui.Create( "DIconLayout", HistoryScrollContainer )
    HistoryView:SetPos( 10, 40 )
    HistoryView:SetSize( 350, 240 )
    HistoryView:SetSpaceX( 5 )
    HistoryView:SetSpaceY( 5 )

    HistoryView.HistoryTable = the_AI.history or {}


    // Display total tokens used.
    local TotalTokensLabel = vgui.Create( "DLabel", HistoryScrollContainer )
    TotalTokensLabel:SetPos( 40, 10 )
    TotalTokensLabel:SetSize( 350, 20 )
    TotalTokensLabel:SetColor( Color( 0, 0, 0 ) )
    TotalTokensLabel:SetText( "Total Tokens: <loading>" )

    TotalTokensLabel.TokenLabels = {}

    TotalTokensLabel.UpdateTokens = function()
        local totalTokens = 0
        for k, v in pairs( TotalTokensLabel.TokenLabels ) do
            totalTokens = totalTokens + v.Tokens
        end
        TotalTokensLabel:SetText( "Total Tokens: " .. totalTokens .. " / " .. TokenLimiter_Input:GetValue() )
    end

    TotalTokensLabel.UpdateTokens()


    HistoryView.Init = function( self )
        self:Clear()

        TotalTokensLabel.TokenLabels = {}

        for k, v in pairs( HistoryView.HistoryTable ) do
            local HistoryPanel = HistoryView:Add( "DPanel" )
            HistoryPanel:SetSize( HistoryView:GetWide() * .95, 150 )
            HistoryPanel.Paint = function( self2, w, h )
                draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
                draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 255, 255, 255 ) )
            end

            // Create a label that says "Role:"
            local HistoryRoleLabel = vgui.Create( "DLabel", HistoryPanel )
            HistoryRoleLabel:SetPos( 10, 10 )
            HistoryRoleLabel:SetColor( Color( 0, 0, 0 ) )
            HistoryRoleLabel:SetText( "Role:" )

            local HistoryRole = vgui.Create( "DComboBox", HistoryPanel )
            HistoryRole:SetPos( 65, 10 )
            HistoryRole:SetSize( 80, 20 )
            HistoryRole:SetValue( v.role or "user" )
            HistoryRole:AddChoice( "user" )
            HistoryRole:AddChoice( "assistant" )

            HistoryRole.OnSelect = function( self3, index, value )
                HistoryView.HistoryTable[k].role = value
            end

            // Create a label that says "Content:"
            local HistoryContentLabel = vgui.Create( "DLabel", HistoryPanel )
            HistoryContentLabel:SetPos( 10, 35 )
            HistoryContentLabel:SetColor( Color( 0, 0, 0 ) )
            HistoryContentLabel:SetText( "Content:" )

            local HistoryContent = vgui.Create( "DTextEntry", HistoryPanel )
            HistoryContent:SetPos( 65, 35 )
            HistoryContent:SetSize( HistoryPanel:GetWide() - 95, 35 )

            HistoryContent:SetMultiline( true )
            HistoryContent:SetText( v.content or "nil")

            HistoryContent:SetUpdateOnType( false )

            // Dynamically set the height of the textEntry box. A new line is 38 character, or "\n".
            // Minimum height is 35, maximum height is 200.
            local contentHeight = 35
            local contentHeightCounter = 0
            for i = 1, string.len( v.content or "nil" ) do
                contentHeightCounter = contentHeightCounter + 1
                if contentHeightCounter > 50 then
                    contentHeight = contentHeight + 15
                    contentHeightCounter = 0
                end
            end
            -- if contentHeight > 200 then
            --     contentHeight = 200
            -- end
            HistoryContent:SetSize( HistoryPanel:GetWide() - 95, contentHeight )
            HistoryPanel:SetSize( HistoryView:GetWide() * .95, contentHeight + 45 )

            // Create a label that says "Tokens: 0"
            local HistoryTokensLabel = vgui.Create( "DLabel", HistoryPanel )
            HistoryTokensLabel:SetPos( HistoryPanel:GetWide() - 100, 9 )
            HistoryTokensLabel:SetColor( Color( 0, 0, 0 ) )
            HistoryTokensLabel:SetText( "Tokens: <loading>" )

            HistoryTokensLabel.Tokens = 0

            table.insert( TotalTokensLabel.TokenLabels, HistoryTokensLabel )

            HistoryTokensLabel.UpdateTokens = function()
                HALOARMORY.AI.Tokens.Encode(HistoryContent:GetText(), function(tokens, success)
                    print("Got Tokens", tokens, success)
                    HistoryTokensLabel.Tokens = tokens
                    if success then
                        HistoryTokensLabel:SetText( "Tokens: " .. tokens )
                    else
                        HistoryTokensLabel:SetText( "Tokens: <error>" )
                    end

                    TotalTokensLabel.UpdateTokens()
                    
                end)
            end

            HistoryTokensLabel.UpdateTokens()

            HistoryContent.OnLoseFocus = function( self4 )
                HistoryView.HistoryTable[k].content = self4:GetValue()

                HistoryTokensLabel.UpdateTokens()

                // Dynamically set the height of the textEntry box.
                // Minimum height is 35, maximum height is 200.
                contentHeight = 35
                contentHeightCounter = 0
                for i = 1, string.len( v.content or "nil" ) do
                    contentHeightCounter = contentHeightCounter + 1
                    if contentHeightCounter > 50 then
                        contentHeight = contentHeight + 15
                        contentHeightCounter = 0
                    end
                end
                -- if contentHeight > 200 then
                --     contentHeight = 200
                -- end
                HistoryContent:SetSize( HistoryPanel:GetWide() - 95, contentHeight )
                HistoryPanel:SetSize( HistoryView:GetWide() * .95, contentHeight + 50 )

                HistoryView:InvalidateLayout()
            end

            // Create a Icon button with this icon: icon16/delete.png
            local HistoryDelete = vgui.Create( "DButton", HistoryPanel )
            HistoryDelete:SetText( "" )
            HistoryDelete:SetIcon( "icon16/delete.png" )
            // Set the position in the top right corner.
            HistoryDelete:SetPos( HistoryPanel:GetWide() - 25, 9 )
            HistoryDelete:SetSize( 20, 20 )
            HistoryDelete.Paint = function( self5, w, h )
                // If mouse hover
                if self5:IsHovered() then
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 138, 138, 138) )
                end
                --draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 255, 255, 255 ) )
            end
            HistoryDelete.DoClick = function()
                HistoryView.HistoryTable[k] = nil
                HistoryPanel:Remove()
                HistoryScrollContainer:InvalidateLayout()
            end
        end
    end

    HistoryView:Init()


    // Add an add button in AI History
    local AIHistory_AddButton = vgui.Create( "DButton", HistoryScrollContainer )
    AIHistory_AddButton:SetText( "" )
    AIHistory_AddButton:SetIcon( "icon16/add.png" )
    AIHistory_AddButton:SetPos( 10, 10 )
    AIHistory_AddButton:SetSize( 20, 20 )

    AIHistory_AddButton.DoClick = function()
        table.insert( HistoryView.HistoryTable, { role = "user", content = "" } )
        HistoryView:Init()
    end


    
    // Add a button to load an AI from the server.
    HALOARMORY.AI.Manager_GUI.LoadAI = vgui.Create( "DButton", HALOARMORY.AI.Manager_GUI.MainWindow )
    HALOARMORY.AI.Manager_GUI.LoadAI:SetText( "Cancel" )
    HALOARMORY.AI.Manager_GUI.LoadAI:SetPos( 10, 30 )
    HALOARMORY.AI.Manager_GUI.LoadAI:SetSize( 100, 30 )
    HALOARMORY.AI.Manager_GUI.LoadAI.DoClick = function()
        net.Start( "HALOARMORY.AI" )
            net.WriteString( "EditAI-List" )
        net.SendToServer()
        HALOARMORY.AI.Manager_GUI.MainWindow:Remove()
    end


    // Add a button to save the AI to the server.
    HALOARMORY.AI.Manager_GUI.SaveAI = vgui.Create( "DButton", HALOARMORY.AI.Manager_GUI.MainWindow )
    HALOARMORY.AI.Manager_GUI.SaveAI:SetText( "Save AI" )
    HALOARMORY.AI.Manager_GUI.SaveAI:SetPos( 120, 30 )
    HALOARMORY.AI.Manager_GUI.SaveAI:SetSize( 100, 30 )
    HALOARMORY.AI.Manager_GUI.SaveAI.DoClick = function()

        local new_AI = {}

        // Grab all the values from the GUI and put them in a table.
        new_AI.API = APIKey_TextInput:GetValue()
        new_AI.enabled = Enabled_Checkbox:GetChecked()
        new_AI.name = AIName_Input:GetValue()
        new_AI.color = AIColor_Box.Color
        new_AI.model = Model_Selector:GetValue()
        new_AI.token_limit = TokenLimiter_Input:GetValue()
        new_AI.global_prompt = AIGlobalPrompt_Input:GetValue()
        new_AI.commands = CommandsLayout.Commands
        new_AI.history = HistoryView.HistoryTable

        // Check if the name is different. If it is, then add the old name to a new variable in the table called old_name.
        if new_AI.name != the_AI.name then
            new_AI.old_name = the_AI.name
        end

        net.Start( "HALOARMORY.AI" )
            net.WriteString( "EditAI-Save" )
            net.WriteTable( new_AI )
        net.SendToServer()
    end

end

// Create a window that lists all the AI's on the server.
function HALOARMORY.AI.Manager_GUI.AIListsGUI( the_AI_List )

    // Check if the user is an admin
    if !LocalPlayer():IsAdmin() then
        HALOARMORY.MsgC("You are not an admin, you cannot use this command.")
        chat.AddText( Color( 255, 0, 0 ), "You are not an admin, you cannot use this command." )
        return
    end

    --print( the_AI_List )
    --PrintTable( the_AI_List )

    // Create a new VGUI
    local mainWindowGUI = vgui.Create( "DFrame" )
    mainWindowGUI:SetSize( 270, 300 )
    mainWindowGUI:Center()
    mainWindowGUI:SetTitle( "AI Editor" )
    mainWindowGUI:SetVisible( true )
    mainWindowGUI:SetDraggable( true )
    mainWindowGUI:ShowCloseButton( true )
    mainWindowGUI:MakePopup()

    HALOARMORY.AI.Manager_GUI.MainWindow = mainWindowGUI

    // Add a scrollbar to the window.
    local ScrollContainer = vgui.Create( "DScrollPanel", mainWindowGUI )
    ScrollContainer:Dock( FILL )

    // Add a button to create a new AI.
    local newAI = vgui.Create( "DButton", ScrollContainer )
    newAI:SetText( "New AI" )
    newAI:Dock( TOP )
    newAI.DoClick = function()
        HALOARMORY.AI.Manager_GUI.OpenAIGUI()
        mainWindowGUI:Remove()
    end

    // Add a list of AI's to the window.

    local listAmount = 0

    for k, v in pairs( the_AI_List ) do

        listAmount = listAmount + 1

        local AIList = vgui.Create( "DPanel", ScrollContainer )
        AIList:Dock( TOP )
        AIList.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
            draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 110, 110, 110) )
        end

        local AIListLabel = vgui.Create( "DLabel", AIList )
        AIListLabel:SetText( "   " .. v )
        AIListLabel:Dock( FILL )

        // Add a button to delete the AI.
        local deleteAI = vgui.Create( "DButton", AIList )
        deleteAI:SetText( "" )
        deleteAI:SetIcon( "icon16/delete.png" )
        deleteAI:Dock( RIGHT )
        deleteAI:SetSize( 25, 25 ) 
        deleteAI.DoClick = function()
            net.Start( "HALOARMORY.AI" )
                net.WriteString( "EditAI-Delete" )
                net.WriteString( k )
            net.SendToServer()

            --mainWindowGUI:Remove()
        end

        local AIButton = vgui.Create( "DButton", AIList )
        AIButton:SetText( "Edit" )
        AIButton:Dock( RIGHT )
        AIButton:SetSize( 100, 30 )
        AIButton.DoClick = function()
            net.Start( "HALOARMORY.AI" )
                net.WriteString( "EditAI-Load" )
                net.WriteString( k )
            net.SendToServer()
            --mainWindowGUI:Remove()
        end

    end

    if listAmount <= 0 then
        local noAILabel = vgui.Create( "DLabel", ScrollContainer )
        noAILabel:SetText( " No AI's found. Create a new one." )
        noAILabel:Dock( TOP )
    end


end


// Create a window that let's you select to edit the AI or the Map Definitions.
function HALOARMORY.AI.Manager_GUI.OpenSelectionGUI()

    // Check if the user is an admin
    if !LocalPlayer():IsAdmin() then
        HALOARMORY.MsgC("You are not an admin, you cannot use this command.")
        chat.AddText( Color( 255, 0, 0 ), "You are not an admin, you cannot use this command." )
        return
    end

    // Create a new VGUI
    local mainWindowGUI = vgui.Create( "DFrame" )
    mainWindowGUI:SetSize( 270, 140 )
    mainWindowGUI:Center()
    mainWindowGUI:SetTitle( "Select what to edit:" )
    mainWindowGUI:SetVisible( true )
    mainWindowGUI:SetDraggable( true )
    mainWindowGUI:ShowCloseButton( true )
    mainWindowGUI:MakePopup()

    HALOARMORY.AI.Manager_GUI.MainWindow = mainWindowGUI

    // Add a button to Edit an AI from the server.
    local loadAI = vgui.Create( "DButton", mainWindowGUI )
    loadAI:SetText( "Edit AI" )
    loadAI:SetPos( 10, 30 )
    loadAI:SetSize( 120, 100 )
    loadAI.DoClick = function()

        net.Start( "HALOARMORY.AI" )
            net.WriteString( "EditAI-List" )
        net.SendToServer()
    end

    // Add a button to Edit the Map Definitions from the server.
    local loadMapDefinitions = vgui.Create( "DButton", mainWindowGUI )
    loadMapDefinitions:SetText( "Edit Map Definitions" )
    loadMapDefinitions:SetPos( 140, 30 )
    loadMapDefinitions:SetSize( 120, 100 )
    loadMapDefinitions.DoClick = function()
        // TODO later
    end

end

concommand.Add("HALOARMORY.ManageAI", HALOARMORY.AI.Manager_GUI.OpenSelectionGUI )

list.Set( "DesktopWindows", "HALOARMORY.AI", {
    title = "AI Editor",
    icon = "vgui/haloarmory/icons/toolbox.png",
    init = function( icon, window )
        HALOARMORY.AI.Manager_GUI.OpenSelectionGUI()
    end,
})



function HALOARMORY.AI.Manager_GUI.RouteNetwork( len, command )
    if command == "EditAI-List-Rply" then
        local AIList = net.ReadTable()

        if HALOARMORY.AI.Manager_GUI.MainWindow then HALOARMORY.AI.Manager_GUI.MainWindow:Remove() end

        HALOARMORY.AI.Manager_GUI.AIListsGUI( AIList )
    
    elseif command == "EditAI-Load-Rply" then
        
        local the_AI = net.ReadTable()

        if HALOARMORY.AI.Manager_GUI.MainWindow then HALOARMORY.AI.Manager_GUI.MainWindow:Remove() end

        HALOARMORY.AI.Manager_GUI.OpenAIGUI( the_AI )
    end
end


--[[ 
################################
||                            ||
||       Debug open GUI       ||
||                            ||
################################
 ]]

-- if HALOARMORY.AI.Manager_GUI.MainWindow then HALOARMORY.AI.Manager_GUI.MainWindow:Remove() end

-- HALOARMORY.AI.Manager_GUI.AIListsGUI( { "test.json", "aurora.json", "test.json", "aurora.json", } )
-- net.Start( "HALOARMORY.AI" )
--     net.WriteString( "EditAI-List" )
-- net.SendToServer()