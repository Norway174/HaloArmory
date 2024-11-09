
HALOARMORY.MsgC("Client HALO Computer Interface Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}


local PANEL = {}


function PANEL:Init()
	self:SetSize(ScrW() - 150, ScrH() - 150)
	self:Center()
	self:MakePopup()
	self:SetTitle("Computer Interface")
	self:ShowCloseButton(true)
	self:SetDraggable(true)


	// Create a DHTML control
	self.html = vgui.Create( "DHTML", self )
	self.html:Dock( FILL )
	self.html:SetHTML(
		HALOARMORY.Markdown.HTMLHeader ..
		[[<div class="container">
  <img src="https://www.w3schools.com/howto/img_nature_wide.jpg" alt="Norway" style="width:100%;">
  <div class="text-block">
    <h4>Nature</h4>
    <p>What a beautiful sunrise</p>
  </div>
</div>]] ..
		HALOARMORY.Markdown.Parse([[
# HALO Computer Interface
This is the HALO Computer Interface. It is a work in progress.

## Features
- [ ] Notes with Markdown support  
- [ ] Emails to SteamID's
		]]) ..
		HALOARMORY.Markdown.HTMLFooter
	)

end

vgui.Register("HALOARMORY.ComputerInterface", PANEL, "DFrame")


function HALOARMORY.COMPUTER.OpenInterace( ent )
	if IsValid(HALOARMORY.COMPUTER.INTERFACE) then
		HALOARMORY.COMPUTER.INTERFACE:Remove()
	end

	local computerInterface = vgui.Create("HALOARMORY.ComputerInterface")
	HALOARMORY.COMPUTER.INTERFACE = computerInterface
	computerInterface:Init()

	if IsValid(ent) then
		RunConsoleCommand("halo_computer_login", ent:EntIndex())
		computerInterface.OnRemove = function()
			RunConsoleCommand("halo_computer_logout", ent:EntIndex())
		end
	end
end

concommand.Add("halo_computer_open", HALOARMORY.COMPUTER.OpenInterace)

if IsValid(HALOARMORY.COMPUTER.INTERFACE) then
	HALOARMORY.COMPUTER.OpenInterace()
end