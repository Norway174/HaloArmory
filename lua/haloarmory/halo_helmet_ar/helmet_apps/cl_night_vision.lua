HALOARMORY.MsgC("Client HALO Augmented Reality NV/FLIR Loading.")

NV = NV or {}

local nv_toggspeed = CreateClientConVar("nv_toggspeed", 0.09, true, false, "How fast the night vision toggles on/off")

local nv_illum_area = CreateClientConVar("nv_illum_area", 512, true, false, "The radius of the illumination light")
local nv_illum_bright = CreateClientConVar("nv_illum_bright", 1, true, false, "The brightness of the illumination light")
local nv_aim_status = CreateClientConVar("nv_aim_status", 0, true, false, "Whether the night vision should aim at the player's crosshair")
local nv_aim_range = CreateClientConVar("nv_aim_range", 200, true, false, "The range of the night vision's aiming feature")

local nv_etisd_status = CreateClientConVar("nv_etisd_status", 0, true, false, "Whether the Eye Trace Illumination-Sensitive Detection feature should be enabled")
local nv_etisd_sensitivity_range = CreateClientConVar("nv_etisd_sensitivity_range", 200, true, false, "The range of the Eye Trace Illumination-Sensitive Detection feature")

local nv_id_status = CreateClientConVar("nv_id_status", 0, true, false, "Whether the Illumination-Detection feature should be enabled")
local nv_id_sens_darkness = CreateClientConVar("nv_id_sens_darkness", 0.25, true, false, "The darkness sensitivity of the Illumination-Detection feature")
local nv_id_reaction_time = CreateClientConVar("nv_id_reaction_time", 1, true, false, "The reaction time of the Illumination-Detection feature")

local nv_isib_status = CreateClientConVar("nv_isib_status", 0, true, false, "Whether the Illumination-Smart Intensity Balancing feature should be enabled")
local nv_isib_sensitivity = CreateClientConVar("nv_isib_sensitivity", 5, true, false, "The sensitivity of the Illumination-Smart Intensity Balancing feature")

local nv_fx_alphapass = CreateClientConVar("nv_fx_alphapass", 5, true, false, "The amount of times the night vision's alpha pass should be drawn")
local nv_fx_blur_status = CreateClientConVar("nv_fx_blur_status", 1, true, false, "Whether the blur effect should be enabled")
local nv_fx_distort_status = CreateClientConVar("nv_fx_distort_status", 1, true, false, "Whether the distortion effect should be enabled")
local nv_fx_colormod_status = CreateClientConVar("nv_fx_colormod_status", 0, true, false, "Whether the color modification effect should be enabled")
local nv_fx_blur_intensity = CreateClientConVar("nv_fx_blur_intensity", 1, true, false, "The intensity of the blur effect")
local nv_fx_goggle_overlay_status = CreateClientConVar("nv_fx_goggle_overlay_status", 0, true, false, "Whether the goggle overlay effect should be enabled")
local nv_fx_bloom_status = CreateClientConVar("nv_fx_bloom_status", 0, true, false, "Whether the bloom effect should be enabled")
local nv_fx_goggle_status = CreateClientConVar("nv_fx_goggle_status", 0, true, false, "Whether the Fisheye goggle effect should be enabled")

local nv_fx_noise_status = CreateClientConVar("nv_fx_noise_status", 0, true, false, "Whether the noise effect should be enabled")
local nv_fx_noise_variety = CreateClientConVar("nv_fx_noise_variety", 20, true, false, "The amount of noise textures to generate")

local nv_type = CreateClientConVar("nv_type", 0, true, false, "0 = Night Vision, 1 = FLIR Thermal Vision")



local Color_Brightness		= 0.8
local Color_Contrast 		= 1.1
local Color_AddGreen		= -0.35
local Color_MultiplyGreen 	= 0.028

local C_B = -0.32

local Bloom_Darken = 0.75
local Bloom_Multiply = 1

