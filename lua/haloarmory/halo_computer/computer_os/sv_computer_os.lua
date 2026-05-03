
HALOARMORY.MsgC("Server HALO Computer Operating System Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}

local function AddClientLuaFiles(directory)
	local files, folders = file.Find(directory .. "*", "LUA")

	for _, fileName in ipairs(files or {}) do
		if string.GetExtensionFromFilename(fileName) == "lua" then
			AddCSLuaFile(directory .. fileName)
		end
	end

	for _, folderName in ipairs(folders or {}) do
		AddClientLuaFiles(directory .. folderName .. "/")
	end
end

AddClientLuaFiles(HALOARMORY.GetOwnScriptPath() .. "html/")
