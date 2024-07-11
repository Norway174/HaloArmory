HALOARMORY.MsgC("Client HALO ARMORY Loadout GUI Loading.")
--HALOARMORY.MsgC("Client HALO ARMORY Loadout GUI Loading.")

HALOARMORY.ARMORY = HALOARMORY.ARMORY or {}
HALOARMORY.ARMORY.GUI = HALOARMORY.ARMORY.GUI or {}

-- local function DoDrop( self, panels, bDoDrop, Command, x, y )
-- 	if ( bDoDrop ) then
-- 		for k, v in pairs( panels ) do
--             print(self)
-- 			self:Add( v )
-- 		end
-- 	end
-- end

local ScrWi, ScrHe = math.min(ScrW() - 10, 1280), math.min(ScrH() - 10, 720)
--ScrWi, ScrHe = 800, 600

hook.Add( "OnScreenSizeChanged", "HALOARMORY.ARMORY.OnSizeChange", function( oldWidth, oldHeight )
    ScrWi, ScrHe = math.min(ScrW() - 10, 1280), math.min(ScrH() - 10, 720)
end )

function HALOARMORY.ARMORY.Open()
    --if not DarkRP then return end

    HALOARMORY.ARMORY.GUI.Menu = vgui.Create("DFrame")
    HALOARMORY.ARMORY.GUI.Menu:SetSize(ScrWi, ScrHe)
    HALOARMORY.ARMORY.GUI.Menu:Center()
    HALOARMORY.ARMORY.GUI.Menu:SetTitle("")
    HALOARMORY.ARMORY.GUI.Menu:MakePopup()
    HALOARMORY.ARMORY.GUI.Menu:ShowCloseButton( false )
    --HALOARMORY.Meny:SetHeight( ScrHe * 0.06 )

    HALOARMORY.ARMORY.GUI.Menu.Paint = function(self, w, h)
        draw.RoundedBox(HALOARMORY.ARMORY.Theme["roundness"], 0, 0, w, h, HALOARMORY.ARMORY.Theme["background"])
        draw.RoundedBoxEx(HALOARMORY.ARMORY.Theme["roundness"], 0, 0, w, h * 0.06, HALOARMORY.ARMORY.Theme["header_color"], true, true, false, false)

        draw.SimpleText("// UNSC // ARMORY //", "HALO_Armory_Font", w / 2, h * .03, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        --draw.SimpleText("✕", "HALO_Armory_Font", w - 25, h * .03, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local CloseButton = vgui.Create( "DButton", HALOARMORY.ARMORY.GUI.Menu )
    CloseButton:SetText( "" )
    CloseButton:SetPos( ScrWi * 0.97, ScrHe * 0.01 )
    CloseButton:SetSize( 30, 30 )
    CloseButton.DoClick = function()
        if HALOARMORY.ARMORY.GUI.Menu then HALOARMORY.ARMORY.GUI.Menu:Remove() end
    end
    CloseButton.Paint = function(self, w, h)
        draw.SimpleText("✕", "HALO_Armory_Font", w / 2, h / 2, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end


    // Panels

    local MainPanel = vgui.Create( "DPanel", HALOARMORY.ARMORY.GUI.Menu ) -- Can be any panel, it will be stretched
    local AmmoPanel = vgui.Create( "DPanel", HALOARMORY.ARMORY.GUI.Menu )



    local divH = vgui.Create( "DHorizontalDivider", HALOARMORY.ARMORY.GUI.Menu )
    divH:Dock( FILL )
    divH:SetLeft( MainPanel )
    divH:SetRight( AmmoPanel )
    divH:SetDividerWidth( 1 )
    divH:SetLeftMin( 20 )
    divH:SetRightMin( 20 )
    divH:SetLeftWidth( ScrWi / 1.5 )
    divH:DockMargin(0, ScrHe * .03 - 2, 0, 0)

    divH.m_DragBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, HALOARMORY.ARMORY.Theme["divider_color"])
    end


--[[     local EquippedPanel = vgui.Create( "DPanel", MainPanel )
    local AvailablePanel = vgui.Create( "DPanel", MainPanel )

    local divV = vgui.Create( "DVerticalDivider", MainPanel )
    divV:Dock( FILL )
    divV:SetTop( EquippedPanel )
    divV:SetBottom( AvailablePanel )
    divV:SetDividerHeight( 1 )
    divV:SetTopMin( 20 )
    divV:SetBottomMin( 20 )

    
    divV.m_DragBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, HALOARMORY.ARMORY.Theme["divider_color"])
    end

    divV:SetTopHeight( ScrHe / 3) -- This sets the height of the top panel
    divV:DockMargin(0, 0, 4, 0) ]]



    MainPanel.Paint = function(self, w, h) end

    AmmoPanel.Paint = function(self, w, h) end
    AmmoPanel:DockPadding(4, 0, 0, 0)

--[[     EquippedPanel.Paint = function(self, w, h) end

    AvailablePanel.Paint = function(self, w, h) end ]]



    // AMMO PANEL

    // TITLE
    local AmmoTitlePanel = vgui.Create( "DPanel", AmmoPanel )
    AmmoTitlePanel:Dock( TOP )
    AmmoTitlePanel:Center()
    AmmoTitlePanel:SetTall( 35 )

    AmmoTitlePanel.Paint = function(self, w, h)
        --surface.SetDrawColor(Color(233, 12, 12, 225))
        --surface.DrawRect(0, 0, w, h)
        draw.SimpleText("AMMO", "HALO_Armory_Font", w / 2, h * .45, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    // CONTENT
    local AmmoContentPanel = vgui.Create( "DScrollPanel", AmmoPanel )
    AmmoContentPanel:Dock( FILL )

    local listOfAmmo = LocalPlayer():GetAmmo()

    --PrintTable(listOfAmmo)
    --For each listofAmmo, create a panel with the ammo name and the amount of ammo
    for k, v in pairs(listOfAmmo) do
        --print(k, v)
        local AmmoPanelType = vgui.Create( "DPanel", AmmoContentPanel )
        AmmoPanelType:Dock( TOP )
        AmmoPanelType:SetTall( 35 )
        AmmoPanelType:DockMargin(0, 0, 0, 5)
        AmmoPanelType.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(54, 54, 54, 117))
            draw.RoundedBox(0, 0, 0, v / HALOARMORY.ARMORY.MaxAmmo * w, h, Color(7, 121, 150, 117))
            draw.SimpleText(game.GetAmmoName( k ), "HALO_Armory_Font", 5, h * .45, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(v .. " / " .. HALOARMORY.ARMORY.MaxAmmo, "HALO_Armory_Font", w - 5, h * .55, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end


    // EQUIPPED PANEL


    // TITLE
    local MainPanelTitle = vgui.Create( "DPanel", MainPanel )
    MainPanelTitle:Dock( TOP )
    MainPanelTitle:Center()
    MainPanelTitle:SetTall( 35 )

    MainPanelTitle.Paint = function(self, w, h)
        --surface.SetDrawColor(Color(233, 12, 12, 225))
        --surface.DrawRect(0, 0, w, h)
        draw.SimpleText("WEAPONS", "HALO_Armory_Font", w / 2, h * .45, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    // CONTENT
    local MainContentPanelScroll = vgui.Create( "DScrollPanel", MainPanel )
    MainContentPanelScroll:Dock( FILL )
    MainContentPanelScroll:DockMargin(0, 0, 5, 0)

    --[[ MainContentPanelScroll.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(54, 54, 54, 117))
    end ]]


    local MainContentPanel = vgui.Create( "DIconLayout", MainContentPanelScroll )
    MainContentPanel:Dock( FILL )
    MainContentPanel:SetSpaceY( 5 ) -- Sets the space in between the panels on the Y Axis by 5
    MainContentPanel:SetSpaceX( 5 ) -- Sets the space in between the panels on the X Axis by 5
    MainContentPanel:DockMargin(10, 0, 0, 0)
    MainContentPanel:SetLayoutDir( TOP )
    --MainContentPanel:ContentCenter()

    // Weapons logic
    local listOfWeapons = HALOARMORY.ARMORY.GetWeapons( LocalPlayer() ) --table.Copy(LocalPlayer():getJobTable().HALOARMORY)

    --PrintTable(listOfWeapons)

    for k, v in pairs(listOfWeapons) do

        local wep = nil
        if v.forceEnable then
            wep = v
        else
            wep = weapons.Get( k )
        end

        --PrintTable(v)

        if not istable(wep) then
            local wepNew = LocalPlayer():GetWeapon( k )
            if wepNew then
                wep = wepNew
            end
        end

        local selectable = true
        if not IsValid(wep) and not istable(wep) then
            selectable = false
        end


        local weaponModel = v.modelOverwrite or wep.WorldModel --[[ or wep.ViewModel ]] or "models/weapons/c_arms_animations.mdl"

--[[         if weaponModel == "" and wep.ViewModel then weaponModel = wep.ViewModel end ]]
        if weaponModel == "" then weaponModel = "models/weapons/c_arms_animations.mdl" end



        local ListItem = vgui.Create( "DPanel", MainContentPanel )
        ListItem:SetSize( (ScrWi / 1.5) / 2 - 20, 120 )
        ListItem:SetText( "" )	

        --print(v.className, weaponModel)

        --ListItem:Dock(LEFT)

        -- TODO:
        -- Add Admin only icon: icon16/shield.png

        ListItem.Paint = function(self, w, h)
            if not selectable then
                draw.RoundedBox(0, 0, 0, w, h, Color(97, 0, 0, 117))
            elseif v.admin_only and v.equipped then
                draw.RoundedBox(0, 0, 0, w, h, Color(150, 140, 7, 117))
            elseif v.admin_only then
                draw.RoundedBox(0, 0, 0, w, h, Color(54, 54, 0, 117))
            elseif not v.loadout and v.equipped then
                draw.RoundedBox(0, 0, 0, w, h, Color(7, 129, 150, 117))
            elseif not v.loadout then
                draw.RoundedBox(0, 0, 0, w, h, Color(1, 39, 46, 117))
            elseif v.equipped then
                draw.RoundedBox(0, 0, 0, w, h, Color(7, 150, 7, 117))
            else
                draw.RoundedBox(0, 0, 0, w, h, Color(54, 54, 54, 117))
            end
        end

        local icon = vgui.Create( "DModelPanel", ListItem )
        icon:SetSize(120,120)
        icon:Dock( LEFT )
        --icon:setWide(120)
        icon:SetModel( weaponModel )
        icon.Entity:SetPos( icon.Entity:GetPos() - Vector(0, 0, 0) )
        icon:SetFOV(30)
        local num = .7
        local min, max = icon.Entity:GetRenderBounds()
        icon:SetCamPos( min:Distance( max ) * Vector( num, num, num ) )
        icon:SetLookAt( ( max + min ) / 2 )
        function icon:LayoutEntity( Entity ) return end

        local oldPaint = icon.Paint
        icon.Paint = function(self, w, h)
            --draw.RoundedBox(0, 0, 0, w, h, Color(185, 0, 0, 117))
            oldPaint(self, w, h)
        end

        --ListItem:SetModel( weaponModel ) 
        --ListItem:SetName( "Pistol" )


        --[[ if (LocalPlayer():HasWeapon(v.className)) then
            EquippedList:Add( ListItem )
        else
            ListAvailable:Add( ListItem )
        end ]]

        // Weapon name
        local WeaponTitlePanel = vgui.Create( "DPanel", ListItem )
        WeaponTitlePanel:Dock( TOP )
        --WeaponTitlePanel:Center()
        WeaponTitlePanel:SetTall( 35 )

        local wep_name = "Placeholder"
        if ( isfunction( wep.GetPrintName ) ) then
            wep_name = wep:GetPrintName()
        else
            wep_name = wep.PrintName or k.Name or wep.Name or k
        end

        --TablePrint(wep)

        WeaponTitlePanel.Paint = function(self, w, h)
            --surface.SetDrawColor(Color(233, 12, 12, 225))
            --surface.DrawRect(0, 0, w, h)
            draw.SimpleText(wep_name, "HALO_Armory_Font", 0, 0, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        --ListItem:SetMouseInputEnabled( true )

        local DescriptionLabel = vgui.Create( "DTextEntry", ListItem )
        DescriptionLabel:Dock( FILL )
        --DescriptionLabel:AlignTop()
        DescriptionLabel:SetMultiline( true )
        DescriptionLabel:SetEditable( false )
        DescriptionLabel:SetPaintBackground( false )
        DescriptionLabel:SetTextColor(HALOARMORY.ARMORY.Theme["text"])

        local desc = ""
        if not selectable then desc = "Weapon not avalible." end
        if wep.Purpose then desc = wep.Purpose end
        -- Sometimes a weapon may have an empty purpose. So Desc is not nil. So we check if the string is empty, if instructions exists instead.
        if wep.Instructions and (not wep.Purpose or desc == "") then desc = wep.Instructions end
        if v.description then desc = v.description end

        if(v.admin_only) then desc = desc .. "\n" .. "Admin only!" end

        DescriptionLabel:SetText( desc )



        local ButtonPanel = vgui.Create( "DButton", ListItem )
        ButtonPanel:SetSize( ListItem:GetSize() )
        ButtonPanel:SetText( "" )
        ButtonPanel:Center()

        ButtonPanel.Paint = function(self, w, h)

        end
        if selectable then
            function ButtonPanel:DoClick() -- Defines what should happen when the label is clicked
                surface.PlaySound("ui/buttonclick.wav")
                --print(v.equipped)
                v.equipped = not v.equipped
                table.Merge(listOfWeapons[k], v)

            end
        end
        

    end



    // CONFIRM CANCEL BUTTON
        local bottomPanel = vgui.Create("DPanel", HALOARMORY.ARMORY.GUI.Menu)
        bottomPanel:Dock( BOTTOM )
        bottomPanel:SetSize( ScrWi, ScrHe * .08 )
        bottomPanel:DockMargin(0, 10, 0, 0)
        bottomPanel.Paint = function(self, w, h) end

        local offset = ScrWi / 2

        local ApplyButton = vgui.Create( "DButton", bottomPanel )
        ApplyButton:SetText( "" )
        ApplyButton:SetPos( offset - 205 - 5 , 0 )
        ApplyButton:SetSize( 205, 48 )
        ApplyButton.Paint = function(self, w, h)
            draw.RoundedBox(2, 0, 0, w, h, HALOARMORY.ARMORY.Theme["apply_btn"])
            draw.SimpleText("Apply", "HALO_Armory_Font", w / 2, h / 2, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        ApplyButton.DoClick = function()
            --print("Sending weapons:")
            --PrintTable(listOfWeapons)

            HALOARMORY.ARMORY.ApplyWeapons( ply, listOfWeapons )
            surface.PlaySound( "items/ammo_pickup.wav" ) 
            if HALOARMORY.ARMORY.GUI.Menu then HALOARMORY.ARMORY.GUI.Menu:Remove() end
        end

        local CancelButton = vgui.Create( "DButton", bottomPanel )
        CancelButton:SetText( "" )
        CancelButton:SetPos( offset + 5, 0 )
        CancelButton:SetSize( 205, 48 )
        CancelButton.Paint = function(self, w, h)
            draw.RoundedBox(2, 0, 0, w, h, HALOARMORY.ARMORY.Theme["cancel_btn"])
            draw.SimpleText("Cancel", "HALO_Armory_Font", w / 2, h / 2, HALOARMORY.ARMORY.Theme["text"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        CancelButton.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            if HALOARMORY.ARMORY.GUI.Menu then HALOARMORY.ARMORY.GUI.Menu:Remove() end
        end


end

concommand.Add("haloarmory_loadout", function() 
    HALOARMORY.ARMORY.Open()
end)

--if HALOARMORY.ARMORY.GUI.Menu then HALOARMORY.ARMORY.GUI.Menu:Remove() end
--HALOARMORY.ARMORY.Open()

