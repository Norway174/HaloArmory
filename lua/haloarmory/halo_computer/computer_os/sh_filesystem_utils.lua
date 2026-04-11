--[[
    File: sh_filesystem_utils.lua
    Purpose: Shared filesystem utilities for WebOS
    Realm: Shared (Client & Server)
    
    Description:
        Provides common functions for path handling, validation, and filename
        sanitization. Respects GMod's file.Write restrictions (forced lowercase,
        character restrictions, required extensions).
    
    Key Functions:
        - ValidatePath: Prevents directory traversal attacks
        - SanitizeFilename: Handles GMod restrictions and file extensions
        - GetDisplayName: Derives user-friendly names from filenames
        - ParsePath: Splits drive:/path format with validation
        - GetFileType: Determines file type from extension
        
    File Type System:
        .txt           → Plain text files (no JSON wrapper)
        .shortcut.dat  → Shortcuts (JSON metadata)
        .dat           → Config and data files (JSON)
]]--

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.FILESYSTEM_UTILS = HALOARMORY.COMPUTER.FILESYSTEM_UTILS or {}

local UTILS = HALOARMORY.COMPUTER.FILESYSTEM_UTILS

-- GMod file.Write restrictions (from wiki.facepunch.com/gmod/file.Write):
-- - Filename is forced lowercase
-- - Path is relative to data/ folder
-- - Restricted symbols: ":", multiple consecutive spaces, and most non-Latin characters
-- - Must end with: .txt, .dat, .json, .xml, .csv, .dem, .vcd, .gma, .mdl, .phy, .vvd, .vtx, .ani, .vtf, .vmt, .png, .jpg, .jpeg, .mp3, .wav, .ogg

-- File type constants
UTILS.FILETYPE_TEXT = ".txt"           -- Plain text files (no JSON wrapper)
UTILS.FILETYPE_SHORTCUT = ".shortcut.dat"  -- Shortcut files (JSON metadata)
UTILS.FILETYPE_IMAGE = ".image.dat"    -- Image files (JSON metadata + data payload)
UTILS.FILETYPE_CONFIG = ".dat"         -- Config files (JSON settings)
UTILS.ALLOWED_EXTENSIONS = {
    [".txt"] = true,
    [".dat"] = true,
    [".json"] = true,
    [".xml"] = true,
    [".csv"] = true,
    [".dem"] = true,
    [".vcd"] = true,
    [".gma"] = true,
    [".mdl"] = true,
    [".phy"] = true,
    [".vvd"] = true,
    [".vtx"] = true,
    [".ani"] = true,
    [".vtf"] = true,
    [".vmt"] = true,
    [".png"] = true,
    [".jpg"] = true,
    [".jpeg"] = true,
    [".mp3"] = true,
    [".wav"] = true,
    [".ogg"] = true
}

local function GetAllowedExtension(name)
    local lowerName = string.lower(name or "")
    local matchedExtension = nil

    for extension, _ in pairs(UTILS.ALLOWED_EXTENSIONS) do
        if string.sub(lowerName, -string.len(extension)) == extension then
            if not matchedExtension or string.len(extension) > string.len(matchedExtension) then
                matchedExtension = extension
            end
        end
    end

    return matchedExtension
end

-- Helper function to validate and sanitize path (prevent directory traversal attacks)
function UTILS.ValidatePath(path)
    if not path or path == "" then
        return false, "Empty path"
    end
    
    -- Check for directory traversal attempts
    if string.find(path, "%.%.") then
        return false, "Invalid path: directory traversal detected"
    end
    
    -- Check for invalid characters (null bytes, etc.)
    if string.find(path, "\0") then
        return false, "Invalid path: null byte detected"
    end
    
    -- Check for absolute paths trying to escape data folder
    if string.find(path, "^/") and not string.match(path, "^[A-Za-z]:") then
        if string.find(path, "/%.%.") then
            return false, "Invalid path: absolute path traversal"
        end
    end
    
    return true, nil
end

