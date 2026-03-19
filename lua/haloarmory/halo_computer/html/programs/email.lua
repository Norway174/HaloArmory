-- Email Program
local EMAIL = {}

function EMAIL.GetContent()
    return [[
<div class="program-email">
    <div class="email-sidebar">
        <button class="email-compose-btn btn btn-primary">Compose</button>
        <div class="email-folders">
            <button class="email-folder active" data-folder="inbox">📥 Inbox</button>
            <button class="email-folder" data-folder="sent">📤 Sent</button>
            <button class="email-folder" data-folder="drafts">📝 Drafts</button>
            <button class="email-folder" data-folder="trash">🗑️ Trash</button>
        </div>
    </div>
    <div class="email-main">
        <div class="email-list">
            <div class="email-placeholder">
                <h2>Email System</h2>
                <p>No emails are loaded in this build yet.</p>
                <p>Compose is available now so attachments can be prepared and tested.</p>
            </div>
        </div>
        <div class="email-compose-panel" style="display: none;">
            <div class="email-compose-header">
                <button class="email-back-btn btn">← Back</button>
                <div class="email-compose-title">New Message</div>
            </div>
            <div class="email-compose-fields">
                <label class="email-field">
                    <span>To</span>
                    <input type="text" class="email-input email-to-input" placeholder="SteamID or recipient" />
                </label>
                <label class="email-field">
                    <span>Subject</span>
                    <input type="text" class="email-input email-subject-input" placeholder="Subject" />
                </label>
            </div>
            <label class="email-field email-body-field">
                <span>Message</span>
                <textarea class="email-body-input" placeholder="Write your message here..."></textarea>
            </label>
            <div class="email-attachments-section">
                <div class="email-attachments-header">
                    <span>Attachments</span>
                    <span class="email-attachments-count">0 files</span>
                </div>
                <div class="email-attachments-list"></div>
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
var emailApp = {
    instances: {},
    cleanupBound: false,

    init: function(windowId) {
        this.instances[windowId] = {
            windowId: windowId,
            currentFolder: 'inbox',
            attachments: []
        };

        this.bindCleanup();
        this.bindEvents(windowId);
        this.registerDropTarget(windowId);
        this.showFolder(windowId, 'inbox');
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

    getInstance: function(windowId) {
        return this.instances[windowId] || null;
    },

    getRootElement: function(windowId) {
        var windowEl = document.getElementById(windowId);
        return windowEl ? windowEl.querySelector('.program-email') : null;
    },

    bindEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        if (!root) {
            return;
        }

        var composeBtn = root.querySelector('.email-compose-btn');
        if (composeBtn) {
            composeBtn.addEventListener('click', function() {
                this.compose(windowId);
            }.bind(this));
        }

        var backBtn = root.querySelector('.email-back-btn');
        if (backBtn) {
            backBtn.addEventListener('click', function() {
                var instance = this.getInstance(windowId);
                this.showFolder(windowId, instance ? instance.currentFolder : 'inbox');
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
            resourceId: 'email-attachments-' + windowId,
            onDrop: function(acceptedItems) {
                this.addAttachments(windowId, acceptedItems);
            }.bind(this)
        });
    },

    compose: function(windowId) {
        var root = this.getRootElement(windowId);
        if (!root) {
            return;
        }

        root.querySelector('.email-list').style.display = 'none';
        root.querySelector('.email-compose-panel').style.display = 'flex';
        this.renderAttachments(windowId);
    },

    showFolder: function(windowId, folder) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        instance.currentFolder = folder;

        root.querySelectorAll('.email-folder').forEach(function(button) {
            button.classList.toggle('active', button.getAttribute('data-folder') === folder);
        });

        root.querySelector('.email-compose-panel').style.display = 'none';
        root.querySelector('.email-list').style.display = 'block';

        var emailList = root.querySelector('.email-list');
        emailList.innerHTML = '<div class="email-placeholder"><h2>' + this.escapeHtml(this.getFolderTitle(folder)) + '</h2><p>No messages are available in this folder yet.</p><p>Use Compose to test attachments and the drag/drop flow.</p></div>';
    },

    getFolderTitle: function(folder) {
        switch (folder) {
            case 'sent': return 'Sent';
            case 'drafts': return 'Drafts';
            case 'trash': return 'Trash';
            default: return 'Inbox';
        }
    },

    addAttachments: function(windowId, items) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var addedCount = 0;

        items.forEach(function(item) {
            var alreadyAttached = instance.attachments.some(function(existing) {
                return normalizePath(existing.filepath) === normalizePath(item.filepath);
            });

            if (alreadyAttached) {
                return;
            }

            instance.attachments.push({
                filepath: item.filepath,
                filename: item.filename || window.getFileNameFromPath(item.filepath),
                displayName: item.displayName || item.name || item.filename || window.getFileNameFromPath(item.filepath),
                filetype: item.filetype
            });
            addedCount++;
        });

        if (addedCount > 0) {
            window.osErrorHandler.showNotification('Attached ' + addedCount + ' file(s)', 'success', 2000);
        }

        this.compose(windowId);
        this.renderAttachments(windowId);
    },

    removeAttachment: function(windowId, filepath) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        instance.attachments = instance.attachments.filter(function(item) {
            return normalizePath(item.filepath) !== normalizePath(filepath);
        });

        this.renderAttachments(windowId);
    },

    renderAttachments: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var list = root.querySelector('.email-attachments-list');
        var count = root.querySelector('.email-attachments-count');

        if (!list || !count) {
            return;
        }

        count.textContent = instance.attachments.length + ' file' + (instance.attachments.length === 1 ? '' : 's');

        if (!instance.attachments.length) {
            list.innerHTML = '<div class="email-attachments-empty">No attachments yet</div>';
            return;
        }

        var html = '';
        instance.attachments.forEach(function(item) {
            html += '<div class="email-attachment-item">' +
                '<div class="email-attachment-meta">' +
                '<div class="email-attachment-name">' + this.escapeHtml(item.displayName) + '</div>' +
                '<div class="email-attachment-path">' + this.escapeHtml(item.filepath) + '</div>' +
                '</div>' +
                '<button class="email-attachment-remove btn" data-filepath="' + this.escapeHtml(item.filepath) + '">Remove</button>' +
                '</div>';
        }.bind(this));

        list.innerHTML = html;

        list.querySelectorAll('.email-attachment-remove').forEach(function(button) {
            button.addEventListener('click', function() {
                this.removeAttachment(windowId, button.getAttribute('data-filepath'));
            }.bind(this));
        }.bind(this));
    },

    escapeHtml: function(text) {
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    destroy: function(windowId) {
        delete this.instances[windowId];
    }
};
]]
end

