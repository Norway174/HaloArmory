-- File Browser Program - Multi-instance explorer for C:/ and ExternalDrive:/
local FILEBROWSER = {}

function FILEBROWSER.GetContent()
    return [[
<div class="program-filebrowser">
    <div class="filebrowser-sidebar">
        <button class="filebrowser-drive-btn active" data-drive="C:/">C:/</button>
        <button class="filebrowser-drive-btn" data-drive="ExternalDrive:/">ExternalDrive:/</button>
    </div>
    <div class="filebrowser-main">
        <div class="filebrowser-toolbar">
            <button class="filebrowser-up-btn btn">Up</button>
            <input type="text" class="filebrowser-path-input" />
            <input type="text" class="filebrowser-filter" placeholder="Filter..." />
            <button class="filebrowser-new-file-btn btn">New File</button>
            <button class="filebrowser-new-folder-btn btn">New Folder</button>
        </div>
        <div class="filebrowser-content">
            <div class="filebrowser-loading">Loading...</div>
        </div>
    </div>
</div>
]]
end

function FILEBROWSER.GetInitScript()
    return [[
        fileBrowserApp.init(windowId);
    ]]
end

function FILEBROWSER.GetJavaScript()
    return [[
var fileBrowserApp = {
    instances: {},
    cleanupBound: false,

    init: function(windowId) {
        var initialPath = (window.programInitialPaths && window.programInitialPaths[windowId]) || 'C:/';
        var instance = {
            windowId: windowId,
            selectionManagerId: 'filebrowser-' + windowId,
            currentPath: this.normalizeFolderPath(initialPath),
            allFiles: [],
            filteredFiles: []
        };

        this.instances[windowId] = instance;
        this.bindCleanup();
        this.bindEvents(windowId);
        this.initSelectionManager(windowId);
        this.registerDragDrop(windowId);
        this.loadFolder(windowId, instance.currentPath);
    },

    bindCleanup: function() {
        if (this.cleanupBound) {
            return;
        }

        this.cleanupBound = true;
        document.addEventListener('windowclosing', function(e) {
            if (e && e.detail && e.detail.id) {
                fileBrowserApp.destroy(e.detail.id);
            }
        });
    },

    normalizeFolderPath: function(path) {
        var normalized = window.normalizePathForNavigation ? window.normalizePathForNavigation(path) : path;
        if (!normalized) {
            normalized = 'C:/';
        }
        if (!normalized.endsWith('/')) {
            normalized = normalized + '/';
        }
        return normalized;
    },

    getInstance: function(windowId) {
        return this.instances[windowId] || null;
    },

    getRootElement: function(windowId) {
        var windowEl = document.getElementById(windowId);
        return windowEl ? windowEl.querySelector('.program-filebrowser') : null;
    },

    getContentElement: function(windowId) {
        var root = this.getRootElement(windowId);
        return root ? root.querySelector('.filebrowser-content') : null;
    },

    getPathInput: function(windowId) {
        var root = this.getRootElement(windowId);
        return root ? root.querySelector('.filebrowser-path-input') : null;
    },

    updateActionState: function(windowId) {
        var instance = this.getInstance(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !root) {
            return;
        }

        var isReadOnly = window.isEditableFilesystemPath
            ? !window.isEditableFilesystemPath(instance.currentPath)
            : (window.isInSystemFolder && window.isInSystemFolder(instance.currentPath));
        var newFileBtn = root.querySelector('.filebrowser-new-file-btn');
        var newFolderBtn = root.querySelector('.filebrowser-new-folder-btn');
        var readOnlyMessage = (window.isInTrashFolder && (window.isInTrashFolder(instance.currentPath) || window.isTrashPath(instance.currentPath)))
            ? 'Trash items are read-only'
            : 'This folder is read-only';

        if (newFileBtn) {
            newFileBtn.disabled = !!isReadOnly;
            newFileBtn.title = isReadOnly ? readOnlyMessage : '';
        }

        if (newFolderBtn) {
            newFolderBtn.disabled = !!isReadOnly;
            newFolderBtn.title = isReadOnly ? readOnlyMessage : '';
        }
    },

    bindEvents: function(windowId) {
        var root = this.getRootElement(windowId);
        if (!root) {
            return;
        }

        var self = this;
        root.querySelectorAll('.filebrowser-drive-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                self.loadFolder(windowId, button.getAttribute('data-drive'));
            });
        });

        var upBtn = root.querySelector('.filebrowser-up-btn');
        if (upBtn) {
            upBtn.addEventListener('click', function() {
                self.goUp(windowId);
            });
        }

        var pathInput = root.querySelector('.filebrowser-path-input');
        if (pathInput) {
            pathInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    self.loadFolder(windowId, pathInput.value);
                }
            });
        }

        var filterInput = root.querySelector('.filebrowser-filter');
        if (filterInput) {
            filterInput.addEventListener('input', function() {
                self.applyFilter(windowId, filterInput.value);
            });
        }

        var newFileBtn = root.querySelector('.filebrowser-new-file-btn');
        if (newFileBtn) {
            newFileBtn.addEventListener('click', function() {
                var instance = self.getInstance(windowId);
                if (!instance) return;
                window.osFileOperations.createNewFile(instance.currentPath, null, function(success) {
                    if (success) {
                        self.refresh(windowId);
                    }
                });
            });
        }

        var newFolderBtn = root.querySelector('.filebrowser-new-folder-btn');
        if (newFolderBtn) {
            newFolderBtn.addEventListener('click', function() {
                var instance = self.getInstance(windowId);
                if (!instance) return;
                window.osFileOperations.createNewFolder(instance.currentPath, null, function(success) {
                    if (success) {
                        self.refresh(windowId);
                    }
                });
            });
        }

        var content = this.getContentElement(windowId);
        if (!content) {
            return;
        }

        content.addEventListener('dblclick', function(e) {
            var item = e.target.closest('.os-file-item');
            if (!item) {
                return;
            }

            var filepath = item.getAttribute('data-filepath');
            var filetype = item.getAttribute('data-filetype');
            if (filetype === 'shortcut' && window.osFileTypeRegistry && window.osFileTypeRegistry.handleShortcut) {
                window.osFileTypeRegistry.handleShortcut(filepath);
                return;
            }
            if (filetype === 'directory') {
                self.loadFolder(windowId, filepath);
                return;
            }

            if (window.osShell && window.osShell.handleFileOpen) {
                window.osShell.handleFileOpen(filepath, {
                    name: item.getAttribute('data-display-name') || item.getAttribute('data-name'),
                    fileType: filetype,
                    type: filetype,
                    program: item.getAttribute('data-program-id') || null,
                    folder: item.getAttribute('data-folder') || null
                }, false);
            }
        });

        content.addEventListener('contextmenu', function(e) {
            e.preventDefault();

            var instance = self.getInstance(windowId);
            var item = e.target.closest('.os-file-item');
            var selectionMgr = window.osSelectionManager ? window.osSelectionManager.get(instance.selectionManagerId) : null;

            if (item) {
                var filepath = item.getAttribute('data-filepath');
                if (selectionMgr && !item.classList.contains('os-item-selected')) {
                    selectionMgr.clearSelection();
                    selectionMgr.selectItem(filepath);
                }

                window.osContextMenuManager.show(e.pageX, e.pageY, {
                    type: 'file',
                    filepath: filepath,
                    filetype: item.getAttribute('data-filetype'),
                    name: item.getAttribute('data-display-name') || item.getAttribute('data-name'),
                    isProtected: item.getAttribute('data-protected') === 'true',
                    location: window.getDriveFromPath(instance.currentPath).toLowerCase() === window.DRIVE_EXTERNAL.toLowerCase() ? 'externaldrive' : 'filebrowser',
                    containerId: instance.selectionManagerId,
                    selectedItems: selectionMgr ? selectionMgr.getSelectedItems() : [filepath],
                    onRefresh: function() {
                        self.refresh(windowId);
                    }
                });
                return;
            }

            window.osContextMenuManager.show(e.pageX, e.pageY, {
                type: 'empty',
                location: window.getDriveFromPath(instance.currentPath).toLowerCase() === window.DRIVE_EXTERNAL.toLowerCase() ? 'externaldrive' : 'filebrowser',
                currentPath: instance.currentPath,
                containerId: instance.selectionManagerId,
                onRefresh: function() {
                    self.refresh(windowId);
                }
            });
        });
    },

    initSelectionManager: function(windowId) {
        var content = this.getContentElement(windowId);
        var instance = this.getInstance(windowId);
        if (!content || !instance || !window.osSelectionManager) {
            return;
        }

        window.osSelectionManager.create(instance.selectionManagerId, content, 'filebrowser');
        content.setAttribute('data-selection-manager-id', instance.selectionManagerId);
    },

    registerDragDrop: function(windowId) {
        var root = this.getRootElement(windowId);
        var content = this.getContentElement(windowId);
        var instance = this.getInstance(windowId);
        if (!root || !content || !instance || !window.osDragDropManager) {
            return;
        }

        window.osDragDropManager.registerFileSourceContainer(content, {
            resourceId: 'filebrowser-source-' + windowId,
            selectionManagerId: instance.selectionManagerId,
            location: 'filebrowser'
        });

        window.osDragDropManager.registerFilesystemDropTarget(root, {
            resourceId: 'filebrowser-target-' + windowId,
            getTargetPath: function() {
                var current = fileBrowserApp.getInstance(windowId);
                return current ? current.currentPath : 'C:/';
            }
        });
    },

    goUp: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var current = this.normalizeFolderPath(instance.currentPath);
        var drive = window.getDriveFromPath(current);
        var withoutDrive = current.substring(drive.length);
        var trimmed = withoutDrive.replace(/\/+$/, '');
        if (!trimmed || trimmed === '/') {
            this.loadFolder(windowId, drive + '/');
            return;
        }

        var segments = trimmed.split('/').filter(function(part) { return part; });
        segments.pop();
        var nextPath = drive + '/' + (segments.length ? segments.join('/') + '/' : '');
        this.loadFolder(windowId, nextPath);
    },

    loadFolder: function(windowId, path) {
        var instance = this.getInstance(windowId);
        var content = this.getContentElement(windowId);
        var root = this.getRootElement(windowId);
        if (!instance || !content || !root) {
            return;
        }

        var normalizedPath = this.normalizeFolderPath(path);
        instance.currentPath = normalizedPath;

        var pathInput = this.getPathInput(windowId);
        if (pathInput) {
            pathInput.value = normalizedPath;
        }

        root.querySelectorAll('.filebrowser-drive-btn').forEach(function(button) {
            button.classList.toggle('active', normalizedPath.indexOf(button.getAttribute('data-drive')) === 0);
        });
        this.updateActionState(windowId);

        content.innerHTML = '<div class="filebrowser-loading">Loading...</div>';

        window.filesystem.listDirectory(normalizedPath, function(files) {
            instance.allFiles = Array.isArray(files) ? files.slice() : [];
            instance.filteredFiles = instance.allFiles.slice();
            fileBrowserApp.render(windowId);
            fileBrowserApp.updateWindowTitle(windowId);
        });
    },

    updateWindowTitle: function(windowId) {
        var instance = this.getInstance(windowId);
        var windowEl = document.getElementById(windowId);
        if (!instance || !windowEl) {
            return;
        }

        var titleEl = windowEl.querySelector('.os-window-title');
        if (titleEl) {
            titleEl.textContent = 'File Browser - ' + instance.currentPath;
        }
    },

    applyFilter: function(windowId, filterText) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }

        var query = String(filterText || '').toLowerCase().trim();
        if (!query) {
            instance.filteredFiles = instance.allFiles.slice();
        } else {
            instance.filteredFiles = instance.allFiles.filter(function(file) {
                return String(file.displayName || file.name || '').toLowerCase().indexOf(query) !== -1;
            });
        }

        this.render(windowId);
    },

    render: function(windowId) {
        var instance = this.getInstance(windowId);
        var content = this.getContentElement(windowId);
        if (!instance || !content) {
            return;
        }

        if (!instance.filteredFiles.length) {
            content.innerHTML = '<div class="filebrowser-empty">This folder is empty</div>';
            return;
        }

        var html = '<div class="filebrowser-file-list">';
        instance.filteredFiles.forEach(function(file) {
            var isDirectory = file.type === 'directory' || file.fileType === 'directory';
            var filepath = instance.currentPath + file.name + (isDirectory ? '/' : '');
            var fileData = {
                name: file.name,
                displayName: file.displayName || file.name,
                filepath: filepath,
                path: filepath,
                fileType: file.fileType || file.type,
                type: file.fileType || file.type,
                icon: file.icon,
                programId: file.programId || file.program,
                folder: file.folder || null,
                protected: file.protected || file.readOnly || false
            };
            html += window.osFileItemRenderer.renderFileItem(fileData, 'filebrowser');
        });
        html += '</div>';
        content.innerHTML = html;
        if (window.osFileItemRenderer && window.osFileItemRenderer.hydrateImagePreviews) {
            window.osFileItemRenderer.hydrateImagePreviews(content);
        }
    },

    refresh: function(windowId) {
        var instance = this.getInstance(windowId);
        if (!instance) {
            return;
        }
        this.loadFolder(windowId, instance.currentPath);
    },

    refreshPath: function(path) {
        var normalized = this.normalizeFolderPath(path);
        if (window.osFileItemRenderer && window.osFileItemRenderer.invalidatePreviewCache) {
            window.osFileItemRenderer.invalidatePreviewCache(normalized);
        }
        Object.keys(this.instances).forEach(function(windowId) {
            var instance = fileBrowserApp.getInstance(windowId);
            if (instance && fileBrowserApp.normalizeFolderPath(instance.currentPath) === normalized) {
                fileBrowserApp.refresh(windowId);
            }
        });
    },

    destroy: function(windowId) {
        var instance = this.instances[windowId];
        if (!instance) {
            return;
        }

        if (window.osSelectionManager) {
            window.osSelectionManager.destroy(instance.selectionManagerId);
        }

        delete this.instances[windowId];
    }
};
]]
end