local Color_Tab = 
{
	[ "$pp_colour_addr" ] 		= -1,
	[ "$pp_colour_addg" ] 		= Color_AddGreen,
	[ "$pp_colour_addb" ] 		= -1,
	[ "$pp_colour_brightness" ] = Color_Brightness,
	[ "$pp_colour_contrast" ]	= Color_Contrast,
	[ "$pp_colour_colour" ] 	= 0,
	[ "$pp_colour_mulr" ] 		= 0,
	[ "$pp_colour_mulg" ] 		= Color_MultiplyGreen,
	[ "$pp_colour_mulb" ] 		= 0
}

local Clr_FLIR = 
{
	[ "$pp_colour_addr" ] 		= 0,
	[ "$pp_colour_addg" ] 		= 0,
	[ "$pp_colour_addb" ] 		= 0,
	[ "$pp_colour_brightness" ] = -0.38, //-0.65,
	[ "$pp_colour_contrast" ]	= 2.2,
	[ "$pp_colour_colour" ] 	= 0,
	[ "$pp_colour_mulr" ] 		= 0,
	[ "$pp_colour_mulg" ] 		= 0,
	[ "$pp_colour_mulb" ] 		= 0
}

local Clr_FLIR_Ents = 
{
	[ "$pp_colour_addr" ] 		= 0,
	[ "$pp_colour_addg" ] 		= 0,
	[ "$pp_colour_addb" ] 		= 0,
	[ "$pp_colour_brightness" ] = 0.6,
	[ "$pp_colour_contrast" ]	= 1,
	[ "$pp_colour_colour" ] 	= 0,
	[ "$pp_colour_mulr" ] 		= 0,
	[ "$pp_colour_mulg" ] 		= 0,
	[ "$pp_colour_mulb" ] 		= 0
}

local CurScale = 0
local sndOn = Sound( "items/nvg_on.wav" )
local sndOff = Sound( "items/nvg_off.wav" )

//local surface, math, render, util = surface, math, render, util

local BloomStrength = 0
local OverlayTexture = surface.GetTextureID("night_vision/effects/nv_overlaytex.vmt")
local Grain = surface.GetTextureID("night_vision/effects/grain.vmt")
local GrainMat = Material("night_vision/effects/grain")
local Line = surface.GetTextureID("night_vision/effects/nvline.vmt")
local LineMat = Material("night_vision/effects/nvline")
local AlphaPass = surface.GetTextureID("night_vision/effects/nightvision.vmt")
local GrainTable = {}

local CT, Output, FT, OldRT

function NV.GenerateGrainTextures()
	CT = SysTime()
	GrainTable = {cur = 1, wait = 0}
	
	MsgN("NVScript: Generating grain textures...")
	
	OldRT = render.GetRenderTarget()
	local w, h = ScrW(), ScrH()
	
	for i = 1, nv_fx_noise_variety:GetInt() do
		Output = GetRenderTarget("Grain" .. i, w / 4, h / 4, true)

		render.SetRenderTarget(Output)
		render.SetViewPort(0, 0, w / 4, h / 4)
		render.Clear(0, 0, 0, 0)

		cam.Start2D()
			for i2 = 1, h / 4 do
				for i3 = 1, 40 do -- 40 grains per every Y pixel
					render.SetViewPort(math.random(0, w / 4), i2 * 2, 1, 1)
					render.Clear(0, 0, 0, math.random(100, 150))
				end
			end
		cam.End2D()

		Output = GetRenderTarget("Grain" .. i, w / 4, h / 4, true)
		GrainTable[i] = Output
		GrainTable.last = i
	end
	
	render.SetViewPort(0, 0, w, h)
	render.SetRenderTarget(OldRT)
	
	MsgN("NVScript: Generation finished! Time taken: " .. math.Round(SysTime() - CT, 2) .. " second(s).")
end

