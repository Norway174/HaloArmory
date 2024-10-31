

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_ship_attacher.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.AddToMenu = false

if(CLIENT) then
    TOOL.SelectedShip = nil
    TOOL.Information = {
        { name = "left" },
        { name = "right" },
        { name = "reload" },
    }
    language.Add("tool.halo_ship_attacher.name","Ship Attacher")
    language.Add("tool.halo_ship_attacher.desc","Attaches a prop to the ship")
    language.Add("tool.halo_ship_attacher.left","Add to ship")
    language.Add("tool.halo_ship_attacher.right","Detach from ship")
    language.Add("tool.halo_ship_attacher.reload","Select the ship")


    function TOOL.BuildCPanel(pnl)
        pnl:AddControl("Header",{Text = "Attacher",Description = [[
Left-Click to attach a prop to the selected ship.
Right-Click to detach a prop from the selected ship.
Reload to select a ship.
        ]]})
    end

    function TOOL:Think()

        // If the ship is invalid, set it to nil
        if not IsValid(self.SelectedShip) then
            self.SelectedShip = nil
        end

        // If the ship is nil, update the desc
        if(self.SelectedShip == nil) then
            language.Add("tool.halo_ship_attacher.desc","Attaches a prop to the ship (No ship selected)")
        else
            local ship_class = self.SelectedShip:GetClass()
            language.Add("tool.halo_ship_attacher.desc","Attaches a prop to the ship ("..ship_class..")")
        end

    end

    function TOOL:LeftClick( trace )
        if trace.Entity == self.SelectedShip then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't attach the ship to itself.")
            return
        end

        net.Start("HALOARMORY.SHIP.STOOL.ATTACH")
            net.WriteBool(true)
            net.WriteEntity(self.SelectedShip)
            net.WriteEntity(trace.Entity)
        net.SendToServer()
    end

    function TOOL:RightClick( trace )
        if trace.Entity == self.SelectedShip then
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't deatach the ship from itself.")
            return
        end

        net.Start("HALOARMORY.SHIP.STOOL.ATTACH")
            net.WriteBool(false)
            net.WriteEntity(self.SelectedShip)
            net.WriteEntity(trace.Entity)
        net.SendToServer()
    end

    function TOOL:Reload( trace )
        local ent = trace.Entity

        if ent.HALOARMORY_Ships_Presets then
            // Set the "ship" convar
            --print("Ship selected", ent)
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Ship selected: ", Color(159,241,255), ent:GetClass(), Color(255,255,255), ".")
            self.SelectedShip = ent
        end
    end

    net.Receive("HALOARMORY.SHIP.STOOL.CHATPRINT", function(len, ply)
        local text = net.ReadTable()

        chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), unpack(text))

    end)
end

if (SERVER) then
    util.AddNetworkString("HALOARMORY.SHIP.STOOL.ATTACH")
    util.AddNetworkString("HALOARMORY.SHIP.STOOL.CHATPRINT")

    net.Receive("HALOARMORY.SHIP.STOOL.ATTACH", function(len, ply)
        local attach = net.ReadBool()
        local ship = net.ReadEntity()
        local prop = net.ReadEntity()

        if not IsValid(ship) or not IsValid(prop) then return end

        if not ship.HALOARMORY_Attached then return end

        local success = false
        local text = {"An error has accoured trying to attach the prop to the ship."}

        if attach then // If attaching

            if table.HasValue(ship.HALOARMORY_Attached, prop) then
                // Already attached
                text = {"Prop is already attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            else
                // Attach
                success = HALOARMORY.Ships.AddProp(ship, prop)
                text = {"Prop attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            end


        else // If detaching

            if table.HasValue(ship.HALOARMORY_Attached, prop) then
                // Detach
                success = HALOARMORY.Ships.RemoveProp(ship, prop)
                text = {"Prop detached from ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            else
                // Already detached
                text = {"The prop is not attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            end
        end

        print("Success:", success)
        if success then
            net.Start("HALOARMORY.SHIP.STOOL.CHATPRINT")
                net.WriteTable(text)
            net.Send(ply)
        else
            -- net.Start("HALOARMORY.SHIP.STOOL.CHATPRINT")
            --     net.WriteTable(text)
            -- net.Send(ply)
        end

    end)


end



// Add a fallback method to add the prop to the ship with a right click context menu
properties.Add( "ship_attacher", {
    MenuLabel = "HALOARMORY - Toggle Attach", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/attach.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        
        if ( not IsValid( ply:GetTool() ) ) then return false end
        if ( not IsValid( ply:GetTool().SelectedShip ) ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        local ship = LocalPlayer():GetTool().SelectedShip
        self:MsgStart()
			net.WriteEntity( ship )
			net.WriteEntity( ent )
		self:MsgEnd()
    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        local ship = net.ReadEntity()
        local prop = net.ReadEntity()

        if not IsValid(ship) or not IsValid(prop) then return end

        if not ship.HALOARMORY_Attached then return end

        local success = false
        local text = {"An error has accoured trying to attach the prop to the ship."}

        if not table.HasValue(ship.HALOARMORY_Attached, prop) then // If attaching

            if table.HasValue(ship.HALOARMORY_Attached, prop) then
                // Already attached
                text = {"Prop is already attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            else
                // Attach
                success = HALOARMORY.Ships.AddProp(ship, prop)
                text = {"Prop attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            end


        else // If detaching

            if table.HasValue(ship.HALOARMORY_Attached, prop) then
                // Detach
                success = HALOARMORY.Ships.RemoveProp(ship, prop)
                text = {"Prop detached from ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            else
                // Already detached
                text = {"The prop is not attached to ", Color(159,241,255), ship:GetClass(), Color(255,255,255), "."}
            end
        end

        print("Success:", success)
        if success then
            net.Start("HALOARMORY.SHIP.STOOL.CHATPRINT")
                net.WriteTable(text)
            net.Send(ply)
        else

        end


    end
} )