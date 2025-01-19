HALOARMORY.MsgC("Shared INTERFACE Image Utilities Loaded!")


HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}

if not CLIENT then return end

local BaseDir = "haloarmory/"
local CacheDir = BaseDir .. "images_cache/"

local function CRC(url)
	local crc = util.CRC(url)

	// Check if the image 
	local fileName = crc..".png"
	// Check if the url ends with .jpg
	if string.EndsWith(url, ".jpg") then
		fileName = crc..".jpg"
	end

	return fileName
end

local IsDownloading = false

function HALOARMORY.INTERFACE.RequestImage(url, callbackFunc, force)
	local filename = CRC(url)
	force = force or false

	if file.Exists(CacheDir..filename, "DATA") and not force then
		callbackFunc( Material("data/"..CacheDir..filename) )
		return
	end

	if IsDownloading then
		callbackFunc( Material("vgui/null") )
		return
	end
	IsDownloading = true
	
	http.Fetch(url, function(body, size, headers, code)
		IsDownloading = false
		print("Downloaded image: ", url,"->", CacheDir..filename, "Web:", code, #body)
		if code == 200 then
			if not file.IsDir(CacheDir, "DATA") then
				file.CreateDir(CacheDir)
			end
			file.Write(CacheDir..filename, body)

			callbackFunc( Material("data/"..CacheDir..filename) )
		else
			callbackFunc( Material("vgui/null") )
		end
	end)
	
end