function EMAIL.GetCSS()
    return [[
.program-email {
    display: flex;
    height: 100%;
    background: var(--color-window-bg, #2d2d2d);
}

.email-sidebar {
    width: 200px;
    padding: 12px;
    border-right: 1px solid var(--color-window-border, #444);
    background: linear-gradient(180deg, var(--color-window-bg, #334055), var(--color-secondary-surface-alt, #2a3446));
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.email-compose-btn {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid var(--color-accent, #5e9be3);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-button-bg, #3b74b5);
    color: var(--color-text-on-button, #ffffff);
    cursor: pointer;
    font: inherit;
}

.email-folders {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.email-folder {
    width: 100%;
    padding: 8px 12px;
    cursor: pointer;
    color: var(--color-text-secondary, #ccc);
    border-radius: var(--radius-ui-small, 4px);
    margin: 0;
    border: 1px solid transparent;
    background: transparent;
    text-align: left;
    transition: background 0.15s;
}

.email-folder:hover {
    background: var(--color-taskbar-item-hover-bg, rgba(255, 255, 255, 0.1));
}

.email-folder.active {
    background: var(--color-accent, #0078d4);
    color: var(--color-text-on-accent, #fff);
}

.email-main {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
}

.email-list {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
}

.email-placeholder {
    text-align: center;
    color: var(--color-text-secondary, #999);
    padding: 40px;
}

.email-placeholder h2 {
    color: var(--color-text-primary, #fff);
    margin-bottom: 16px;
}

.email-compose-panel {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 14px;
    padding: 16px;
    overflow-y: auto;
    background: linear-gradient(180deg, var(--color-secondary-surface, #334055), var(--color-secondary-surface-alt, #2a3446));
}

.email-compose-header {
    display: flex;
    align-items: center;
    gap: 12px;
}

.email-compose-title {
    color: var(--color-text-primary, #fff);
    font-size: 18px;
    font-weight: 600;
}

.email-back-btn,
.email-attachment-remove {
    padding: 8px 12px;
    border: 1px solid var(--color-button-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-muted-bg, #2f2f2f);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    font: inherit;
}

.email-back-btn:hover,
.email-attachment-remove:hover,
.email-compose-btn:hover {
    background: var(--color-button-hover-bg, #3d3d3d);
}

.email-compose-fields {
    display: grid;
    gap: 12px;
}

.email-field {
    display: flex;
    flex-direction: column;
    gap: 6px;
    color: var(--color-text-primary, #ddd);
    font-size: 12px;
}

.email-input,
.email-body-input {
    width: 100%;
    padding: 10px 12px;
    border-radius: var(--radius-ui, 6px);
    border: 1px solid var(--color-window-border, #444);
    background: var(--color-secondary-surface-alt, #1f1f1f);
    color: var(--color-text-primary, #fff);
    font: inherit;
}

.email-body-field {
    flex: 1;
}

.email-body-input {
    min-height: 180px;
    resize: vertical;
}

.email-attachments-section {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.email-attachments-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    color: var(--color-text-primary, #ddd);
    font-size: 12px;
}

.email-attachments-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.email-attachments-empty {
    color: var(--color-text-secondary, #888);
    font-size: 12px;
    padding: 6px 2px;
}

.email-attachment-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 12px;
    border: 1px solid var(--color-window-border, #333);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-window-bg, #1e1e1e);
}

.email-attachment-meta {
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.email-attachment-name {
    color: var(--color-text-primary, #fff);
    font-size: 13px;
}

.email-attachment-path {
    color: var(--color-text-secondary, #7f7f7f);
    font-size: 11px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100%;
}

.email-attachment-remove {
    flex-shrink: 0;
}
]]
end

return {
    title = "Email",
    icon = "📧",
    width = 800,
    height = 600,
    getContent = EMAIL.GetContent,
    getInitScript = EMAIL.GetInitScript,
    getJavaScript = EMAIL.GetJavaScript,
    getCSS = EMAIL.GetCSS
}
