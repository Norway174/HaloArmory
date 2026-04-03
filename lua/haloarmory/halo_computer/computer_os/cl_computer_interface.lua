
HALOARMORY.MsgC("Client HALO Computer Interface Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}

-- Helper function to escape JSON string for JavaScript string literal
local function EscapeJSONForJavaScript(jsonString)
    if not jsonString then return "null" end
    local escaped = jsonString
    escaped = string.gsub(escaped, "\\", "\\\\")  -- Escape backslashes first
    escaped = string.gsub(escaped, "\"", "\\\"")    -- Escape double quotes
    escaped = string.gsub(escaped, "\n", "\\n")     -- Escape newlines
    escaped = string.gsub(escaped, "\r", "\\r")     -- Escape carriage returns
    escaped = string.gsub(escaped, "'", "\\'")       -- Escape single quotes
    return escaped
end

local function BuildInterfaceTitle(ent)
	local title = "Computer Interface"

	if not IsValid(ent) then
		return title
	end

	local pcId = ent.GetPC_ID and ent:GetPC_ID() or nil
	if pcId and pcId ~= "" then
		return string.format("%s [PERSISTENT: %s]", title, pcId)
	end

	return title .. " [NOT PERSISTENT]"
end

HALOARMORY.COMPUTER.INTERFACE.PRESETS = HALOARMORY.COMPUTER.INTERFACE.PRESETS or {}

local PRESETS = HALOARMORY.COMPUTER.INTERFACE.PRESETS

local function EscapeJavaScriptString(value)
	if not value then return "" end

	local escaped = tostring(value)
	escaped = string.gsub(escaped, "\\", "\\\\")
	escaped = string.gsub(escaped, "\n", "\\n")
	escaped = string.gsub(escaped, "\r", "\\r")
	escaped = string.gsub(escaped, "'", "\\'")
	return escaped
end

local function SendPresetResponse(callbackId, payload)
	local frame = HALOARMORY.COMPUTER.INTERFACE.frame
	if not IsValid(frame) or not IsValid(frame.html) then
		return
	end

	local payloadJson = util.TableToJSON(payload or {}) or "{}"
	local escapedPayload = EscapeJSONForJavaScript(payloadJson)
	local escapedCallbackId = EscapeJavaScriptString(callbackId or "")

	frame.html:RunJavascript(string.format([[
		if (window.settingsApp && window.settingsApp.handlePresetCallback) {
			window.settingsApp.handlePresetCallback('%s', "%s");
		}
	]], escapedCallbackId, escapedPayload))
end

local function EnsurePresetsDirectory()
	local presetPath = HALOARMORY.COMPUTER.PresetsPC or (HALOARMORY.COMPUTER.Directory .. "presets/")
	if not file.IsDir(presetPath, "DATA") then
		file.CreateDir(presetPath)
	end
	return presetPath
end

local function TrimUnderscores(value)
	value = string.gsub(value or "", "^_+", "")
	value = string.gsub(value or "", "_+$", "")
	return value
end

local function BuildPresetFileName(displayName)
	local safeName = string.Trim(displayName or "")
	safeName = string.lower(safeName)
	safeName = string.gsub(safeName, "[^%w%s%-_]", "")
	safeName = string.gsub(safeName, "%s+", "_")
	safeName = string.gsub(safeName, "_+", "_")
	safeName = TrimUnderscores(safeName)

	if safeName == "" then
		safeName = "preset"
	end

	return safeName .. ".preset.dat"
end

local function ReadPresetPayload(fileName)
	if not fileName or fileName == "" then
		return nil
	end

	local presetPath = EnsurePresetsDirectory()
	local fullPath = presetPath .. fileName
	if not file.Exists(fullPath, "DATA") then
		return nil
	end

	local raw = file.Read(fullPath, "DATA")
	if not raw or raw == "" then
		return nil
	end

	local success, data = pcall(util.JSONToTable, raw)
	if not success or not istable(data) then
		return nil
	end

	return data
end

function PRESETS.List(callbackId)
	local presetPath = EnsurePresetsDirectory()
	local files = file.Find(presetPath .. "*", "DATA") or {}
	local presets = {}

	for _, fileName in ipairs(files) do
		if string.match(string.lower(fileName), "%.preset%.dat$") then
			local payload = ReadPresetPayload(fileName)
			local displayName = string.gsub(fileName, "%.preset%.dat$", "")
			local updatedAt = nil

			if istable(payload) then
				displayName = payload.name or displayName
				updatedAt = payload.updatedAt
			end

			table.insert(presets, {
				fileName = fileName,
				name = displayName,
				updatedAt = updatedAt
			})
		end
	end

	table.sort(presets, function(a, b)
		return string.lower(a.name or "") < string.lower(b.name or "")
	end)

	SendPresetResponse(callbackId, {
		success = true,
		presets = presets
	})
end

function PRESETS.Save(callbackId, displayName, configJson)
	displayName = string.Trim(displayName or "")
	if displayName == "" then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Preset name is required."
		})
		return
	end

	local success, config = pcall(util.JSONToTable, configJson or "")
	if not success or not istable(config) then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Preset data was invalid."
		})
		return
	end

	local presetPath = EnsurePresetsDirectory()
	local fileName = BuildPresetFileName(displayName)
	local payload = {
		name = displayName,
		updatedAt = os.date("%Y-%m-%d %H:%M:%S"),
		config = config
	}

	local payloadJson = util.TableToJSON(payload)
	if not payloadJson then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Could not encode preset data."
		})
		return
	end

	file.Write(presetPath .. fileName, payloadJson)

	SendPresetResponse(callbackId, {
		success = true,
		fileName = fileName,
		name = displayName
	})
