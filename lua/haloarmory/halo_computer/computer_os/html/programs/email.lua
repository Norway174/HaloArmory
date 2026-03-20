-- Email Program
local EMAIL = {}

function EMAIL.GetContent()
    return [[
<div class="program-email">
    <div class="email-sidebar">
        <button class="email-compose-btn btn btn-primary">Compose</button>
        <div class="email-folders">
            <button class="email-folder active" data-folder="inbox">Inbox</button>
            <button class="email-folder" data-folder="sent">Sent</button>
            <button class="email-folder" data-folder="drafts">Drafts</button>
            <button class="email-folder" data-folder="trash">Trash</button>
        </div>
    </div>
    <div class="email-main">
        <div class="email-view-root">
            <div class="email-loading-state">
                <div class="email-loading-title">Email</div>
                <div class="email-loading-text">Loading mailbox...</div>
            </div>
        </div>
    </div>
</div>
]]
end

function EMAIL.GetInitScript()
    return [[
        emailApp.init(windowId);
    ]]
end

function EMAIL.GetJavaScript()
    return [[
if (!window.emailBridge) {
    window.emailBridge = {
        callbacks: {},
        requestCounter: 0,

        request: function(action, payload, callback) {
            var callbackId = 'email_' + Date.now() + '_' + (++this.requestCounter);
            if (callback) {
                this.callbacks[callbackId] = callback;
            }

            try {
                if (window.email && window.email.request) {
                    window.email.request(callbackId, action, JSON.stringify(payload || {}));
                } else {
                    console.error('[EmailBridge] email.request bridge is unavailable');
                    if (callback) {
                        callback({ success: false, message: 'Email bridge is unavailable.' });
                    }
                }
            } catch (error) {
                console.error('[EmailBridge] request failed', error);
                if (callback) {
                    callback({ success: false, message: 'Email bridge request failed.' });
                }
            }

            return callbackId;
        },

        handleCallback: function(callbackId, payloadJson) {
            var callback = this.callbacks[callbackId];
            if (!callback) {
                return;
            }

            delete this.callbacks[callbackId];

            var payload = {};
            try {
                payload = payloadJson ? JSON.parse(payloadJson) : {};
            } catch (error) {
                console.error('[EmailBridge] Failed to parse callback payload', error, payloadJson);
                payload = { success: false, message: 'Failed to parse callback payload.' };
            }

            callback(payload);
        }
    };
}

var emailApp = {
    instances: {},
    cleanupBound: false,

    init: function(windowId) {
        this.instances[windowId] = {
            windowId: windowId,
            currentFolder: 'inbox',
            currentView: 'folder',
            loading: true,
            messagesByFolder: {
                inbox: [],
                sent: [],
                trash: []
            },
            unreadCount: 0,
            selectedIds: {},
            detailMessage: null,
            detailFolder: 'inbox',
            onlinePlayers: [],
            contacts: [],
            favorites: [],
            drafts: [],
            compose: this.createEmptyComposeState(),
            recipientQuery: '',
            autosaveTimer: null
        };

        this.bindCleanup();
        this.bindStaticEvents(windowId);
        this.registerDropTarget(windowId);
        this.loadInitialData(windowId);
        this.render(windowId);
    },

    createEmptyComposeState: function() {
        return {
            draftId: null,
            recipients: [],
            subject: '',
            bodyMarkdown: '',
            attachments: [],
            previewMode: false,
            dirty: false
        };
    },

    bindCleanup: function() {
        if (this.cleanupBound) {
            return;
        }

        this.cleanupBound = true;
        document.addEventListener('windowclosing', function(e) {
            if (e && e.detail && e.detail.id) {
                emailApp.destroy(e.detail.id);
            }
        });
    },

    bindStaticEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        if (!root) {
            return;
        }

        var composeBtn = root.querySelector('.email-compose-btn');
        if (composeBtn) {
            composeBtn.addEventListener('click', function() {
                this.openCompose(windowId);
            }.bind(this));
        }

        root.querySelectorAll('.email-folder').forEach(function(button) {
            button.addEventListener('click', function() {
                this.showFolder(windowId, button.getAttribute('data-folder'));
            }.bind(this));
        }.bind(this));
    },

    registerDropTarget: function(windowId) {
        var root = this.getRootElement(windowId);
        if (!root || !window.osDragDropManager) {
            return;
        }

        window.osDragDropManager.registerAttachmentDropTarget(root, {
            resourceId: 'email-drop-' + windowId,
            onDrop: function(acceptedItems) {
                this.ensureComposeForDrop(windowId);
                this.addAttachments(windowId, acceptedItems);
            }.bind(this)
        });
    },

    destroy: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        this.saveDraftIfNeeded(windowId);
        if (instance.autosaveTimer) {
            clearTimeout(instance.autosaveTimer);
        }

        delete this.instances[windowId];
    },

    getInstance: function(windowId) {
        return this.instances[windowId] || null;
    },

    getRootElement: function(windowId) {
        var windowEl = document.getElementById(windowId);
        return windowEl ? windowEl.querySelector('.program-email') : null;
    },

    getViewRoot: function(windowId) {
        var root = this.getRootElement(windowId);
        return root ? root.querySelector('.email-view-root') : null;
    },

    loadInitialData: function(windowId) {
        this.request(windowId, 'load_favorites', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.favorites = Array.isArray(payload.favorites) ? payload.favorites : [];
            this.render(windowId);
        }.bind(this));

        this.request(windowId, 'load_drafts', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.drafts = Array.isArray(payload.drafts) ? payload.drafts : [];
            this.render(windowId);
        }.bind(this));

        this.request(windowId, 'contacts', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.contacts = Array.isArray(payload.contacts) ? payload.contacts : [];
            this.render(windowId);
        }.bind(this));

        this.request(windowId, 'online_players', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.onlinePlayers = Array.isArray(payload.players) ? payload.players : [];
            this.render(windowId);
        }.bind(this));

        this.showFolder(windowId, 'inbox');
    },

    request: function(windowId, action, payload, callback) {
        window.emailBridge.request(action, payload || {}, function(response) {
            if (callback) {
                callback(response || {});
            }
        });
    },

    showFolder: function(windowId, folder) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.currentFolder = folder;
        instance.currentView = 'folder';
        instance.detailMessage = null;
        instance.selectedIds = {};
        instance.loading = true;

        var root = this.getRootElement(windowId);
        if (root) {
            root.querySelectorAll('.email-folder').forEach(function(button) {
                button.classList.toggle('active', button.getAttribute('data-folder') === folder);
            });
        }

        this.render(windowId);

        if (folder === 'drafts') {
            this.request(windowId, 'load_drafts', {}, function(payload) {
                var current = this.getInstance(windowId);
                if (!current) return;
                current.drafts = Array.isArray(payload.drafts) ? payload.drafts : [];
                current.loading = false;
                this.render(windowId);
            }.bind(this));
            return;
        }

        this.request(windowId, 'mailbox_index', { folder: folder }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.messagesByFolder[folder] = Array.isArray(payload.messages) ? payload.messages : [];
            current.unreadCount = payload.unreadCount || 0;
            current.loading = false;
            this.render(windowId);
        }.bind(this));
    },

    openCompose: function(windowId, existingDraft) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (existingDraft) {
            instance.compose = {
                draftId: existingDraft.id || null,
                recipients: Array.isArray(existingDraft.recipients) ? existingDraft.recipients.slice() : [],
                subject: existingDraft.subject || '',
                bodyMarkdown: existingDraft.bodyMarkdown || '',
                attachments: Array.isArray(existingDraft.attachments) ? existingDraft.attachments.slice() : [],
                previewMode: false,
                dirty: false
            };
        } else {
            instance.compose = this.createEmptyComposeState();
        }

        instance.recipientQuery = '';
        instance.currentView = 'compose';
        instance.loading = false;
        this.render(windowId);
    },

    ensureComposeForDrop: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) return;

        if (instance.currentView !== 'compose') {
            this.openCompose(windowId);
        }
    },

    onComposeChanged: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.compose.dirty = true;
        this.scheduleDraftSave(windowId);
        this.render(windowId);
    },

    scheduleDraftSave: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (instance.autosaveTimer) {
            clearTimeout(instance.autosaveTimer);
        }

        instance.autosaveTimer = setTimeout(function() {
            this.saveDraftIfNeeded(windowId);
        }.bind(this), 900);
    },

    saveDraftIfNeeded: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance || instance.currentView !== 'compose') {
            return;
        }

        if (!instance.compose.dirty && instance.compose.draftId) {
            return;
        }

        var hasContent = instance.compose.recipients.length > 0 ||
            instance.compose.subject.trim() !== '' ||
            instance.compose.bodyMarkdown.trim() !== '' ||
            instance.compose.attachments.length > 0;

        if (!hasContent) {
            return;
        }

        this.request(windowId, 'save_draft', {
            id: instance.compose.draftId,
            recipients: instance.compose.recipients,
            subject: instance.compose.subject,
            bodyMarkdown: instance.compose.bodyMarkdown,
            attachments: instance.compose.attachments
        }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current || !payload.success || !payload.draft) {
                return;
            }

            current.compose.draftId = payload.draft.id;
            current.compose.dirty = false;
            this.refreshDrafts(windowId);
        }.bind(this));
    },

    refreshDrafts: function(windowId) {
        this.request(windowId, 'load_drafts', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.drafts = Array.isArray(payload.drafts) ? payload.drafts : [];
            if (instance.currentFolder === 'drafts' && instance.currentView === 'folder') {
                this.render(windowId);
            }
        }.bind(this));
    },

    openDetail: function(windowId, folder, messageId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.loading = true;
        instance.detailFolder = folder;
        instance.currentView = 'detail';
        instance.detailMessage = null;
        this.render(windowId);

        this.request(windowId, 'email_detail', { messageId: messageId }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.loading = false;

            if (payload.success && payload.email) {
                current.detailMessage = payload.email;
                this.patchMessageSummary(windowId, payload.email);
            }

            this.render(windowId);
        }.bind(this));
    },

    patchMessageSummary: function(windowId, emailData) {
        var instance = this.getInstance(windowId);
        if (!instance || !emailData) {
            return;
        }

        ['inbox', 'sent', 'trash'].forEach(function(folder) {
            var list = instance.messagesByFolder[folder] || [];
            for (var i = 0; i < list.length; i++) {
                if (String(list[i].id) === String(emailData.id)) {
                    list[i].read = emailData.read === true;
                }
            }
        });
    },

    addAttachments: function(windowId, items) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var added = 0;
        items.forEach(function(item) {
            var exists = instance.compose.attachments.some(function(existing) {
                return this.normalizePath(existing.filepath || '') === this.normalizePath(item.filepath || '');
            }.bind(this));

            if (exists) {
                return;
            }

            var attachment = {
                filepath: item.filepath,
                filename: item.filename || window.getFileNameFromPath(item.filepath),
                displayName: item.displayName || item.name || item.filename || window.getFileNameFromPath(item.filepath),
                filetype: item.filetype || window.getFileTypeFromPath(item.filepath),
                sourcePath: item.filepath || '',
                content: null
            };

            instance.compose.attachments.push(attachment);
            added++;
            this.hydrateAttachment(windowId, attachment);
        }.bind(this));

        if (added > 0 && window.osErrorHandler) {
            window.osErrorHandler.showNotification('Attached ' + added + ' file(s)', 'success', 1800);
        }

        this.onComposeChanged(windowId);
    },

    hydrateAttachment: function(windowId, attachment) {
        if (!attachment || !attachment.filepath || !window.filesystem) {
            return;
        }

        window.filesystem.readFile(attachment.filepath, function(content) {
            if (content === null || content === undefined) {
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification('Failed to read attachment: ' + (attachment.displayName || attachment.filepath), 'warning', 2400);
                }
                return;
            }

            attachment.content = content;
            var instance = this.getInstance(windowId);
            if (instance && instance.currentView === 'compose') {
                this.scheduleDraftSave(windowId);
            }
        }.bind(this));
    },

    removeAttachment: function(windowId, attachmentIndex) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.compose.attachments.splice(attachmentIndex, 1);
        this.onComposeChanged(windowId);
    },

    normalizePath: function(path) {
        return String(path || '').replace(/\\/g, '/').toLowerCase();
    },

    getFolderTitle: function(folder) {
        switch (folder) {
            case 'sent': return 'Sent';
            case 'drafts': return 'Drafts';
            case 'trash': return 'Trash';
            default: return 'Inbox';
        }
    },

    getCurrentFolderMessages: function(instance) {
        if (!instance) {
            return [];
        }

        if (instance.currentFolder === 'drafts') {
            return Array.isArray(instance.drafts) ? instance.drafts : [];
        }

        return Array.isArray(instance.messagesByFolder[instance.currentFolder]) ? instance.messagesByFolder[instance.currentFolder] : [];
    },

    toggleSelection: function(windowId, messageId) {
        var instance = this.getInstance(windowId);
        if (!instance) return;

        if (instance.selectedIds[messageId]) {
            delete instance.selectedIds[messageId];
        } else {
            instance.selectedIds[messageId] = true;
        }

        this.render(windowId);
    },

    toggleSelectAll: function(windowId, checked) {
        var instance = this.getInstance(windowId);
        if (!instance) return;

        instance.selectedIds = {};
        if (checked) {
            this.getCurrentFolderMessages(instance).forEach(function(message) {
                instance.selectedIds[message.id] = true;
            });
        }

        this.render(windowId);
    },

    performBulkAction: function(windowId, operation) {
        var instance = this.getInstance(windowId);
        if (!instance) return;

        var messageIds = Object.keys(instance.selectedIds);
        if (!messageIds.length) {
            return;
        }

        if (instance.currentFolder === 'drafts') {
            if (operation === 'delete') {
                this.deleteDrafts(windowId, messageIds);
            }
            return;
        }

        this.request(windowId, 'update_state', {
            operation: operation,
            messageIds: messageIds
        }, function() {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.selectedIds = {};
            this.showFolder(windowId, current.currentFolder);
        }.bind(this));
    },

    deleteDrafts: function(windowId, draftIds) {
        var remaining = draftIds.length;
        if (!remaining) {
            return;
        }

        draftIds.forEach(function(draftId) {
            this.request(windowId, 'delete_draft', { id: draftId }, function() {
                remaining--;
                if (remaining <= 0) {
                    var instance = this.getInstance(windowId);
                    if (!instance) return;
                    instance.selectedIds = {};
                    this.refreshDrafts(windowId);
                    if (instance.currentFolder === 'drafts') {
                        this.showFolder(windowId, 'drafts');
                    }
                }
            }.bind(this));
        }.bind(this));
    },

    deleteCurrentDetail: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance || !instance.detailMessage) {
            return;
        }

        this.request(windowId, 'update_state', {
            operation: 'delete',
            messageIds: [instance.detailMessage.id]
        }, function() {
            this.showFolder(windowId, instance.detailFolder || instance.currentFolder || 'inbox');
        }.bind(this));
    },

    replyToCurrent: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance || !instance.detailMessage) {
            return;
        }

        var original = instance.detailMessage;
        var quoted = this.quoteMarkdown(original.bodyMarkdown || '');
        var subject = String(original.subject || '');
        if (subject.toLowerCase().indexOf('re:') !== 0) {
            subject = 'Re: ' + subject;
        }

        instance.compose = this.createEmptyComposeState();
        instance.compose.recipients = [original.sender];
        instance.compose.subject = subject;
        instance.compose.bodyMarkdown = '\n\n' + quoted;
        instance.compose.attachments = [];
        instance.compose.dirty = true;
        instance.compose.previewMode = false;
        instance.currentView = 'compose';
        this.render(windowId);
    },

    forwardCurrent: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance || !instance.detailMessage) {
            return;
        }

        var original = instance.detailMessage;
        var subject = String(original.subject || '');
        if (subject.toLowerCase().indexOf('fwd:') !== 0) {
            subject = 'Fwd: ' + subject;
        }

        instance.compose = this.createEmptyComposeState();
        instance.compose.subject = subject;
        instance.compose.bodyMarkdown = original.bodyMarkdown || '';
        instance.compose.attachments = Array.isArray(original.attachments) ? original.attachments.slice() : [];
        instance.compose.dirty = true;
        instance.compose.previewMode = false;
        instance.currentView = 'compose';
        this.render(windowId);
    },

    quoteMarkdown: function(markdown) {
        return String(markdown || '').split('\n').map(function(line) {
            return '> ' + line;
        }).join('\n');
    },

    commitRecipientInput: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var input = root.querySelector('.email-to-input');
        if (!input) {
            return;
        }

        var value = String(input.value || '').trim();
        if (!value) {
            return;
        }

        var options = this.getRecipientOptions(instance, value);
        var selected = null;

        for (var i = 0; i < options.length; i++) {
            var option = options[i];
            if (String(option.steamID64 || '').toLowerCase() === value.toLowerCase() ||
                String(option.steamID || '').toLowerCase() === value.toLowerCase()) {
                selected = option;
                break;
            }
        }

        if (!selected && options.length > 0) {
            selected = options[0];
        }

        if (!selected && this.isLikelySteamId(value)) {
            selected = {
                steamID: this.looksLikeSteamId64(value) ? '' : value,
                steamID64: this.looksLikeSteamId64(value) ? value : '',
                nickname: value
            };
        }

        if (!selected) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Enter a valid SteamID or pick a recipient.', 'warning', 2200);
            }
            return;
        }

        this.addRecipient(windowId, selected);
        input.value = '';
        instance.recipientQuery = '';
        this.render(windowId);
    },

    isLikelySteamId: function(value) {
        return /^STEAM_\d:\d:\d+$/.test(String(value || '')) || this.looksLikeSteamId64(value);
    },

    looksLikeSteamId64: function(value) {
        return /^\d{17}$/.test(String(value || ''));
    },

    addRecipient: function(windowId, contact) {
        var instance = this.getInstance(windowId);
        if (!instance || !contact) {
            return;
        }

        var key = String(contact.steamID64 || contact.steamID || '').toLowerCase();
        if (!key) {
            return;
        }

        var exists = instance.compose.recipients.some(function(existing) {
            return String(existing.steamID64 || existing.steamID || '').toLowerCase() === key;
        });

        if (exists) {
            return;
        }

        instance.compose.recipients.push({
            steamID: contact.steamID || '',
            steamID64: contact.steamID64 || '',
            nickname: contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact'
        });

        this.onComposeChanged(windowId);
    },

    removeRecipient: function(windowId, key) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.compose.recipients = instance.compose.recipients.filter(function(contact) {
            return String(contact.steamID64 || contact.steamID || '') !== String(key || '');
        });

        this.onComposeChanged(windowId);
    },

    isFavorite: function(instance, contact) {
        var key = String(contact.steamID64 || contact.steamID || '');
        return (instance.favorites || []).some(function(favorite) {
            return String(favorite.steamID64 || favorite.steamID || '') === key;
        });
    },

    toggleFavorite: function(windowId, contact) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        this.request(windowId, 'set_favorite', {
            contact: contact,
            favorite: !this.isFavorite(instance, contact)
        }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.favorites = Array.isArray(payload.favorites) ? payload.favorites : [];
            this.render(windowId);
        }.bind(this));
    },

    getRecipientOptions: function(instance, query) {
        var merged = {};
        var ordered = [];

        var ingest = function(contact, source) {
            if (!contact) return;
            var key = String(contact.steamID64 || contact.steamID || '').toLowerCase();
            if (!key) return;

            if (!merged[key]) {
                merged[key] = {
                    steamID: contact.steamID || '',
                    steamID64: contact.steamID64 || '',
                    nickname: contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact',
                    source: source
                };
                ordered.push(merged[key]);
                return;
            }

            if ((!merged[key].nickname || merged[key].nickname === merged[key].steamID || merged[key].nickname === merged[key].steamID64) && contact.nickname) {
                merged[key].nickname = contact.nickname;
            }
        };

        (instance.favorites || []).forEach(function(contact) { ingest(contact, 'favorite'); });
        (instance.onlinePlayers || []).forEach(function(contact) { ingest(contact, 'online'); });
        (instance.contacts || []).forEach(function(contact) { ingest(contact, 'history'); });

        var normalizedQuery = String(query || '').toLowerCase().trim();
        if (normalizedQuery) {
            ordered = ordered.filter(function(contact) {
                return String(contact.nickname || '').toLowerCase().indexOf(normalizedQuery) !== -1 ||
                    String(contact.steamID || '').toLowerCase().indexOf(normalizedQuery) !== -1 ||
                    String(contact.steamID64 || '').toLowerCase().indexOf(normalizedQuery) !== -1;
            });
        }

        ordered.sort(function(a, b) {
            var scoreA = (instance.favorites || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(a.steamID64 || a.steamID || '');
            }) ? 0 : ((instance.onlinePlayers || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(a.steamID64 || a.steamID || '');
            }) ? 1 : 2);

            var scoreB = (instance.favorites || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(b.steamID64 || b.steamID || '');
            }) ? 0 : ((instance.onlinePlayers || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(b.steamID64 || b.steamID || '');
            }) ? 1 : 2);

            if (scoreA !== scoreB) {
                return scoreA - scoreB;
            }

            return String(a.nickname || '').localeCompare(String(b.nickname || ''));
        });

        return ordered.slice(0, 24);
    },

    openDraft: function(windowId, draftId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var draft = (instance.drafts || []).find(function(entry) {
            return String(entry.id) === String(draftId);
        });

        if (draft) {
            this.openCompose(windowId, draft);
        }
    },

    sendCurrentEmail: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (!instance.compose.recipients.length) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Add at least one recipient.', 'warning', 2200);
            }
            return;
        }

        this.resolveAttachmentContents(windowId, function(resolvedAttachments) {
            var current = this.getInstance(windowId);
            if (!current) return;

            current.loading = true;
            this.render(windowId);

            this.request(windowId, 'send_email', {
                recipients: current.compose.recipients,
                subject: current.compose.subject,
                bodyMarkdown: current.compose.bodyMarkdown,
                attachments: resolvedAttachments
            }, function(payload) {
                var latest = this.getInstance(windowId);
                if (!latest) return;
                latest.loading = false;

                if (payload.success) {
                    if (latest.compose.draftId) {
                        this.request(windowId, 'delete_draft', { id: latest.compose.draftId }, function() {});
                    }

                    latest.compose = this.createEmptyComposeState();
                    latest.recipientQuery = '';
                    this.refreshDrafts(windowId);
                    this.request(windowId, 'contacts', {}, function(contactsPayload) {
                        var refreshed = this.getInstance(windowId);
                        if (!refreshed) return;
                        refreshed.contacts = Array.isArray(contactsPayload.contacts) ? contactsPayload.contacts : refreshed.contacts;
                    }.bind(this));

                    if (window.osErrorHandler) {
                        window.osErrorHandler.showNotification('Email sent.', 'success', 2000);
                    }

                    this.showFolder(windowId, 'sent');
                } else {
                    this.render(windowId);
                    if (window.osErrorHandler) {
                        window.osErrorHandler.showNotification(payload.message || 'Failed to send email.', 'error', 2600);
                    }
                }
            }.bind(this));
        }.bind(this));
    },

    resolveAttachmentContents: function(windowId, callback) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            callback([]);
            return;
        }

        var attachments = instance.compose.attachments || [];
        if (!attachments.length) {
            callback([]);
            return;
        }

        var remaining = attachments.length;
        var resolved = [];

        attachments.forEach(function(attachment, index) {
            var finalize = function(content) {
                resolved[index] = {
                    displayName: attachment.displayName,
                    filename: attachment.filename,
                    filetype: attachment.filetype,
                    sourcePath: attachment.sourcePath || attachment.filepath || '',
                    content: content || ''
                };

                remaining--;
                if (remaining <= 0) {
                    callback(resolved);
                }
            };

            if (attachment.content !== null && attachment.content !== undefined) {
                finalize(attachment.content);
                return;
            }

            if (!attachment.filepath || !window.filesystem) {
                finalize('');
                return;
            }

            window.filesystem.readFile(attachment.filepath, function(content) {
                attachment.content = content || '';
                finalize(attachment.content);
            });
        });
    },

    toggleComposePreview: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.compose.previewMode = !instance.compose.previewMode;
        this.render(windowId);
    },

    formatComposeText: function(windowId, format) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance) return;

        var editor = root.querySelector('.email-body-input');
        if (!editor) return;

        var start = editor.selectionStart;
        var end = editor.selectionEnd;
        var selectedText = editor.value.substring(start, end);
        var beforeText = editor.value.substring(0, start);
        var afterText = editor.value.substring(end);
        var replacement = '';

        switch (format) {
            case 'bold':
                replacement = '**' + (selectedText || 'text') + '**';
                break;
            case 'italic':
                replacement = '*' + (selectedText || 'text') + '*';
                break;
            case 'h1':
                replacement = '# ' + (selectedText || 'Heading 1');
                break;
            case 'h2':
                replacement = '## ' + (selectedText || 'Heading 2');
                break;
            case 'h3':
                replacement = '### ' + (selectedText || 'Heading 3');
                break;
            case 'bullet':
                replacement = selectedText ? selectedText.split('\n').map(function(line) { return '- ' + line; }).join('\n') : '- List item';
                break;
            case 'numbered':
                replacement = selectedText ? selectedText.split('\n').map(function(line, index) { return (index + 1) + '. ' + line; }).join('\n') : '1. List item';
                break;
            case 'code':
                replacement = '`' + (selectedText || 'code') + '`';
                break;
        }

        editor.value = beforeText + replacement + afterText;
        editor.focus();
        editor.setSelectionRange(start + replacement.length, start + replacement.length);
        instance.compose.bodyMarkdown = editor.value;
        this.onComposeChanged(windowId);
    },

    render: function(windowId) {
        var instance = this.getInstance(windowId);
        var viewRoot = this.getViewRoot(windowId);
        if (!instance || !viewRoot) {
            return;
        }

        if (instance.currentView === 'compose') {
            viewRoot.innerHTML = this.renderComposeView(instance);
            this.bindComposeEvents(windowId);
            return;
        }

        if (instance.currentView === 'detail') {
            viewRoot.innerHTML = this.renderDetailView(instance);
            this.bindDetailEvents(windowId);
            return;
        }

        viewRoot.innerHTML = this.renderFolderView(instance);
        this.bindFolderEvents(windowId);
    },

    renderFolderView: function(instance) {
        var messages = this.getCurrentFolderMessages(instance);
        var selectedCount = Object.keys(instance.selectedIds || {}).length;
        var allowReadButtons = instance.currentFolder !== 'drafts' && instance.currentFolder !== 'sent';
        var title = this.getFolderTitle(instance.currentFolder);

        var html = '' +
            '<div class="email-panel email-folder-panel">' +
                '<div class="email-toolbar">' +
                    '<div class="email-toolbar-title-wrap">' +
                        '<div class="email-toolbar-title">' + this.escapeHtml(title) + '</div>' +
                        '<div class="email-toolbar-subtitle">' + this.escapeHtml(String(messages.length)) + ' item(s)</div>' +
                    '</div>' +
                    '<div class="email-toolbar-actions">' +
                        '<button class="email-toolbar-btn email-refresh-btn">Refresh</button>' +
                        '<button class="email-toolbar-btn email-bulk-delete-btn" ' + (selectedCount ? '' : 'disabled') + '>Delete</button>';

        if (allowReadButtons) {
            html += '<button class="email-toolbar-btn email-bulk-read-btn" ' + (selectedCount ? '' : 'disabled') + '>Mark Read</button>' +
                '<button class="email-toolbar-btn email-bulk-unread-btn" ' + (selectedCount ? '' : 'disabled') + '>Mark Unread</button>';
        }

        html += '</div></div>';

        if (instance.loading) {
            html += '<div class="email-empty-state"><div class="email-empty-title">Loading...</div><div class="email-empty-text">Fetching ' + this.escapeHtml(title.toLowerCase()) + '.</div></div></div>';
            return html;
        }

        if (!messages.length) {
            html += '<div class="email-empty-state"><div class="email-empty-title">No ' + this.escapeHtml(title.toLowerCase()) + '</div><div class="email-empty-text">This folder is empty.</div></div></div>';
            return html;
        }

        html += '<div class="email-list-table">';
        html += '<div class="email-list-header">' +
            '<label class="email-checkbox-wrap"><input type="checkbox" class="email-select-all" ' + (selectedCount && selectedCount === messages.length ? 'checked' : '') + ' /><span></span></label>' +
            '<div class="email-list-col email-list-primary">Message</div>' +
            '<div class="email-list-col email-list-secondary">When</div>' +
        '</div>';

        messages.forEach(function(message) {
            var isUnread = !message.read && instance.currentFolder !== 'sent' && instance.currentFolder !== 'drafts';
            var checked = !!instance.selectedIds[message.id];
            html += '<div class="email-list-row ' + (isUnread ? 'is-unread' : '') + '" data-message-id="' + this.escapeHtml(message.id) + '">' +
                '<label class="email-checkbox-wrap"><input type="checkbox" class="email-row-checkbox" data-message-id="' + this.escapeHtml(message.id) + '" ' + (checked ? 'checked' : '') + ' /><span></span></label>' +
                '<div class="email-list-col email-list-primary">' +
                    '<div class="email-row-topline">' + this.escapeHtml(this.getMessagePrimaryLabel(instance.currentFolder, message)) + '</div>' +
                    '<div class="email-row-subject">' + this.escapeHtml(message.subject || 'No Subject') + '</div>' +
                    '<div class="email-row-preview">' + this.escapeHtml(message.preview || '') + '</div>' +
                '</div>' +
                '<div class="email-list-col email-list-secondary">' +
                    '<div class="email-row-date">' + this.escapeHtml(this.formatTimestamp(message.sentAt)) + '</div>' +
                    '<div class="email-row-meta">' + this.escapeHtml((message.attachmentsCount || 0) + ' attachment(s)') + '</div>' +
                '</div>' +
            '</div>';
        }.bind(this));

        html += '</div></div>';
        return html;
    },

    getMessagePrimaryLabel: function(folder, message) {
        if (folder === 'sent') {
            var recipients = Array.isArray(message.recipients) ? message.recipients : [];
            if (!recipients.length) {
                return 'To: Unknown Recipient';
            }

            if (recipients.length === 1) {
                return 'To: ' + this.formatContact(recipients[0]);
            }

            return 'To: ' + this.formatContact(recipients[0]) + ' +' + (recipients.length - 1);
        }

        if (folder === 'drafts') {
            var draftRecipients = Array.isArray(message.recipients) ? message.recipients : [];
            return draftRecipients.length ? ('Draft to: ' + this.formatContact(draftRecipients[0])) : 'Draft';
        }

        return 'From: ' + this.formatContact(message.sender || {});
    },

    renderComposeView: function(instance) {
        var options = this.getRecipientOptions(instance, instance.recipientQuery);
        var html = '' +
            '<div class="email-panel email-compose-panel">' +
                '<div class="email-compose-header">' +
                    '<button class="email-back-btn btn">Back</button>' +
                    '<div class="email-compose-title-wrap">' +
                        '<div class="email-compose-title">' + (instance.compose.draftId ? 'Edit Draft' : 'New Message') + '</div>' +
                        '<div class="email-compose-subtitle">' + this.escapeHtml(this.getFolderTitle(instance.currentFolder)) + '</div>' +
                    '</div>' +
                    '<div class="email-compose-header-actions">' +
                        '<button class="email-toolbar-btn email-save-draft-btn">Save Draft</button>' +
                        '<button class="email-toolbar-btn email-preview-toggle-btn">' + (instance.compose.previewMode ? 'Edit' : 'Preview') + '</button>' +
                        '<button class="email-toolbar-btn email-send-btn">Send</button>' +
                    '</div>' +
                '</div>' +
                '<div class="email-compose-fields">' +
                    '<div class="email-field">' +
                        '<span>To</span>' +
                        '<div class="email-recipient-input-box">' +
                            '<div class="email-recipient-chips">';

        instance.compose.recipients.forEach(function(recipient) {
            var key = recipient.steamID64 || recipient.steamID || '';
            html += '<div class="email-recipient-chip">' +
                '<span class="email-recipient-chip-name">' + this.escapeHtml(this.formatContact(recipient)) + '</span>' +
                '<button class="email-recipient-chip-remove" data-recipient-key="' + this.escapeHtml(key) + '">x</button>' +
            '</div>';
        }.bind(this));

        html += '</div>' +
                            '<input type="text" class="email-input email-to-input" placeholder="SteamID, SteamID64, or contact name" value="' + this.escapeHtml(instance.recipientQuery) + '" />' +
                        '</div>' +
                        '<div class="email-recipient-dropdown ' + (instance.recipientQuery !== '' || options.length ? 'is-open' : '') + '">';

        if (options.length) {
            options.forEach(function(option) {
                var favorite = this.isFavorite(instance, option);
                html += '<div class="email-recipient-option" data-recipient-key="' + this.escapeHtml(option.steamID64 || option.steamID || '') + '">' +
                    '<button class="email-favorite-toggle" data-favorite-key="' + this.escapeHtml(option.steamID64 || option.steamID || '') + '">' + (favorite ? '★' : '☆') + '</button>' +
                    '<div class="email-recipient-option-main">' +
                        '<div class="email-recipient-option-name">' + this.escapeHtml(option.nickname || option.steamID || option.steamID64 || 'Unknown') + '</div>' +
                        '<div class="email-recipient-option-meta">' + this.escapeHtml(option.steamID || option.steamID64 || '') + '</div>' +
                    '</div>' +
                '</div>';
            }.bind(this));
        } else {
            html += '<div class="email-recipient-empty">Type a SteamID or pick from your contacts.</div>';
        }

        html += '</div></div>' +
                    '<label class="email-field">' +
                        '<span>Subject</span>' +
                        '<input type="text" class="email-input email-subject-input" value="' + this.escapeHtml(instance.compose.subject) + '" placeholder="Subject" />' +
                    '</label>' +
                '</div>' +
                '<div class="email-attachments-section">' +
                    '<div class="email-section-header">' +
                        '<span>Attachments</span>' +
                        '<span class="email-section-meta">' + instance.compose.attachments.length + ' file(s)</span>' +
                    '</div>' +
                    '<div class="email-attachments-list">';

        if (!instance.compose.attachments.length) {
            html += '<div class="email-attachments-empty">Drop files anywhere on the Email window to attach them.</div>';
        } else {
            instance.compose.attachments.forEach(function(attachment, index) {
                html += '<div class="email-attachment-item">' +
                    '<div class="email-attachment-meta">' +
                        '<div class="email-attachment-name">' + this.escapeHtml(attachment.displayName || attachment.filename || 'Attachment') + '</div>' +
                        '<div class="email-attachment-path">' + this.escapeHtml(attachment.filepath || attachment.sourcePath || '') + '</div>' +
                    '</div>' +
                    '<button class="email-toolbar-btn email-attachment-remove-btn" data-attachment-index="' + index + '">Remove</button>' +
                '</div>';
            }.bind(this));
        }

        html += '</div></div>' +
                '<div class="email-editor-shell">' +
                    '<div class="email-editor-toolbar">' +
                        '<button class="email-format-btn" data-format="bold">B</button>' +
                        '<button class="email-format-btn" data-format="italic">I</button>' +
                        '<button class="email-format-btn" data-format="h1">H1</button>' +
                        '<button class="email-format-btn" data-format="h2">H2</button>' +
                        '<button class="email-format-btn" data-format="h3">H3</button>' +
                        '<button class="email-format-btn" data-format="bullet">List</button>' +
                        '<button class="email-format-btn" data-format="numbered">1.</button>' +
                        '<button class="email-format-btn" data-format="code">Code</button>' +
                    '</div>';

        if (instance.compose.previewMode) {
            html += '<div class="email-body-preview">' + this.renderMarkdown(instance.compose.bodyMarkdown) + '</div>';
        } else {
            html += '<textarea class="email-body-input" placeholder="Write your message here... Markdown is supported.">' + this.escapeHtml(instance.compose.bodyMarkdown) + '</textarea>';
        }

        html += '</div></div>';
        return html;
    },

    renderDetailView: function(instance) {
        var message = instance.detailMessage;
        if (instance.loading || !message) {
            return '<div class="email-panel email-detail-panel"><div class="email-empty-state"><div class="email-empty-title">Loading...</div><div class="email-empty-text">Opening email.</div></div></div>';
        }

        var html = '' +
            '<div class="email-panel email-detail-panel">' +
                '<div class="email-detail-header">' +
                    '<button class="email-back-btn btn">Back</button>' +
                    '<div class="email-detail-title-wrap">' +
                        '<div class="email-detail-title">' + this.escapeHtml(message.subject || 'No Subject') + '</div>' +
                        '<div class="email-detail-meta">From ' + this.escapeHtml(this.formatContact(message.sender || {})) + ' • ' + this.escapeHtml(this.formatTimestamp(message.sentAt)) + '</div>' +
                    '</div>' +
                    '<div class="email-detail-actions">' +
                        '<button class="email-toolbar-btn email-reply-btn">Reply</button>' +
                        '<button class="email-toolbar-btn email-forward-btn">Forward</button>' +
                        '<button class="email-toolbar-btn email-delete-btn">Delete</button>' +
                    '</div>' +
                '</div>' +
                '<div class="email-detail-recipients">To: ' + this.escapeHtml((message.recipients || []).map(function(recipient) {
                    return emailApp.formatContact(recipient);
                }).join(', ')) + '</div>' +
                '<div class="email-detail-body">' + this.renderMarkdown(message.bodyMarkdown || '') + '</div>' +
                '<div class="email-attachments-section">' +
                    '<div class="email-section-header">' +
                        '<span>Attachments</span>' +
                        '<span class="email-section-meta">' + ((message.attachments || []).length) + ' file(s)</span>' +
                    '</div>' +
                    '<div class="email-attachments-list">';

        if (!message.attachments || !message.attachments.length) {
            html += '<div class="email-attachments-empty">No attachments.</div>';
        } else {
            (message.attachments || []).forEach(function(attachment, index) {
                html += '<div class="email-attachment-item">' +
                    '<div class="email-attachment-meta">' +
                        '<div class="email-attachment-name">' + this.escapeHtml(attachment.displayName || attachment.filename || 'Attachment') + '</div>' +
                        '<div class="email-attachment-path">' + this.escapeHtml(attachment.filetype || '') + '</div>' +
                    '</div>' +
                    '<div class="email-detail-attachment-actions">' +
                        '<button class="email-toolbar-btn email-open-attachment-btn" data-attachment-index="' + index + '">Open</button>' +
                        '<button class="email-toolbar-btn email-save-attachment-btn" data-attachment-index="' + index + '">Save</button>' +
                    '</div>' +
                '</div>';
            }.bind(this));
        }

        html += '</div></div></div>';
        return html;
    },

    bindFolderEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance) {
            return;
        }

        var refreshBtn = root.querySelector('.email-refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', function() {
                this.showFolder(windowId, instance.currentFolder);
            }.bind(this));
        }

        var deleteBtn = root.querySelector('.email-bulk-delete-btn');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', function() {
                this.performBulkAction(windowId, 'delete');
            }.bind(this));
        }

        var readBtn = root.querySelector('.email-bulk-read-btn');
        if (readBtn) {
            readBtn.addEventListener('click', function() {
                this.performBulkAction(windowId, 'read');
            }.bind(this));
        }

        var unreadBtn = root.querySelector('.email-bulk-unread-btn');
        if (unreadBtn) {
            unreadBtn.addEventListener('click', function() {
                this.performBulkAction(windowId, 'unread');
            }.bind(this));
        }

        var selectAll = root.querySelector('.email-select-all');
        if (selectAll) {
            selectAll.addEventListener('change', function() {
                this.toggleSelectAll(windowId, selectAll.checked);
            }.bind(this));
        }

        root.querySelectorAll('.email-row-checkbox').forEach(function(checkbox) {
            checkbox.addEventListener('click', function(e) {
                e.stopPropagation();
            });
            checkbox.addEventListener('change', function() {
                this.toggleSelection(windowId, checkbox.getAttribute('data-message-id'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-list-row').forEach(function(row) {
            row.addEventListener('click', function(e) {
                if (e.target.closest('.email-checkbox-wrap')) {
                    return;
                }

                var messageId = row.getAttribute('data-message-id');
                if (instance.currentFolder === 'drafts') {
                    this.openDraft(windowId, messageId);
                } else {
                    this.openDetail(windowId, instance.currentFolder, messageId);
                }
            }.bind(this));
        }.bind(this));
    },

    bindComposeEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance) {
            return;
        }

        var backBtn = root.querySelector('.email-back-btn');
        if (backBtn) {
            backBtn.addEventListener('click', function() {
                this.saveDraftIfNeeded(windowId);
                this.showFolder(windowId, instance.currentFolder || 'inbox');
            }.bind(this));
        }

        var saveDraftBtn = root.querySelector('.email-save-draft-btn');
        if (saveDraftBtn) {
            saveDraftBtn.addEventListener('click', function() {
                this.saveDraftIfNeeded(windowId);
                this.refreshDrafts(windowId);
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification('Draft saved.', 'success', 1600);
                }
            }.bind(this));
        }

        var previewBtn = root.querySelector('.email-preview-toggle-btn');
        if (previewBtn) {
            previewBtn.addEventListener('click', function() {
                this.toggleComposePreview(windowId);
            }.bind(this));
        }

        var sendBtn = root.querySelector('.email-send-btn');
        if (sendBtn) {
            sendBtn.addEventListener('click', function() {
                this.commitRecipientInput(windowId);
                this.sendCurrentEmail(windowId);
            }.bind(this));
        }

        var toInput = root.querySelector('.email-to-input');
        if (toInput) {
            toInput.addEventListener('input', function() {
                instance.recipientQuery = toInput.value;
                this.render(windowId);
            }.bind(this));

            toInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === 'Tab' || e.key === ',') {
                    e.preventDefault();
                    this.commitRecipientInput(windowId);
                }
            }.bind(this));
        }

        var subjectInput = root.querySelector('.email-subject-input');
        if (subjectInput) {
            subjectInput.addEventListener('input', function() {
                instance.compose.subject = subjectInput.value;
                this.onComposeChanged(windowId);
            }.bind(this));
        }

        var bodyInput = root.querySelector('.email-body-input');
        if (bodyInput) {
            bodyInput.addEventListener('input', function() {
                instance.compose.bodyMarkdown = bodyInput.value;
                this.onComposeChanged(windowId);
            }.bind(this));
        }

        root.querySelectorAll('.email-format-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.formatComposeText(windowId, button.getAttribute('data-format'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-recipient-chip-remove').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeRecipient(windowId, button.getAttribute('data-recipient-key'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-recipient-option').forEach(function(optionNode) {
            optionNode.addEventListener('click', function(e) {
                if (e.target.closest('.email-favorite-toggle')) {
                    return;
                }

                var key = optionNode.getAttribute('data-recipient-key');
                var contact = this.getRecipientOptions(instance, instance.recipientQuery).find(function(option) {
                    return String(option.steamID64 || option.steamID || '') === String(key || '');
                });

                if (contact) {
                    this.addRecipient(windowId, contact);
                    instance.recipientQuery = '';
                    this.render(windowId);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-favorite-toggle').forEach(function(button) {
            button.addEventListener('click', function(e) {
                e.stopPropagation();
                var key = button.getAttribute('data-favorite-key');
                var contact = this.getRecipientOptions(instance, instance.recipientQuery).find(function(option) {
                    return String(option.steamID64 || option.steamID || '') === String(key || '');
                });
                if (contact) {
                    this.toggleFavorite(windowId, contact);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-attachment-remove-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeAttachment(windowId, parseInt(button.getAttribute('data-attachment-index'), 10) || 0);
            }.bind(this));
        }.bind(this));
    },

    bindDetailEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance) {
            return;
        }

        var backBtn = root.querySelector('.email-back-btn');
        if (backBtn) {
            backBtn.addEventListener('click', function() {
                this.showFolder(windowId, instance.detailFolder || instance.currentFolder || 'inbox');
            }.bind(this));
        }

        var replyBtn = root.querySelector('.email-reply-btn');
        if (replyBtn) {
            replyBtn.addEventListener('click', function() {
                this.replyToCurrent(windowId);
            }.bind(this));
        }

        var forwardBtn = root.querySelector('.email-forward-btn');
        if (forwardBtn) {
            forwardBtn.addEventListener('click', function() {
                this.forwardCurrent(windowId);
            }.bind(this));
        }

        var deleteBtn = root.querySelector('.email-delete-btn');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', function() {
                this.deleteCurrentDetail(windowId);
            }.bind(this));
        }

        root.querySelectorAll('.email-open-attachment-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.exportDetailAttachment(windowId, parseInt(button.getAttribute('data-attachment-index'), 10) || 0, true);
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-save-attachment-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.exportDetailAttachment(windowId, parseInt(button.getAttribute('data-attachment-index'), 10) || 0, false);
            }.bind(this));
        }.bind(this));
    },

    exportDetailAttachment: function(windowId, attachmentIndex, openAfterSave) {
        var instance = this.getInstance(windowId);
        if (!instance || !instance.detailMessage || !window.filesystem) {
            return;
        }

        var attachments = instance.detailMessage.attachments || [];
        var attachment = attachments[attachmentIndex];
        if (!attachment) {
            return;
        }

        var folderName = openAfterSave ? 'opened' : 'saved';
        var targetPath = 'ExternalDrive:/email_attachments/' + folderName + '/' + this.sanitizePathToken(instance.detailMessage.id || 'message') + '_' + this.sanitizePathToken(attachment.displayName || attachment.filename || 'attachment.txt');

        window.filesystem.writeFile(targetPath, attachment.content || '', function(success) {
            if (!success) {
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification('Failed to export attachment.', 'error', 2400);
                }
                return;
            }

            if (openAfterSave && window.osShell && window.osShell.handleFileOpen) {
                window.osShell.handleFileOpen(targetPath, {
                    filetype: attachment.filetype || window.getFileTypeFromPath(targetPath)
                }, false);
            } else if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Attachment saved to ExternalDrive:/email_attachments/' + folderName, 'success', 2200);
            }
        });
    },

    sanitizePathToken: function(value) {
        return String(value || 'item').toLowerCase().replace(/[^a-z0-9._-]/g, '_');
    },

    formatContact: function(contact) {
        if (!contact) {
            return 'Unknown Contact';
        }

        return contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact';
    },

    formatTimestamp: function(unixTime) {
        if (!unixTime) {
            return 'Unknown';
        }

        try {
            var date = new Date(unixTime * 1000);
            return date.toLocaleString();
        } catch (error) {
            return String(unixTime);
        }
    },

    renderMarkdown: function(markdown) {
        var escaped = this.escapeHtml(String(markdown || ''));
        var html = escaped
            .replace(/^### (.*$)/gim, '<h3>$1</h3>')
            .replace(/^## (.*$)/gim, '<h2>$1</h2>')
            .replace(/^# (.*$)/gim, '<h1>$1</h1>')
            .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/gim, '<em>$1</em>')
            .replace(/`(.*?)`/gim, '<code>$1</code>')
            .replace(/^> (.*$)/gim, '<blockquote>$1</blockquote>')
            .replace(/^- (.*$)/gim, '<li>$1</li>')
            .replace(/^(\d+)\. (.*$)/gim, '<li>$2</li>')
            .replace(/\n/gim, '<br>');

        html = html.replace(/(<li>.*?<\/li>)/gim, function(match) {
            if (match.indexOf('<ul>') !== -1) {
                return match;
            }
            return '<ul>' + match + '</ul>';
        });

        return html || '<p class="email-markdown-empty">Nothing to preview.</p>';
    },

    escapeHtml: function(text) {
        var div = document.createElement('div');
        div.textContent = String(text || '');
        return div.innerHTML;
    }
};
]]
end

