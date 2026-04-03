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

local function GetFavoriteKind(entry)
    local kind = string.lower(tostring(istable(entry) and entry.kind or "contact"))
    if kind == "local_list" or kind == "server_set" then
        return kind
    end
    return "contact"
end

local function GetFavoriteKey(entry)
    if not istable(entry) then
        return ""
    end

    local kind = GetFavoriteKind(entry)
    if kind == "contact" then
        return tostring(EMAIL.NormalizeSteamID64(entry.steamID64 or entry.steamID) or "")
    end

    return kind .. ":" .. tostring(entry.id or entry.listId or entry.setId or entry.name or "")
end

local function NormalizeFavoriteMembers(rawMembers)
    local members = {}
    for _, rawMember in ipairs(istable(rawMembers) and rawMembers or {}) do
        local steamID64 = EMAIL.NormalizeSteamID64((istable(rawMember) and (rawMember.steamID64 or rawMember.steamID or rawMember.value)) or rawMember)
        if steamID64 then
            table.insert(members, steamID64)
        end
    end
    return members
end

local function NormalizeFavoriteEntry(rawFavorite)
    if not istable(rawFavorite) then
        return nil
    end

    local kind = GetFavoriteKind(rawFavorite)
    if kind == "contact" then
        local steamID64 = EMAIL.NormalizeSteamID64(rawFavorite.steamID64 or rawFavorite.steamID)
        if not steamID64 then
            return nil
        end

        return {
            kind = "contact",
            steamID = EMAIL.NormalizeSteamID(rawFavorite.steamID or rawFavorite.steamID64),
            steamID64 = steamID64,
            nickname = tostring(rawFavorite.nickname or rawFavorite.steamID or rawFavorite.steamID64 or "")
        }
    end

    local id = string.Trim(tostring(rawFavorite.id or rawFavorite.listId or rawFavorite.setId or ""))
    local name = string.Trim(tostring(rawFavorite.name or rawFavorite.nickname or ""))
    if id == "" or name == "" then
        return nil
    end

    return {
        kind = kind,
        id = id,
        listId = kind == "local_list" and id or nil,
        setId = kind == "server_set" and id or nil,
        name = name,
        members = NormalizeFavoriteMembers(rawFavorite.members),
        memberCount = tonumber(rawFavorite.memberCount) or #(istable(rawFavorite.members) and rawFavorite.members or {})
    }
end

local function GetFavoriteSortLabel(entry)
    if not istable(entry) then
        return ""
    end

    if GetFavoriteKind(entry) == "contact" then
        return string.lower(tostring(entry.nickname or entry.steamID or entry.steamID64 or ""))
    end

    return string.lower(tostring(entry.name or entry.nickname or ""))
end

local function LoadFavorites()
    local stored = ReadJSONFile(EMAIL.CLIENT_FAVORITES_FILE, {})
    local favorites = {}
    local seen = {}

    for _, rawFavorite in ipairs(istable(stored) and stored or {}) do
        local favorite = NormalizeFavoriteEntry(rawFavorite)
        local key = GetFavoriteKey(favorite)
        if favorite and key ~= "" and not seen[key] then
            seen[key] = true
            table.insert(favorites, favorite)
        end
    end

    table.sort(favorites, function(a, b)
        return GetFavoriteSortLabel(a) < GetFavoriteSortLabel(b)
    end)

    return favorites
end

local function SaveFavorites(favorites)
    return WriteJSONFile(EMAIL.CLIENT_FAVORITES_FILE, favorites or {})
end

local function LoadAliases()
    local aliases = ReadJSONFile(EMAIL.CLIENT_ALIASES_FILE, {})
    if not istable(aliases) then
        aliases = {}
    end

    table.sort(aliases, function(a, b)
        return string.lower(tostring(a.nickname or a.steamID or a.steamID64 or "")) < string.lower(tostring(b.nickname or b.steamID or b.steamID64 or ""))
    end)

    return aliases
end

local function SaveAliases(aliases)
    return WriteJSONFile(EMAIL.CLIENT_ALIASES_FILE, aliases or {})
end

local function SetAlias(contact)
    local aliases = LoadAliases()
    local steamID64 = EMAIL.NormalizeSteamID64(contact and (contact.steamID64 or contact.steamID))
    local nickname = string.Trim(tostring(contact and contact.nickname or ""))
    local updated = {}
    local matched = false

    for _, existing in ipairs(aliases) do
        local existingSteamID64 = EMAIL.NormalizeSteamID64(existing.steamID64 or existing.steamID)
        if existingSteamID64 == steamID64 then
            matched = true
            if nickname ~= "" then
                existing.nickname = nickname
                existing.steamID = EMAIL.NormalizeSteamID(contact.steamID or contact.steamID64) or existing.steamID or ""
                existing.steamID64 = steamID64
                table.insert(updated, existing)
            end
        else
            table.insert(updated, existing)
        end
    end

    if nickname ~= "" and steamID64 and not matched then
        table.insert(updated, {
            steamID = EMAIL.NormalizeSteamID(contact.steamID or contact.steamID64),
            steamID64 = steamID64,
            nickname = nickname
        })
    end

    SaveAliases(updated)
    return LoadAliases()
