HALOARMORY.MsgC("Client HALO Augmented Reality NV/FLIR QMenu Settings Loading.")

nvspanel = {}
nvspanel.NVSPanelB = nil

function nvspanel.NVSPanelA(panel)
	panel:ClearControls()
	
	panel:AddControl("Label", {Text = "Main Controls"})
	panel:AddControl("Button", {Label = "Toggle Night Vision", Command = "nv_toggle"})
	panel:AddControl("Slider", {Label = "Toggle Speed", Command = "nv_toggspeed", Type = "Float", Min = "0.02", Max = "1"})
	panel:AddControl("Slider", {Label = "Illumination Radius", Command = "nv_illum_area", Type = "Integer", Min = "64", Max = "1024"})
	panel:AddControl("Slider", {Label = "Illumination Brightness", Command = "nv_illum_bright", Type = "Float", Min = "0.2", Max = "1"})
	
	local Type = vgui.Create("DComboBox", panel)
	Type:SetText("Goggle Type")
	Type:AddChoice("Night Vision")
	Type:AddChoice("FLIR (Thermal)")
	Type.OnSelect = function(_panel, index, value, data)
		RunConsoleCommand("nv_type", tonumber(index) - 1)
	end
	
	panel:AddItem(Type)
	
	panel:AddControl("Label", {Text = "Alternate Illumination Method (AIM)"})
	panel:AddControl("CheckBox", {Label = "AIM: Status", Description = "", Command = "nv_aim_status"})
	panel:AddControl("Slider", {Label = "AIM: Range", Command = "nv_aim_range", Type = "Integer", Min = "50", Max = "300"})
	
	panel:AddControl("Label", {Text = "Illumination-Detection Controls"})
	panel:AddControl("CheckBox", {Label = "ID: Status", Description = "", Command = "nv_id_status"})
	panel:AddControl("Slider", {Label = "ID: Darkness sensitivity", Command = "nv_id_sens_darkness", Type = "Float", Min = "0.05", Max = "1"})
	panel:AddControl("Slider", {Label = "ID: Reaction Time", Command = "nv_id_reaction_time", Type = "Float", Min = "0.1", Max = "1.5"})
	
	panel:AddControl("Label", {Text = "Eye Trace Illumination-Sensitive Detection Controls"})
	panel:AddControl("CheckBox", {Label = "ETISD: Status", Description = "", Command = "nv_etisd_status"})
	panel:AddControl("Slider", {Label = "ETISD: Range", Command = "nv_etisd_sensitivity_range", Type = "Integer", Min = "100", Max = "500"})
	
	panel:AddControl("Label", {Text = "Illumination-Smart Intensity Balancing Controls"})
	panel:AddControl("CheckBox", {Label = "ISIB: Status", Description = "", Command = "nv_isib_status"})
	panel:AddControl("Slider", {Label = "ISIB: sensitivity", Command = "nv_isib_sensitivity", Type = "Float", Min = "2", Max = "10"})
	
	panel:AddControl("Label", {Text = "Night Vision FX Controls"})
	panel:AddControl("CheckBox", {Label = "FX: Use Distortion Effect?", Description = "Use Distortion Effect?", Command = "nv_fx_distort_status"})
	panel:AddControl("CheckBox", {Label = "FX: Use Blur Effect?", Description = "Use Blur Effect?", Command = "nv_fx_blur_status"})
	panel:AddControl("CheckBox", {Label = "FX: Use Color Mod? (Recommended)", Description = "Use Green Overlay Effect?", Command = "nv_fx_colormod_status"})

	panel:AddControl("CheckBox", {Label = "FX: Use Noise Effect?", Description = "Use Noise Effect?", Command = "nv_fx_noise_status"})
	panel:AddControl("Slider", {Label = "NOISE: Noise texture amount", Command = "nv_fx_noise_variety", Type = "Int", Min = "5", Max = "40"})
	panel:AddControl("Button", {Label = "NOISE: Generate textures", Command = "nv_generate_noise_textures"})
	
	panel:AddControl("CheckBox", {Label = "FX: Use Goggle Effect?", Description = "Use Camera Effect?", Command = "nv_fx_goggle_status"})
	panel:AddControl("CheckBox", {Label = "FX: Use Goggle Overlay Effect?", Description = "Use Goggle Effect?", Command = "nv_fx_goggle_overlay_status"})
	panel:AddControl("CheckBox", {Label = "FX: Use Bloom Effect?", Description = "Use Bloom Effect?", Command = "nv_fx_bloom_status"})
	
	panel:AddControl("Slider", {Label = "FX: Blur Effect Intensity", Command = "nv_fx_blur_intensity", Type = "Float", Min = "0.2", Max = "1.75"})
	panel:AddControl("Slider", {Label = "FX: Alpha pass amount", Command = "nv_fx_alphapass", Type = "Int", Min = "0", Max = "12"})
	
	panel:AddControl("Label", {Text = "Miscellaneous"})
	panel:AddControl("Button", {Label = "Reset Controls", Command = "nv_reset_everything"})

	panel:AddControl("Label", {Text = "Credits"})
	panel:AddControl("Label", {Text = "Night Vision System by: "})
	panel:AddControl("Label", {Text = "Spy"})
	panel:AddControl("Label", {Text = "Used with permission."})
end

function nvspanel.OpenMySpawnMenu()
	if(nvspanel.NVSPanelB) then
		nvspanel.NVSPanelA(nvspanel.NVSPanelB)
	end
end
hook.Add("SpawnMenuOpen", "nvspanel.OpenMySpawnMenu", nvspanel.OpenMySpawnMenu)

local function PopulateMyMenu_NVS()
	spawnmenu.AddToolMenuOption("Options", "HALOARMORY", "Night Vision", "Client", "", "", nvspanel.NVSPanelA)
end
hook.Add("PopulateToolMenu", "PopulateMyMenu_NVS", PopulateMyMenu_NVS)

