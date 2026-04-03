-- Email Program
local EMAIL = {}

function EMAIL.GetContent()
    return [[
<div class="program-email">
    <div class="email-sidebar">
        <button class="email-compose-btn">Compose</button>
        <div class="email-folders">
            <button class="email-folder active" data-folder="inbox"><span>Inbox</span><span class="email-folder-badge" style="display: none;">0</span></button>
            <button class="email-folder" data-folder="sent">Sent</button>
            <button class="email-folder" data-folder="drafts">Drafts</button>
            <button class="email-folder" data-folder="trash">Trash</button>
        </div>
        <div class="email-sidebar-bottom">
            <button class="email-folder" data-folder="contacts">Contacts</button>
            <div class="email-storage-widget"></div>
            <div class="email-user-widget"></div>
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
    return [=[
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
            storageUsed: 0,
            storageLimit: 0,
            selectedIds: {},
            detailMessage: null,
            detailFolder: 'inbox',
            onlinePlayers: [],
            contacts: [],
            favorites: [],
            localAliases: [],
            localLists: [],
            serverSets: [],
            adminAccess: false,
            drafts: [],
            compose: this.createEmptyComposeState(),
            contactsTab: 'local',
            localContactsSubTab: 'favorites',
            localContactDraft: {
                steamIdInput: '',
                nickname: ''
            },
            favoriteInlineEditKey: '',
            favoriteInlineEditValue: '',
            localListEditor: this.createCollectionEditorState('local_list'),
            serverSetEditor: this.createCollectionEditorState('server_set'),
            recipientQuery: '',
            recipientDropdownTab: 'all',
            recipientDropdownOpen: false,
            recipientBlurTimer: null,
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

    createCollectionEditorState: function(kind) {
        return {
            kind: kind || 'collection',
            id: null,
            name: '',
            members: [],
            manualMemberInput: ''
        };
    },

    resetCollectionEditorState: function(editor, kind) {
        if (!editor) {
            return this.createCollectionEditorState(kind);
        }

        editor.kind = kind || editor.kind || 'collection';
        editor.id = null;
        editor.name = '';
        editor.members = [];
        editor.manualMemberInput = '';
        return editor;
    },

    cloneAttachment: function(attachment) {
        if (!attachment) {
            return null;
        }

        var displayName = attachment.displayName || attachment.filename || attachment.name || 'attachment';
        var filepath = attachment.filepath || null;
        var sourcePath = attachment.sourcePath || filepath || '';

        return {
            filepath: filepath,
            sourcePath: sourcePath,
            filename: attachment.filename || displayName,
            displayName: displayName,
            filetype: attachment.filetype || '',
            content: attachment.content !== undefined ? attachment.content : null
        };
    },

    cloneAttachments: function(attachments) {
        if (!Array.isArray(attachments)) {
            return [];
        }

        return attachments.map(function(attachment) {
            return this.cloneAttachment(attachment);
        }.bind(this)).filter(function(attachment) {
            return !!attachment;
        });
    },

    getRecipientKind: function(recipient) {
        var kind = String((recipient && recipient.kind) || 'contact').toLowerCase();
        if (kind === 'local_list' || kind === 'server_set') {
            return kind;
        }
        return 'contact';
    },

    getRecipientKey: function(recipient) {
        if (!recipient) {
            return '';
        }

        if (recipient.key) {
            return String(recipient.key);
        }

        var kind = this.getRecipientKind(recipient);
        if (kind === 'local_list') {
            return 'local_list:' + String(recipient.listId || recipient.id || recipient.name || '');
        }

        if (kind === 'server_set') {
            return 'server_set:' + String(recipient.setId || recipient.id || recipient.name || '');
        }

        return 'contact:' + String(recipient.steamID64 || recipient.steamID || recipient.nickname || '');
    },

    cloneRecipient: function(recipient) {
        if (!recipient) {
            return null;
        }

        var kind = this.getRecipientKind(recipient);
        if (kind === 'local_list') {
            return {
                kind: 'local_list',
                key: this.getRecipientKey(recipient),
                listId: recipient.listId || recipient.id || '',
                name: recipient.name || recipient.nickname || 'Local List',
                members: Array.isArray(recipient.members) ? recipient.members.slice() : [],
                memberCount: parseInt(recipient.memberCount || (recipient.members && recipient.members.length) || 0, 10) || 0
            };
        }

        if (kind === 'server_set') {
            return {
                kind: 'server_set',
                key: this.getRecipientKey(recipient),
                setId: recipient.setId || recipient.id || '',
                name: recipient.name || recipient.nickname || 'Contact Set',
                members: Array.isArray(recipient.members) ? recipient.members.slice() : [],
                memberCount: parseInt(recipient.memberCount || (recipient.members && recipient.members.length) || 0, 10) || 0
            };
        }

        return {
            kind: 'contact',
            key: this.getRecipientKey(recipient),
            steamID: recipient.steamID || '',
            steamID64: recipient.steamID64 || '',
            nickname: recipient.nickname || recipient.steamID || recipient.steamID64 || 'Unknown Contact'
        };
    },

    cloneRecipients: function(recipients) {
        if (!Array.isArray(recipients)) {
            return [];
        }

        return recipients.map(function(recipient) {
            return this.cloneRecipient(recipient);
        }.bind(this)).filter(function(recipient) {
            return !!recipient;
        });
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
        if (instance.recipientBlurTimer) {
            clearTimeout(instance.recipientBlurTimer);
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
        this.request(windowId, 'load_drafts', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.drafts = Array.isArray(payload.drafts) ? payload.drafts : [];
            this.render(windowId);
        }.bind(this));

        this.refreshLocalContactData(windowId, { render: true });
        this.refreshContactDirectory(windowId, { render: true });
        this.showFolder(windowId, 'inbox');
    },

    refreshLocalContactData: function(windowId, options) {
        this.request(windowId, 'load_local_contact_data', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.favorites = Array.isArray(payload.favorites) ? payload.favorites : [];
            instance.localAliases = Array.isArray(payload.aliases) ? payload.aliases : [];
            instance.localLists = Array.isArray(payload.localLists) ? payload.localLists : [];

            if (!options || options.render !== false) {
                this.render(windowId);
            }
        }.bind(this));
    },

    request: function(windowId, action, payload, callback) {
        window.emailBridge.request(action, payload || {}, function(response) {
            if (callback) {
                callback(response || {});
            }
        });
    },

    refreshContactDirectory: function(windowId, options) {
        this.request(windowId, 'contact_directory', {}, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;

            instance.contacts = Array.isArray(payload.contacts) ? payload.contacts : [];
            instance.onlinePlayers = Array.isArray(payload.players) ? payload.players : [];
            instance.serverSets = Array.isArray(payload.serverSets) ? payload.serverSets : [];
            instance.adminAccess = payload.adminAccess === true;

            if (!options || options.render !== false) {
                this.render(windowId);
            }
        }.bind(this));
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

        this.render(windowId);

        if (folder === 'contacts') {
            instance.loading = false;
            instance.currentView = 'contacts';
            instance.contactsTab = 'local';
            instance.localContactsSubTab = 'favorites';
            this.refreshLocalContactData(windowId, { render: true });
            this.refreshContactDirectory(windowId, { render: true });
            this.render(windowId);
            return;
        }

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
            current.storageUsed = typeof payload.storageUsed === 'number' ? payload.storageUsed : current.storageUsed;
            current.storageLimit = typeof payload.storageLimit === 'number' ? payload.storageLimit : current.storageLimit;
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
                recipients: this.cloneRecipients(existingDraft.recipients),
                subject: existingDraft.subject || '',
                bodyMarkdown: existingDraft.bodyMarkdown || '',
                attachments: this.cloneAttachments(existingDraft.attachments),
                previewMode: false,
                dirty: false
            };
        } else {
            instance.compose = this.createEmptyComposeState();
        }

        instance.recipientQuery = '';
        instance.recipientDropdownTab = 'all';
        instance.recipientDropdownOpen = false;
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

    onComposeChanged: function(windowId, options) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        options = options || {};
        instance.compose.dirty = true;
        this.scheduleDraftSave(windowId);
        if (!options.skipRender) {
            this.render(windowId);

            if (options.refocusRecipient) {
                this.focusRecipientInput(windowId);
            }
        }
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

        this.resolveAttachmentContents(windowId, function(resolvedAttachments) {
            var current = this.getInstance(windowId);
            if (!current || current.currentView !== 'compose') {
                return;
            }

            var draftAttachments = resolvedAttachments.map(function(attachment, index) {
                var hydrated = this.cloneAttachment(attachment) || {};
                var existing = current.compose.attachments[index] || {};
                hydrated.filepath = existing.filepath || null;
                hydrated.sourcePath = existing.sourcePath || existing.filepath || '';
                return hydrated;
            }.bind(this));

            this.request(windowId, 'save_draft', {
                id: current.compose.draftId,
                recipients: current.compose.recipients,
                subject: current.compose.subject,
                bodyMarkdown: current.compose.bodyMarkdown,
                attachments: draftAttachments
            }, function(payload) {
                var latest = this.getInstance(windowId);
                if (!latest || !payload.success || !payload.draft) {
                    return;
                }

                latest.compose.draftId = payload.draft.id;
                latest.compose.attachments = this.cloneAttachments(draftAttachments);
                latest.compose.dirty = false;
                this.refreshDrafts(windowId);
            }.bind(this));
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
                if (typeof payload.unreadCount === 'number') {
                    current.unreadCount = payload.unreadCount;
                }
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
                sourcePath: item.filepath,
                filename: item.filename || item.displayName || item.name || window.getFileNameFromPath(item.filepath),
                displayName: item.filename || item.displayName || item.name || window.getFileNameFromPath(item.filepath),
                filetype: item.filetype || window.getFileTypeFromPath(item.filepath),
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
            case 'contacts': return 'Contacts';
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
        instance.compose.attachments = this.cloneAttachments(original.attachments);
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
        instance.compose.attachments = this.cloneAttachments(original.attachments);
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

    focusRecipientInput: function(windowId) {
        window.setTimeout(function() {
            var root = this.getRootElement(windowId);
            var input = root && root.querySelector('.email-to-input');
            if (!input) {
                return;
            }

            input.focus();
            var valueLength = String(input.value || '').length;
            if (input.setSelectionRange) {
                input.setSelectionRange(valueLength, valueLength);
            }
        }.bind(this), 0);
    },

    setRecipientDropdownOpen: function(windowId, isOpen) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (instance.recipientBlurTimer) {
            clearTimeout(instance.recipientBlurTimer);
            instance.recipientBlurTimer = null;
        }

        instance.recipientDropdownOpen = isOpen === true;
        this.refreshRecipientDropdown(windowId);
    },

    scheduleRecipientDropdownClose: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (instance.recipientBlurTimer) {
            clearTimeout(instance.recipientBlurTimer);
        }

        instance.recipientBlurTimer = window.setTimeout(function() {
            var current = this.getInstance(windowId);
            if (!current) {
                return;
            }

            current.recipientBlurTimer = null;
            current.recipientDropdownOpen = false;
            this.refreshRecipientDropdown(windowId);
        }.bind(this), 120);
    },

    renderRecipientDropdownContents: function(instance) {
        var options = instance.recipientDropdownOpen ? this.getRecipientOptions(instance, instance.recipientQuery) : [];
        var html = '';

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
            html = '<div class="email-recipient-empty">Type a SteamID or pick from your contacts.</div>';
        }

        return html;
    },

    refreshRecipientDropdown: function(windowId) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance || instance.currentView !== 'compose') {
            return;
        }

        var dropdown = root.querySelector('.email-recipient-dropdown');
        if (!dropdown) {
            return;
        }

        dropdown.classList.toggle('is-open', instance.recipientDropdownOpen === true);
        dropdown.innerHTML = this.renderRecipientDropdownContents(instance);
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

        instance.recipientQuery = '';
        instance.recipientDropdownOpen = true;
        this.addRecipient(windowId, selected, { refocusRecipient: true });
    },

    isLikelySteamId: function(value) {
        return /^STEAM_\d:\d:\d+$/.test(String(value || '')) || this.looksLikeSteamId64(value);
    },

    looksLikeSteamId64: function(value) {
        return /^\d{17}$/.test(String(value || ''));
    },

    addRecipient: function(windowId, contact, options) {
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

        this.onComposeChanged(windowId, options);
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
            this.refreshRecipientDropdown(windowId);
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

    getLocalAlias: function(instance, contact) {
        if (!instance || !contact) {
            return null;
        }

        var key = String(contact.steamID64 || contact.steamID || '');
        if (!key) {
            return null;
        }

        var matched = null;
        (instance.localAliases || []).some(function(alias) {
            if (String(alias.steamID64 || alias.steamID || '') === key) {
                matched = alias;
                return true;
            }
            return false;
        });

        return matched;
    },

    applyLocalAlias: function(instance, contact) {
        if (!contact) {
            return contact;
        }

        var alias = this.getLocalAlias(instance, contact);
        return {
            kind: contact.kind || 'contact',
            steamID: contact.steamID || (alias && alias.steamID) || '',
            steamID64: contact.steamID64 || (alias && alias.steamID64) || '',
            nickname: (alias && alias.nickname) || contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact'
        };
    },

    createContactRecipient: function(instance, contact) {
        return this.cloneRecipient(this.applyLocalAlias(instance, {
            kind: 'contact',
            steamID: contact.steamID || '',
            steamID64: contact.steamID64 || '',
            nickname: contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact'
        }));
    },

    createCollectionRecipient: function(kind, collection) {
        var normalizedKind = kind === 'server_set' ? 'server_set' : 'local_list';
        return this.cloneRecipient({
            kind: normalizedKind,
            id: collection.id || '',
            listId: normalizedKind === 'local_list' ? (collection.id || collection.listId || '') : '',
            setId: normalizedKind === 'server_set' ? (collection.id || collection.setId || '') : '',
            name: collection.name || collection.label || 'Collection',
            members: Array.isArray(collection.members) ? collection.members.slice() : [],
            memberCount: Array.isArray(collection.members) ? collection.members.length : (collection.memberCount || 0)
        });
    },

    isFavorite: function(instance, contact) {
        if (!contact) {
            return false;
        }

        var key = String(this.getRecipientKey(contact) || '');
        return (instance.favorites || []).some(function(favorite) {
            return String(this.getRecipientKey(favorite) || '') === key;
        }.bind(this));
    },

    isSetRecipient: function(recipient) {
        var kind = this.getRecipientKind(recipient);
        return kind === 'local_list' || kind === 'server_set';
    },

    isContactRecipient: function(recipient) {
        return this.getRecipientKind(recipient) === 'contact';
    },

    getFavoriteCollections: function(instance) {
        return this.getCollectionOptions(instance).filter(function(recipient) {
            return this.isFavorite(instance, recipient);
        });
    },

    getContactOptions: function(instance) {
        var merged = {};
        var ordered = [];

        var ingest = function(contact) {
            if (!contact) return;
            var key = String(contact.steamID64 || contact.steamID || '').toLowerCase();
            if (!key) return;

            var next = this.applyLocalAlias(instance, {
                kind: 'contact',
                steamID: contact.steamID || '',
                steamID64: contact.steamID64 || '',
                nickname: contact.nickname || contact.steamID || contact.steamID64 || 'Unknown Contact'
            });

            if (!merged[key]) {
                merged[key] = next;
                ordered.push(merged[key]);
                return;
            }

            if ((!merged[key].nickname || merged[key].nickname === merged[key].steamID || merged[key].nickname === merged[key].steamID64) && next.nickname) {
                merged[key].nickname = next.nickname;
            }
        }.bind(this);

        (instance.favorites || []).forEach(ingest);
        (instance.onlinePlayers || []).forEach(ingest);
        (instance.contacts || []).forEach(ingest);
        (instance.localAliases || []).forEach(ingest);

        ordered.sort(function(a, b) {
            var scoreA = this.isFavorite(instance, a) ? 0 : ((instance.onlinePlayers || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(a.steamID64 || a.steamID || '');
            }) ? 1 : 2);

            var scoreB = this.isFavorite(instance, b) ? 0 : ((instance.onlinePlayers || []).some(function(contact) {
                return String(contact.steamID64 || contact.steamID || '') === String(b.steamID64 || b.steamID || '');
            }) ? 1 : 2);

            if (scoreA !== scoreB) {
                return scoreA - scoreB;
            }

            return String(a.nickname || '').localeCompare(String(b.nickname || ''));
        }.bind(this));

        return ordered;
    },

    getCollectionOptions: function(instance) {
        var localOptions = (instance.localLists || []).map(function(collection) {
            return this.createCollectionRecipient('local_list', collection);
        }.bind(this));

        var serverOptions = (instance.serverSets || []).map(function(collection) {
            return this.createCollectionRecipient('server_set', collection);
        }.bind(this));

        return localOptions.concat(serverOptions);
    },

    getRecipientDisplayLabel: function(instance, recipient) {
        var kind = this.getRecipientKind(recipient);
        if (kind === 'local_list' || kind === 'server_set') {
            return recipient.name || recipient.nickname || 'Collection';
        }

        var aliased = this.applyLocalAlias(instance, recipient);
        return aliased.nickname || aliased.steamID || aliased.steamID64 || 'Unknown Contact';
    },

    getRecipientOptionMeta: function(instance, recipient) {
        var kind = this.getRecipientKind(recipient);
        if (kind === 'local_list' || kind === 'server_set') {
            var memberCount = parseInt(recipient.memberCount || (recipient.members && recipient.members.length) || 0, 10) || 0;
            var collectionMeta = [];
            if (this.isFavorite(instance, recipient)) {
                collectionMeta.push('Favorite');
            }
            collectionMeta.push((kind === 'local_list' ? 'Local list' : 'Admin set') + ' • ' + memberCount + ' member(s)');
            return collectionMeta.join(' • ');
        }

        var meta = [];
        if (this.isFavorite(instance, recipient)) {
            meta.push('Favorite');
        }

        var alias = this.getLocalAlias(instance, recipient);
        if (alias && alias.nickname && alias.nickname !== recipient.nickname) {
            meta.push('Nickname');
        }

        meta.push(recipient.steamID || recipient.steamID64 || 'Unknown');
        return meta.join(' • ');
    },

    getRecipientDropdownTab: function(instance) {
        var tab = String(instance && instance.recipientDropdownTab || 'all');
        if (tab === 'favorites' || tab === 'players' || tab === 'sets') {
            return tab;
        }
        return 'all';
    },

    setRecipientDropdownTab: function(windowId, tab) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.recipientDropdownTab = this.getRecipientDropdownTab({ recipientDropdownTab: tab });
        instance.recipientDropdownOpen = true;
        this.refreshRecipientDropdown(windowId);
        this.focusRecipientInput(windowId);
    },

    renderRecipientDropdownContents: function(instance) {
        var activeTab = this.getRecipientDropdownTab(instance);
        var options = instance.recipientDropdownOpen ? this.getRecipientOptions(instance, instance.recipientQuery, activeTab) : [];
        var html = '<div class="email-recipient-dropdown-tabs">' +
            '<button class="email-recipient-dropdown-tab ' + (activeTab === 'all' ? 'active' : '') + '" data-recipient-tab="all">All</button>' +
            '<button class="email-recipient-dropdown-tab ' + (activeTab === 'favorites' ? 'active' : '') + '" data-recipient-tab="favorites">Favorites</button>' +
            '<button class="email-recipient-dropdown-tab ' + (activeTab === 'players' ? 'active' : '') + '" data-recipient-tab="players">Players</button>' +
            '<button class="email-recipient-dropdown-tab ' + (activeTab === 'sets' ? 'active' : '') + '" data-recipient-tab="sets">Sets</button>' +
        '</div>';

        if (options.length) {
            html += '<div class="email-recipient-dropdown-list">';
            options.forEach(function(option) {
                var kind = this.getRecipientKind(option);
                var favorite = this.isFavorite(instance, option);
                html += '<div class="email-recipient-option email-recipient-option-' + this.escapeHtml(kind) + '" data-recipient-key="' + this.escapeHtml(this.getRecipientKey(option)) + '">' +
                    '<button class="email-favorite-toggle' + (favorite ? ' is-active' : '') + '" data-favorite-key="' + this.escapeHtml(this.getRecipientKey(option)) + '" aria-label="' + this.escapeHtml(favorite ? 'Remove favorite' : 'Add favorite') + '">' + (favorite ? '★' : '☆') + '</button>' +
                    '<div class="email-recipient-option-main">' +
                        '<div class="email-recipient-option-name">' + this.escapeHtml(this.getRecipientDisplayLabel(instance, option)) + '</div>' +
                        '<div class="email-recipient-option-meta">' + this.escapeHtml(this.getRecipientOptionMeta(instance, option)) + '</div>' +
                    '</div>' +
                    (kind === 'contact'
                        ? '<div class="email-recipient-type-pill email-recipient-type-pill-contact">Player</div>'
                        : '<div class="email-recipient-type-pill email-recipient-type-pill-' + this.escapeHtml(kind) + '">' + this.escapeHtml(kind === 'local_list' ? 'List' : 'Set') + '</div>') +
                '</div>';
            }.bind(this));
            html += '</div>';
        } else {
            html += '<div class="email-recipient-empty">Type a SteamID, contact name, list name, or set name.</div>';
        }

        return html;
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

        var options = this.getRecipientOptions(instance, value, this.getRecipientDropdownTab(instance));
        var selected = null;

        for (var i = 0; i < options.length; i++) {
            var option = options[i];
            if (String(this.getRecipientDisplayLabel(instance, option) || '').toLowerCase() === value.toLowerCase() ||
                String(option.steamID64 || '').toLowerCase() === value.toLowerCase() ||
                String(option.steamID || '').toLowerCase() === value.toLowerCase()) {
                selected = option;
                break;
            }
        }

        if (!selected && options.length > 0) {
            selected = options[0];
        }

        if (!selected && this.isLikelySteamId(value)) {
            selected = this.createContactRecipient(instance, {
                steamID: this.looksLikeSteamId64(value) ? '' : value,
                steamID64: this.looksLikeSteamId64(value) ? value : '',
                nickname: value
            });
        }

        if (!selected) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Enter a valid SteamID or pick a contact, list, or set.', 'warning', 2200);
            }
            return;
        }

        instance.recipientQuery = '';
        instance.recipientDropdownOpen = true;
        this.addRecipient(windowId, selected, { refocusRecipient: true });
    },

    addRecipient: function(windowId, contact, options) {
        var instance = this.getInstance(windowId);
        if (!instance || !contact) {
            return;
        }

        var recipient = this.cloneRecipient(contact);
        var key = String(this.getRecipientKey(recipient) || '').toLowerCase();
        if (!key) {
            return;
        }

        var exists = instance.compose.recipients.some(function(existing) {
            return String(this.getRecipientKey(existing) || '').toLowerCase() === key;
        }.bind(this));

        if (exists) {
            return;
        }

        if (this.getRecipientKind(recipient) !== 'contact' &&
            (!Array.isArray(recipient.members) || recipient.members.length <= 0)) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('This recipient has no members to email.', 'warning', 2200);
            }
            return;
        }

        instance.compose.recipients.push(recipient);
        this.onComposeChanged(windowId, options);
    },

    removeRecipient: function(windowId, key) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.compose.recipients = instance.compose.recipients.filter(function(contact) {
            return String(this.getRecipientKey(contact) || '') !== String(key || '');
        }.bind(this));

        this.onComposeChanged(windowId);
    },

    toggleFavorite: function(windowId, contact) {
        var instance = this.getInstance(windowId);
        if (!instance || !contact) {
            return;
        }

        this.request(windowId, 'set_favorite', {
            contact: contact,
            favorite: !this.isFavorite(instance, contact)
        }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.favorites = Array.isArray(payload.favorites) ? payload.favorites : [];
            this.refreshRecipientDropdown(windowId);
            if (current.currentView === 'contacts') {
                this.render(windowId);
            }
        }.bind(this));
    },

    getRecipientOptions: function(instance, query, tabOverride) {
        var normalizedQuery = String(query || '').toLowerCase().trim();
        var activeTab = tabOverride || this.getRecipientDropdownTab(instance);
        var options = this.getContactOptions(instance).concat(this.getCollectionOptions(instance));

        options = options.filter(function(option) {
            var kind = this.getRecipientKind(option);
            if (activeTab === 'favorites') {
                return this.isFavorite(instance, option);
            }
            if (activeTab === 'players') {
                return kind === 'contact';
            }
            if (activeTab === 'sets') {
                return kind === 'local_list' || kind === 'server_set';
            }
            return true;
        }.bind(this));

        if (normalizedQuery) {
            options = options.filter(function(option) {
                if (this.getRecipientKind(option) === 'contact') {
                    return String(this.getRecipientDisplayLabel(instance, option) || '').toLowerCase().indexOf(normalizedQuery) !== -1 ||
                        String(option.steamID || '').toLowerCase().indexOf(normalizedQuery) !== -1 ||
                        String(option.steamID64 || '').toLowerCase().indexOf(normalizedQuery) !== -1;
                }

                return String(option.name || '').toLowerCase().indexOf(normalizedQuery) !== -1;
            }.bind(this));
        }

        options.sort(function(a, b) {
            var favoriteA = this.isFavorite(instance, a) ? 0 : 1;
            var favoriteB = this.isFavorite(instance, b) ? 0 : 1;
            if (favoriteA !== favoriteB) {
                return favoriteA - favoriteB;
            }

            var kindOrder = {
                contact: 0,
                local_list: 1,
                server_set: 2
            };
            var kindA = kindOrder[this.getRecipientKind(a)] || 0;
            var kindB = kindOrder[this.getRecipientKind(b)] || 0;
            if (kindA !== kindB) {
                return kindA - kindB;
            }

            return String(this.getRecipientDisplayLabel(instance, a) || '').localeCompare(String(this.getRecipientDisplayLabel(instance, b) || ''));
        }.bind(this));

        return options.slice(0, 30);
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

    resolveRecipientContact: function(instance, steamID64) {
        if (!steamID64) {
            return null;
        }

        var resolved = null;
        this.getContactOptions(instance).some(function(contact) {
            if (String(contact.steamID64 || '') === String(steamID64 || '') ||
                String(contact.steamID || '') === String(steamID64 || '')) {
                resolved = this.createContactRecipient(instance, contact);
                return true;
            }
            return false;
        }.bind(this));

        if (resolved) {
            return resolved;
        }

        return this.createContactRecipient(instance, {
            steamID: this.looksLikeSteamId64(steamID64) ? '' : String(steamID64 || ''),
            steamID64: this.looksLikeSteamId64(steamID64) ? String(steamID64 || '') : '',
            nickname: String(steamID64 || '')
        });
    },

    getExpandedRecipientMembers: function(instance, recipient) {
        var kind = this.getRecipientKind(recipient);
        if (kind === 'contact') {
            return [this.createContactRecipient(instance, recipient)];
        }

        return (recipient.members || []).map(function(steamID64) {
            return this.resolveRecipientContact(instance, steamID64);
        }.bind(this)).filter(function(contact) {
            return !!contact;
        });
    },

    expandComposeRecipients: function(instance) {
        var expanded = [];
        var seen = {};

        (instance.compose.recipients || []).forEach(function(recipient) {
            this.getExpandedRecipientMembers(instance, recipient).forEach(function(contact) {
                var key = String(contact.steamID64 || contact.steamID || '').toLowerCase();
                if (!key || seen[key]) {
                    return;
                }

                seen[key] = true;
                expanded.push({
                    steamID: contact.steamID || '',
                    steamID64: contact.steamID64 || '',
                    nickname: this.getRecipientDisplayLabel(instance, contact)
                });
            }.bind(this));
        }.bind(this));

        return expanded;
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

        var expandedRecipients = this.expandComposeRecipients(instance);
        if (!expandedRecipients.length) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('No valid recipients could be resolved from the selected contacts, lists, or sets.', 'warning', 2600);
            }
            return;
        }

        this.resolveAttachmentContents(windowId, function(resolvedAttachments) {
            var current = this.getInstance(windowId);
            if (!current) return;

            current.loading = true;
            this.render(windowId);

            this.request(windowId, 'send_email', {
                recipients: expandedRecipients,
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
                    this.refreshContactDirectory(windowId, { render: false });

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
                    displayName: attachment.filename || attachment.displayName,
                    filename: attachment.filename || attachment.displayName,
                    filetype: attachment.filetype,
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
                if (content === null || content === undefined) {
                    if (window.osErrorHandler) {
                        window.osErrorHandler.showNotification('Failed to read attachment: ' + (attachment.displayName || attachment.filepath), 'warning', 2400);
                    }
                    finalize('');
                    return;
                }

                attachment.content = content;
                finalize(attachment.content);
            });
        });
    },

    toggleComposePreview: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var composeBody = root.querySelector('.email-compose-body');
        var scrollTop = composeBody ? composeBody.scrollTop : 0;
        instance.compose.previewMode = !instance.compose.previewMode;
        this.render(windowId);

        window.setTimeout(function() {
            var refreshedRoot = this.getRootElement(windowId);
            var refreshedBody = refreshedRoot && refreshedRoot.querySelector('.email-compose-body');
            if (refreshedBody) {
                refreshedBody.scrollTop = scrollTop;
            }
        }.bind(this), 0);
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
        this.onComposeChanged(windowId, { skipRender: true });
    },

    render: function(windowId) {
        var instance = this.getInstance(windowId);
        var viewRoot = this.getViewRoot(windowId);
        if (!instance || !viewRoot) {
            return;
        }

        this.updateSidebarState(windowId);
        this.updateSidebarMeta(windowId);

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

    getSelfProfile: function(instance) {
        var selfProfile = null;
        (instance.onlinePlayers || []).some(function(playerInfo) {
            if (playerInfo && playerInfo.isSelf) {
                selfProfile = playerInfo;
                return true;
            }
            return false;
        });

        return selfProfile || {
            nickname: 'Local User',
            steamID64: '',
            steamID: ''
        };
    },

    getInitials: function(label) {
        var words = String(label || '').trim().split(/\s+/).filter(Boolean);
        if (!words.length) {
            return 'U';
        }

        if (words.length === 1) {
            return words[0].slice(0, 2).toUpperCase();
        }

        return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
    },

    updateSidebarMeta: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var storageNode = root.querySelector('.email-storage-widget');
        if (storageNode) {
            var used = Math.max(0, parseInt(instance.storageUsed || 0, 10) || 0);
            var limit = Math.max(1, parseInt(instance.storageLimit || 0, 10) || 1);
            var usagePercent = Math.min(100, Math.max(0, (used / limit) * 100));

            storageNode.innerHTML = '' +
                '<div class="email-storage-inline">' +
                    '<div class="email-sidebar-card-label">Mailbox Storage</div>' +
                    '<div class="email-storage-count">' + this.escapeHtml(String(used)) + ' / ' + this.escapeHtml(String(limit)) + '</div>' +
                    '<div class="email-storage-bar"><span style="width: ' + usagePercent.toFixed(2) + '%;"></span></div>' +
                '</div>';
        }

        var userNode = root.querySelector('.email-user-widget');
        if (userNode) {
            var selfProfile = this.getSelfProfile(instance);
            var displayName = selfProfile.nickname || selfProfile.steamID || selfProfile.steamID64 || 'Local User';
            var subtitle = selfProfile.steamID || selfProfile.steamID64 || 'Offline Profile';

            userNode.innerHTML = '' +
                '<div class="email-sidebar-card email-user-card">' +
                    '<div class="email-user-name">' + this.escapeHtml(displayName) + '</div>' +
                    '<div class="email-user-subtitle">' + this.escapeHtml(subtitle) + '</div>' +
                '</div>';
        }
    },

    updateSidebarState: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var composeBtn = root.querySelector('.email-compose-btn');
        if (composeBtn) {
            composeBtn.classList.toggle('active', instance.currentView === 'compose');
        }

        root.querySelectorAll('.email-folder').forEach(function(button) {
            var isActive = instance.currentView !== 'compose' && button.getAttribute('data-folder') === instance.currentFolder;
            button.classList.toggle('active', isActive);
        });

        var inboxButton = root.querySelector('.email-folder[data-folder="inbox"]');
        if (inboxButton) {
            var badge = inboxButton.querySelector('.email-folder-badge');
            if (badge) {
                var unread = Math.max(0, parseInt(instance.unreadCount || 0, 10) || 0);
                badge.textContent = String(unread);
                badge.style.display = unread > 0 ? 'inline-block' : 'none';
            }
        }
    },

    isOnlineContact: function(instance, contact) {
        return (instance.onlinePlayers || []).some(function(playerInfo) {
            return String(playerInfo.steamID64 || playerInfo.steamID || '') === String(contact && (contact.steamID64 || contact.steamID) || '');
        });
    },

    getCollectionEditorByKind: function(instance, kind) {
        return kind === 'server_set' ? instance.serverSetEditor : instance.localListEditor;
    },

    getCollectionsByKind: function(instance, kind) {
        return kind === 'server_set' ? (instance.serverSets || []) : (instance.localLists || []);
    },

    renderContactBadges: function(instance, contact) {
        var badges = [];
        if (this.isFavorite(instance, contact)) {
            badges.push('<span class="email-contact-badge is-favorite">Favorite</span>');
        }
        if (this.isOnlineContact(instance, contact)) {
            badges.push('<span class="email-contact-badge is-online">Online</span>');
        }
        if (this.getLocalAlias(instance, contact)) {
            badges.push('<span class="email-contact-badge is-alias">Nickname</span>');
        }
        return badges.join('');
    },

    getLocalContactsSubTab: function(instance) {
        return instance && instance.localContactsSubTab === 'local_lists' ? 'local_lists' : 'favorites';
    },

    getFavoriteContacts: function(instance) {
        return this.getContactOptions(instance).filter(function(contact) {
            return this.isFavorite(instance, contact);
        }.bind(this));
    },

    getNonFavoriteContacts: function(instance) {
        return this.getContactOptions(instance).filter(function(contact) {
            return !this.isFavorite(instance, contact);
        }.bind(this));
    },

    isFavoriteInlineEditing: function(instance, contactKey) {
        return !!instance && String(instance.favoriteInlineEditKey || '') === String(contactKey || '');
    },

    renderContactsStats: function(stats) {
        var html = '<div class="email-contacts-stats">';
        (stats || []).forEach(function(stat) {
            html += '<div class="email-contacts-stat">' +
                '<div class="email-contacts-stat-value">' + this.escapeHtml(String(stat.value || 0)) + '</div>' +
                '<div class="email-contacts-stat-label">' + this.escapeHtml(stat.label || '') + '</div>' +
            '</div>';
        }.bind(this));
        html += '</div>';
        return html;
    },

    renderFavoriteBadges: function(instance, contact) {
        var badges = [];
        if (this.isOnlineContact(instance, contact)) {
            badges.push('<span class="email-contact-badge is-online">Online</span>');
        }
        if (this.getLocalAlias(instance, contact)) {
            badges.push('<span class="email-contact-badge is-alias">Nickname</span>');
        }
        return badges.join('');
    },

    renderContactDirectory: function(instance, contacts, options) {
        options = options || {};
        if (!contacts.length) {
            return '<div class="email-empty-state compact"><div class="email-empty-title">' + this.escapeHtml(options.emptyTitle || 'No contacts yet') + '</div><div class="email-empty-text">' + this.escapeHtml(options.emptyText || 'Contacts will appear here as they become available.') + '</div></div>';
        }

        var html = '<div class="email-contact-directory' + (options.compact ? ' compact' : '') + '">';
        contacts.forEach(function(contact) {
            var contactKey = String(contact.steamID64 || contact.steamID || '');
            var alias = this.getLocalAlias(instance, contact);
            html += '<div class="email-contact-row">' +
                '<div class="email-contact-row-main">' +
                    '<div class="email-contact-row-name">' + this.escapeHtml(this.getRecipientDisplayLabel(instance, contact)) + '</div>' +
                    '<div class="email-contact-row-meta">' + this.escapeHtml(contact.steamID || contact.steamID64 || '') + '</div>' +
                    '<div class="email-contact-row-badges">' + this.renderContactBadges(instance, contact) + '</div>' +
                '</div>' +
                '<div class="email-contact-row-actions">' +
                    '<input type="text" class="email-input email-contact-alias-input" data-contact-key="' + this.escapeHtml(contactKey) + '" value="' + this.escapeHtml((alias && alias.nickname) || '') + '" placeholder="Nickname" />' +
                    '<button class="email-toolbar-btn email-save-alias-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">Save Nickname</button>' +
                    '<button class="email-toolbar-btn email-toggle-favorite-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">' + this.escapeHtml(this.isFavorite(instance, contact) ? '★ Remove Favorite' : '☆ Favorite') + '</button>' +
                    '<button class="email-toolbar-btn email-compose-contact-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">Insert</button>' +
                '</div>' +
            '</div>';
        }.bind(this));
        html += '</div>';
        return html;
    },

    renderCompactFavoriteDirectory: function(instance, contacts) {
        if (!contacts.length) {
            return '<div class="email-empty-state compact"><div class="email-empty-title">No favorites yet</div><div class="email-empty-text">Mark players as favorites or add one manually to keep them here.</div></div>';
        }

        var html = '<div class="email-favorite-directory">';
        contacts.forEach(function(contact) {
            var contactKey = String(contact.steamID64 || contact.steamID || '');
            var alias = this.getLocalAlias(instance, contact);
            var isEditing = this.isFavoriteInlineEditing(instance, contactKey);
            var badges = this.renderFavoriteBadges(instance, contact);
            html += '<div class="email-favorite-row">' +
                '<div class="email-favorite-row-top">' +
                    '<div class="email-favorite-row-main">' +
                        '<div class="email-favorite-row-icon" aria-hidden="true">★</div>' +
                        '<div class="email-favorite-row-copy">' +
                            '<div class="email-favorite-row-name">' + this.escapeHtml(this.getRecipientDisplayLabel(instance, contact)) + '</div>' +
                            '<div class="email-favorite-row-meta">' + this.escapeHtml(contact.steamID || contact.steamID64 || '') + '</div>' +
                            (badges ? '<div class="email-contact-row-badges compact">' + badges + '</div>' : '') +
                        '</div>' +
                    '</div>' +
                    '<div class="email-favorite-row-actions">' +
                        '<button class="email-toolbar-btn email-favorite-edit-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">' + (isEditing ? 'Editing' : 'Edit') + '</button>' +
                        '<button class="email-toolbar-btn email-compose-contact-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">Insert</button>' +
                        '<button class="email-toolbar-btn email-toggle-favorite-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">★ Remove</button>' +
                    '</div>' +
                '</div>' +
                (isEditing
                    ? '<div class="email-favorite-inline-editor">' +
                        '<input type="text" class="email-input email-favorite-edit-input" data-contact-key="' + this.escapeHtml(contactKey) + '" value="' + this.escapeHtml(instance.favoriteInlineEditValue || (alias && alias.nickname) || '') + '" placeholder="Nickname" />' +
                        '<button class="email-toolbar-btn email-favorite-save-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">Save</button>' +
                        '<button class="email-toolbar-btn email-favorite-cancel-btn" data-contact-key="' + this.escapeHtml(contactKey) + '">Cancel</button>' +
                    '</div>'
                    : '') +
            '</div>';
        }.bind(this));
        html += '</div>';
        return html;
    },

    renderEditorMembers: function(instance, editor) {
        var html = '';
        (editor.members || []).forEach(function(steamID64) {
            var contact = this.resolveRecipientContact(instance, steamID64);
            html += '<div class="email-editor-member-chip">' +
                '<span>' + this.escapeHtml(this.getRecipientDisplayLabel(instance, contact)) + '</span>' +
                '<button class="email-editor-member-remove" data-editor-kind="' + this.escapeHtml(editor.kind) + '" data-member-id="' + this.escapeHtml(String(steamID64)) + '">x</button>' +
            '</div>';
        }.bind(this));

        return html || '<div class="email-contacts-empty-inline">No members selected yet.</div>';
    },

    renderCollectionEditor: function(instance, kind) {
        var editor = this.getCollectionEditorByKind(instance, kind);
        var contacts = this.getContactOptions(instance);
        var title = kind === 'server_set'
            ? (editor.id ? 'Edit Contact Set' : 'Create Contact Set')
            : (editor.id ? 'Edit Local List' : 'Create Local List');
        var saveLabel = kind === 'server_set' ? 'Save Set' : 'Save List';

        var html = '' +
            '<div class="email-contacts-card">' +
                '<div class="email-contacts-card-header">' +
                    '<div class="email-contacts-card-title">' + this.escapeHtml(title) + '</div>' +
                    '<div class="email-contacts-card-subtitle">' + this.escapeHtml((editor.members || []).length + ' member(s) selected') + '</div>' +
                '</div>' +
                '<label class="email-field">' +
                    '<span>Name</span>' +
                    '<input type="text" class="email-input email-collection-name-input" data-editor-kind="' + this.escapeHtml(kind) + '" value="' + this.escapeHtml(editor.name || '') + '" placeholder="' + this.escapeHtml(kind === 'server_set' ? 'Command Staff' : 'Squad Alpha') + '" />' +
                '</label>' +
                '<div class="email-field">' +
                    '<span>Add Member By SteamID / SteamID64</span>' +
                    '<div class="email-inline-form">' +
                        '<input type="text" class="email-input email-collection-manual-input" data-editor-kind="' + this.escapeHtml(kind) + '" value="' + this.escapeHtml(editor.manualMemberInput || '') + '" placeholder="STEAM_0:1:1234 or 7656..." />' +
                        '<button class="email-toolbar-btn email-collection-manual-add-btn" data-editor-kind="' + this.escapeHtml(kind) + '">Add</button>' +
                    '</div>' +
                '</div>' +
                '<div class="email-field">' +
                    '<span>Selected Members</span>' +
                    '<div class="email-editor-member-list">' + this.renderEditorMembers(instance, editor) + '</div>' +
                '</div>' +
                '<div class="email-field">' +
                    '<span>Available Contacts</span>' +
                    '<div class="email-collection-contact-picker">';

        contacts.forEach(function(contact) {
            var key = String(contact.steamID64 || contact.steamID || '');
            var checked = (editor.members || []).indexOf(key) !== -1;
            html += '<label class="email-collection-contact-option">' +
                '<input type="checkbox" class="email-collection-member-toggle" data-editor-kind="' + this.escapeHtml(kind) + '" data-member-id="' + this.escapeHtml(key) + '" ' + (checked ? 'checked' : '') + ' />' +
                '<span class="email-collection-contact-main">' +
                    '<span class="email-collection-contact-name">' + this.escapeHtml(this.getRecipientDisplayLabel(instance, contact)) + '</span>' +
                    '<span class="email-collection-contact-meta">' + this.escapeHtml(contact.steamID || contact.steamID64 || '') + '</span>' +
                '</span>' +
            '</label>';
        }.bind(this));

        html += '</div></div>' +
                '<div class="email-contacts-card-actions">' +
                    '<button class="email-toolbar-btn email-save-collection-btn" data-editor-kind="' + this.escapeHtml(kind) + '">' + this.escapeHtml(saveLabel) + '</button>' +
                    '<button class="email-toolbar-btn email-clear-collection-btn" data-editor-kind="' + this.escapeHtml(kind) + '">Clear</button>' +
                '</div>' +
            '</div>';

        return html;
    },

    renderCollectionCards: function(instance, kind) {
        var collections = this.getCollectionsByKind(instance, kind);
        if (!collections.length) {
            return '<div class="email-empty-state compact"><div class="email-empty-title">No ' + this.escapeHtml(kind === 'server_set' ? 'contact sets' : 'local lists') + '</div><div class="email-empty-text">Create one to insert it into the recipient box as a single entry.</div></div>';
        }

        var html = '<div class="email-collection-grid">';
        collections.forEach(function(collection) {
            var recipient = this.createCollectionRecipient(kind, collection);
            var memberSummary = (collection.members || []).slice(0, 4).map(function(steamID64) {
                return this.getRecipientDisplayLabel(instance, this.resolveRecipientContact(instance, steamID64));
            }.bind(this)).join(', ');

            html += '<div class="email-contacts-card">' +
                '<div class="email-contacts-card-header">' +
                    '<div class="email-contacts-card-title">' + this.escapeHtml(collection.name || 'Collection') + '</div>' +
                    '<div class="email-contacts-card-subtitle">' + this.escapeHtml((collection.members || []).length + ' member(s)') + '</div>' +
                '</div>' +
                '<div class="email-collection-card-preview">' + this.escapeHtml(memberSummary || 'No members yet.') + '</div>' +
                '<div class="email-contacts-card-actions">' +
                    '<button class="email-toolbar-btn email-compose-collection-btn" data-collection-kind="' + this.escapeHtml(kind) + '" data-collection-id="' + this.escapeHtml(collection.id) + '">Insert</button>' +
                    '<button class="email-toolbar-btn email-edit-collection-btn" data-collection-kind="' + this.escapeHtml(kind) + '" data-collection-id="' + this.escapeHtml(collection.id) + '">Edit</button>' +
                    '<button class="email-toolbar-btn email-delete-collection-btn" data-collection-kind="' + this.escapeHtml(kind) + '" data-collection-id="' + this.escapeHtml(collection.id) + '">Delete</button>' +
                '</div>' +
            '</div>';
        }.bind(this));
        html += '</div>';
        return html;
    },

    renderLocalFavoritesView: function(instance) {
        var favorites = this.getFavoriteContacts(instance);
        var otherContacts = this.getNonFavoriteContacts(instance);

        return '' +
            '<div class="email-contacts-section-grid email-contacts-section-grid-wide">' +
                '<div class="email-contacts-column email-contacts-column-wide">' +
                    '<div class="email-contacts-card email-contacts-card-highlight">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">Favorites</div>' +
                            '<div class="email-contacts-card-subtitle">Your pinned contacts stay at the top and are the quickest way to start a message.</div>' +
                        '</div>' +
                        this.renderContactsStats([
                            { label: 'Favorites', value: favorites.length },
                            { label: 'Known Contacts', value: (favorites.length + otherContacts.length) },
                            { label: 'Online Now', value: (instance.onlinePlayers || []).length }
                        ]) +
                        this.renderCompactFavoriteDirectory(instance, favorites) +
                    '</div>' +
                '</div>' +
                '<div class="email-contacts-column">' +
                    '<div class="email-contacts-card">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">Add Favorite</div>' +
                            '<div class="email-contacts-card-subtitle">Store a SteamID with an optional nickname for this computer.</div>' +
                        '</div>' +
                        '<div class="email-inline-form stacked">' +
                            '<input type="text" class="email-input email-manual-favorite-id" value="' + this.escapeHtml(instance.localContactDraft.steamIdInput || '') + '" placeholder="STEAM_0:1:1234 or 7656..." />' +
                            '<input type="text" class="email-input email-manual-favorite-nickname" value="' + this.escapeHtml(instance.localContactDraft.nickname || '') + '" placeholder="Optional nickname" />' +
                            '<button class="email-toolbar-btn email-manual-favorite-add-btn">Add Favorite</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="email-contacts-card">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">All Players & Contacts</div>' +
                            '<div class="email-contacts-card-subtitle">Everyone available to favorite, nickname, or insert into compose.</div>' +
                        '</div>' +
                        this.renderContactDirectory(instance, otherContacts, {
                            compact: true,
                            emptyTitle: 'No more contacts',
                            emptyText: 'All known contacts are already favorited.'
                        }) +
                    '</div>' +
                '</div>' +
            '</div>';
    },

    renderLocalListsView: function(instance) {
        return '' +
            '<div class="email-contacts-section-grid email-contacts-section-grid-wide">' +
                '<div class="email-contacts-column email-contacts-column-wide">' +
                    '<div class="email-contacts-card email-contacts-card-highlight">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">Local Lists</div>' +
                            '<div class="email-contacts-card-subtitle">Your private contact shortcuts on this computer. Insert them as one recipient badge and expand them when sending.</div>' +
                        '</div>' +
                        this.renderContactsStats([
                            { label: 'Local Lists', value: (instance.localLists || []).length },
                            { label: 'Known Contacts', value: this.getContactOptions(instance).length },
                            { label: 'Favorites', value: this.getFavoriteContacts(instance).length }
                        ]) +
                        this.renderCollectionCards(instance, 'local_list') +
                    '</div>' +
                '</div>' +
                '<div class="email-contacts-column">' +
                    this.renderCollectionEditor(instance, 'local_list') +
                '</div>' +
            '</div>';
    },

    renderAdminContactsView: function(instance) {
        if (!instance.adminAccess) {
            return '<div class="email-contacts-card email-contacts-card-highlight"><div class="email-empty-state"><div class="email-empty-title">Admin Access Required</div><div class="email-empty-text">You need the ' + this.escapeHtml('HALOARMORY.Email Contact Sets') + ' permission to manage server contact sets.</div></div></div>';
        }

        return '' +
            '<div class="email-contacts-section-grid email-contacts-section-grid-wide">' +
                '<div class="email-contacts-column email-contacts-column-wide">' +
                    '<div class="email-contacts-card email-contacts-card-highlight">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">Server Contact Sets</div>' +
                            '<div class="email-contacts-card-subtitle">Shared recipient shortcuts for the whole server. Everyone can use them in compose, admins manage the membership.</div>' +
                        '</div>' +
                        this.renderContactsStats([
                            { label: 'Server Sets', value: (instance.serverSets || []).length },
                            { label: 'Known Contacts', value: this.getContactOptions(instance).length },
                            { label: 'Online Now', value: (instance.onlinePlayers || []).length }
                        ]) +
                        this.renderCollectionCards(instance, 'server_set') +
                    '</div>' +
                '</div>' +
                '<div class="email-contacts-column">' +
                    '<div class="email-contacts-card email-contacts-card-muted">' +
                        '<div class="email-contacts-card-header">' +
                            '<div class="email-contacts-card-title">How Server Sets Work</div>' +
                            '<div class="email-contacts-card-subtitle">Keep shared recipient groups consistent for everyone using the terminal.</div>' +
                        '</div>' +
                        '<div class="email-contacts-help-copy">Use sets for departments, squads, or command chains. Each set stores SteamIDs only, then expands into the real recipients when someone sends an email.</div>' +
                    '</div>' +
                    this.renderCollectionEditor(instance, 'server_set') +
                '</div>' +
            '</div>';
    },

    renderContactsView: function(instance) {
        var contacts = this.getContactOptions(instance);
        var activeTab = instance.contactsTab === 'admin' ? 'admin' : 'local';
        var localSubTab = this.getLocalContactsSubTab(instance);
        var html = '' +
            '<div class="email-panel email-contacts-panel">' +
                '<div class="email-toolbar">' +
                    '<div class="email-toolbar-title-wrap">' +
                        '<div class="email-toolbar-title">Contacts</div>' +
                        '<div class="email-toolbar-subtitle">' + this.escapeHtml(String(contacts.length)) + ' contact(s) available</div>' +
                    '</div>' +
                    '<div class="email-toolbar-actions">' +
                        '<button class="email-toolbar-btn email-refresh-contacts-btn">Refresh</button>' +
                    '</div>' +
                '</div>' +
                '<div class="email-contacts-shell">' +
                    '<div class="email-contacts-tabs">' +
                        '<button class="email-contacts-tab ' + (activeTab === 'local' ? 'active' : '') + '" data-contacts-tab="local">Local</button>' +
                        '<button class="email-contacts-tab ' + (activeTab === 'admin' ? 'active' : '') + '" data-contacts-tab="admin">Admin</button>' +
                    '</div>' +
                    (activeTab === 'local'
                        ? '<div class="email-contacts-subtabs">' +
                            '<button class="email-contacts-subtab ' + (localSubTab === 'favorites' ? 'active' : '') + '" data-local-contacts-tab="favorites">Favorites</button>' +
                            '<button class="email-contacts-subtab ' + (localSubTab === 'local_lists' ? 'active' : '') + '" data-local-contacts-tab="local_lists">Local Lists</button>' +
                        '</div>'
                        : '') +
                '</div>' +
                '<div class="email-contacts-body">' +
                    '<div class="email-contacts-page-intro">' + this.escapeHtml(activeTab === 'admin'
                        ? 'Shared recipient shortcuts managed per server.'
                        : (localSubTab === 'local_lists'
                            ? 'Your private contact shortcuts and recipient groups for this computer.'
                            : 'Your pinned contacts and local nicknames, with favorites front and center.')) + '</div>' +
                    (activeTab === 'local'
                        ? (localSubTab === 'local_lists'
                            ? this.renderLocalListsView(instance)
                            : this.renderLocalFavoritesView(instance))
                        : this.renderAdminContactsView(instance)) +
                '</div>' +
            '</div>';
        return html;
    },

    render: function(windowId) {
        var instance = this.getInstance(windowId);
        var viewRoot = this.getViewRoot(windowId);
        if (!instance || !viewRoot) {
            return;
        }

        this.updateSidebarState(windowId);
        this.updateSidebarMeta(windowId);

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

        if (instance.currentView === 'contacts') {
            viewRoot.innerHTML = this.renderContactsView(instance);
            this.bindContactsEvents(windowId);
            return;
        }

        viewRoot.innerHTML = this.renderFolderView(instance);
        this.bindFolderEvents(windowId);
    },

    renderFolderView: function(instance) {
        var messages = this.getCurrentFolderMessages(instance);
        var selectedCount = Object.keys(instance.selectedIds || {}).length;
        var allowReadButtons = instance.currentFolder !== 'drafts' && instance.currentFolder !== 'sent' && instance.currentFolder !== 'trash';
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
        var options = instance.recipientDropdownOpen ? this.getRecipientOptions(instance, instance.recipientQuery) : [];
        var html = '' +
            '<div class="email-panel email-compose-panel">' +
                '<div class="email-compose-header">' +
                    '<button class="email-back-btn btn">Back</button>' +
                    '<div class="email-compose-title-wrap">' +
                        '<div class="email-compose-title">' + (instance.compose.draftId ? 'Edit Draft' : 'New Message') + '</div>' +
                        '<div class="email-compose-subtitle">' + this.escapeHtml(this.getFolderTitle(instance.currentFolder)) + '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="email-compose-body">' +
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
                        '<div class="email-recipient-dropdown ' + (instance.recipientDropdownOpen ? 'is-open' : '') + '">';

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

        html += '</div></div>' +
                '<div class="email-compose-footer">' +
                    '<div class="email-compose-footer-actions">' +
                        '<div class="email-compose-footer-left">' +
                            '<button class="email-toolbar-btn email-preview-toggle-btn">' + (instance.compose.previewMode ? 'Edit' : 'Preview') + '</button>' +
                        '</div>' +
                        '<div class="email-compose-footer-right">' +
                        '<button class="email-toolbar-btn email-save-draft-btn">Save Draft</button>' +
                        '<button class="email-toolbar-btn email-send-btn">Send</button>' +
                        '</div>' +
                    '</div>' +
                '</div></div>';
        return html;
    },

    renderComposeView: function(instance) {
        var options = instance.recipientDropdownOpen ? this.getRecipientOptions(instance, instance.recipientQuery) : [];
        var html = '' +
            '<div class="email-panel email-compose-panel">' +
                '<div class="email-compose-header">' +
                    '<button class="email-back-btn btn">Back</button>' +
                    '<div class="email-compose-title-wrap">' +
                        '<div class="email-compose-title">' + (instance.compose.draftId ? 'Edit Draft' : 'New Message') + '</div>' +
                        '<div class="email-compose-subtitle">' + this.escapeHtml(this.getFolderTitle(instance.currentFolder)) + '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="email-compose-body">' +
                '<div class="email-compose-fields">' +
                    '<div class="email-field">' +
                        '<span>To</span>' +
                        '<div class="email-recipient-input-box">' +
                            '<div class="email-recipient-chips">';

        instance.compose.recipients.forEach(function(recipient) {
            var key = this.getRecipientKey(recipient);
            var kind = this.getRecipientKind(recipient);
            html += '<div class="email-recipient-chip email-recipient-chip-' + this.escapeHtml(kind) + '">' +
                '<span class="email-recipient-chip-name">' + this.escapeHtml(this.getRecipientDisplayLabel(instance, recipient)) + '</span>' +
                '<button class="email-recipient-chip-remove" data-recipient-key="' + this.escapeHtml(key) + '">x</button>' +
            '</div>';
        }.bind(this));

        html += '</div>' +
                            '<input type="text" class="email-input email-to-input" placeholder="SteamID, SteamID64, contact, list, or set" value="' + this.escapeHtml(instance.recipientQuery) + '" />' +
                        '</div>' +
                        '<div class="email-recipient-dropdown ' + (instance.recipientDropdownOpen ? 'is-open' : '') + '">' +
                            this.renderRecipientDropdownContents(instance) +
                        '</div></div>' +
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

        html += '</div></div>' +
                '<div class="email-compose-footer">' +
                    '<div class="email-compose-footer-actions">' +
                        '<div class="email-compose-footer-left">' +
                            '<button class="email-toolbar-btn email-preview-toggle-btn">' + (instance.compose.previewMode ? 'Edit' : 'Preview') + '</button>' +
                        '</div>' +
                        '<div class="email-compose-footer-right">' +
                            '<button class="email-toolbar-btn email-save-draft-btn">Save Draft</button>' +
                            '<button class="email-toolbar-btn email-send-btn">Send</button>' +
                        '</div>' +
                    '</div>' +
                '</div></div>';

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
                if (!instance.recipientDropdownOpen) {
                    instance.recipientDropdownOpen = true;
                }
                this.refreshRecipientDropdown(windowId);
            }.bind(this));

            toInput.addEventListener('focus', function() {
                this.setRecipientDropdownOpen(windowId, true);
            }.bind(this));

            toInput.addEventListener('blur', function() {
                this.scheduleRecipientDropdownClose(windowId);
            }.bind(this));

            toInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === 'Tab' || e.key === ',') {
                    e.preventDefault();
                    this.commitRecipientInput(windowId);
                    return;
                }

                if (e.key === 'Escape') {
                    this.setRecipientDropdownOpen(windowId, false);
                }
            }.bind(this));
        }

        var subjectInput = root.querySelector('.email-subject-input');
        if (subjectInput) {
            subjectInput.addEventListener('input', function() {
                instance.compose.subject = subjectInput.value;
                this.onComposeChanged(windowId, { skipRender: true });
            }.bind(this));
        }

        var bodyInput = root.querySelector('.email-body-input');
        if (bodyInput) {
            bodyInput.addEventListener('input', function() {
                instance.compose.bodyMarkdown = bodyInput.value;
                this.onComposeChanged(windowId, { skipRender: true });
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

        var recipientBox = root.querySelector('.email-recipient-input-box');
        if (recipientBox) {
            recipientBox.addEventListener('click', function(e) {
                if (e.target.closest('.email-recipient-chip-remove')) {
                    return;
                }

                this.focusRecipientInput(windowId);
            }.bind(this));
        }

        var recipientDropdown = root.querySelector('.email-recipient-dropdown');
        if (recipientDropdown) {
            recipientDropdown.addEventListener('mousedown', function(e) {
                if (e.target.closest('.email-recipient-option') || e.target.closest('.email-favorite-toggle')) {
                    e.preventDefault();
                }
            });

            recipientDropdown.addEventListener('click', function(e) {
                var favoriteButton = e.target.closest('.email-favorite-toggle');
                if (favoriteButton) {
                    e.stopPropagation();

                    var favoriteKey = favoriteButton.getAttribute('data-favorite-key');
                    var favoriteContact = this.getRecipientOptions(instance, instance.recipientQuery).find(function(option) {
                        return String(option.steamID64 || option.steamID || '') === String(favoriteKey || '');
                    });

                    if (favoriteContact) {
                        this.toggleFavorite(windowId, favoriteContact);
                    }
                    return;
                }

                var optionNode = e.target.closest('.email-recipient-option');
                if (!optionNode) {
                    return;
                }

                var key = optionNode.getAttribute('data-recipient-key');
                var contact = this.getRecipientOptions(instance, instance.recipientQuery).find(function(option) {
                    return String(option.steamID64 || option.steamID || '') === String(key || '');
                });

                if (contact) {
                    instance.recipientQuery = '';
                    instance.recipientDropdownOpen = true;
                    this.addRecipient(windowId, contact, { refocusRecipient: true });
                }
            }.bind(this));
        }

        root.querySelectorAll('.email-attachment-remove-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeAttachment(windowId, parseInt(button.getAttribute('data-attachment-index'), 10) || 0);
            }.bind(this));
        }.bind(this));
    },

    findContactOptionByKey: function(instance, key) {
        var matched = null;
        this.getContactOptions(instance).some(function(contact) {
            if (String(contact.steamID64 || contact.steamID || '') === String(key || '')) {
                matched = contact;
                return true;
            }
            return false;
        });
        return matched;
    },

    findCollectionById: function(instance, kind, collectionId) {
        var matched = null;
        this.getCollectionsByKind(instance, kind).some(function(collection) {
            if (String(collection.id || '') === String(collectionId || '')) {
                matched = collection;
                return true;
            }
            return false;
        });
        return matched;
    },

    openComposeWithRecipient: function(windowId, recipient) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        if (instance.currentView !== 'compose') {
            this.openCompose(windowId);
            instance = this.getInstance(windowId);
        }

        this.addRecipient(windowId, recipient, { refocusRecipient: true });
    },

    setContactsTab: function(windowId, tab) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.contactsTab = tab === 'admin' ? 'admin' : 'local';
        this.render(windowId);
    },

    setLocalContactsSubTab: function(windowId, tab) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.localContactsSubTab = tab === 'local_lists' ? 'local_lists' : 'favorites';
        this.render(windowId);
    },

    startFavoriteInlineEdit: function(windowId, contactKey) {
        var instance = this.getInstance(windowId);
        var contact = instance && this.findContactOptionByKey(instance, contactKey);
        if (!instance || !contact) {
            return;
        }

        var alias = this.getLocalAlias(instance, contact);
        instance.favoriteInlineEditKey = String(contactKey || '');
        instance.favoriteInlineEditValue = String((alias && alias.nickname) || contact.nickname || '');
        this.render(windowId);
    },

    cancelFavoriteInlineEdit: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.favoriteInlineEditKey = '';
        instance.favoriteInlineEditValue = '';
        this.render(windowId);
    },

    updateFavoriteInlineEditValue: function(windowId, value) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.favoriteInlineEditValue = value;
    },

    saveFavoriteInlineEdit: function(windowId, contactKey) {
        var instance = this.getInstance(windowId);
        var contact = instance && this.findContactOptionByKey(instance, contactKey);
        if (!instance || !contact) {
            return;
        }

        var nickname = String(instance.favoriteInlineEditValue || '').trim();
        this.saveContactAlias(windowId, contact, nickname, function() {
            var current = this.getInstance(windowId);
            if (!current) {
                return;
            }

            current.favoriteInlineEditKey = '';
            current.favoriteInlineEditValue = '';
            this.render(windowId);
        }.bind(this));
    },

    updateCollectionEditorField: function(windowId, kind, field, value) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var editor = this.getCollectionEditorByKind(instance, kind);
        if (!editor) {
            return;
        }

        editor[field] = value;
    },

    toggleCollectionEditorMember: function(windowId, kind, steamID64, checked) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var editor = this.getCollectionEditorByKind(instance, kind);
        if (!editor) {
            return;
        }

        var normalized = String(steamID64 || '');
        if (!normalized) {
            return;
        }

        var nextMembers = (editor.members || []).filter(function(memberId) {
            return String(memberId || '') !== normalized;
        });

        if (checked) {
            nextMembers.push(normalized);
        }

        editor.members = nextMembers;
        this.render(windowId);
    },

    removeEditorMember: function(windowId, kind, steamID64) {
        this.toggleCollectionEditorMember(windowId, kind, steamID64, false);
    },

    addManualMemberToEditor: function(windowId, kind) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var editor = this.getCollectionEditorByKind(instance, kind);
        var value = String(editor.manualMemberInput || '').trim();
        if (!value) {
            return;
        }

        if (!this.isLikelySteamId(value) && window.osErrorHandler) {
            window.osErrorHandler.showNotification('Enter a valid SteamID or SteamID64.', 'warning', 2200);
            return;
        }

        if ((editor.members || []).indexOf(value) === -1) {
            editor.members.push(value);
        }

        editor.manualMemberInput = '';
        this.render(windowId);
    },

    clearCollectionEditor: function(windowId, kind) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        this.resetCollectionEditorState(this.getCollectionEditorByKind(instance, kind), kind);
        this.render(windowId);
    },

    editCollection: function(windowId, kind, collectionId) {
        var instance = this.getInstance(windowId);
        var collection = instance && this.findCollectionById(instance, kind, collectionId);
        if (!instance || !collection) {
            return;
        }

        var editor = this.getCollectionEditorByKind(instance, kind);
        editor.id = collection.id || null;
        editor.name = collection.name || '';
        editor.members = Array.isArray(collection.members) ? collection.members.slice() : [];
        editor.manualMemberInput = '';
        if (kind === 'server_set') {
            instance.contactsTab = 'admin';
        } else {
            instance.contactsTab = 'local';
            instance.localContactsSubTab = 'local_lists';
        }
        this.render(windowId);
    },

    saveCollection: function(windowId, kind) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var editor = this.getCollectionEditorByKind(instance, kind);
        var action = kind === 'server_set' ? 'save_contact_set' : 'save_local_list';

        this.request(windowId, action, {
            id: editor.id,
            name: editor.name,
            members: editor.members
        }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;

            if (!payload.success) {
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification(payload.message || 'Failed to save collection.', 'error', 2600);
                }
                return;
            }

            if (kind === 'server_set') {
                current.serverSets = Array.isArray(payload.serverSets) ? payload.serverSets : current.serverSets;
            } else {
                current.localLists = Array.isArray(payload.localLists) ? payload.localLists : current.localLists;
            }

            this.resetCollectionEditorState(this.getCollectionEditorByKind(current, kind), kind);
            this.render(windowId);

            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification(kind === 'server_set' ? 'Contact set saved.' : 'Local list saved.', 'success', 1800);
            }
        }.bind(this));
    },

    deleteCollection: function(windowId, kind, collectionId) {
        var action = kind === 'server_set' ? 'delete_contact_set' : 'delete_local_list';
        this.request(windowId, action, { id: collectionId }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;

            if (!payload.success) {
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification(payload.message || 'Failed to delete collection.', 'error', 2600);
                }
                return;
            }

            if (kind === 'server_set') {
                current.serverSets = Array.isArray(payload.serverSets) ? payload.serverSets : [];
            } else {
                current.localLists = Array.isArray(payload.localLists) ? payload.localLists : [];
            }

            this.resetCollectionEditorState(this.getCollectionEditorByKind(current, kind), kind);
            this.render(windowId);
        }.bind(this));
    },

    saveContactAlias: function(windowId, contact, nickname, callback) {
        this.request(windowId, 'save_contact_alias', {
            contact: {
                steamID: contact.steamID || '',
                steamID64: contact.steamID64 || '',
                nickname: nickname || ''
            }
        }, function(payload) {
            var instance = this.getInstance(windowId);
            if (!instance) return;
            instance.localAliases = Array.isArray(payload.aliases) ? payload.aliases : [];
            this.render(windowId);
            if (typeof callback === 'function') {
                callback(payload);
            }
        }.bind(this));
    },

    addManualFavorite: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var rawId = String(instance.localContactDraft.steamIdInput || '').trim();
        var nickname = String(instance.localContactDraft.nickname || '').trim();
        if (!rawId) {
            return;
        }

        var contact = {
            steamID: this.looksLikeSteamId64(rawId) ? '' : rawId,
            steamID64: this.looksLikeSteamId64(rawId) ? rawId : '',
            nickname: nickname || rawId
        };

        this.request(windowId, 'set_favorite', {
            contact: contact,
            favorite: true
        }, function(payload) {
            var current = this.getInstance(windowId);
            if (!current) return;
            current.favorites = Array.isArray(payload.favorites) ? payload.favorites : [];

            var finish = function() {
                var refreshed = this.getInstance(windowId);
                if (!refreshed) return;
                refreshed.localContactDraft.steamIdInput = '';
                refreshed.localContactDraft.nickname = '';
                this.render(windowId);
                if (window.osErrorHandler) {
                    window.osErrorHandler.showNotification('Favorite saved.', 'success', 1800);
                }
            }.bind(this);

            if (nickname) {
                this.request(windowId, 'save_contact_alias', { contact: contact }, function(aliasPayload) {
                    var refreshed = this.getInstance(windowId);
                    if (!refreshed) return;
                    refreshed.localAliases = Array.isArray(aliasPayload.aliases) ? aliasPayload.aliases : refreshed.localAliases;
                    finish();
                }.bind(this));
                return;
            }

            finish();
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
                if (!instance.recipientDropdownOpen) {
                    instance.recipientDropdownOpen = true;
                }
                this.refreshRecipientDropdown(windowId);
            }.bind(this));

            toInput.addEventListener('focus', function() {
                this.setRecipientDropdownOpen(windowId, true);
            }.bind(this));

            toInput.addEventListener('blur', function() {
                this.scheduleRecipientDropdownClose(windowId);
            }.bind(this));

            toInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === 'Tab' || e.key === ',') {
                    e.preventDefault();
                    this.commitRecipientInput(windowId);
                    return;
                }

                if (e.key === 'Escape') {
                    this.setRecipientDropdownOpen(windowId, false);
                }
            }.bind(this));
        }

        var subjectInput = root.querySelector('.email-subject-input');
        if (subjectInput) {
            subjectInput.addEventListener('input', function() {
                instance.compose.subject = subjectInput.value;
                this.onComposeChanged(windowId, { skipRender: true });
            }.bind(this));
        }

        var bodyInput = root.querySelector('.email-body-input');
        if (bodyInput) {
            bodyInput.addEventListener('input', function() {
                instance.compose.bodyMarkdown = bodyInput.value;
                this.onComposeChanged(windowId, { skipRender: true });
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

        var recipientBox = root.querySelector('.email-recipient-input-box');
        if (recipientBox) {
            recipientBox.addEventListener('click', function(e) {
                if (e.target.closest('.email-recipient-chip-remove')) {
                    return;
                }

                this.focusRecipientInput(windowId);
            }.bind(this));
        }

        var recipientDropdown = root.querySelector('.email-recipient-dropdown');
        if (recipientDropdown) {
            recipientDropdown.addEventListener('mousedown', function(e) {
                if (e.target.closest('.email-recipient-option') || e.target.closest('.email-favorite-toggle') || e.target.closest('.email-recipient-dropdown-tab')) {
                    e.preventDefault();
                }
            });

            recipientDropdown.addEventListener('click', function(e) {
                var tabButton = e.target.closest('.email-recipient-dropdown-tab');
                if (tabButton) {
                    e.stopPropagation();
                    this.setRecipientDropdownTab(windowId, tabButton.getAttribute('data-recipient-tab'));
                    return;
                }

                var favoriteButton = e.target.closest('.email-favorite-toggle');
                if (favoriteButton) {
                    e.stopPropagation();

                    var favoriteKey = favoriteButton.getAttribute('data-favorite-key');
                    var favoriteContact = this.getRecipientOptions(instance, instance.recipientQuery, this.getRecipientDropdownTab(instance)).find(function(option) {
                        return String(this.getRecipientKey(option) || '') === String(favoriteKey || '');
                    }.bind(this));

                    if (favoriteContact) {
                        this.toggleFavorite(windowId, favoriteContact);
                    }
                    return;
                }

                var optionNode = e.target.closest('.email-recipient-option');
                if (!optionNode) {
                    return;
                }

                var key = optionNode.getAttribute('data-recipient-key');
                var contact = this.getRecipientOptions(instance, instance.recipientQuery, this.getRecipientDropdownTab(instance)).find(function(option) {
                    return String(this.getRecipientKey(option) || '') === String(key || '');
                }.bind(this));

                if (contact) {
                    instance.recipientQuery = '';
                    instance.recipientDropdownOpen = true;
                    this.addRecipient(windowId, contact, { refocusRecipient: true });
                }
            }.bind(this));
        }

        root.querySelectorAll('.email-attachment-remove-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeAttachment(windowId, parseInt(button.getAttribute('data-attachment-index'), 10) || 0);
            }.bind(this));
        }.bind(this));
    },

    bindContactsEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !instance) {
            return;
        }

        var refreshBtn = root.querySelector('.email-refresh-contacts-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', function() {
                this.refreshLocalContactData(windowId, { render: true });
                this.refreshContactDirectory(windowId, { render: true });
            }.bind(this));
        }

        root.querySelectorAll('.email-contacts-tab').forEach(function(button) {
            button.addEventListener('click', function() {
                this.setContactsTab(windowId, button.getAttribute('data-contacts-tab'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-contacts-subtab').forEach(function(button) {
            button.addEventListener('click', function() {
                this.setLocalContactsSubTab(windowId, button.getAttribute('data-local-contacts-tab'));
            }.bind(this));
        }.bind(this));

        var manualIdInput = root.querySelector('.email-manual-favorite-id');
        if (manualIdInput) {
            manualIdInput.addEventListener('input', function() {
                instance.localContactDraft.steamIdInput = manualIdInput.value;
            });
        }

        var manualNicknameInput = root.querySelector('.email-manual-favorite-nickname');
        if (manualNicknameInput) {
            manualNicknameInput.addEventListener('input', function() {
                instance.localContactDraft.nickname = manualNicknameInput.value;
            });
        }

        var addManualFavoriteBtn = root.querySelector('.email-manual-favorite-add-btn');
        if (addManualFavoriteBtn) {
            addManualFavoriteBtn.addEventListener('click', function() {
                this.addManualFavorite(windowId);
            }.bind(this));
        }

        root.querySelectorAll('.email-contact-alias-input').forEach(function(input) {
            input.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    var contact = this.findContactOptionByKey(instance, input.getAttribute('data-contact-key'));
                    if (contact) {
                        this.saveContactAlias(windowId, contact, input.value);
                    }
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-save-alias-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                var key = button.getAttribute('data-contact-key');
                var contact = this.findContactOptionByKey(instance, key);
                var input = null;
                root.querySelectorAll('.email-contact-alias-input').forEach(function(field) {
                    if (!input && String(field.getAttribute('data-contact-key') || '') === String(key || '')) {
                        input = field;
                    }
                });
                if (contact && input) {
                    this.saveContactAlias(windowId, contact, input.value);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-favorite-edit-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.startFavoriteInlineEdit(windowId, button.getAttribute('data-contact-key'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-favorite-edit-input').forEach(function(input) {
            input.addEventListener('input', function() {
                this.updateFavoriteInlineEditValue(windowId, input.value);
            }.bind(this));

            input.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    this.saveFavoriteInlineEdit(windowId, input.getAttribute('data-contact-key'));
                    return;
                }

                if (e.key === 'Escape') {
                    e.preventDefault();
                    this.cancelFavoriteInlineEdit(windowId);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-favorite-save-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.saveFavoriteInlineEdit(windowId, button.getAttribute('data-contact-key'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-favorite-cancel-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.cancelFavoriteInlineEdit(windowId);
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-toggle-favorite-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                var key = button.getAttribute('data-contact-key');
                var contact = this.findContactOptionByKey(instance, key);
                if (contact) {
                    this.toggleFavorite(windowId, contact);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-compose-contact-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                var key = button.getAttribute('data-contact-key');
                var contact = this.findContactOptionByKey(instance, key);
                if (contact) {
                    this.openComposeWithRecipient(windowId, contact);
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-collection-name-input').forEach(function(input) {
            input.addEventListener('input', function() {
                this.updateCollectionEditorField(windowId, input.getAttribute('data-editor-kind'), 'name', input.value);
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-collection-manual-input').forEach(function(input) {
            input.addEventListener('input', function() {
                this.updateCollectionEditorField(windowId, input.getAttribute('data-editor-kind'), 'manualMemberInput', input.value);
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-collection-manual-add-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.addManualMemberToEditor(windowId, button.getAttribute('data-editor-kind'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-collection-member-toggle').forEach(function(input) {
            input.addEventListener('change', function() {
                this.toggleCollectionEditorMember(windowId, input.getAttribute('data-editor-kind'), input.getAttribute('data-member-id'), input.checked);
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-editor-member-remove').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeEditorMember(windowId, button.getAttribute('data-editor-kind'), button.getAttribute('data-member-id'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-save-collection-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.saveCollection(windowId, button.getAttribute('data-editor-kind'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-clear-collection-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.clearCollectionEditor(windowId, button.getAttribute('data-editor-kind'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-compose-collection-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                var kind = button.getAttribute('data-collection-kind');
                var collection = this.findCollectionById(instance, kind, button.getAttribute('data-collection-id'));
                if (collection) {
                    this.openComposeWithRecipient(windowId, this.createCollectionRecipient(kind, collection));
                }
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-edit-collection-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.editCollection(windowId, button.getAttribute('data-collection-kind'), button.getAttribute('data-collection-id'));
            }.bind(this));
        }.bind(this));

        root.querySelectorAll('.email-delete-collection-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                this.deleteCollection(windowId, button.getAttribute('data-collection-kind'), button.getAttribute('data-collection-id'));
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
        if (!instance || !instance.detailMessage) {
            return;
        }

        var attachments = instance.detailMessage.attachments || [];
        var attachment = attachments[attachmentIndex];
        if (!attachment) {
            return;
        }

        if (openAfterSave) {
            this.openAttachmentInEditor(attachment);
            return;
        }

        this.saveAttachmentAs(attachment);
    },

    sanitizePathToken: function(value) {
        return String(value || 'item').toLowerCase().replace(/[^a-z0-9._-]/g, '_');
    },

    stripExtension: function(fileName) {
        return String(fileName || '').replace(/\.[^.]+$/, '') || 'untitled';
    },

    isImageAttachment: function(attachment) {
        if (!attachment) {
            return false;
        }

        var fileType = String(attachment.filetype || '').toLowerCase();
        var displayName = String(attachment.displayName || attachment.filename || '').toLowerCase();

        return fileType === 'image' ||
            /\.image(\.dat)?$/i.test(displayName) ||
            /\.(png|jpg|jpeg)$/i.test(displayName);
    },

    getAttachmentDisplayName: function(attachment) {
        var displayName = String((attachment && (attachment.displayName || attachment.filename)) || 'attachment').trim();
        if (!displayName) {
            displayName = 'attachment';
        }

        if (this.isImageAttachment(attachment) && !/\.image$/i.test(displayName)) {
            displayName = displayName.replace(/\.image\.dat$/i, '.image');
            displayName = displayName.replace(/\.(png|jpg|jpeg)$/i, '.image');
            if (!/\.image$/i.test(displayName)) {
                displayName += '.image';
            }
        }

        return displayName;
    },

    openAttachmentInEditor: function(attachment) {
        if (!window.osShell || !window.osShell.openProgram) {
            return;
        }

        if (!window.pendingFileOpen || typeof window.pendingFileOpen !== 'object') {
            window.pendingFileOpen = {};
        }

        var pendingFileId = 'pending-file-' + Date.now() + '-' + Math.random().toString(36).slice(2);

        if (this.isImageAttachment(attachment)) {
            window.pendingFileOpen[pendingFileId] = {
                path: null,
                content: attachment.content || '',
                displayName: this.getAttachmentDisplayName(attachment),
                editMode: true
            };

            var paintWindowId = window.osShell.openProgram('paint');
            var paintWindow = paintWindowId ? document.getElementById(paintWindowId) : null;
            if (paintWindow) {
                paintWindow.setAttribute('data-pending-file', pendingFileId);
            }
            return;
        }

        window.pendingFileOpen[pendingFileId] = {
            path: null,
            content: attachment.content || '',
            displayName: this.stripExtension(this.getAttachmentDisplayName(attachment)),
            editMode: true
        };

        var notesWindowId = window.osShell.openProgram('notes');
        var notesWindow = notesWindowId ? document.getElementById(notesWindowId) : null;
        if (notesWindow) {
            notesWindow.setAttribute('data-pending-file', pendingFileId);
        }
    },

    saveAttachmentAs: function(attachment) {
        if (!window.osFileDialogs || !window.osFileDialogs.showSaveAs || !window.filesystem) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Save dialog is not available.', 'error', 2400);
            }
            return;
        }

        var defaultName = this.getAttachmentDisplayName(attachment);
        var nameParts = window.osFileDialogs.splitFileName(defaultName);
        var defaultExtension = this.isImageAttachment(attachment) ? '.image' : (nameParts.extension || '.txt');
        window.osFileDialogs.showSaveAs({
            title: 'Save Attachment As...',
            initialPath: 'C:/desktop/',
            defaultName: nameParts.baseName || 'attachment',
            defaultExtension: defaultExtension,
            allowedExtensions: [defaultExtension],
            confirmLabel: 'Save',
            onSave: function(filePath) {
                window.filesystem.writeFile(filePath, attachment.content || '', function(success) {
                    if (window.osErrorHandler) {
                        if (success) {
                            window.osErrorHandler.showNotification('Attachment saved.', 'success', 2200);
                        } else {
                            window.osErrorHandler.showNotification('Failed to save attachment.', 'error', 2400);
                        }
                    }
                });
            }
        });
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
]=]
end

function EMAIL.GetCSS()
    return [[
.program-email {
    display: flex;
    height: 100%;
    min-height: 0;
    background: var(--color-window-bg, #2d2d2d);
}

.email-sidebar {
    width: 170px;
    padding: 12px;
    border-right: 1px solid var(--color-window-border, #444);
    background: var(--color-sidebar-bg, #202020);
    display: flex;
    flex-direction: column;
    gap: 8px;
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
    padding: 10px 12px;
    text-align: left;
    border: 1px solid var(--color-secondary-button-border, #3f4a59);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-secondary-button-bg, #566375);
    color: var(--color-text-on-secondary-button, #ffffff);
    cursor: pointer;
    box-shadow: none;
    transition: background 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease, color 0.15s ease;
}

.email-compose-btn:hover {
    background: var(--color-secondary-button-hover-bg, #465364) !important;
    border-color: var(--color-highlight, #4a9eff) !important;
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff) !important;
}

.email-compose-btn.active {
    background: var(--color-secondary-button-active-bg, #4f5b6c);
    border-color: var(--color-secondary-button-border, #3f4a59);
    color: var(--color-text-on-secondary-button, #ffffff);
}

.email-compose-btn.active:hover {
    background: var(--color-secondary-button-active-hover-bg, #404c5c) !important;
    border-color: var(--color-highlight, #4a9eff) !important;
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff) !important;
}

.email-folders {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.email-sidebar-bottom {
    margin-top: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding-top: 10px;
}

.email-sidebar-card {
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: var(--radius-ui, 6px);
    background: rgba(0, 0, 0, 0.14);
    padding: 10px;
}

.email-storage-inline {
    padding: 2px 2px 0;
}

.email-sidebar-card-label {
    color: var(--color-text-secondary, #aeb8c7);
    font-size: 11px;
    letter-spacing: 0.05em;
    text-transform: uppercase;
}

.email-storage-count {
    margin-top: 5px;
    color: var(--color-text-primary, #ffffff);
    font-size: 15px;
    font-weight: 700;
}

.email-storage-bar {
    margin-top: 8px;
    height: 6px;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.08);
    overflow: hidden;
}

.email-storage-bar span {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: var(--color-highlight, #4a9eff);
}

.email-user-card {
    display: flex;
    flex-direction: column;
}

.email-user-name {
    color: var(--color-text-primary, #ffffff);
    font-size: 13px;
    font-weight: 700;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.email-user-subtitle {
    margin-top: 3px;
    color: var(--color-text-secondary, #aeb8c7);
    font-size: 11px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.email-folder {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-button-muted-bg, #2e2e2e);
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    text-align: left;
}

.email-folder:hover {
    background: var(--color-button-hover-bg, #3a3a3a);
    border-color: var(--color-accent, #555);
}

.email-folder.active {
    background: var(--color-button-bg, #3b74b5);
    border-color: var(--color-accent, #5e9be3);
    color: var(--color-text-on-button, #ffffff);
}

.email-folder-badge {
    min-width: 22px;
    padding: 2px 6px;
    border-radius: 999px;
    background: rgba(0, 0, 0, 0.22);
    color: inherit;
    font-size: 11px;
    font-weight: 700;
    line-height: 1.2;
    text-align: center;
    flex-shrink: 0;
}

.email-main {
    flex: 1;
    min-width: 0;
    min-height: 0;
    display: flex;
    flex-direction: column;
    background: var(--color-window-bg, #252525);
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
    color: var(--color-text-secondary, #9a9a9a);
    padding: 20px;
    text-align: center;
}

.email-loading-title,
.email-empty-title {
    font-size: 20px;
    font-weight: 700;
    color: var(--color-text-primary, #ffffff);
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
    padding: 12px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: var(--color-window-bg, #334055);
    color: var(--color-text-on-primary-surface, #ffffff);
}

.email-toolbar-title-wrap,
.email-compose-title-wrap,
.email-detail-title-wrap {
    min-width: 0;
}

.email-toolbar-title,
.email-compose-title,
.email-detail-title {
    color: var(--color-text-on-primary-surface, #ffffff);
    font-size: 18px;
    font-weight: 700;
}

.email-toolbar-subtitle,
.email-compose-subtitle,
.email-detail-meta,
.email-section-meta {
    color: rgba(255, 255, 255, 0.72);
    font-size: 12px;
}

.email-toolbar-actions,
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
    border: 1px solid var(--color-button-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-muted-bg, #2f2f2f);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
}

.email-toolbar-btn:hover,
.email-back-btn:hover,
.email-format-btn:hover {
    background: var(--color-button-hover-bg, #3a3a3a);
    border-color: var(--color-accent, #555);
}

.email-toolbar-btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.email-delete-btn,
.email-bulk-delete-btn {
    border-color: var(--color-secondary-button-border, #3f4a59);
    background: var(--color-secondary-button-bg, #566375);
    color: var(--color-text-on-secondary-button, #ffffff);
}

.email-delete-btn:hover,
.email-bulk-delete-btn:hover {
    background: var(--color-secondary-button-hover-bg, #465364) !important;
    border-color: var(--color-highlight, #4a9eff) !important;
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff) !important;
}

.email-list-table {
    flex: 1;
    min-height: 0;
    overflow: auto;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
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
    background: #283140;
    border-bottom: 1px solid var(--color-window-border, #444);
    color: rgba(255, 255, 255, 0.72);
    font-size: 12px;
}

.email-list-row {
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    cursor: pointer;
    background: transparent;
}

.email-list-row:hover {
    background: rgba(255, 255, 255, 0.06);
}

.email-list-row.is-unread {
    background: rgba(94, 155, 227, 0.12);
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
    color: var(--color-text-primary, #ffffff);
    font-size: 13px;
}

.email-row-subject {
    color: var(--color-text-primary, #ffffff);
    font-size: 14px;
    font-weight: 700;
    margin-top: 2px;
}

.email-row-preview,
.email-row-meta {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
    margin-top: 3px;
}

.email-row-date {
    color: var(--color-text-primary, #ffffff);
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
    min-height: 0;
}

.email-detail-panel {
    overflow: auto;
}

.email-compose-panel {
    overflow: hidden;
}

.email-compose-body {
    flex: 1;
    min-height: 0;
    overflow: auto;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
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
    color: rgba(255, 255, 255, 0.82);
    font-size: 12px;
    position: relative;
}

.email-input,
.email-body-input {
    width: 100%;
    padding: 8px 10px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-input-bg, #1f1f1f);
    color: var(--color-text-primary, #fff);
    font: inherit;
    box-sizing: border-box;
}

.email-recipient-input-box {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 8px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-input-bg, #1f1f1f);
}

.email-recipient-input-box:focus-within {
    border-color: var(--color-accent, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-accent, #4a9eff);
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
    background: rgba(59, 116, 181, 0.18);
    border: 1px solid rgba(94, 155, 227, 0.45);
    color: #dbe9ff;
    font-size: 12px;
}

.email-recipient-chip-local_list {
    background: rgba(72, 148, 92, 0.2);
    border-color: rgba(95, 191, 121, 0.42);
    color: #dcffe4;
}

.email-recipient-chip-server_set {
    background: rgba(165, 116, 49, 0.2);
    border-color: rgba(218, 160, 74, 0.42);
    color: #fff1d3;
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
    position: absolute;
    top: calc(100% + 6px);
    left: 0;
    right: 0;
    z-index: 25;
    border: 1px solid var(--color-window-border, #444);
    border-radius: 6px;
    overflow: hidden;
    background: #232a34;
    box-shadow: 0 10px 22px rgba(0, 0, 0, 0.28);
    max-height: 250px;
    overflow-y: auto;
}

.email-recipient-dropdown.is-open {
    display: block;
}

.email-recipient-dropdown-tabs {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    padding: 8px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    background: rgba(255, 255, 255, 0.02);
}

.email-recipient-dropdown-tab {
    padding: 6px 10px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-bg, rgba(255, 255, 255, 0.06));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    font-size: 11px;
}

.email-recipient-dropdown-tab.active {
    background: var(--color-button-active-bg, rgba(255, 255, 255, 0.12));
    border-color: var(--color-button-active-border, var(--color-window-border, #666));
}

.email-recipient-dropdown-list {
    display: flex;
    flex-direction: column;
}

.email-recipient-option {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    cursor: pointer;
}

.email-recipient-option:last-child {
    border-bottom: none;
}

.email-recipient-option:hover {
    background: rgba(255, 255, 255, 0.06);
}

.email-favorite-toggle {
    width: 30px;
    height: 28px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-muted-bg, #2f2f2f);
    color: #f7cb58;
    cursor: pointer;
    flex-shrink: 0;
    padding: 0;
    font-size: 15px;
    line-height: 1;
}

.email-favorite-toggle.is-active {
    background: rgba(232, 185, 77, 0.16);
    border-color: rgba(232, 185, 77, 0.35);
}

.email-recipient-type-pill {
    min-width: 48px;
    height: 28px;
    padding: 0 8px;
    border-radius: var(--radius-ui-small, 4px);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    flex-shrink: 0;
}

.email-recipient-type-pill-local_list {
    background: rgba(72, 148, 92, 0.18);
    border: 1px solid rgba(95, 191, 121, 0.45);
    color: #d9ffe2;
}

.email-recipient-type-pill-server_set {
    background: rgba(165, 116, 49, 0.18);
    border: 1px solid rgba(218, 160, 74, 0.45);
    color: #fff0cf;
}

.email-recipient-type-pill-contact {
    background: rgba(96, 150, 224, 0.18);
    border: 1px solid rgba(96, 150, 224, 0.4);
    color: #d7e8ff;
}

.email-recipient-option-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
}

.email-recipient-option-meta,
.email-recipient-empty {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
}

.email-contacts-panel {
    display: flex;
    flex-direction: column;
    min-height: 0;
}

.email-contacts-shell {
    padding: 12px 16px 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.03), rgba(255, 255, 255, 0.01));
}

.email-contacts-tabs {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.email-contacts-tab {
    padding: 8px 14px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-bg, rgba(255, 255, 255, 0.06));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    transition: background 0.18s ease, border-color 0.18s ease, color 0.18s ease;
}

.email-contacts-tab.active {
    background: var(--color-button-active-bg, rgba(255, 255, 255, 0.12));
    border-color: var(--color-button-active-border, var(--color-window-border, #666));
    color: var(--color-text-primary, #fff);
}

.email-contacts-subtabs {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.email-contacts-subtab {
    padding: 7px 12px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-bg, rgba(255, 255, 255, 0.06));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    transition: background 0.18s ease, border-color 0.18s ease, color 0.18s ease;
}

.email-contacts-subtab.active {
    background: var(--color-button-active-bg, rgba(255, 255, 255, 0.12));
    border-color: var(--color-button-active-border, var(--color-window-border, #666));
    color: var(--color-text-primary, #fff);
}

.email-contacts-body {
    padding: 16px;
    overflow: auto;
}

.email-contacts-page-intro {
    color: var(--color-text-secondary, #b4bcc8);
    font-size: 12px;
    margin-bottom: 14px;
}

.email-contacts-section-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 16px;
}

.email-contacts-section-grid-wide {
    grid-template-columns: 1fr;
}

.email-contacts-column {
    display: flex;
    flex-direction: column;
    gap: 16px;
    min-width: 0;
}

.email-contacts-column-wide {
    min-width: 0;
}

.email-contacts-card {
    border: 1px solid var(--color-window-border, #444);
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.03);
    padding: 14px;
}

.email-contacts-card-highlight {
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.02));
    border-color: rgba(255, 255, 255, 0.1);
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
}

.email-contacts-card-muted {
    background: rgba(0, 0, 0, 0.14);
}

.email-contacts-card-header {
    margin-bottom: 12px;
}

.email-contacts-card-title {
    color: var(--color-text-primary, #fff);
    font-size: 14px;
    font-weight: 700;
}

.email-contacts-card-subtitle {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
    margin-top: 4px;
}

.email-inline-form {
    display: flex;
    gap: 8px;
    align-items: center;
}

.email-inline-form.stacked {
    flex-direction: column;
    align-items: stretch;
}

.email-contacts-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
    gap: 10px;
    margin-bottom: 14px;
}

.email-contacts-stat {
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    padding: 10px 12px;
    background: rgba(0, 0, 0, 0.14);
}

.email-contacts-stat-value {
    color: var(--color-text-primary, #fff);
    font-size: 18px;
    font-weight: 700;
    line-height: 1;
}

.email-contacts-stat-label {
    color: var(--color-text-secondary, #aab3c0);
    font-size: 11px;
    margin-top: 6px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.email-contact-directory {
    display: flex;
    flex-direction: column;
    gap: 12px;
    max-height: none;
    overflow: visible;
}

.email-contact-directory.compact {
    max-height: none;
}

.email-favorite-directory {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.email-favorite-row {
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    padding: 10px 12px;
    background: rgba(0, 0, 0, 0.14);
}

.email-favorite-row-top {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 10px;
}

.email-favorite-row-main {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    min-width: 0;
    flex: 1;
}

.email-favorite-row-icon {
    width: 22px;
    height: 22px;
    border-radius: var(--radius-ui-small, 4px);
    background: rgba(232, 185, 77, 0.16);
    border: 1px solid rgba(232, 185, 77, 0.28);
    color: #ffe7a9;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    flex-shrink: 0;
}

.email-favorite-row-copy {
    min-width: 0;
}

.email-favorite-row-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
    font-weight: 700;
}

.email-favorite-row-meta {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 11px;
    margin-top: 2px;
}

.email-favorite-row-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    justify-content: flex-end;
}

.email-favorite-inline-editor {
    display: flex;
    gap: 8px;
    align-items: center;
    margin-top: 10px;
    padding-top: 10px;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.email-favorite-inline-editor .email-input {
    flex: 1;
    min-width: 0;
}

.email-contact-row {
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    padding: 12px;
    background: rgba(0, 0, 0, 0.12);
}

.email-contact-row-main {
    margin-bottom: 10px;
}

.email-contact-row-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
    font-weight: 700;
}

.email-contact-row-meta {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 11px;
    margin-top: 3px;
}

.email-contact-row-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 8px;
}

.email-contact-row-badges.compact {
    margin-top: 6px;
}

.email-contact-badge {
    display: inline-flex;
    align-items: center;
    padding: 3px 8px;
    border-radius: 999px;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
}

.email-contact-badge.is-favorite {
    background: rgba(232, 185, 77, 0.18);
    color: #ffe7a9;
}

.email-contact-badge.is-online {
    background: rgba(77, 201, 124, 0.18);
    color: #c8ffd7;
}

.email-contact-badge.is-alias {
    background: rgba(96, 150, 224, 0.18);
    color: #d7e8ff;
}

.email-contact-row-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
}

.email-contact-row-actions .email-input {
    flex: 1;
    min-width: 160px;
}

.email-contacts-empty-inline {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
}

.email-editor-member-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.email-editor-member-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 10px;
    border-radius: 999px;
    background: rgba(74, 158, 255, 0.12);
    border: 1px solid rgba(74, 158, 255, 0.28);
    color: #dbe9ff;
    font-size: 12px;
}

.email-editor-member-remove {
    border: none;
    background: transparent;
    color: inherit;
    cursor: pointer;
}

.email-collection-contact-picker {
    max-height: 260px;
    overflow: auto;
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
}

.email-collection-contact-option {
    display: flex;
    gap: 10px;
    align-items: center;
    padding: 10px 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.email-collection-contact-option:last-child {
    border-bottom: none;
}

.email-collection-contact-main {
    display: flex;
    flex-direction: column;
    min-width: 0;
}

.email-collection-contact-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
}

.email-collection-contact-meta {
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 11px;
}

.email-contacts-card-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 12px;
}

.email-contacts-help-copy {
    color: var(--color-text-secondary, #c2c8d0);
    font-size: 12px;
    line-height: 1.6;
}

.email-collection-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 12px;
}

.email-collection-card-preview {
    color: var(--color-text-secondary, #c2c8d0);
    font-size: 12px;
    line-height: 1.5;
    min-height: 36px;
}

.email-empty-state.compact {
    padding: 18px 12px;
}

.email-attachments-section {
    padding-top: 16px;
}

.email-section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    color: var(--color-text-primary, #ffffff);
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
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
}

.email-attachment-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 12px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.03);
}

.email-attachment-meta {
    min-width: 0;
}

.email-attachment-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
}

.email-attachment-path {
    color: var(--color-text-secondary, #9a9a9a);
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
    padding-bottom: 28px;
    display: flex;
    flex-direction: column;
}

.email-editor-toolbar {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    margin-bottom: 10px;
    padding: 10px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.03);
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
    border: 1px solid var(--color-window-border, #444);
    border-radius: 6px;
    background: var(--color-input-bg, #1f1f1f);
    color: var(--color-text-primary, #fff);
    padding: 14px;
    line-height: 1.55;
}

.email-detail-recipients {
    padding-top: 14px;
    color: var(--color-text-secondary, #9a9a9a);
    font-size: 12px;
}

.email-detail-body {
    margin-top: 14px;
}

.email-compose-footer {
    flex-shrink: 0;
    padding: 12px;
    border-top: 1px solid var(--color-window-border, #444);
    background: var(--color-footer-bar-bg, #2d3747) !important;
}

.email-compose-footer-actions {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
}

.email-compose-footer-left,
.email-compose-footer-right {
    display: flex;
    align-items: center;
    gap: 10px;
}

.email-compose-footer .email-send-btn {
    border-color: var(--color-secondary-button-border, #3f4a59);
    background: var(--color-secondary-button-bg, #566375);
    color: var(--color-text-on-secondary-button, #ffffff);
    box-shadow: none;
}

.email-compose-footer .email-send-btn:hover {
    background: var(--color-secondary-button-hover-bg, #465364) !important;
    border-color: var(--color-highlight, #4a9eff) !important;
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff) !important;
}

.email-body-preview h1,
.email-body-preview h2,
.email-body-preview h3,
.email-detail-body h1,
.email-detail-body h2,
.email-detail-body h3 {
    color: #8dc2ff;
}

.email-body-preview code,
.email-detail-body code {
    padding: 2px 4px;
    border-radius: 4px;
    background: #151a20;
    color: #d7ba7d;
}

.email-body-preview blockquote,
.email-detail-body blockquote {
    margin: 8px 0;
    padding-left: 12px;
    border-left: 3px solid var(--color-accent, #5e9be3);
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
