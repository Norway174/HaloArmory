HALOARMORY.MsgC("Client HALO Computer Email Bridge Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}
HALOARMORY.COMPUTER.INTERFACE.EMAIL = HALOARMORY.COMPUTER.INTERFACE.EMAIL or {}
HALOARMORY.COMPUTER.EMAIL = HALOARMORY.COMPUTER.EMAIL or {}


local EMAIL = HALOARMORY.COMPUTER.EMAIL
local EMAIL_BRIDGE = HALOARMORY.COMPUTER.INTERFACE.EMAIL

EMAIL_BRIDGE.PendingResponses = EMAIL_BRIDGE.PendingResponses or {}
EMAIL_BRIDGE.ServerResponses = EMAIL_BRIDGE.ServerResponses or {}

local function EscapeJSONForJavaScript(jsonString)
    if not jsonString then
        return "null"
    end

    local escaped = tostring(jsonString)
    escaped = string.gsub(escaped, "\\", "\\\\")
    escaped = string.gsub(escaped, "\"", "\\\"")
    escaped = string.gsub(escaped, "\n", "\\n")
    escaped = string.gsub(escaped, "\r", "\\r")
    escaped = string.gsub(escaped, "'", "\\'")

    return escaped
end

local function GetFrame()
    local frame = HALOARMORY.COMPUTER.INTERFACE.frame
    if IsValid(frame) and IsValid(frame.html) then
        return frame
    end
    return nil
end

local function SendUIResponse(callbackId, payload)
    local frame = GetFrame()
    if not frame then
        return
    end

    local payloadJson = util.TableToJSON(payload or {}) or "{}"
    local escapedPayload = EscapeJSONForJavaScript(payloadJson)
    local escapedCallback = EscapeJSONForJavaScript(callbackId or "")

    frame.html:RunJavascript(string.format([[
        try {
            if (window.emailBridge && window.emailBridge.handleCallback) {
                window.emailBridge.handleCallback("%s", "%s");
            }
        } catch (error) {
            console.error("emailBridge.handleCallback failed", error);
        }
    ]], escapedCallback, escapedPayload))
end

local function EnsureClientStorageDirectory()
    if not file.IsDir(EMAIL.CLIENT_STORAGE_DIR, "DATA") then
        file.CreateDir(EMAIL.CLIENT_STORAGE_DIR)
    end
end

local function ReadJSONFile(path, fallback)
    EnsureClientStorageDirectory()

    if not file.Exists(path, "DATA") then
        return fallback
    end

    local raw = file.Read(path, "DATA")
    if not raw or raw == "" then
        return fallback
    end

    local success, data = pcall(util.JSONToTable, raw)
    if success and data ~= nil then
        return data
    end

    return fallback
end

local function WriteJSONFile(path, payload)
    EnsureClientStorageDirectory()

    local json = util.TableToJSON(payload or {}, false)
    if not json then
        return false
    end

    file.Write(path, json)
    return true
end

local function GenerateDraftId()
    return "draft_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

local function LoadDrafts()
    local drafts = ReadJSONFile(EMAIL.CLIENT_DRAFTS_FILE, {})
    if not istable(drafts) then
        drafts = {}
    end

    table.sort(drafts, function(a, b)
        return tonumber(a.updatedAt or 0) > tonumber(b.updatedAt or 0)
    end)

    return drafts
end

local function SaveDraft(payload)
    local drafts = LoadDrafts()
    local draftId = tostring(payload.id or "")

    if draftId == "" then
        draftId = GenerateDraftId()
    end

    local draftData = {
        id = draftId,
        recipients = istable(payload.recipients) and payload.recipients or {},
        subject = tostring(payload.subject or ""),
        bodyMarkdown = tostring(payload.bodyMarkdown or ""),
        attachments = istable(payload.attachments) and payload.attachments or {},
        updatedAt = os.time()
    }

    local replaced = false
    for index, existingDraft in ipairs(drafts) do
        if tostring(existingDraft.id or "") == draftId then
            drafts[index] = draftData
            replaced = true
            break
        end
    end

    if not replaced then
        table.insert(drafts, draftData)
    end

    WriteJSONFile(EMAIL.CLIENT_DRAFTS_FILE, drafts)
    return draftData
end

local function DeleteDraft(draftId)
    local drafts = LoadDrafts()
    local keptDrafts = {}
    local deleted = false

    for _, draft in ipairs(drafts) do
        if tostring(draft.id or "") == tostring(draftId or "") then
            deleted = true
        else
            table.insert(keptDrafts, draft)
        end
    end

    WriteJSONFile(EMAIL.CLIENT_DRAFTS_FILE, keptDrafts)
    return deleted
end

local function LoadFavorites()
    local favorites = ReadJSONFile(EMAIL.CLIENT_FAVORITES_FILE, {})
    if not istable(favorites) then
        favorites = {}
    end

    table.sort(favorites, function(a, b)
        return string.lower(tostring(a.nickname or a.steamID or a.steamID64 or "")) < string.lower(tostring(b.nickname or b.steamID or b.steamID64 or ""))
    end)

    return favorites
end

local function SaveFavorites(favorites)
    return WriteJSONFile(EMAIL.CLIENT_FAVORITES_FILE, favorites or {})
end

local function SetFavorite(contact, shouldFavorite)
    local favorites = LoadFavorites()
    local steamID64 = EMAIL.NormalizeSteamID64(contact and (contact.steamID64 or contact.steamID))
    local updated = {}
    local found = false

    for _, favorite in ipairs(favorites) do
        local favoriteSteamID64 = EMAIL.NormalizeSteamID64(favorite.steamID64 or favorite.steamID)
        if favoriteSteamID64 == steamID64 then
            found = true
            if shouldFavorite then
                favorite.nickname = tostring(contact.nickname or favorite.nickname or favorite.steamID or favorite.steamID64 or "")
                favorite.steamID = favorite.steamID or contact.steamID
                favorite.steamID64 = favorite.steamID64 or contact.steamID64
                table.insert(updated, favorite)
            end
        else
            table.insert(updated, favorite)
        end
    end

    if shouldFavorite and steamID64 and not found then
        table.insert(updated, {
            steamID = EMAIL.NormalizeSteamID(contact.steamID or contact.steamID64),
            steamID64 = steamID64,
            nickname = tostring(contact.nickname or contact.steamID or contact.steamID64 or "")
        })
    end

    SaveFavorites(updated)
    return LoadFavorites()
end

local function SendServerRequest(requestId, payload)
    local payloadJson = util.TableToJSON(payload or {}) or "{}"
    local compressed = util.Compress(payloadJson)
    if not compressed then
        SendUIResponse(requestId, {
            success = false,
            message = "Failed to compress email request."
        })
        return
    end

    local totalChunks = math.max(1, math.ceil(#compressed / EMAIL.CHUNK_SIZE))

    net.Start(EMAIL.NET_NAME)
    net.WriteUInt(EMAIL.NET_REQUEST_BEGIN, 8)
    net.WriteString(requestId)
    net.WriteUInt(totalChunks, 16)
    net.SendToServer()

    for chunkIndex = 1, totalChunks do
        local startIndex = ((chunkIndex - 1) * EMAIL.CHUNK_SIZE) + 1
        local chunkData = string.sub(compressed, startIndex, startIndex + EMAIL.CHUNK_SIZE - 1)

        net.Start(EMAIL.NET_NAME)
        net.WriteUInt(EMAIL.NET_REQUEST_CHUNK, 8)
        net.WriteString(requestId)
        net.WriteUInt(chunkIndex, 16)
        net.WriteUInt(#chunkData, 32)
        net.WriteData(chunkData, #chunkData)
        net.SendToServer()
    end

    net.Start(EMAIL.NET_NAME)
    net.WriteUInt(EMAIL.NET_REQUEST_COMMIT, 8)
    net.WriteString(requestId)
    net.SendToServer()
end

function EMAIL_BRIDGE.HandleUIRequest(callbackId, action, payloadJson)
    local payload = {}
    if payloadJson and payloadJson ~= "" then
        local success, parsed = pcall(util.JSONToTable, payloadJson)
        if success and istable(parsed) then
            payload = parsed
        end
    end

    callbackId = tostring(callbackId or ("email_" .. tostring(os.time())))
    action = tostring(action or "")

    if action == "load_drafts" then
        SendUIResponse(callbackId, {
            success = true,
            drafts = LoadDrafts()
        })
        return
    end

    if action == "save_draft" then
        SendUIResponse(callbackId, {
            success = true,
            draft = SaveDraft(payload)
        })
        return
    end

    if action == "delete_draft" then
        SendUIResponse(callbackId, {
            success = DeleteDraft(payload.id)
        })
        return
    end

    if action == "load_favorites" then
        SendUIResponse(callbackId, {
            success = true,
            favorites = LoadFavorites()
        })
        return
    end

    if action == "set_favorite" then
        SendUIResponse(callbackId, {
            success = true,
            favorites = SetFavorite(payload.contact or {}, payload.favorite == true)
        })
        return
    end

    SendServerRequest(callbackId, {
        action = action,
        folder = payload.folder,
        messageId = payload.messageId,
        messageIds = payload.messageIds,
        operation = payload.operation,
        recipients = payload.recipients,
        subject = payload.subject,
        bodyMarkdown = payload.bodyMarkdown,
        attachments = payload.attachments
    })
end

net.Receive(EMAIL.NET_NAME, function()
    local messageType = net.ReadUInt(8)
    local requestId = net.ReadString()

    if messageType == EMAIL.NET_RESPONSE_BEGIN then
        EMAIL_BRIDGE.ServerResponses[requestId] = {
            totalChunks = net.ReadUInt(16),
            chunks = {}
        }
        return
    end

    local pending = EMAIL_BRIDGE.ServerResponses[requestId]
    if not pending then
        return
    end

    if messageType == EMAIL.NET_RESPONSE_CHUNK then
        local chunkIndex = net.ReadUInt(16)
        local dataLength = net.ReadUInt(32)
        pending.chunks[chunkIndex] = net.ReadData(dataLength)
        return
    end

    if messageType == EMAIL.NET_RESPONSE_COMMIT then
        EMAIL_BRIDGE.ServerResponses[requestId] = nil

        local buffer = {}
        for index = 1, pending.totalChunks do
            if not pending.chunks[index] then
                SendUIResponse(requestId, {
                    success = false,
                    message = "Incomplete email response."
                })
                return
            end

            buffer[#buffer + 1] = pending.chunks[index]
        end

        local compressed = table.concat(buffer)
        local jsonPayload = util.Decompress(compressed)
        if not jsonPayload then
            SendUIResponse(requestId, {
                success = false,
                message = "Failed to decode email response."
            })
            return
        end

        local success, payload = pcall(util.JSONToTable, jsonPayload)
        if not success or not istable(payload) then
            SendUIResponse(requestId, {
                success = false,
                message = "Failed to parse email response."
            })
            return
        end

        SendUIResponse(requestId, payload)
    end
end)
