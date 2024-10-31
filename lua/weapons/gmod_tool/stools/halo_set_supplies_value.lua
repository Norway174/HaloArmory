

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_set_supplies_value.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.halo_set_supplies_value.name","Vehicle Supplies Value")
    language.Add("tool.halo_set_supplies_value.desc","Sets the configured supplies value to the vehicle.")
    language.Add("tool.halo_set_supplies_value.left","Set Supplies Value")
    language.Add("tool.halo_set_supplies_value.right","Get Supplies Value")
    language.Add("tool.halo_set_supplies_value.reload","Clear all Supplies Values")

    TOOL.ClientConVar["supplies"] = 0
end



function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "Set/Get Supplies", Description = [[
This Tool lets you set the supplies value of a vehicle. Or get the supplies value of a vehicle.
    ]]})

    pnl:AddControl("Slider", {
        Label = "Supplies Value",
        Type = "Integer",
        Min = 0,
        Max = 1000000,
        Command = "halo_set_supplies_value_supplies"
    })
end

function TOOL:Think()
end

function TOOL:ValidVehicle( ent )
    if ent.HALOARMORY_Ships_Presets then return false end

    if ent.LVS then
        return true
    end

    if ent.LVSsimfphys then
        return true
    end

    if ent.IsSimfphyscar then
        return true
    end

    if ent:IsVehicle() then
        return true
    end

    return false
end

function TOOL:LeftClick( trace )
    local ent = trace.Entity
    if not IsValid(ent) then return end

    if not self:ValidVehicle(ent) then return end

    local cost = self:GetClientNumber("supplies")

    if SERVER then
        ent:SetNW2Int( "HALOARMORY_COST", cost )
    else
        notification.AddLegacy( "Set Supplies Value: ".. cost, NOTIFY_GENERIC, 5 )
    end

end

function TOOL:RightClick( trace )
    if SERVER then return end

    local ent = trace.Entity
    if not IsValid(ent) then return end

    if not self:ValidVehicle(ent) then return end

    local cost = ent:GetNW2Int( "HALOARMORY_COST", 0 )

    RunConsoleCommand("halo_set_supplies_value_supplies", cost)

    notification.AddLegacy( "Copied Supplies Value: ".. cost, NOTIFY_GENERIC, 5 )

end

function TOOL:Reload( trace )
    local ent = trace.Entity
    if not IsValid(ent) then return end

    if not self:ValidVehicle(ent) then return end

    if SERVER then
        ent:SetNW2Int( "HALOARMORY_COST", 0 )
    else
        notification.AddLegacy( "Reset Supplies to 0", NOTIFY_GENERIC, 5 )
    end

end


if CLIENT then
    function TOOL:DrawHUD()

        local trace = LocalPlayer():GetEyeTrace()
        local ent = trace.Entity

        if not IsValid(ent) then return end

        if not self:ValidVehicle(ent) then return end

        local x, y = 10, ScrH() / 2 - 50
        draw.RoundedBox( 0, x, y, 200, 100, Color(0,0,0,200) )

        local cost = ent:GetNW2Int( "HALOARMORY_COST", 0 )
        draw.SimpleText("Cost: ".. cost, "Trebuchet24", x + 5, y + 2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local refund = HALOARMORY.Requisition.RefundAmount( ent )
        draw.SimpleText("Refund: ".. refund, "Trebuchet24", x + 5, y + 22, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local new_cost = self:GetClientNumber("supplies")
        draw.SimpleText("New Cost: ".. new_cost, "Trebuchet24", x + 5, y + 42, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    end
end