function NV.GenerateLineTexture()
	CT = SysTime()
	
	MsgN("NVScript: Generating night-vision line texture...")
	
		OldRT = render.GetRenderTarget()
		local w, h = ScrW(), ScrH()
		
		Output = GetRenderTarget("NVLine", w, h, true)

		render.SetRenderTarget(Output)
			render.Clear(0, 0, 0, 0)
			render.SetViewPort(0, 0, w, h)

			cam.Start2D()
				for i = 1, h / 4 do
					render.SetViewPort(0, i * 4, w, 2)
					render.Clear(255, 255, 255, 200)
				end
			cam.End2D()
			
			render.SetViewPort(0, 0, w, h)
		render.SetRenderTarget(OldRT)

		Output = GetRenderTarget("NVLine", w, h, true)
		LineMat:SetTexture("$basetexture", Output)
	
	MsgN("NVScript: Generation finished! Time taken: " .. math.Round(SysTime() - CT, 2) .. " second(s).")
end

function NV.GenerateTextures()
	timer.Simple(2, function()
		--NV.GenerateGrainTextures()
		NV.GenerateLineTexture()
	end)
end

hook.Add("InitPostEntity", "NV_GenerateTextures", NV.GenerateTextures )
NV.GenerateTextures()


function NV.Status()
	return hook.GetTable()["HUDPaintBackground"]["NV_FX"] and true or false
end


function NV.FX()

	if not NV.Status() then
		hook.Remove("HUDPaintBackground", "NV_FX")
		hook.Remove("Think", "NV_Illumination")
		return
	end

	local ply = LocalPlayer()
	
	if not ply:Alive() then
		NV_TurnOFF()
		return
	end

	w, h = ScrW(), ScrH()
	FT = FrameTime()
	
	CurScale = Lerp(FT * (30 * nv_toggspeed:GetInt() ), CurScale, 1)
	
	if not nv_type:GetBool() then
		if nv_fx_bloom_status:GetBool() then
			Bloom_Multiply = Lerp(0.025, Bloom_Multiply, 3)
			Bloom_Darken = Lerp(0.1, Bloom_Darken, 0.75 - BloomStrength)
			
			DrawBloom(Bloom_Darken, Bloom_Multiply, 9, 9, 1, 1, 1, 1, 1)
		end
		
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture(AlphaPass)
		
		for i = 1, nv_fx_alphapass:GetInt() do
			surface.DrawTexturedRect(0, 0, w, h)
		end
		
		surface.SetTexture(Line)
		surface.SetDrawColor(25, 50, 25, 255)
		surface.DrawTexturedRect(0, 0, w, h)
		

		-- if nv_fx_noise_status:GetBool() then
		-- 	for i = 1, nv_fx_noise_variety:GetInt() do
		-- 		surface.SetTexture(GrainTable[i])
		-- 		surface.SetDrawColor(255, 255, 255, 255)
		-- 		surface.DrawTexturedRect(0, 0, w, h)
		-- 	end
		-- end
		
		
		if nv_fx_distort_status:GetBool() then
			DrawMaterialOverlay("models/shadertest/shader3.vmt", 0.0001)
		end
		
		if nv_fx_goggle_status:GetBool() then
			DrawMaterialOverlay("models/props_c17/fisheyelens.vmt", -0.03)
		end
		
		local BlurIntensity = nv_fx_blur_intensity:GetInt()
		
		if nv_fx_blur_status:GetBool() then
			DrawMotionBlur(0.05 * BlurIntensity, 0.2 * BlurIntensity, 0.023 * BlurIntensity)
		end
		
		if nv_fx_colormod_status:GetBool() then
			Color_Tab[ "$pp_colour_brightness" ] = CurScale * Color_Brightness
			Color_Tab[ "$pp_colour_contrast" ] = CurScale * Color_Contrast
			
			DrawColorModify( Color_Tab )
		end
	else
		DrawColorModify(Clr_FLIR)
	end
end

