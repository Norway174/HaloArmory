

TOOL.Category = "HALOARMORY"
TOOL.Name = "#tool.halo_ship_attacher_v2.name"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.halo_ship_attacher_v2.name","Ship Attacher V2")
    language.Add("tool.halo_ship_attacher_v2.desc","Attaches a prop to the ship")
    language.Add("tool.halo_ship_attacher_v2.left","Add to ship")
    language.Add("tool.halo_ship_attacher_v2.right","Detach from ship")
    language.Add("tool.halo_ship_attacher_v2.reload","Select the ship")
end



function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "Attacher",Description = [[
Left-Click to attach a prop to the selected ship.
Right-Click to detach a prop from the selected ship.
Reload to select a ship.
    ]]})
end

function TOOL:Think()

    if CLIENT then
        // If the ship is nil, update the desc
        if not IsValid(self:GetEnt( 1 )) then
            language.Add("tool.halo_ship_attacher_v2.desc","Attaches a prop to the ship (No ship selected)")
        else
            local ship_class = self:GetEnt( 1 ):GetClass()
            language.Add("tool.halo_ship_attacher_v2.desc","Attaches a prop to the ship ("..ship_class..")")
        end
    end


end

function TOOL:LeftClick( trace )
    if not IsValid(trace.Entity) then return end

    if trace.Entity == self:GetEnt( 1 ) then
        if CLIENT then 
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't attach the ship to itself.")
        end
        return
    end

    local ship  = self:GetEnt( 1 )

    if not IsValid(ship) then
        if CLIENT then 
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "No ship is selected. Please select a ship first, by pressing R on the ship.")
        end
        return
    end

    if SERVER then
        
        local success, msg = HALOARMORY.Ships.AddProp(ship, trace.Entity)

        local message = { "" }

        local the_object = trace.Entity:GetClass()
        if the_object == "prop_physics" then
            the_object = trace.Entity:GetModel()
        end

        if success then
            message = {
                Color(255,0,0),
                "[HALOARMORY] ",
                Color(238,193,45),
                the_object,
                Color(255,255,255),
                " attached to ",
                Color(159,241,255),
                ship:GetClass(),
                Color(255,255,255),
                "."
            }
        else
            if msg == "Object attached" then
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(238,193,45),
                    the_object,
                    Color(255,255,255),
                    " already attached to ",
                    Color(159,241,255),
                    ship:GetClass(),
                    Color(255,255,255),
                    "."
                }
            else
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(255,255,255),
                    "Error: ",
                    Color(252,156,67),
                    msg
                }
            end
            
        end


        message = table.ToString( message )
        // Trim the first and last character
        message = string.sub(message, 2, string.len(message) - 2)

        local ply = self:GetOwner()
        ply:SendLua("chat.AddText( "..message.." )")
    end
    

end

function TOOL:RightClick( trace )
    if not IsValid(trace.Entity) then return end

    if trace.Entity == self:GetEnt( 1 ) then
        if CLIENT then 
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "You can't attach the ship to itself.")
        end
        return
    end

    local ship  = self:GetEnt( 1 )

    if not IsValid(ship) then
        if CLIENT then 
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "No ship is selected. Please select a ship first, by pressing R on the ship.")
        end
        return
    end

    if SERVER then
        
        local success, msg = HALOARMORY.Ships.RemoveProp(ship, trace.Entity)

        local message = { "" }

        local the_object = trace.Entity:GetClass()
        if the_object == "prop_physics" then
            the_object = trace.Entity:GetModel()
        end

        if success then
            message = {
                Color(255,0,0),
                "[HALOARMORY] ",
                Color(238,193,45),
                the_object,
                Color(255,255,255),
                " detached from ",
                Color(159,241,255),
                ship:GetClass(),
                Color(255,255,255),
                "."
            }
        else
            if msg == "Object is not attached" then
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(238,193,45),
                    the_object,
                    Color(255,255,255),
                    " is not attached to ",
                    Color(159,241,255),
                    ship:GetClass(),
                    Color(255,255,255),
                    "."
                }
            else
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(255,255,255),
                    "Error: ",
                    Color(252,156,67),
                    msg
                }
            end
        end



        message = table.ToString( message )
        // Trim the first and last character
        message = string.sub(message, 2, string.len(message) - 2)

        local ply = self:GetOwner()
        ply:SendLua("chat.AddText( "..message.." )")


    end

