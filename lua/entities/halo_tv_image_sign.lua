AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "halo_tv_screen"
 
ENT.PrintName = "Image Screen"
ENT.Category = "HALOARMORY - UNSC"
ENT.Author = "Norway174"
ENT.Spawnable = true

ENT.IsHALOARMORY = true

ENT.DeviceType = "image_screen"

ENT.Editable = true

ENT.SelectedModel = 1

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "SignURL", { KeyName = "URL", Edit = { type = "String", order = 1 } } )
    self:NetworkVar( "Bool", 0, "SignFill", { KeyName = "Fill", Edit = { type = "Boolean", order = 2 } } )
    self:NetworkVar( "Int", 0, "RefreshRate", { KeyName = "Refresh Rate", Edit = { type = "Int", min = 0, max = 120, order = 120 } } )

    if SERVER then
        self:SetSignURL( "https://iili.io/2PlWAZb.jpg" )
        self:SetSignFill( true )
        self:SetRefreshRate( 0 )
    end

    if CLIENT then
        // Update the screen when the URL changes
        self:NetworkVarNotify( "SignURL", function( name, old, new )
            self.SignMaterial = nil
        end )
    end

end

if SERVER then

end


properties.Add( "refresh_image", {
    MenuLabel = "Refresh", -- Name to display on the context menu
    Order = -99999, -- The order to display this property relative to other properties
    MenuIcon = "icon16/computer_edit.png", -- The icon to display next to the property
    PrependSpacer = true,

    Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
        if ( !IsValid( ent ) ) then return false end
        if ( ent:IsPlayer() ) then return false end
        if ( not ply:IsAdmin() ) then return false end
        if ( ent.DeviceType != "image_screen" ) then return false end

        return true
    end,
    Action = function( self, ent )
        // Refresh the screen
    end
} )



if not CLIENT then return end
// Only clients down here!

local function IsValidMaterial(mat)
    return mat and mat:IsError() == false
end

function ENT:Think()
    if self:GetSignURL() == "" then
        return
    end

    if not IsValidMaterial(self.SignMaterial) then
        if not self.NextRequestTime or CurTime() > self.NextRequestTime then
            self.NextRequestTime = CurTime() + 10

            HALOARMORY.INTERFACE.RequestImage(self:GetSignURL(), function(mat)
                self.SignMaterial = mat
            end)
        end
        return
    end

    if self:GetRefreshRate() > 0 then
        if not self.NextRefreshTime then
            self.NextRefreshTime = CurTime() + self:GetRefreshRate()
        end

        if CurTime() > self.NextRefreshTime then
            self.NextRefreshTime = CurTime() + self:GetRefreshRate()
            HALOARMORY.INTERFACE.RequestImage(self:GetSignURL(), function(mat)
                self.SignMaterial = mat
            end, true)
        end
    end

end

function ENT:DrawScreen()

    local model_table = self.ScreenModels[self.Model]

    self.frameW = model_table["frameW"]
    self.frameH = model_table["frameH"]

    // TODO: Draw the image

    // Check if we have a valid URL
    if self:GetSignURL() == "" then return end

    // Check if we have a valid material
    if not self.SignMaterial and not IsValid(self.SignMaterial) then
        return
    end

    // Draw the image
    local w, h = self.frameW, self.frameH - 75

    if not self:GetSignFill() then
            local aspect = self.SignMaterial:Width() / self.SignMaterial:Height()
            if aspect > 1 then
                w = h * aspect
            else
                h = w * aspect
            end
    end

    x = (self.frameW - w) / 2
    y = (self.frameH - h) / 2

    surface.SetMaterial( self.SignMaterial )
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.DrawTexturedRect( x, y, w, h )

end