function NV.FLIR()

	if not NV.Status() then
		hook.Remove("PostDrawOpaqueRenderables", "FLIRFX")
		return
	end

	if not nv_type:GetBool() then
		return
	end
	
	render.ClearStencil()
	render.SetStencilEnable(true)
			
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilReferenceValue(1)
			
	render.SuppressEngineLighting(true)
	
	FT = FrameTime()
	
	for _, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() or ent:IsPlayer() then
			if not ent:IsEffectActive(EF_NODRAW) then -- since there is no proper way to check if the NPC is dead, we just check if the NPC has a nodraw effect on him
				render.SuppressEngineLighting(true)
				ent:DrawModel()
				render.SuppressEngineLighting(false)
			end
		elseif ent:GetClass() == "class C_ClientRagdoll" then
			if not ent.Int then
				ent.Int = 1
			else
				ent.Int = math.Clamp(ent.Int - FT * 0.015, 0, 1)
			end
			
			render.SetColorModulation(ent.Int, ent.Int, ent.Int)
				render.SuppressEngineLighting(true)
					ent:DrawModel()
				render.SuppressEngineLighting(false)
			render.SetColorModulation(1, 1, 1)
		end
	end
	
	render.SuppressEngineLighting(false)
	 
	render.SetStencilReferenceValue(2)
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilReferenceValue(1)
	DrawColorModify(Clr_FLIR_Ents)

	render.SetStencilEnable( false )
end



local NV_Vector = 0
local NV_TimeToVector = 0
local ISIBIntensity = 1

local Vec001 = Vector(0, 0, -1)

local reg = debug.getregistry()
local Length = reg.Vector.Length

NV.dlight = NV.dlight or {}
NV.clr = NV.clr or 0

function NV.Illumination()
	local ply = LocalPlayer()

	if not ply:Alive() then
		return
	end

	local EP, EA = ply:EyePos(), ply:EyeAngles():Forward()
	CT = CurTime()

	
	if NV.Status() then	
		local IlluminationArea = nv_illum_area:GetInt()
		local ISIBSensitivity = nv_isib_sensitivity:GetInt()
		local aim = nv_aim_status:GetInt()

		local Brightness = nv_illum_bright:GetFloat()

		local TexLight = NV.TexLight or ProjectedTexture()

		TexLight:SetTexture("effects/flashlight/soft") // effects/flashlight001
		TexLight:SetPos( ply:GetShootPos() )
		TexLight:SetAngles( ply:GetAimVector():Angle() )

		TexLight:SetBrightness( 1 )
		TexLight:SetFarZ( 2048 )
		TexLight:SetFOV( 90 )
		TexLight:SetColor( Color( 125 * Brightness, 255 * Brightness, 125 * Brightness) )

		TexLight:Update()

		NV.TexLight = TexLight


		NV.dlight = DynamicLight(ply:EntIndex())
		
		if NV.dlight then
			FT = FrameTime()
			aim = nv_aim_status:GetInt()
			
			if aim > 0 then
				local tr = {}
				tr.start = EP
				tr.endpos = tr.start + EA * nv_aim_range:GetInt()
				tr.filter = ply
				
				trace = util.TraceLine(tr)

				if not trace.Hit then
					if CT > NV_TimeToVector then
						NV_Vector = math.Clamp(NV_Vector + 1, 0, 20)
						NV_TimeToVector = CT + 0.005
					end
					
					NV.dlight.Pos = trace.HitPos + Vector(0, 0, NV_Vector)
				else
				
					if CT > NV_TimeToVector then
						NV_Vector = math.Clamp(NV_Vector - 1, 0, 20)
						NV_TimeToVector = CT + 0.005
					end
					
					NV.dlight.Pos = trace.HitPos + Vector(0, 0, NV_Vector)
				end
				
			else
				--print("here")
				NV.dlight.Pos = ply:GetShootPos()
			end

			NV.dlight.r = 125 * Brightness
			NV.dlight.g = 255 * Brightness
			NV.dlight.b = 125 * Brightness

			NV.dlight.Brightness = 1
			
			if nv_isib_status:GetInt() < 1 then
				NV.dlight.Size = IlluminationArea * CurScale
				NV.dlight.Decay = IlluminationArea * CurScale
			else
				if aim > 0 then
					--NV.clr = Vector(render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)):Length() * 33
					NV.clr = Length(render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)) * 33
					ISIBIntensity = Lerp(FT * 10, ISIBIntensity, NV.clr * ISIBSensitivity)
				else
					--NV.clr = Vector(render.ComputeLighting(EP, Vec001) - render.ComputeDynamicLighting(EP, Vec001)):Length() * 33
					NV.clr = Length(render.ComputeLighting(EP, Vec001) - render.ComputeDynamicLighting(EP, Vec001)) * 33
					ISIBIntensity = Lerp(FT * 10, ISIBIntensity, NV.clr * ISIBSensitivity)
				end
				
				NV.dlight.Size = math.Clamp((IlluminationArea * CurScale) / ISIBIntensity, 0, IlluminationArea)
				NV.dlight.Decay = math.Clamp((IlluminationArea * CurScale) / ISIBIntensity, 0, IlluminationArea)
			end
			
			NV.dlight.DieTime = CT + FT * 3
		end
	end
