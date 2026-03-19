HALOARMORY.MsgC("Server HALO Computer Email Backend Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.EMAIL = HALOARMORY.COMPUTER.EMAIL or {}

local EMAIL = HALOARMORY.COMPUTER.EMAIL

EMAIL.PendingRequests = EMAIL.PendingRequests or {}

local function EnsureDirectory(path)
    if path and path ~= "" and not file.IsDir(path, "DATA") then
        file.CreateDir(path)
    end
    return path
end

local function EnsureMailboxDirectory(steamID64)
    return EnsureDirectory(EMAIL.GetMailboxDirectory(steamID64))
end

local function MakeMessagePath(steamID64, messageId)
    local directory = EnsureMailboxDirectory(steamID64)
    if not directory then
        return nil
    end

    local normalizedId = string.gsub(tostring(messageId or ""), "%.json$", "")
    return directory .. EMAIL.MakeMessageFilename(normalizedId)
end

local function GetMessageIdFromFilename(fileName)
    return string.gsub(tostring(fileName or ""), "%.json$", "")
end

local function ReadMessageByPath(path)
    if not path or not file.Exists(path, "DATA") then
        return nil
    end

    local raw = file.Read(path, "DATA")
    if not raw or raw == "" then
        return nil
    end

    local success, payload = pcall(util.JSONToTable, raw)
    if not success or not istable(payload) then
        return nil
    end

    payload.id = payload.id or GetMessageIdFromFilename(string.GetFileFromFilename(path))
    payload.subject = tostring(payload.subject or "")
    payload.bodyMarkdown = tostring(payload.bodyMarkdown or "")
    payload.attachments = istable(payload.attachments) and payload.attachments or {}
    payload.sender = istable(payload.sender) and payload.sender or {}
    payload.recipients = istable(payload.recipients) and payload.recipients or {}
    payload.sentAt = tonumber(payload.sentAt) or os.time()
    payload.read = payload.read == true
    payload.deleted = payload.deleted == true
    payload.mailboxRoles = istable(payload.mailboxRoles) and payload.mailboxRoles or {}
    payload.mailboxRoles.sender = payload.mailboxRoles.sender == true
    payload.mailboxRoles.recipient = payload.mailboxRoles.recipient == true

    return payload
end

local function ReadMessageForPlayer(steamID64, messageId)
    local path = MakeMessagePath(steamID64, messageId)
    if not path then
        return nil
    end

    return ReadMessageByPath(path), path
end

local function WriteMessageForPlayer(steamID64, emailData)
    local path = MakeMessagePath(steamID64, emailData and emailData.id)
    if not path or not emailData then
        return false
    end

    local json = util.TableToJSON(emailData, false)
    if not json then
        return false
    end

    file.Write(path, json)
    return true
end

local function DeleteMessageForPlayer(steamID64, messageId)
    local path = MakeMessagePath(steamID64, messageId)
    if path and file.Exists(path, "DATA") then
        file.Delete(path)
        return true
    end
    return false
end

local function ListMailboxMessages(steamID64)
    local directory = EnsureMailboxDirectory(steamID64)
    local fileNames = file.Find(directory .. "*.json", "DATA") or {}
    local messages = {}

    for _, fileName in ipairs(fileNames) do
        local path = directory .. fileName
        local payload = ReadMessageByPath(path)
        if payload then
            table.insert(messages, {
                id = payload.id,
                path = path,
                data = payload
            })
        end
    end

    return messages
end

local function SortBySentAscending(a, b)
    local aSent = tonumber(a and a.data and a.data.sentAt) or 0
    local bSent = tonumber(b and b.data and b.data.sentAt) or 0

    if aSent == bSent then
        return tostring(a.id or "") < tostring(b.id or "")
    end

    return aSent < bSent
end

local function SortBySentDescending(a, b)
    local aSent = tonumber(a and a.sentAt) or 0
    local bSent = tonumber(b and b.sentAt) or 0

    if aSent == bSent then
        return tostring(a.id or "") > tostring(b.id or "")
    end

    return aSent > bSent
end

local function PurgeExpiredTrash(steamID64)
    local now = os.time()
    local maxAge = math.max(1, tonumber(HALOARMORY.COMPUTER.EMAIL_Conf.DeleteTrashDays) or 30) * 86400
    local deletedCount = 0

    for _, message in ipairs(ListMailboxMessages(steamID64)) do
        if message.data.deleted and (now - (tonumber(message.data.sentAt) or now)) >= maxAge then
            if DeleteMessageForPlayer(steamID64, message.id) then
                deletedCount = deletedCount + 1
            end
        end
    end

    return deletedCount
end

local function EnforceMailboxLimit(steamID64, incomingCount)
    incomingCount = math.max(0, tonumber(incomingCount) or 0)
    PurgeExpiredTrash(steamID64)

    local maxEmails = math.max(1, tonumber(HALOARMORY.COMPUTER.EMAIL_Conf.MaxEmails) or 500)
    local messages = ListMailboxMessages(steamID64)

    table.sort(messages, SortBySentAscending)

    while (#messages + incomingCount) > maxEmails do
        local oldest = table.remove(messages, 1)
        if not oldest then
            break
        end

        DeleteMessageForPlayer(steamID64, oldest.id)
    end
end

local function BuildOnlinePlayerIndex()
    local index = {}

    for _, playerEntity in ipairs(player.GetAll()) do
        local steamID = playerEntity:SteamID()
        local steamID64 = playerEntity:SteamID64()

        index[steamID64] = {
            steamID = steamID,
            steamID64 = steamID64,
            nickname = playerEntity:Nick()
        }

        index[steamID] = index[steamID64]
    end

    return index
end

local function MakeContactFromSource(source)
    if not istable(source) then
        return nil
    end

    local steamID64 = EMAIL.NormalizeSteamID64(source.steamID64 or source.steamID)
    local steamID = EMAIL.NormalizeSteamID(source.steamID or source.steamID64)
    local nickname = string.Trim(tostring(source.nickname or source.name or ""))

    if not steamID64 and not steamID then
        return nil
    end

    if steamID64 and (not steamID or steamID == "") and util.SteamIDFrom64 then
        steamID = util.SteamIDFrom64(steamID64)
    end

    if nickname == "" then
        nickname = steamID or steamID64 or "Unknown Contact"
    end

    return {
        steamID = steamID,
        steamID64 = steamID64,
        nickname = nickname
    }
end

local function CollectContactsForPlayer(steamID64)
    local byKey = {}

    for _, message in ipairs(ListMailboxMessages(steamID64)) do
        local sentAt = tonumber(message.data.sentAt) or 0
        local contactSources = {}

        if istable(message.data.sender) then
            table.insert(contactSources, message.data.sender)
        end

        if istable(message.data.recipients) then
            for _, recipient in ipairs(message.data.recipients) do
                table.insert(contactSources, recipient)
            end
        end

        for _, source in ipairs(contactSources) do
            local contact = MakeContactFromSource(source)
            if contact and contact.steamID64 ~= steamID64 then
                local key = contact.steamID64 or contact.steamID
                local current = byKey[key]
                if not current or sentAt >= (current.sentAt or 0) then
                    byKey[key] = {
                        steamID = contact.steamID,
                        steamID64 = contact.steamID64,
                        nickname = contact.nickname,
                        sentAt = sentAt
                    }
                end
            end
        end
    end

    local contacts = {}
    for _, contact in pairs(byKey) do
        table.insert(contacts, {
            steamID = contact.steamID,
            steamID64 = contact.steamID64,
            nickname = contact.nickname
        })
    end

    table.sort(contacts, function(a, b)
        return string.lower(a.nickname or "") < string.lower(b.nickname or "")
    end)

    return contacts
end

local function CountUnreadForPlayer(steamID64)
    local unread = 0

    for _, message in ipairs(ListMailboxMessages(steamID64)) do
        local data = message.data
        if data.mailboxRoles.recipient and not data.deleted and not data.read then
            unread = unread + 1
        end
    end

    return unread
end

local function MessageMatchesFolder(messageData, folder)
    folder = string.lower(tostring(folder or "inbox"))

    if folder == "trash" then
        return messageData.deleted
    end

    if folder == "sent" then
        return not messageData.deleted and messageData.mailboxRoles.sender
    end

    if folder == "drafts" then
        return false
    end

    return not messageData.deleted and messageData.mailboxRoles.recipient
end

local function BuildMessageSummary(messageData)
    return {
        id = messageData.id,
        subject = messageData.subject,
        sentAt = messageData.sentAt,
        read = messageData.read,
        deleted = messageData.deleted,
        sender = messageData.sender,
        recipients = messageData.recipients,
        mailboxRoles = messageData.mailboxRoles,
        attachmentsCount = istable(messageData.attachments) and #messageData.attachments or 0,
        preview = string.sub(string.Trim(tostring(messageData.bodyMarkdown or "")), 1, 160)
    }
end

local function ListFolderSummaries(steamID64, folder)
    PurgeExpiredTrash(steamID64)

    local summaries = {}
    for _, message in ipairs(ListMailboxMessages(steamID64)) do
        if MessageMatchesFolder(message.data, folder) then
            table.insert(summaries, BuildMessageSummary(message.data))
        end
    end

    table.sort(summaries, SortBySentDescending)
    return summaries
end

local function GetPlayerDisplayName(targetPly)
    return IsValid(targetPly) and targetPly:Nick() or "Unknown Sender"
end

local function NormalizeRecipientEntry(rawContact, onlineIndex)
    local source = istable(rawContact) and rawContact or {}
    local steamID64 = EMAIL.NormalizeSteamID64(source.steamID64 or source.steamID or source.value)
    local steamID = EMAIL.NormalizeSteamID(source.steamID or source.steamID64 or source.value)
    local online = onlineIndex[steamID64 or steamID]

    if not steamID64 and online then
        steamID64 = online.steamID64
    end

    if not steamID and online then
        steamID = online.steamID
    end

    if not steamID64 and steamID and util.SteamIDTo64 then
        local converted = util.SteamIDTo64(steamID)
        if converted and converted ~= "0" then
            steamID64 = converted
        end
    end

    if not steamID64 then
        return nil
    end

    if (not steamID or steamID == "") and util.SteamIDFrom64 then
        steamID = util.SteamIDFrom64(steamID64)
    end

    return {
        steamID = steamID,
        steamID64 = steamID64,
        nickname = string.Trim(tostring((online and online.nickname) or source.nickname or source.name or source.label or steamID or steamID64))
    }
end

local function NormalizeAttachment(rawAttachment)
    if not istable(rawAttachment) then
        return nil
    end

    local displayName = EMAIL.SanitizeAttachmentName(rawAttachment.displayName or rawAttachment.filename or rawAttachment.name or "attachment.txt")
    local fileType = string.lower(string.Trim(tostring(rawAttachment.filetype or "")))
    local content = tostring(rawAttachment.content or "")

    return {
        displayName = displayName,
        filename = displayName,
        filetype = fileType,
        content = content,
        sourcePath = tostring(rawAttachment.sourcePath or rawAttachment.filepath or "")
    }
end

local function EmitToastCount(ply, unreadCount)
    if not IsValid(ply) or not ply:IsPlayer() then
        return
    end

    ply:ConCommand(string.format("%s %d", EMAIL.TOAST_COMMAND, math.max(0, tonumber(unreadCount) or 0)))
end

local function EmitUnreadSummaryToast(ply, unreadCount)
    unreadCount = math.max(0, tonumber(unreadCount) or 0)
    if unreadCount <= 0 then
        return
    end

    EmitToastCount(ply, unreadCount)
end

local function DispatchResponse(ply, requestId, payloadTable)
    local requestJson = util.TableToJSON(payloadTable or {}) or "{}"
    local compressed = util.Compress(requestJson)
    if not compressed then
        return
    end

    local totalChunks = math.max(1, math.ceil(#compressed / EMAIL.CHUNK_SIZE))

    net.Start(EMAIL.NET_NAME)
    net.WriteUInt(EMAIL.NET_RESPONSE_BEGIN, 8)
    net.WriteString(requestId or "")
    net.WriteUInt(totalChunks, 16)
    net.Send(ply)

    for chunkIndex = 1, totalChunks do
        local startIndex = ((chunkIndex - 1) * EMAIL.CHUNK_SIZE) + 1
        local chunkData = string.sub(compressed, startIndex, startIndex + EMAIL.CHUNK_SIZE - 1)

        net.Start(EMAIL.NET_NAME)
        net.WriteUInt(EMAIL.NET_RESPONSE_CHUNK, 8)
        net.WriteString(requestId or "")
        net.WriteUInt(chunkIndex, 16)
        net.WriteUInt(#chunkData, 32)
        net.WriteData(chunkData, #chunkData)
        net.Send(ply)
    end

    net.Start(EMAIL.NET_NAME)
    net.WriteUInt(EMAIL.NET_RESPONSE_COMMIT, 8)
    net.WriteString(requestId or "")
    net.Send(ply)
end

local function HandleMailboxIndexRequest(ply, requestId, payload)
    local steamID64 = ply:SteamID64()
    local folder = payload.folder or "inbox"
    local summaries = ListFolderSummaries(steamID64, folder)

    DispatchResponse(ply, requestId, {
        success = true,
        folder = folder,
        messages = summaries,
        unreadCount = CountUnreadForPlayer(steamID64)
    })
end

local function HandleEmailDetailRequest(ply, requestId, payload)
    local messageId = tostring(payload.messageId or "")
    local messageData = ReadMessageForPlayer(ply:SteamID64(), messageId)

    if not messageData then
        DispatchResponse(ply, requestId, {
            success = false,
            message = "Email not found."
        })
        return
    end

    if messageData.mailboxRoles.recipient and not messageData.read then
        messageData.read = true
        WriteMessageForPlayer(ply:SteamID64(), messageData)
    end

    DispatchResponse(ply, requestId, {
        success = true,
        email = messageData
    })
end

local function HandleUpdateStateRequest(ply, requestId, payload)
    local steamID64 = ply:SteamID64()
    local operation = string.lower(tostring(payload.operation or ""))
    local messageIds = istable(payload.messageIds) and payload.messageIds or {}
    local updated = 0

    for _, messageId in ipairs(messageIds) do
        local messageData = ReadMessageForPlayer(steamID64, messageId)
        if messageData then
            if operation == "delete" then
                messageData.deleted = true
                updated = updated + 1
            elseif operation == "read" then
                messageData.read = true
                updated = updated + 1
            elseif operation == "unread" then
                messageData.read = false
                updated = updated + 1
            end

            WriteMessageForPlayer(steamID64, messageData)
        end
    end

    PurgeExpiredTrash(steamID64)

    DispatchResponse(ply, requestId, {
        success = true,
        updated = updated,
        unreadCount = CountUnreadForPlayer(steamID64)
    })
end

local function HandleOnlinePlayersRequest(ply, requestId)
    local playersPayload = {}

    for _, target in ipairs(player.GetAll()) do
        table.insert(playersPayload, {
            steamID = target:SteamID(),
            steamID64 = target:SteamID64(),
            nickname = GetPlayerDisplayName(target),
            isSelf = target == ply
        })
    end

    table.sort(playersPayload, function(a, b)
        return string.lower(a.nickname or "") < string.lower(b.nickname or "")
    end)

    DispatchResponse(ply, requestId, {
        success = true,
        players = playersPayload
    })
end

local function HandleContactsRequest(ply, requestId)
    DispatchResponse(ply, requestId, {
        success = true,
        contacts = CollectContactsForPlayer(ply:SteamID64())
    })
end

local function DeliverEmailCopies(senderPly, payload)
    local senderSteamID64 = senderPly:SteamID64()
    local senderContact = {
        steamID = senderPly:SteamID(),
        steamID64 = senderSteamID64,
        nickname = senderPly:Nick()
    }

    local onlineIndex = BuildOnlinePlayerIndex()
    local normalizedRecipients = {}
    local recipientsBySteamID64 = {}

    for _, rawRecipient in ipairs(istable(payload.recipients) and payload.recipients or {}) do
        local contact = NormalizeRecipientEntry(rawRecipient, onlineIndex)
        if contact and not recipientsBySteamID64[contact.steamID64] then
            recipientsBySteamID64[contact.steamID64] = contact
            table.insert(normalizedRecipients, contact)
        end
    end

    if #normalizedRecipients <= 0 then
        return false, "No valid recipients were provided."
    end

    local normalizedAttachments = {}
    for _, rawAttachment in ipairs(istable(payload.attachments) and payload.attachments or {}) do
        local attachment = NormalizeAttachment(rawAttachment)
        if attachment then
            table.insert(normalizedAttachments, attachment)
        end
    end

    local mailboxIncomingCounts = {}
    mailboxIncomingCounts[senderSteamID64] = (mailboxIncomingCounts[senderSteamID64] or 0) + 1
    for _, recipient in ipairs(normalizedRecipients) do
        mailboxIncomingCounts[recipient.steamID64] = (mailboxIncomingCounts[recipient.steamID64] or 0) + 1
    end

    for steamID64, incomingCount in pairs(mailboxIncomingCounts) do
        EnforceMailboxLimit(steamID64, incomingCount)
    end

    local now = os.time()
    local baseSubject = string.Trim(tostring(payload.subject or ""))
    local baseBody = tostring(payload.bodyMarkdown or "")

    local senderCopy = {
        id = EMAIL.GenerateUUID(),
        subject = baseSubject,
        bodyMarkdown = baseBody,
        attachments = normalizedAttachments,
        sender = senderContact,
        recipients = normalizedRecipients,
        sentAt = now,
        read = true,
        deleted = false,
        mailboxRoles = {
            sender = true,
            recipient = false
        }
    }

    WriteMessageForPlayer(senderSteamID64, senderCopy)

    for _, recipient in ipairs(normalizedRecipients) do
        local recipientCopy = {
            id = EMAIL.GenerateUUID(),
            subject = baseSubject,
            bodyMarkdown = baseBody,
            attachments = normalizedAttachments,
            sender = senderContact,
            recipients = normalizedRecipients,
            sentAt = now,
            read = false,
            deleted = false,
            mailboxRoles = {
                sender = false,
                recipient = true
            }
        }

        WriteMessageForPlayer(recipient.steamID64, recipientCopy)

        local recipientPly = player.GetBySteamID64(recipient.steamID64)
        if IsValid(recipientPly) then
            EmitToastCount(recipientPly, 0)
        end
    end

    return true, nil
end

local function HandleSendEmailRequest(ply, requestId, payload)
    local success, err = DeliverEmailCopies(ply, payload or {})
    DispatchResponse(ply, requestId, {
        success = success,
        message = err
    })
end

local function HandleRequestPayload(ply, requestId, payload)
    local action = tostring(payload.action or "")

    if action == EMAIL.ACTION_MAILBOX_INDEX then
        HandleMailboxIndexRequest(ply, requestId, payload)
    elseif action == EMAIL.ACTION_EMAIL_DETAIL then
        HandleEmailDetailRequest(ply, requestId, payload)
    elseif action == EMAIL.ACTION_SEND_EMAIL then
        HandleSendEmailRequest(ply, requestId, payload)
    elseif action == EMAIL.ACTION_UPDATE_STATE then
        HandleUpdateStateRequest(ply, requestId, payload)
    elseif action == EMAIL.ACTION_ONLINE_PLAYERS then
        HandleOnlinePlayersRequest(ply, requestId)
    elseif action == EMAIL.ACTION_CONTACTS then
        HandleContactsRequest(ply, requestId)
    else
        DispatchResponse(ply, requestId, {
            success = false,
            message = "Unknown email action: " .. action
        })
    end
end

net.Receive(EMAIL.NET_NAME, function(_, ply)
    local messageType = net.ReadUInt(8)
    local requestId = net.ReadString()

    EMAIL.PendingRequests[ply] = EMAIL.PendingRequests[ply] or {}

    if messageType == EMAIL.NET_REQUEST_BEGIN then
        EMAIL.PendingRequests[ply][requestId] = {
            totalChunks = net.ReadUInt(16),
            chunks = {},
            receivedAt = CurTime()
        }
        return
    end

    local pending = EMAIL.PendingRequests[ply][requestId]
    if not pending then
        return
    end

    if messageType == EMAIL.NET_REQUEST_CHUNK then
        local chunkIndex = net.ReadUInt(16)
        local dataLength = net.ReadUInt(32)
        pending.chunks[chunkIndex] = net.ReadData(dataLength)
        return
    end

    if messageType == EMAIL.NET_REQUEST_COMMIT then
        local buffer = {}
        for index = 1, pending.totalChunks do
            if not pending.chunks[index] then
                EMAIL.PendingRequests[ply][requestId] = nil
                return
            end
            buffer[#buffer + 1] = pending.chunks[index]
        end

        EMAIL.PendingRequests[ply][requestId] = nil

        local compressed = table.concat(buffer)
        local jsonPayload = util.Decompress(compressed)
        if not jsonPayload then
            DispatchResponse(ply, requestId, {
                success = false,
                message = "Failed to decode request payload."
            })
            return
        end

        local success, payload = pcall(util.JSONToTable, jsonPayload)
        if not success or not istable(payload) then
            DispatchResponse(ply, requestId, {
                success = false,
                message = "Failed to parse request payload."
            })
            return
        end

        HandleRequestPayload(ply, requestId, payload)
    end
end)

hook.Add("PlayerInitialSpawn", "HALOARMORY.COMPUTER.EMAIL.JoinReminder", function(ply)
    local timerName = "HALOARMORY.COMPUTER.EMAIL.JoinReminder." .. ply:SteamID64()
    timer.Remove(timerName)

    timer.Create(timerName, tonumber(HALOARMORY.COMPUTER.EMAIL_Conf.JoinReminderDelay) or 120, 1, function()
        if not IsValid(ply) then
            return
        end

        EmitUnreadSummaryToast(ply, CountUnreadForPlayer(ply:SteamID64()))
    end)
end)

hook.Add("PlayerDisconnected", "HALOARMORY.COMPUTER.EMAIL.JoinReminderCleanup", function(ply)
    timer.Remove("HALOARMORY.COMPUTER.EMAIL.JoinReminder." .. ply:SteamID64())
    EMAIL.PendingRequests[ply] = nil
end)