end

function TOOL:Reload( trace )
    if not IsValid(trace.Entity) then return end
    local ent = trace.Entity

    if ent.HALOARMORY_Ships_Presets then
        // Set the "ship" convar
        --print("Ship selected", ent)
        self:SetObject( 1, ent, trace.HitPos, trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )
        if CLIENT then 
            chat.AddText(Color(255,0,0), "[HALOARMORY] ", Color(255,255,255), "Ship selected: ", Color(159,241,255), ent:GetClass(), Color(255,255,255), ".")
        end
    end
end





// Add a fallback method to add the prop to the ship with a right click context menu
properties.Add( "ship_attacher_v2", {
    MenuLabel = "HALOARMORY - Toggle Attach", -- Name to display on the context menu
    Order = 10001, -- The order to display this property relative to other properties
    MenuIcon = "icon16/attach.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        
        if ( not IsValid( ply:GetTool() ) ) then return false end
        if ( not IsValid( ply:GetTool():GetEnt( 1 ) ) ) then return false end

        return true
        
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        local ship = LocalPlayer():GetTool():GetEnt( 1 )
        self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
    end,
    Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
        local prop = net.ReadEntity()
        local ship = ply:GetTool():GetEnt( 1 )

        if not IsValid(ship) or not IsValid(prop) then return end

        if not ship.HALOARMORY_Attached then return end


        if not table.HasValue(ship.HALOARMORY_Attached, prop) then // If attaching

            local success, msg = HALOARMORY.Ships.AddProp(ship, prop)

            local message = { "" }
    
            local the_object = prop:GetClass()
            if the_object == "prop_physics" then
                the_object = prop:GetModel()
            end
    
            if success then
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(238,193,45),
                    the_object,
                    Color(255,255,255),
                    " attached to ",
                    Color(159,241,255),
                    ship:GetClass(),
                    Color(255,255,255),
                    "."
                }
            else
                if msg == "Object attached" then
                    message = {
                        Color(255,0,0),
                        "[HALOARMORY] ",
                        Color(238,193,45),
                        the_object,
                        Color(255,255,255),
                        " already attached to ",
                        Color(159,241,255),
                        ship:GetClass(),
                        Color(255,255,255),
                        "."
                    }
                else
                    message = {
                        Color(255,0,0),
                        "[HALOARMORY] ",
                        Color(255,255,255),
                        "Error: ",
                        Color(252,156,67),
                        msg
                    }
                end
                
            end
    
    
            message = table.ToString( message )
            // Trim the first and last character
            message = string.sub(message, 2, string.len(message) - 2)
    
            ply:SendLua("chat.AddText( "..message.." )")

        else // If detaching

            
            local success, msg = HALOARMORY.Ships.RemoveProp(ship, prop)

            local message = { "" }
            local the_object = prop:GetClass()
            if the_object == "prop_physics" then
                the_object = prop:GetModel()
            end
    
            if success then
                message = {
                    Color(255,0,0),
                    "[HALOARMORY] ",
                    Color(238,193,45),
                    the_object,
                    Color(255,255,255),
                    " detached from ",
                    Color(159,241,255),
                    ship:GetClass(),
                    Color(255,255,255),
                    "."
                }
            else
                if msg == "Object is not attached" then
                    message = {
                        Color(255,0,0),
                        "[HALOARMORY] ",
                        Color(238,193,45),
                        the_object,
                        Color(255,255,255),
                        " is not attached to ",
                        Color(159,241,255),
                        ship:GetClass(),
                        Color(255,255,255),
                        "."
                    }
                else
                    message = {
                        Color(255,0,0),
                        "[HALOARMORY] ",
                        Color(255,255,255),
                        "Error: ",
                        Color(252,156,67),
                        msg
                    }
                end
            end



            message = table.ToString( message )
            // Trim the first and last character
            message = string.sub(message, 2, string.len(message) - 2)

            ply:SendLua("chat.AddText( "..message.." )")


        end




    end
} )