function FILEBROWSER.GetCSS()
    return [[
.program-filebrowser {
    display: flex;
    height: 100%;
    min-height: 0;
    background: var(--color-window-bg, #2d2d2d);
}

.filebrowser-sidebar {
    width: 150px;
    padding: 12px;
    border-right: 1px solid var(--color-window-border, #444);
    background: var(--color-sidebar-bg, #202020);
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.filebrowser-drive-btn {
    width: 100%;
    padding: 10px 12px;
    text-align: left;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-button-muted-bg, #2e2e2e);
    color: var(--color-text-primary, #fff);
    cursor: pointer;
}

.filebrowser-drive-btn.active {
    background: var(--color-button-bg, #3b74b5);
    border-color: var(--color-accent, #5e9be3);
    color: var(--color-text-on-button, #ffffff);
}

.filebrowser-main {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    background: var(--color-window-bg, #252525);
}

.filebrowser-toolbar {
    display: flex;
    gap: 8px;
    padding: 12px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: var(--color-window-bg, #334055);
    align-items: center;
    color: var(--color-text-on-primary-surface, #ffffff);
}

.filebrowser-toolbar .btn {
    padding: 8px 12px;
    border: 1px solid var(--color-button-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-muted-bg, #2f2f2f);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    font-family: inherit;
}

.filebrowser-toolbar .btn:hover {
    background: var(--color-button-hover-bg, #3a3a3a);
    border-color: var(--color-accent, #555);
}

.filebrowser-toolbar .btn:active {
    background: var(--color-accent-active, #262626);
}

.filebrowser-toolbar .btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.filebrowser-path-input,
.filebrowser-filter {
    padding: 8px 10px;
    border: 1px solid var(--color-window-border, #444);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-input-bg, #1f1f1f);
    color: var(--color-text-primary, #fff);
}

.filebrowser-path-input {
    flex: 1.5;
}

.filebrowser-filter {
    flex: 1;
}

.filebrowser-content {
    flex: 1;
    overflow: auto;
    padding: 12px;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
}

.filebrowser-file-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, 80px);
    grid-auto-rows: 90px;
    gap: 16px;
}

.filebrowser-item:hover {
    background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.3));
    border-radius: var(--radius-ui-small, 4px);
}

.filebrowser-item:hover .os-item-label {
    border-radius: var(--radius-ui-small, 4px);
}

.filebrowser-loading,
.filebrowser-empty {
    padding: 32px;
    text-align: center;
    color: var(--color-text-secondary, #9a9a9a);
}
]]
end

return {
    title = "File Browser",
    icon = "📁",
    width = 810,
    height = 500,
    getContent = FILEBROWSER.GetContent,
    getInitScript = FILEBROWSER.GetInitScript,
    getJavaScript = FILEBROWSER.GetJavaScript,
    getCSS = FILEBROWSER.GetCSS
}