end

function PRESETS.Load(callbackId, fileName)
	local payload = ReadPresetPayload(fileName)
	if not istable(payload) or not istable(payload.config) then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Preset could not be loaded."
		})
		return
	end

	SendPresetResponse(callbackId, {
		success = true,
		preset = {
			fileName = fileName,
			name = payload.name or string.gsub(fileName or "", "%.preset%.dat$", ""),
			updatedAt = payload.updatedAt,
			config = payload.config
		}
	})
end

function PRESETS.Delete(callbackId, fileName)
	if not fileName or fileName == "" then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Preset name was invalid."
		})
		return
	end

	local presetPath = EnsurePresetsDirectory()
	local fullPath = presetPath .. fileName
	if not file.Exists(fullPath, "DATA") then
		SendPresetResponse(callbackId, {
			success = false,
			message = "Preset was not found."
		})
		return
	end

	file.Delete(fullPath)

	SendPresetResponse(callbackId, {
		success = true
	})
end

local PANEL = {}

function PANEL:Init()
	if IsValid(self.html) then
		return
	end

	local frameWidth = math.min(ScrW() - 10, 1280)
	local frameHeight = math.min(ScrH() - 10, 720)

	self:SetSize(frameWidth, frameHeight)
	self:Center()
	self:MakePopup()
	self:SetTitle(BuildInterfaceTitle(self.entity or HALOARMORY.COMPUTER.INTERFACE.entity))
	self:ShowCloseButton(true)
	self:SetDraggable(true)


	// Create a DHTML control
	self.html = vgui.Create( "DHTML", self )
	self.html:Dock( FILL )

	// Enable Lua bridge
	//self.html:AllowLua(true)

	// Set up Lua callback handler
	self.html:AddFunction("console", "lua_exec", function(luaCode)
		-- Execute Lua code from JavaScript
		local func = CompileString(luaCode, "HTML_Lua_Bridge", false)
		if func then
			local success, err = pcall(func)
			if not success then
				print("Lua Bridge Error: ", err)
			end
		end
	end)

	// Add function to close the interface
	self.html:AddFunction("console", "close_interface", function()
		if IsValid(self) then
			self:Remove()
		end
	end)

	// Add filesystem callback function
	self.html:AddFunction("filesystem", "callback", function(callbackId, resultJson)
		-- Call JavaScript callback function
		if self.html and IsValid(self.html) then
			-- Escape special characters for JavaScript string literal
			local escapedJson = EscapeJSONForJavaScript(resultJson or "null")

			local jsCode = string.format([[
				try {
					if (window.filesystemCallback) {
						var result = null;
						try {
							var jsonStr = "%s";
							result = JSON.parse(jsonStr);
						} catch(e) {
							console.error("JSON parse error:", e, "jsonStr:", jsonStr);
							result = null;
						}
						window.filesystemCallback('%s', result);
					} else {
						console.error("window.filesystemCallback not found!");
					}
				} catch(e) {
					console.error("filesystem.callback JS error:", e);
				}
			]], escapedJson, callbackId)
			self.html:RunJavascript(jsCode)
		end
	end)

	// Add email bridge request function
	self.html:AddFunction("email", "request", function(callbackId, action, payloadJson)
		if HALOARMORY.COMPUTER.INTERFACE.EMAIL and HALOARMORY.COMPUTER.INTERFACE.EMAIL.HandleUIRequest then
			HALOARMORY.COMPUTER.INTERFACE.EMAIL.HandleUIRequest(callbackId, action, payloadJson)
		end
	end)

	// Load and set HTML
	local htmlContent = include(HALOARMORY.GetOwnScriptPath() .. "html/index.lua")

	// Save a copy of the HTML locally for debugging
	file.Write(HALOARMORY.COMPUTER.Directory .. "html.txt", htmlContent)

	self.html:SetHTML(htmlContent)

end

vgui.Register("HALOARMORY.ComputerInterface", PANEL, "DFrame")


function HALOARMORY.COMPUTER.OpenInterface( ent )
	if IsValid(HALOARMORY.COMPUTER.INTERFACE.frame) then
		HALOARMORY.COMPUTER.INTERFACE.frame:Remove()
	end

	-- Store entity reference for filesystem bridge
	HALOARMORY.COMPUTER.INTERFACE.entity = ent

	-- Request PC_Files sync from server
	if IsValid(ent) then
		if HALOARMORY.COMPUTER.INTERFACE.NETWORK and HALOARMORY.COMPUTER.INTERFACE.NETWORK.RequestPCFiles then
			HALOARMORY.COMPUTER.INTERFACE.NETWORK.RequestPCFiles(ent:EntIndex())
		end
	end

	local computerInterface = vgui.Create("HALOARMORY.ComputerInterface")
	HALOARMORY.COMPUTER.INTERFACE.frame = computerInterface
	computerInterface.entity = ent
	computerInterface:SetTitle(BuildInterfaceTitle(ent))

	if IsValid(ent) then
		RunConsoleCommand("halo_computer_login", ent:EntIndex())
		computerInterface.OnRemove = function()
			RunConsoleCommand("halo_computer_logout", ent:EntIndex())
			HALOARMORY.COMPUTER.INTERFACE.entity = nil
		end
	end
end

concommand.Add("halo_computer_open", HALOARMORY.COMPUTER.OpenInterface)