end

local function GenerateCollectionId(prefix)
    return tostring(prefix or "collection") .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

local function NormalizeListMembers(rawMembers)
    local members = {}
    local seen = {}

    for _, rawMember in ipairs(istable(rawMembers) and rawMembers or {}) do
        local steamID64 = EMAIL.NormalizeSteamID64((istable(rawMember) and (rawMember.steamID64 or rawMember.steamID or rawMember.value)) or rawMember)
        if steamID64 and not seen[steamID64] then
            seen[steamID64] = true
            table.insert(members, steamID64)
        end
    end

    table.sort(members, function(a, b)
        return tostring(a or "") < tostring(b or "")
    end)

    return members
end

local function NormalizeLocalList(rawList)
    if not istable(rawList) then
        return nil
    end

    local name = string.Trim(tostring(rawList.name or rawList.label or ""))
    if name == "" then
        return nil
    end

    local id = string.Trim(tostring(rawList.id or ""))
    if id == "" then
        id = GenerateCollectionId("local_list")
    end

    return {
        id = id,
        name = name,
        members = NormalizeListMembers(rawList.members),
        updatedAt = tonumber(rawList.updatedAt) or os.time()
    }
end

local function LoadLocalLists()
    local lists = ReadJSONFile(EMAIL.CLIENT_CONTACT_LISTS_FILE, {})
    local normalized = {}

    for _, rawList in ipairs(istable(lists) and lists or {}) do
        local localList = NormalizeLocalList(rawList)
        if localList then
            table.insert(normalized, localList)
        end
    end

    table.sort(normalized, function(a, b)
        return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
    end)

    return normalized
end

local function SaveLocalLists(lists)
    return WriteJSONFile(EMAIL.CLIENT_CONTACT_LISTS_FILE, lists or {})
end

local function SaveLocalList(rawList)
    local localList = NormalizeLocalList(rawList)
    if not localList then
        return false, "List name is required.", LoadLocalLists()
    end

    local lists = LoadLocalLists()
    local replaced = false

    for index, existing in ipairs(lists) do
        if tostring(existing.id or "") == tostring(localList.id or "") then
            lists[index] = localList
            replaced = true
            break
        end
    end

    if not replaced then
        table.insert(lists, localList)
    end

    table.sort(lists, function(a, b)
        return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
    end)

    SaveLocalLists(lists)
    return true, nil, lists, localList
end

local function DeleteLocalList(listId)
    local kept = {}
    local deleted = false

    for _, existing in ipairs(LoadLocalLists()) do
        if tostring(existing.id or "") == tostring(listId or "") then
            deleted = true
        else
            table.insert(kept, existing)
        end
    end

    SaveLocalLists(kept)
    return deleted, kept
end

local function SetFavorite(contact, shouldFavorite)
    local favorites = LoadFavorites()
    local favoriteEntry = NormalizeFavoriteEntry(contact or {})
    local targetKey = GetFavoriteKey(favoriteEntry)
    local updated = {}
    local found = false

    for _, favorite in ipairs(favorites) do
        if GetFavoriteKey(favorite) == targetKey then
            found = true
            if shouldFavorite then
                table.insert(updated, favoriteEntry or favorite)
            end
        else
            table.insert(updated, favorite)
        end
    end

    if shouldFavorite and favoriteEntry and targetKey ~= "" and not found then
        table.insert(updated, favoriteEntry)
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

    if action == "load_local_contact_data" then
        SendUIResponse(callbackId, {
            success = true,
            favorites = LoadFavorites(),
            aliases = LoadAliases(),
            localLists = LoadLocalLists()
        })
        return
    end

    if action == "save_contact_alias" then
        SendUIResponse(callbackId, {
            success = true,
            aliases = SetAlias(payload.contact or {})
        })
        return
    end

    if action == "save_local_list" then
        local success, err, lists, savedList = SaveLocalList(payload)
        SendUIResponse(callbackId, {
            success = success,
            message = err,
            localLists = lists or LoadLocalLists(),
            localList = savedList
        })
        return
    end

    if action == "delete_local_list" then
        local success, lists = DeleteLocalList(payload.id)
        SendUIResponse(callbackId, {
            success = success,
            localLists = lists or LoadLocalLists()
        })
        return
    end

    SendServerRequest(callbackId, {
        action = action,
        id = payload.id,
        name = payload.name,
        folder = payload.folder,
        messageId = payload.messageId,
        messageIds = payload.messageIds,
        members = payload.members,
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