end



local IsBrighter = false
local IsMade = false

function NV.MonitorIllumMeter()
	local ply = LocalPlayer()

	if nv_id_status:GetBool() then // Whether the Illumination-Detection feature should be enabled

		if not IsBrighter then

			--clr = Vector((render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)) * 33):Length()
			--NV.clr = Length(render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)) * 33

			if NV.clr < nv_id_sens_darkness:GetInt() then
				if not IsMade then
					timer.Create("MonitorIllumTimer", nv_id_reaction_time:GetInt(), 1, function()
							if NV.clr < nv_id_sens_darkness:GetInt() then
								NV.TurnON()
							else
								NV.TurnOFF()
							end
							
						IsMade = false
					end)
					
					IsMade = true
				end
			else
				timer.Start("MonitorIllumTimer")
			end
		end
		
		if nv_etisd_status:GetBool() then // Whether the Eye Trace Illumination-Sensitive Detection feature should be enabled
			local EP, EA = ply:EyePos(), ply:EyeAngles():Forward()

			local tr = {}
			tr.start = EP
			tr.endpos = tr.start + EA * nv_etisd_sensitivity_range:GetInt()
			tr.filter = ply
			trace = util.TraceLine(tr)

			--NV.clr = Vector((render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)) * 33):Length()
			NV.clr = Length(render.ComputeLighting(trace.HitPos, Vec001) - render.ComputeDynamicLighting(trace.HitPos, Vec001)) * 33

			if NV.clr > nv_id_sens_darkness:GetInt() then -- If we're looking from darkness into somewhere bright
				if not IsBrighter then
					NV.TurnOFF()
					IsBrighter = true
					timer.Stop("MonitorIllumTimer")
				else
					timer.Start("MonitorIllumTimer")
				end
			else
				IsBrighter = false
			end
		end
	end

end

function NV.InitIllumMeter()
	if nv_id_status:GetBool() then
		hook.Add("Think", "MonitorIllumMeter", NV.MonitorIllumMeter)
	else
		hook.Remove("Think", "MonitorIllumMeter")
		timer.Stop("MonitorIllumTimer")
	end
end

cvars.AddChangeCallback("nv_id_status", NV.InitIllumMeter)
NV.InitIllumMeter()


function NV.HUDPaint()
	local ply = LocalPlayer()
	
	if ply:Alive() then
		if NV.Status() then
			if nv_fx_goggle_overlay_status:GetInt() > 0 then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetTexture(OverlayTexture)
				surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
			end
		end
	end
end


// HUDPaintBackground
// RenderScreenspaceEffects

function NV.TurnON()
	CurScale = 0.5

	hook.Add("HUDPaintBackground", "NV_FX", NV.FX)
	hook.Add("Think", "NV_Illumination", NV.Illumination)
	hook.Add("PostDrawOpaqueRenderables", "FLIRFX", NV.FLIR)
	hook.Add("HUDPaint", "NV_HUDPaint", NV.HUDPaint)

	surface.PlaySound( sndOn )
end

