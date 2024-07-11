HALOARMORY.MsgC("Shared HALO INTERFACE Draw Manager Loading.")

HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}
HALOARMORY.INTERFACE.CONTROL_PANEL = HALOARMORY.INTERFACE.CONTROL_PANEL or {}

HALOARMORY.INTERFACE.CONTROL_PANEL["Panel_Types"] = {
    ["Outside"] = "outside",
    ["Inside"] = "inside",
    --["test"] = "test",
}

if not CLIENT then return end
-- ONLY CLIENT PAST THIS POINT!

local ply = LocalPlayer()

function HALOARMORY.INTERFACE.CONTROL_PANEL.DrawManager( ent )


    if not IsValid(ent) then ui3d2d.endDraw() return end
    if not IsValid(ply) and not ply:IsPlayer() then ply = LocalPlayer() end
    if not IsValid(ply) and not ply:IsPlayer() then ui3d2d.endDraw() return end

    if ent.GetPanelType and isfunction( ent.GetPanelType) then

        if ent:GetPos():Distance( ply:GetPos() ) >= 100 then return end

        if ent:GetPanelType() == "outside" then
            HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR.DrawOutside( ent )
        elseif ent:GetPanelType() == "inside" then
            HALOARMORY.INTERFACE.CONTROL_PANEL.DOOR.DrawInside( ent )
        end

    elseif (ent.DeviceType == "controller") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end

        HALOARMORY.INTERFACE.CONTROL_PANEL.SUPPLY.DrawControl( ent )

    elseif (ent.DeviceType == "cargo_access") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end

        HALOARMORY.INTERFACE.CONTROL_PANEL.CARGO.DrawAccessPoint( ent )

    elseif (ent.DeviceType == "storage") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end
 
        HALOARMORY.INTERFACE.CONTROL_PANEL.CARGO.DrawLabel( ent )

    elseif (ent.DeviceType == "auto_doc_screen") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end

        HALOARMORY.INTERFACE.CONTROL_PANEL.AUTODOC.DrawScreen( ent )
        
    elseif (ent.DeviceType == "room_claim_screen") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end

        HALOARMORY.INTERFACE.CONTROL_PANEL.ROOM_CLAIM.DrawScreen( ent )
        
    elseif (ent.DeviceType == "atc_contacts_screen") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 700 then return end

        HALOARMORY.INTERFACE.CONTROL_PANEL.ATC_CONTACTS.DrawScreen( ent )

    elseif (ent.DeviceType == "text_screen") then

        if ent:GetPos():Distance( ply:GetPos() ) >= 10000 then return end

        --print("text screen", SysTime(), ent:GetPos():Distance( ply:GetPos() ) )

        HALOARMORY.INTERFACE.CONTROL_PANEL.SIGN.DrawScreen( ent )

    end
    
end

