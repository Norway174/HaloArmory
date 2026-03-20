HALOARMORY.MsgC("Shared HALO Computer Email Core Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.EMAIL = HALOARMORY.COMPUTER.EMAIL or {}

local EMAIL = HALOARMORY.COMPUTER.EMAIL

function EMAIL.GetMailboxDirectory(steamID64)
    if not steamID64 or steamID64 == "" then
        return nil
    end

    local pattern = HALOARMORY.COMPUTER.Directory_Emails
    return string.gsub(pattern, "{steam_id}", tostring(steamID64))
end

function EMAIL.NormalizeSteamID64(value)
    if not value then
        return nil
    end

    value = string.Trim(tostring(value))
    if value == "" then
        return nil
    end

    if string.match(value, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
        return value
    end

    if util.SteamIDTo64 then
        local converted = util.SteamIDTo64(value)
        if converted and converted ~= "0" then
            return converted
        end
    end

    return nil
end

function EMAIL.NormalizeSteamID(value)
    if not value then
        return nil
    end

    value = string.Trim(tostring(value))
    if value == "" then
        return nil
    end

    if string.match(value, "^STEAM_%d:%d:%d+$") then
        return value
    end

    local steamID64 = EMAIL.NormalizeSteamID64(value)
    if steamID64 and util.SteamIDFrom64 then
        return util.SteamIDFrom64(steamID64)
    end

    return nil
end

function EMAIL.SanitizeFileToken(value, fallback)
    local sanitized = string.Trim(string.lower(tostring(value or "")))
    sanitized = string.gsub(sanitized, "[^a-z0-9_%-%.]", "_")
    sanitized = string.gsub(sanitized, "_+", "_")
    sanitized = string.gsub(sanitized, "^_+", "")
    sanitized = string.gsub(sanitized, "_+$", "")

    if sanitized == "" then
        sanitized = fallback or "item"
    end

    return sanitized
end

function EMAIL.SanitizeAttachmentName(name)
    local value = string.Trim(tostring(name or "attachment.txt"))
    if value == "" then
        value = "attachment.txt"
    end

    local extension = string.match(value, "(%.[^%.]+)$") or ".txt"
    local baseName = string.gsub(value, "%.[^%.]+$", "")
    baseName = EMAIL.SanitizeFileToken(baseName, "attachment")
    extension = string.gsub(string.lower(extension), "[^a-z0-9%.]", "")

    if extension == "" or extension == "." then
        extension = ".txt"
    end

    return baseName .. extension
end

function EMAIL.GenerateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local seed = tostring(SysTime()) .. tostring(os.time()) .. tostring(math.random(100000, 999999))
    local hash = util.CRC(seed)
    local cursor = 1

    return string.gsub(template, "[xy]", function(token)
        local char = string.sub(hash, cursor, cursor)
        cursor = cursor + 1

        local value = tonumber(char, 16) or math.random(0, 15)
        if token == "y" then
            value = bit.bor(bit.band(value, 0x3), 0x8)
        end

        return string.format("%x", value)
    end)
end

function EMAIL.MakeMessageFilename(messageId)
    return tostring(messageId) .. ".json"
end

function EMAIL.MakeToastHex(payload)
    local json = util.TableToJSON(payload or {}) or "{}"
    return string.gsub(json, ".", function(character)
        return string.format("%02x", string.byte(character))
    end)
end

function EMAIL.ReadToastHex(hexValue)
    if not hexValue or hexValue == "" then
        return nil
    end

    local success, decoded = pcall(function()
        return string.gsub(hexValue, "%x%x", function(hexPair)
            return string.char(tonumber(hexPair, 16))
        end)
    end)

    if not success or not decoded then
        return nil
    end

    local parseSuccess, payload = pcall(util.JSONToTable, decoded)
    if parseSuccess and istable(payload) then
        return payload
    end

    return nil
end

if SERVER then
    util.AddNetworkString(EMAIL.NET_NAME)
end