function NV.TurnOFF()
	hook.Remove("HUDPaintBackground", "NV_FX")
	hook.Remove("Think", "NV_Illumination")
	hook.Remove("PostDrawOpaqueRenderables", "FLIRFX")
	hook.Remove("HUDPaint", "NV_HUDPaint")

	surface.PlaySound( sndOff )

	if NV.TexLight then
		NV.TexLight:Remove()
		NV.TexLight = nil
	end
end


function NV.ToggleNightVision()
	local ply = LocalPlayer()
	if not ply:Alive() then
		return
	end
	
	if NV.Status() then
		NV.TurnOFF()
	else
		NV.TurnON()
	end
end

concommand.Add("nv_toggle", NV.ToggleNightVision)









if NV.Status() then
	NV.TurnON()
end



-- NVG Toggle
HALOARMORY.AR.RegisterApp("AR_NVG", 10, "Toggle NVG", "vgui/haloarmory/icons/NVG.png", function()
    surface.PlaySound("buttons/button24.wav")

    -- Set the NV type to NVG (0 for NVG)
    RunConsoleCommand("nv_type", 0)
    
    -- If neither NVG nor FLIR is on, toggle NVG on
    if not NV.Status() then
        RunConsoleCommand("nv_toggle")
    else
        -- If NVG is on and we're selecting NVG, turn it off
        if not nv_type:GetBool() then
            RunConsoleCommand("nv_toggle")
        end
    end
end, 
function()
    -- Display correct status for NVG
    return (NV.Status() and not nv_type:GetBool()) and "NVG [ON]" or "NVG [OFF]"
end)

-- FLIR Toggle
HALOARMORY.AR.RegisterApp("AR_FLIR", 11, "Toggle FLIR", "vgui/haloarmory/icons/FLIR.png", function()
    surface.PlaySound("buttons/button24.wav")

    -- Set the NV type to FLIR (1 for FLIR)
    RunConsoleCommand("nv_type", 1)

    -- If neither NVG nor FLIR is on, toggle FLIR on
    if not NV.Status() then
        RunConsoleCommand("nv_toggle")
    else
        -- If FLIR is on and we're selecting FLIR, turn it off
        if nv_type:GetBool() then
            RunConsoleCommand("nv_toggle")
        end
    end

	-- Turn off IFF HUD if it's on, since it's buggy with FLIR.
	hook.Remove( "PreDrawHalos", "HALOARMORY.DrawARIFF" )
end, 
function()
    -- Display correct status for FLIR
    return (NV.Status() and nv_type:GetBool()) and "FLIR [ON]" or "FLIR [OFF]"
end)








function NV.ResetEverything()

	if NV.Status() then
		surface.PlaySound( sndOff )
	end
	
	hook.Remove("HUDPaintBackground", "NV_FX")
	hook.Remove("PostDrawOpaqueRenderables", "FLIRFX")
	hook.Remove("Think", "MonitorIllumMeter")

	-- Night Vision
	nv_toggspeed:Revert()
	nv_illum_area:Revert()
	nv_illum_bright:Revert()
	nv_aim_status:Revert()
	nv_aim_range:Revert()
	nv_type:Revert()

	-- Various features/etc
	nv_id_status:Revert()
	nv_id_sens_darkness:Revert()
	nv_id_reaction_time:Revert()
	nv_etisd_status:Revert()
	nv_etisd_sensitivity_range:Revert()
	nv_isib_status:Revert()
	nv_isib_sensitivity:Revert()

	-- FX
	nv_fx_blur_status:Revert()
	nv_fx_distort_status:Revert()
	nv_fx_colormod_status:Revert()
	nv_fx_goggle_overlay_status:Revert()
	nv_fx_goggle_status:Revert()
	nv_fx_noise_status:Revert()
	nv_fx_noise_variety:Revert()
	nv_fx_bloom_status:Revert()
	nv_fx_blur_intensity:Revert()
	nv_fx_alphapass:Revert()

	LocalPlayer():ChatPrint("Night Vision settings have been reset.")
end
concommand.Add("nv_reset", NV.ResetEverything)