function EMAIL.GetCSS()
    return [[
.program-email {
    display: flex;
    height: 100%;
    min-height: 0;
    background: var(--color-window-bg, #1f1f1f);
}

.email-sidebar {
    width: 220px;
    padding: 14px;
    border-right: 1px solid #323232;
    background: linear-gradient(180deg, #303846, #252b35);
    display: flex;
    flex-direction: column;
    gap: 14px;
}

.email-compose-btn,
.email-toolbar-btn,
.email-format-btn,
.email-folder,
.email-back-btn,
.email-favorite-toggle,
.email-recipient-chip-remove {
    font: inherit;
}

.email-compose-btn {
    width: 100%;
    padding: 11px 14px;
    border: 1px solid #4d8fca;
    border-radius: 6px;
    background: #2b6ba3;
    color: #fff;
    cursor: pointer;
}

.email-compose-btn:hover {
    background: #3379b7;
}

.email-folders {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.email-folder {
    width: 100%;
    padding: 9px 12px;
    text-align: left;
    border: 1px solid transparent;
    border-radius: 6px;
    background: transparent;
    color: #d5d5d5;
    cursor: pointer;
}

.email-folder:hover {
    background: rgba(255, 255, 255, 0.06);
}

.email-folder.active {
    background: #007acc;
    color: #fff;
}

.email-main {
    flex: 1;
    min-width: 0;
    min-height: 0;
    display: flex;
    flex-direction: column;
    background: linear-gradient(180deg, #1f2329, #181b20);
}

.email-view-root {
    flex: 1;
    min-height: 0;
}

.email-loading-state,
.email-empty-state {
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: #9ea7b3;
    padding: 20px;
    text-align: center;
}

.email-loading-title,
.email-empty-title {
    font-size: 22px;
    font-weight: 700;
    color: #d4d4d4;
    margin-bottom: 8px;
}

.email-panel {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
}

.email-toolbar,
.email-compose-header,
.email-detail-header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    border-bottom: 1px solid #2f3137;
    background: #242830;
}

.email-toolbar-title-wrap,
.email-compose-title-wrap,
.email-detail-title-wrap {
    min-width: 0;
}

.email-toolbar-title,
.email-compose-title,
.email-detail-title {
    color: #d4d4d4;
    font-size: 19px;
    font-weight: 700;
}

.email-toolbar-subtitle,
.email-compose-subtitle,
.email-detail-meta,
.email-section-meta {
    color: #8a93a2;
    font-size: 12px;
}

.email-toolbar-actions,
.email-compose-header-actions,
.email-detail-actions,
.email-detail-attachment-actions {
    margin-left: auto;
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.email-toolbar-btn,
.email-back-btn,
.email-format-btn {
    padding: 8px 12px;
    border: 1px solid #3a404a;
    border-radius: 6px;
    background: #2a2f38;
    color: #e2e6eb;
    cursor: pointer;
}

.email-toolbar-btn:hover,
.email-back-btn:hover,
.email-format-btn:hover {
    background: #343a45;
}

.email-toolbar-btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.email-list-table {
    flex: 1;
    min-height: 0;
    overflow: auto;
}

.email-list-header,
.email-list-row {
    display: grid;
    grid-template-columns: 34px minmax(0, 1fr) 170px;
    gap: 12px;
    align-items: center;
    padding: 10px 16px;
}

.email-list-header {
    position: sticky;
    top: 0;
    z-index: 1;
    background: #1d2127;
    border-bottom: 1px solid #2b2e34;
    color: #93a0b0;
    font-size: 12px;
}

.email-list-row {
    border-bottom: 1px solid #252a31;
    cursor: pointer;
    background: transparent;
}

.email-list-row:hover {
    background: rgba(255, 255, 255, 0.04);
}

.email-list-row.is-unread {
    background: rgba(0, 122, 204, 0.08);
}

.email-row-topline,
.email-row-subject,
.email-row-preview,
.email-row-date,
.email-row-meta {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.email-row-topline {
    color: #d4d4d4;
    font-size: 13px;
}

.email-row-subject {
    color: #ffffff;
    font-size: 14px;
    font-weight: 700;
    margin-top: 2px;
}

.email-row-preview,
.email-row-meta {
    color: #8f98a8;
    font-size: 12px;
    margin-top: 3px;
}

.email-row-date {
    color: #d4d4d4;
    font-size: 12px;
    text-align: right;
}

.email-list-secondary {
    text-align: right;
}

.email-checkbox-wrap {
    display: flex;
    align-items: center;
    justify-content: center;
}

.email-checkbox-wrap input {
    width: 16px;
    height: 16px;
}

.email-compose-panel,
.email-detail-panel {
    overflow: auto;
}

.email-compose-fields,
.email-detail-recipients,
.email-detail-body,
.email-attachments-section,
.email-editor-shell {
    padding: 0 16px;
}

.email-compose-fields {
    padding-top: 16px;
    display: grid;
    gap: 14px;
}

.email-field {
    display: flex;
    flex-direction: column;
    gap: 6px;
    color: #c5cfdb;
    font-size: 12px;
    position: relative;
}

.email-input,
.email-body-input {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid #3a404a;
    border-radius: 6px;
    background: #161a1f;
    color: #eef2f6;
    font: inherit;
    box-sizing: border-box;
}

.email-recipient-input-box {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 8px;
    border: 1px solid #3a404a;
    border-radius: 6px;
    background: #161a1f;
}

.email-recipient-chips {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.email-recipient-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 10px;
    border-radius: 999px;
    background: #007acc;
    color: #fff;
    font-size: 12px;
}

.email-recipient-chip-remove {
    border: none;
    background: transparent;
    color: inherit;
    cursor: pointer;
    padding: 0;
}

.email-to-input {
    flex: 1;
    min-width: 180px;
    border: none;
    background: transparent;
    padding: 6px 4px;
    outline: none;
}

.email-recipient-dropdown {
    display: none;
    margin-top: 6px;
    border: 1px solid #3a404a;
    border-radius: 8px;
    overflow: hidden;
    background: #1f242b;
    box-shadow: 0 12px 24px rgba(0, 0, 0, 0.35);
    max-height: 250px;
    overflow-y: auto;
}

.email-recipient-dropdown.is-open {
    display: block;
}

.email-recipient-option {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    border-bottom: 1px solid #2c3139;
    cursor: pointer;
}

.email-recipient-option:last-child {
    border-bottom: none;
}

.email-recipient-option:hover {
    background: rgba(255, 255, 255, 0.04);
}

.email-favorite-toggle {
    width: 28px;
    height: 28px;
    border: 1px solid #3a404a;
    border-radius: 6px;
    background: #272c34;
    color: #f7cb58;
    cursor: pointer;
    flex-shrink: 0;
}

.email-recipient-option-name {
    color: #eef2f6;
    font-size: 13px;
}

.email-recipient-option-meta,
.email-recipient-empty {
    color: #8b94a3;
    font-size: 12px;
}

.email-attachments-section {
    padding-top: 16px;
}

.email-section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    color: #d4d4d4;
    font-size: 13px;
    font-weight: 700;
    margin-bottom: 10px;
}

.email-attachments-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.email-attachments-empty {
    padding: 10px 0;
    color: #8f98a8;
    font-size: 12px;
}

.email-attachment-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 12px;
    border: 1px solid #2f333a;
    border-radius: 8px;
    background: #171b20;
}

.email-attachment-meta {
    min-width: 0;
}

.email-attachment-name {
    color: #eef2f6;
    font-size: 13px;
}

.email-attachment-path {
    color: #8f98a8;
    font-size: 11px;
    margin-top: 4px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.email-editor-shell {
    flex: 1;
    min-height: 0;
    padding-top: 16px;
    padding-bottom: 16px;
    display: flex;
    flex-direction: column;
}

.email-editor-toolbar {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    margin-bottom: 10px;
}

.email-body-input,
.email-body-preview {
    min-height: 260px;
    flex: 1;
}

.email-body-input {
    resize: vertical;
}

.email-body-preview,
.email-detail-body {
    border: 1px solid #2f333a;
    border-radius: 8px;
    background: #15191e;
    color: #d4d4d4;
    padding: 14px;
    line-height: 1.55;
}

.email-detail-recipients {
    padding-top: 14px;
    color: #8f98a8;
    font-size: 12px;
}

.email-detail-body {
    margin-top: 14px;
}

.email-body-preview h1,
.email-body-preview h2,
.email-body-preview h3,
.email-detail-body h1,
.email-detail-body h2,
.email-detail-body h3 {
    color: #4fc1ff;
}

.email-body-preview code,
.email-detail-body code {
    padding: 2px 4px;
    border-radius: 4px;
    background: #11151a;
    color: #d7ba7d;
}

.email-body-preview blockquote,
.email-detail-body blockquote {
    margin: 8px 0;
    padding-left: 12px;
    border-left: 3px solid #007acc;
    color: #b6c1cf;
}

.email-detail-panel .email-attachments-section {
    padding-bottom: 16px;
}
]]
end

return {
    title = "Email",
    icon = "📧",
    width = 800,
    height = 500,
    getContent = EMAIL.GetContent,
    getInitScript = EMAIL.GetInitScript,
    getJavaScript = EMAIL.GetJavaScript,
    getCSS = EMAIL.GetCSS
}