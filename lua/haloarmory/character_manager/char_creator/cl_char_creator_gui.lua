HALOARMORY.MsgC("Client CHARACTHER Creator Loading.")

HALOARMORY = HALOARMORY or {}
HALOARMORY.Character = HALOARMORY.Character or {}
HALOARMORY.Character.GUI = HALOARMORY.Character.GUI or {}

HALOARMORY.Character.GUI.Background = "vgui/character_creator/unsc_flag_hex.png"

surface.CreateFont( "HALO_CHC_Title", {
    font = "Quantico",
    size = 75,
    weight = 100,
} )

surface.CreateFont( "HALO_CHC_FormTitle", {
    font = "Quantico",
    size = 33,
    weight = 100,
} )

surface.CreateFont( "HALO_CHC_FormText", {
    font = "Quantico",
    size = 30,
    weight = 100,
} )


function HALOARMORY.Character.GUI.OpenCharacterWindow()

    // Create a new frame. Disable controls. Set it to max size, to cover the whole sceen.
    HALOARMORY.Character.GUI.Frame = vgui.Create( "DFrame" )
    HALOARMORY.Character.GUI.Frame:SetSize( ScrW(), ScrH() )
    HALOARMORY.Character.GUI.Frame:SetTitle( "" )
    HALOARMORY.Character.GUI.Frame:SetVisible( true )
    HALOARMORY.Character.GUI.Frame:SetDraggable( false )
    HALOARMORY.Character.GUI.Frame:ShowCloseButton( true )
    --HALOARMORY.Character.GUI.Frame:MakePopup()
    HALOARMORY.Character.GUI.Frame:Center()


    -- Create material panel
    local mat = vgui.Create("DImage", HALOARMORY.Character.GUI.Frame)
    mat:SetPos(0, 0)
    mat:SetSize( HALOARMORY.Character.GUI.Frame:GetSize() )

    -- This has to be set manually since mat:SetMaterial only accepts string argument
    mat:SetImage( HALOARMORY.Character.GUI.Background )
    mat:SetImageColor( Color( 148, 148, 148) )

    local BackupPaint = mat.Paint
    mat.Paint = function( self, w, h )
        BackupPaint( self, w, h )
        
        // Draw a title.
        draw.SimpleTextOutlined( "WELCOME TO THE ", "HALO_CHC_Title", ScrW() * .40, ScrH() * .1, Color( 107, 107, 107), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color( 0, 0, 0, 255 ) )
        draw.SimpleTextOutlined( "UNSC RECRUITMENT CENTER!", "HALO_CHC_Title", ScrW() * .40, ScrH() * .1, Color( 219, 112, 11), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color( 0, 0, 0, 255 ) )
        
    end


    local CharacterForm = vgui.Create( "DFrame", HALOARMORY.Character.GUI.Frame )
    CharacterForm:SetSize( 800, 400 )
    CharacterForm:SetTitle( "" )
    CharacterForm:SetVisible( true )
    CharacterForm:SetDraggable( true )
    CharacterForm:ShowCloseButton( false )
    CharacterForm:MakePopup()
    CharacterForm:Center()

    CharacterForm.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 35, 35, 35, 221) )
        draw.RoundedBox( 0, 0, 0, w, 30, Color( 0, 0, 0, 66) )

        // Draw a title.
        draw.SimpleTextOutlined( "PLEASE COMPLETE THE FORM", "HALO_CHC_FormTitle", 5, 15, Color( 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 255 ) )

    end

    local FirstNamePanel = vgui.Create( "DPanel", CharacterForm )
    FirstNamePanel:SetPos( 20, 50 ) -- Set the position of the panel
    FirstNamePanel:SetSize( 350, 80 ) -- Set the size of the panel
    FirstNamePanel.Paint = function( self, w, h ) -- Paint function
        draw.SimpleText( "FIRST NAME", "HALO_CHC_FormText", 5, 15, Color( 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    // Create a text input for the first name.
    local FirstNameInput = vgui.Create( "DTextEntry", FirstNamePanel ) -- create the form as a child of frame
    FirstNameInput:SetPos( 5, 32 )
    FirstNameInput:SetSize( 350, 40 )
    FirstNameInput:SetText( "" )
    FirstNameInput:SetFont("HALO_CHC_FormText")

    local LastNamePanel = vgui.Create( "DPanel", CharacterForm )
    LastNamePanel:SetPos( 20, 140 ) -- Set the position of the panel
    LastNamePanel:SetSize( 350, 80 ) -- Set the size of the panel
    LastNamePanel.Paint = function( self, w, h ) -- Paint function
        draw.SimpleText( "LAST NAME", "HALO_CHC_FormText", 5, 15, Color( 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    // Create a text input for the last name.
    local LastNameInput = vgui.Create( "DTextEntry", LastNamePanel ) -- create the form as a child of frame
    LastNameInput:SetPos( 5, 32 )
    LastNameInput:SetSize( 350, 40 )
    LastNameInput:SetText( "" )
    LastNameInput:SetFont("HALO_CHC_FormText")

    // On the right side of the form, add a panel to display the character model.
    local CharacterModelPanel = vgui.Create( "DPanel", CharacterForm )
    CharacterModelPanel:SetPos( 440, 40 ) -- Set the position of the panel
    CharacterModelPanel:SetSize( 350, 350 ) -- Set the size of the panel
    CharacterModelPanel.Paint = function( self, w, h ) -- Paint function
        draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 147) )
    end

    // Get the current player model.
    local SelectedPlyModel = LocalPlayer():GetModel()

    if DarkRP then
        local DefaultJob = GAMEMODE.DefaultTeam
        local JobTable = RPExtraTeams[DefaultJob]["model"]
        SelectedPlyModel = JobTable[math.random(1, #JobTable)]
    end

    // Create a model panel to display the model.
    local CharacterModel = vgui.Create( "DModelPanel", CharacterModelPanel )
    CharacterModel:SetPos( 0, 0 )
    CharacterModel:SetSize( CharacterModelPanel:GetSize() )
    CharacterModel:SetModel( SelectedPlyModel )
    CharacterModel:SetAnimated( true )
    CharacterModel:SetCamPos( Vector( 50, 0, 50 ) )
    CharacterModel:SetFOV( 77 )
    CharacterModel:SetCursor( "arrow" )
    

    function CharacterModel:LayoutEntity( Entity ) return end -- disables default rotation
    

    // Create a button under the character model to change the model. A clickable label would be better, but I'm too lazy to figure out how to do that.
    local ChangeModelButton = vgui.Create( "DButton", CharacterModelPanel )
    ChangeModelButton:SetPos( 0, 300 )
    ChangeModelButton:SetSize( 350, 50 )
    ChangeModelButton:SetText( "CHANGE PHOTO" )
    ChangeModelButton:SetFont("HALO_CHC_FormText")
    ChangeModelButton:SetTextColor( Color( 255, 255, 255 ) )
    ChangeModelButton.Paint = function( self, w, h )
        // On hovr, change the color.
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 31, 31, 31, 147) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 66) )
        end
    end

    // Onclick, create a new VGUI window to select a model.
    ChangeModelButton.DoClick = function()
        CharacterForm:Hide()

        // Create a new window.
        local ModelSelectWindow = vgui.Create( "DFrame", HALOARMORY.Character.GUI.Frame )
        ModelSelectWindow:SetSize( 750, 750 )
        ModelSelectWindow:SetTitle( "" )
        ModelSelectWindow:SetVisible( true )
        ModelSelectWindow:SetDraggable( true )
        ModelSelectWindow:ShowCloseButton( false )
        ModelSelectWindow:MakePopup()
        ModelSelectWindow:Center()

        ModelSelectWindow.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 35, 35, 35, 221) )
            draw.RoundedBox( 0, 0, 0, w, 30, Color( 0, 0, 0, 66) )

            // Draw a title.
            draw.SimpleTextOutlined( "SELECT A PHOTO", "HALO_CHC_FormTitle", 5, 15, Color( 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0, 255 ) )

        end

        local Scroll = vgui.Create( "DScrollPanel", ModelSelectWindow ) -- Create the Scroll panel
        Scroll:Dock( FILL )

        // Create a list of models.
        local ModelList = vgui.Create( "DIconLayout", Scroll )
        ModelList:Dock( FILL )
        ModelList:SetSpaceY( 5 ) -- Sets the space in between the panels on the Y Axis by 5
        ModelList:SetSpaceX( 5 ) -- Sets the space in between the panels on the X Axis by 5

        // Loop through all the models.

        local PlayerModelsOptions = {}

        if DarkRP then
            local DefaultJob = GAMEMODE.DefaultTeam
            PlayerModelsOptions = RPExtraTeams[DefaultJob]["model"]
        end

        for k, v in pairs( PlayerModelsOptions ) do
            // Create a model panel.
            local ModelPanel = ModelList:Add( "DModelPanel" )
            ModelPanel:SetSize( 350, 350 )
            ModelPanel:SetModel( v )
            ModelPanel:SetAnimated( true )
            ModelPanel:SetCamPos( Vector( 50, 0, 50 ) )
            ModelPanel:SetFOV( 77 )

            function ModelPanel:LayoutEntity( Entity ) return end -- disables default rotation

            local PaintBackup = ModelPanel.Paint
            ModelPanel.Paint = function( self, w, h )

                // On hover, change the color.
                if self:IsHovered() then
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 31, 31, 31, 147) )
                else
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 66) )
                end
                PaintBackup( self, w, h )
            end

            // On click, change the model.
            ModelPanel.DoClick = function()
                // Set the model.
                CharacterModel:SetModel( v )

                // Close the model select window.
                ModelSelectWindow:Close()
                CharacterForm:Show()
            end
        end

            // Add a X button to close the window in the top right corner.
            local CloseButtonModelSelector = vgui.Create( "DButton", ModelSelectWindow )
            CloseButtonModelSelector:SetPos( 750 - 30, 0 )
            CloseButtonModelSelector:SetSize( 30, 30 )
            CloseButtonModelSelector:SetText( "X" )
            CloseButtonModelSelector:SetFont("HALO_CHC_FormText")
            CloseButtonModelSelector:SetTextColor( Color( 122, 122, 122) )
            CloseButtonModelSelector.Paint = function( self, w, h )
                --draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 0, 0) )
            end
            CloseButtonModelSelector.DoClick = function()
                ModelSelectWindow:Close()
                CharacterForm:Show()
            end
    end

    // Create a green large "Enlist Today!" button in the bottom left corner.
    local EnlistButton = vgui.Create( "DButton", CharacterForm )
    EnlistButton:SetPos( 30, 337 )
    EnlistButton:SetSize( 350, 50 )
    EnlistButton:SetText( "ENLIST TODAY!" )
    EnlistButton:SetFont("HALO_CHC_FormText")
    EnlistButton:SetTextColor( Color( 255, 255, 255 ) )
    EnlistButton.Paint = function( self, w, h )
        // On hovr, change the color.
        if self:IsHovered() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 24, 54, 10) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 26, 92, 0) )
        end
    end

    // Onclick, send the data to the server.
    EnlistButton.DoClick = function()
        // Get the data.
        local FirstName = FirstNameInput:GetValue()
        local LastName = LastNameInput:GetValue()
        local SelectedModel = CharacterModel:GetModel()

        // Send the data to the server.
        net.Start( "HALOARMORY.Character.SEND_DATA" )
            net.WriteString( FirstName )
            net.WriteString( LastName )
            net.WriteString( SelectedModel )
        net.SendToServer()

        // Close the window.
        HALOARMORY.Character.GUI.Frame:Close()
    end

    // Add a X button to close the window in the top right corner.
    local CloseButton = vgui.Create( "DButton", CharacterForm )
    CloseButton:SetPos( 800 - 30, 0 )
    CloseButton:SetSize( 30, 30 )
    CloseButton:SetText( "X" )
    CloseButton:SetFont("HALO_CHC_FormText")
    CloseButton:SetTextColor( Color( 122, 122, 122) )
    CloseButton.Paint = function( self, w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 0, 0) )
    end

    CloseButton.DoClick = function()
        HALOARMORY.Character.GUI.Frame:Close()
    end

end


net.Receive( "HALOARMORY.Character.OPEN_GUI", function( len )
    HALOARMORY.Character.GUI.OpenCharacterWindow()
end )

// Create a concommand to open the character creator.
concommand.Add( "HALOARMORY.Character.OPEN_GUI", function( ply, cmd, args )
    HALOARMORY.Character.GUI.OpenCharacterWindow()
end )

--if HALOARMORY.Character.GUI.Frame then HALOARMORY.Character.GUI.Frame:Remove() end
--HALOARMORY.Character.GUI.OpenCharacterWindow()