-- Unified filename sanitization (for both files and folders)
-- GMod forces lowercase and restricts characters
-- Returns: sanitized_filename, error_message
function UTILS.SanitizeFilename(name, fileType)
    if not name or name == "" then
        return nil, "Empty filename"
    end

    local lowerName = string.lower(name)
    local passthroughExtension = GetAllowedExtension(lowerName)
    
    -- Check if name already has the correct extension for the file type
    local hasCorrectExtension = false
    if fileType == "shortcut" then
        if string.match(name, "%.shortcut%.dat$") then
            hasCorrectExtension = true
            -- Extract base name (remove .shortcut.dat extension)
            name = string.gsub(name, "%.shortcut%.dat$", "")
        end
    elseif fileType == "image" then
        if string.match(name, "%.image%.dat$") then
            hasCorrectExtension = true
            name = string.gsub(name, "%.image%.dat$", "")
        elseif string.match(name, "%.image$") then
            hasCorrectExtension = true
            name = string.gsub(name, "%.image$", "")
        elseif string.match(name, "%.png$") or string.match(name, "%.jpg$") or string.match(name, "%.jpeg$") then
            hasCorrectExtension = true
            name = string.gsub(name, "%.[^.]+$", "")
        end
    elseif fileType == "config" then
        if string.match(name, "%.dat$") and (name == "config.dat" or name == ".config.dat") then
            hasCorrectExtension = true
            name = "config"
        end
    elseif fileType == "text" or fileType == "file" then
        if string.match(name, "%.txt$") then
            hasCorrectExtension = true
            -- Extract base name (remove .txt extension)
            name = string.gsub(name, "%.txt$", "")
        end
    elseif (fileType == "image" or fileType == "passthrough" or fileType == "file") and passthroughExtension and UTILS.ALLOWED_EXTENSIONS[passthroughExtension] then
        hasCorrectExtension = true
        name = string.gsub(name, "%.[^.]+$", "")
    end
    
    -- Convert to lowercase (GMod requirement)
    name = string.lower(name)
    
    -- Replace spaces with underscores
    name = string.gsub(name, "%s+", "_")

    -- Allow Latin letters, digits, underscores, hyphens, and periods
    name = string.gsub(name, "[^a-z0-9_%.%-]", "")

    -- Special files/folders reserve a leading period
    name = string.gsub(name, "^%.+", "")

    -- Remove leading/trailing underscores
    name = string.gsub(name, "^_+", "")
    name = string.gsub(name, "_+$", "")

    -- Collapse multiple underscores
    name = string.gsub(name, "_+", "_")

    -- Clamp to max length
    if string.len(name) > 32 then
        name = string.sub(name, 1, 32)
        name = string.gsub(name, "_+$", "")
    end
    
    -- Ensure we have something left
    if name == "" then
        name = "untitled"
    end
    
    -- Add appropriate extension based on file type
    if fileType == "shortcut" then
        return name .. UTILS.FILETYPE_SHORTCUT, nil
    elseif fileType == "image" then
        return name .. UTILS.FILETYPE_IMAGE, nil
    elseif fileType == "config" then
        return "config" .. UTILS.FILETYPE_CONFIG, nil
    elseif fileType == "text" or fileType == "file" then
        return name .. UTILS.FILETYPE_TEXT, nil
    elseif (fileType == "image" or fileType == "passthrough" or fileType == "file") and passthroughExtension and UTILS.ALLOWED_EXTENSIONS[passthroughExtension] then
        return name .. passthroughExtension, nil
    elseif fileType == "directory" or fileType == "folder" then
        -- Directories don't get extensions
        return name, nil
    else
        -- Default to .txt
        return name .. UTILS.FILETYPE_TEXT, nil
    end
end

-- Derive display name from sanitized filename
-- Example: "my_cool_file.txt" -> "My Cool File"
function UTILS.GetDisplayName(filename)
    if not filename then return "untitled" end
    
    -- Handle special files
    if filename == "config.dat" then
        return ".config"
    end

    if string.match(filename, "%.shortcut%.dat$") then
        return string.gsub(filename, "%.shortcut%.dat$", "")
    end

    if string.match(filename, "%.image%.dat$") then
        local baseName = string.gsub(filename, "%.image%.dat$", "")
        baseName = string.gsub(baseName, "%.(png|jpg|jpeg)$", "")
        return baseName .. ".image"
    end

    if string.match(filename, "%.txt$") then
        return string.gsub(filename, "%.txt$", "")
    end

    return filename
end

-- Parse drive:path format
-- Returns: drive, filepath, error
function UTILS.ParsePath(path)
    -- Validate path first
    local valid, err = UTILS.ValidatePath(path)
    if not valid then
        return nil, nil, err
    end
    
    local drive, filepath = string.match(path, "^([^:]+):(.+)$")
    if not drive or not filepath then
        return nil, nil, "Invalid path format (expected 'drive:/path')"
    end
    
    return drive, filepath, nil
end

-- Determine file type from filename
function UTILS.GetFileType(filename)
    if not filename then return "unknown" end
    
    if string.match(filename, "%.shortcut%.dat$") then
        return "shortcut"
    elseif string.match(filename, "%.image%.dat$") then
        return "image"
    elseif string.match(filename, "%.image$") then
        return "image"
    elseif filename == "config.dat" then
        return "config"
    elseif string.match(filename, "%.txt$") then
        return "text"
    elseif string.match(filename, "%.json$") or string.match(filename, "%.xml$") or string.match(filename, "%.csv$") then
        return "text"
    elseif string.match(filename, "%.png$") or string.match(filename, "%.jpg$") or string.match(filename, "%.jpeg$") then
        return "image"
    elseif string.match(filename, "%.mp3$") or string.match(filename, "%.wav$") or string.match(filename, "%.ogg$") then
        return "audio"
    elseif string.match(filename, "%.dem$") or string.match(filename, "%.vcd$") or string.match(filename, "%.gma$") or string.match(filename, "%.mdl$") or string.match(filename, "%.phy$") or string.match(filename, "%.vvd$") or string.match(filename, "%.vtx$") or string.match(filename, "%.ani$") or string.match(filename, "%.vtf$") or string.match(filename, "%.vmt$") then
        return "file"
    elseif string.match(filename, "%.exe$") then
        return "program"
    elseif string.match(filename, "%.dat$") then
        return "data"
    else
        return "unknown"
    end
end

-- Check if a file should be stored as JSON
function UTILS.IsJSONFile(filename)
    local fileType = UTILS.GetFileType(filename)
    return fileType == "shortcut" or fileType == "image" or fileType == "config" or fileType == "data"
end

-- Check if path is to C:/ drive (vs ExternalDrive:/)
function UTILS.IsCDrive(path)
    if not path then return true end -- Default to C:
    return string.match(path, "^C:") ~= nil
end

-- Check if path is to ExternalDrive:/
function UTILS.IsExternalDrive(path)
    if not path then return false end
    return string.match(path, "^ExternalDrive:") ~= nil
end

return UTILS

