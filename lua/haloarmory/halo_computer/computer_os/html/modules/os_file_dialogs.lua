local MODULE = {}

function MODULE.GetCSS()
    return [[
.os-file-dialog-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.55);
    z-index: 22000;
}

.os-file-dialog {
    position: fixed;
    width: min(760px, calc(100vw - 48px));
    height: min(520px, calc(100vh - 48px));
    background: #202020;
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: var(--radius-ui, 8px);
    box-shadow: 0 18px 48px rgba(0, 0, 0, 0.45);
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.os-file-dialog-header,
.os-file-dialog-footer {
    padding: 12px 14px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(255, 255, 255, 0.03);
}

.os-file-dialog-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    cursor: move;
}

.os-file-dialog-title {
    color: #fff;
    font-size: 15px;
    font-weight: 600;
}

.os-file-dialog-close {
    width: 30px;
    height: 30px;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: var(--radius-ui-small, 4px);
    background: rgba(255, 255, 255, 0.06);
    color: #fff;
    cursor: pointer;
}

.os-file-dialog-close:hover {
    background: rgba(255, 255, 255, 0.12);
    border-color: rgba(255, 255, 255, 0.2);
}

.os-file-dialog-body {
    flex: 1;
    min-height: 0;
    display: flex;
}

.os-file-dialog-sidebar {
    width: 150px;
    padding: 12px;
    border-right: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(255, 255, 255, 0.025);
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.os-file-dialog-drive-btn {
    width: 100%;
    padding: 10px 12px;
    text-align: left;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: var(--radius-ui, 6px);
    background: rgba(255, 255, 255, 0.04);
    color: #fff;
    cursor: pointer;
}

.os-file-dialog-drive-btn.active {
    background: rgba(102, 166, 255, 0.25);
    border-color: rgba(102, 166, 255, 0.55);
}

.os-file-dialog-drive-btn:hover {
    background: rgba(255, 255, 255, 0.08);
}

.os-file-dialog-main {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
}

.os-file-dialog-toolbar {
    display: flex;
    gap: 8px;
    padding: 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    align-items: center;
}

.os-file-dialog-button {
    padding: 8px 12px;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: var(--radius-ui-small, 4px);
    background: rgba(255, 255, 255, 0.06);
    color: #fff;
    cursor: pointer;
    font-family: inherit;
}

.os-file-dialog-button:hover {
    background: rgba(255, 255, 255, 0.12);
    border-color: rgba(255, 255, 255, 0.2);
}

.os-file-dialog-button:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.os-file-dialog-button-primary {
    background: rgba(102, 166, 255, 0.28);
    border-color: rgba(102, 166, 255, 0.55);
}

.os-file-dialog-button-primary:hover {
    background: rgba(102, 166, 255, 0.38);
    border-color: rgba(140, 190, 255, 0.72);
}

.os-file-dialog-path,
.os-file-dialog-filter,
.os-file-dialog-filename,
.os-file-dialog-extension {
    padding: 8px 10px;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: var(--radius-ui-small, 4px);
    background: rgba(0, 0, 0, 0.28);
    color: #fff;
}

.os-file-dialog-path {
    flex: 1.5;
}

.os-file-dialog-filter {
    flex: 1;
}

.os-file-dialog-content {
    flex: 1;
    min-height: 0;
    overflow: auto;
    padding: 12px;
}

.os-file-dialog-empty,
.os-file-dialog-loading {
    padding: 30px 16px;
    text-align: center;
    color: rgba(255, 255, 255, 0.6);
}

.os-file-dialog-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, 100px);
    gap: 16px;
}

.os-file-dialog-list .os-file-item.os-item-selected {
    background: rgba(102, 166, 255, 0.18);
    border-radius: var(--radius-ui, 6px);
}

.os-file-dialog-footer {
    border-bottom: none;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
    display: flex;
    gap: 10px;
    align-items: center;
}

.os-file-dialog-name-group {
    flex: 1;
    display: flex;
    gap: 8px;
    align-items: center;
    min-width: 0;
}

.os-file-dialog-filename {
    flex: 1;
    min-width: 0;
}

.os-file-dialog-extension {
    width: 112px;
    flex: 0 0 112px;
}

.os-file-dialog-actions {
    display: flex;
    gap: 10px;
}

.os-file-dialog-readonly {
    margin-right: auto;
    color: rgba(255, 196, 110, 0.95);
    font-size: 12px;
}
]]
end

function MODULE.GetJavaScript()
    return [[
window.osFileDialogs = {
    activeDialog: null,
    allowedExtensions: [
        '.image',
        '.txt', '.dat', '.json', '.xml', '.csv', '.dem', '.vcd', '.gma',
        '.mdl', '.phy', '.vvd', '.vtx', '.ani', '.vtf', '.vmt',
        '.png', '.jpg', '.jpeg', '.mp3', '.wav', '.ogg'
    ],

    normalizeFolderPath: function(path) {
        var normalized = window.normalizePathForNavigation ? window.normalizePathForNavigation(path) : (path || 'C:/');
        if (!normalized.endsWith('/')) {
            normalized += '/';
        }
        return normalized;
    },

    isSystemPath: function(path) {
        var normalized = this.normalizeFolderPath(path).toLowerCase();
        return normalized === 'c:/.system/' || normalized.indexOf('c:/.system/') === 0;
    },

    normalizeExtension: function(extension) {
        var ext = String(extension || '').trim().toLowerCase();
        if (!ext) {
            return '';
        }
        if (ext.charAt(0) !== '.') {
            ext = '.' + ext;
        }
        return this.allowedExtensions.indexOf(ext) >= 0 ? ext : '';
    },

    getAllowedExtensions: function(extensions) {
        var source = Array.isArray(extensions) && extensions.length ? extensions : this.allowedExtensions;
        var seen = {};
        var normalized = [];

        for (var i = 0; i < source.length; i++) {
            var ext = this.normalizeExtension(source[i]);
            if (ext && !seen[ext]) {
                seen[ext] = true;
                normalized.push(ext);
            }
        }

        if (!normalized.length) {
            normalized.push('.txt');
        }

        return normalized;
    },

    splitFileName: function(filename) {
        var rawName = String(filename || '').trim();
        if (!rawName) {
            return {
                baseName: '',
                extension: ''
            };
        }

        var lowerName = rawName.toLowerCase();
        var matchedExtension = '';
        for (var i = 0; i < this.allowedExtensions.length; i++) {
            var extension = this.allowedExtensions[i];
            if (lowerName.endsWith(extension) && extension.length > matchedExtension.length) {
                matchedExtension = extension;
            }
        }

        return {
            baseName: matchedExtension ? rawName.slice(0, -matchedExtension.length) : rawName,
            extension: matchedExtension
        };
    },

    sanitizeFileName: function(filename, extension, allowedExtensions) {
        var normalizedExtensions = this.getAllowedExtensions(allowedExtensions);
        var normalizedExtension = this.normalizeExtension(extension) || normalizedExtensions[0];
        var baseName = String(filename || '');

        if (window.osFilenameRules) {
            var validation = window.osFilenameRules.validateBaseName(baseName);
            baseName = validation.normalizedValue;
        } else {
            baseName = String(baseName || '').toLowerCase();
            baseName = baseName.replace(/\s+/g, '_');
            baseName = baseName.replace(/[^a-z0-9_.-]/g, '');
            baseName = baseName.replace(/^\.+/, '');
            baseName = baseName.replace(/^_+/, '').replace(/_+$/, '');
            baseName = baseName.replace(/_+/g, '_');
        }

        if (!baseName) {
            baseName = 'untitled';
        }

        return baseName + normalizedExtension;
    },

    getDisplayName: function(filename) {
        var rawName = String(filename || '');
        if (!rawName) {
            return '';
        }

        if (/\.shortcut\.dat$/i.test(rawName)) {
            return rawName.replace(/\.shortcut\.dat$/i, '');
        }

        if (/\.image\.dat$/i.test(rawName)) {
            return rawName.replace(/\.image\.dat$/i, '.image').replace(/\.(png|jpg|jpeg)\.image$/i, '.image');
        }

        if (/\.image$/i.test(rawName)) {
            return rawName;
        }

        if (/\.txt$/i.test(rawName)) {
            return rawName.replace(/\.txt$/i, '');
        }

        return rawName.replace(/\.[^.]+$/i, '');
    },

    isVisibleSaveEntry: function(file) {
        if (!file) {
            return false;
        }

        var fileType = String(file.fileType || file.type || '').toLowerCase();
        return fileType !== 'shortcut' && fileType !== 'program';
    },

    close: function() {
        if (!this.activeDialog) {
            return;
        }

        if (typeof this.activeDialog.dragCleanup === 'function') {
            this.activeDialog.dragCleanup();
            this.activeDialog.dragCleanup = null;
        }

        if (this.activeDialog.overlay && this.activeDialog.overlay.parentNode) {
            this.activeDialog.overlay.parentNode.removeChild(this.activeDialog.overlay);
        }

        this.activeDialog = null;
        window._saveDialogCurrentFolder = null;
        window._saveDialogLoadFolder = null;
    },

    showOpen: function(options) {
        options = options || {};
        this.close();
        var requestedPath = options.folder || options.initialPath || 'C:/desktop/';

        var state = {
            mode: 'open',
            title: options.title || 'Open...',
            confirmLabel: options.confirmLabel || 'Open',
            initialPath: this.normalizeFolderPath(requestedPath),
            currentPath: this.normalizeFolderPath(requestedPath),
            filter: '',
            selectedPath: null,
            allFiles: [],
            filteredFiles: [],
            allowedExtensions: this.getAllowedExtensions(options.allowedExtensions),
            onOpen: typeof options.onOpen === 'function' ? options.onOpen : function() {},
            overlay: null,
            dialog: null,
            dragCleanup: null
        };

        var overlay = document.createElement('div');
        overlay.className = 'os-file-dialog-overlay';
        overlay.innerHTML = '' +
            '<div class="os-file-dialog">' +
                '<div class="os-file-dialog-header">' +
                    '<div class="os-file-dialog-title">' + escapeHtml(state.title) + '</div>' +
                    '<button class="os-file-dialog-close" type="button">x</button>' +
                '</div>' +
                '<div class="os-file-dialog-body">' +
                    '<div class="os-file-dialog-sidebar">' +
                        '<button class="os-file-dialog-drive-btn active" data-drive="C:/">C:/</button>' +
                        '<button class="os-file-dialog-drive-btn" data-drive="ExternalDrive:/">ExternalDrive:/</button>' +
                    '</div>' +
                    '<div class="os-file-dialog-main">' +
                        '<div class="os-file-dialog-toolbar">' +
                            '<button class="os-file-dialog-up os-file-dialog-button" type="button">Up</button>' +
                            '<input type="text" class="os-file-dialog-path" />' +
                            '<input type="text" class="os-file-dialog-filter" placeholder="Filter..." />' +
                        '</div>' +
                        '<div class="os-file-dialog-content"><div class="os-file-dialog-loading">Loading...</div></div>' +
                    '</div>' +
                '</div>' +
                '<div class="os-file-dialog-footer">' +
                    '<div class="os-file-dialog-readonly" style="display:none;"></div>' +
                    '<div class="os-file-dialog-actions" style="margin-left:auto;">' +
                        '<button class="os-file-dialog-button" type="button" data-action="cancel">Cancel</button>' +
                        '<button class="os-file-dialog-button os-file-dialog-button-primary" type="button" data-action="open">' + escapeHtml(state.confirmLabel) + '</button>' +
                    '</div>' +
                '</div>' +
            '</div>';

        document.body.appendChild(overlay);
        state.overlay = overlay;
        state.dialog = overlay.querySelector('.os-file-dialog');
        this.activeDialog = state;

        var self = this;
        var pathInput = overlay.querySelector('.os-file-dialog-path');
        var filterInput = overlay.querySelector('.os-file-dialog-filter');
        pathInput.value = state.currentPath;

        overlay.addEventListener('mousedown', function(e) {
            if (e.target === overlay) {
                self.close();
            }
        });

        this.centerDialog();
        this.bindDragging();

        overlay.querySelector('.os-file-dialog-close').addEventListener('click', function() {
            self.close();
        });

        overlay.querySelector('[data-action="cancel"]').addEventListener('click', function() {
            self.close();
        });

        overlay.querySelector('[data-action="open"]').addEventListener('click', function() {
            self.confirmOpen();
        });

        overlay.querySelector('.os-file-dialog-up').addEventListener('click', function() {
            self.goUp();
        });

        overlay.querySelectorAll('.os-file-dialog-drive-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                self.loadFolder(button.getAttribute('data-drive'));
            });
        });

        pathInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                self.loadFolder(pathInput.value);
            }
        });

        filterInput.addEventListener('input', function() {
            if (!self.activeDialog) {
                return;
            }
            self.activeDialog.filter = filterInput.value || '';
            self.applyFilter();
        });

        this.loadFolder(state.currentPath);

        setTimeout(function() {
            if (filterInput) {
                filterInput.focus();
            }
        }, 10);
    },

    showSaveAs: function(options) {
        options = options || {};
        this.close();
        var requestedPath = options.folder || options.initialPath || 'C:/desktop/';

        var state = {
            title: options.title || 'Save As...',
            confirmLabel: options.confirmLabel || 'Save',
            initialPath: this.normalizeFolderPath(requestedPath),
            currentPath: this.normalizeFolderPath(requestedPath),
            defaultName: options.defaultName || '',
            filename: '',
            selectedExtension: '',
            filter: '',
            selectedPath: null,
            allFiles: [],
            filteredFiles: [],
            allowedExtensions: this.getAllowedExtensions(options.allowedExtensions),
            onSave: typeof options.onSave === 'function' ? options.onSave : function() {},
            overlay: null,
            dialog: null,
            dragCleanup: null
        };

        var initialParts = this.splitFileName(state.defaultName);
        state.filename = initialParts.baseName || state.defaultName || '';
        state.selectedExtension = this.normalizeExtension(options.defaultExtension) || initialParts.extension || state.allowedExtensions[0];
        if (state.allowedExtensions.indexOf(state.selectedExtension) === -1) {
            state.selectedExtension = state.allowedExtensions[0];
        }

        var overlay = document.createElement('div');
        overlay.className = 'os-file-dialog-overlay';
        overlay.innerHTML = '' +
            '<div class="os-file-dialog">' +
                '<div class="os-file-dialog-header">' +
                    '<div class="os-file-dialog-title">' + escapeHtml(state.title) + '</div>' +
                    '<button class="os-file-dialog-close" type="button">x</button>' +
                '</div>' +
                '<div class="os-file-dialog-body">' +
                    '<div class="os-file-dialog-sidebar">' +
                        '<button class="os-file-dialog-drive-btn active" data-drive="C:/">C:/</button>' +
                        '<button class="os-file-dialog-drive-btn" data-drive="ExternalDrive:/">ExternalDrive:/</button>' +
                    '</div>' +
                    '<div class="os-file-dialog-main">' +
                        '<div class="os-file-dialog-toolbar">' +
                            '<button class="os-file-dialog-up os-file-dialog-button" type="button">Up</button>' +
                            '<input type="text" class="os-file-dialog-path" />' +
                            '<input type="text" class="os-file-dialog-filter" placeholder="Filter..." />' +
                            '<button class="os-file-dialog-new-folder os-file-dialog-button" type="button">New Folder</button>' +
                        '</div>' +
                        '<div class="os-file-dialog-content"><div class="os-file-dialog-loading">Loading...</div></div>' +
                    '</div>' +
                '</div>' +
                '<div class="os-file-dialog-footer">' +
                    '<div class="os-file-dialog-readonly" style="display:none;">This location is read-only.</div>' +
                    '<div class="os-file-dialog-name-group">' +
                        '<input type="text" class="os-file-dialog-filename" placeholder="File name" />' +
                        '<select class="os-file-dialog-extension"></select>' +
                    '</div>' +
                    '<div class="os-file-dialog-actions">' +
                        '<button class="os-file-dialog-button" type="button" data-action="cancel">Cancel</button>' +
                        '<button class="os-file-dialog-button os-file-dialog-button-primary" type="button" data-action="save">' + escapeHtml(state.confirmLabel) + '</button>' +
                    '</div>' +
                '</div>' +
            '</div>';

        document.body.appendChild(overlay);
        state.overlay = overlay;
        state.dialog = overlay.querySelector('.os-file-dialog');
        this.activeDialog = state;

        var self = this;
        var pathInput = overlay.querySelector('.os-file-dialog-path');
        var filterInput = overlay.querySelector('.os-file-dialog-filter');
        var filenameInput = overlay.querySelector('.os-file-dialog-filename');
        var extensionSelect = overlay.querySelector('.os-file-dialog-extension');

        pathInput.value = state.currentPath;
        filenameInput.value = state.filename;
        extensionSelect.innerHTML = state.allowedExtensions.map(function(ext) {
            return '<option value="' + escapeHtml(ext) + '">' + escapeHtml(ext) + '</option>';
        }).join('');
        extensionSelect.value = state.selectedExtension;

        overlay.addEventListener('mousedown', function(e) {
            if (e.target === overlay) {
                self.close();
            }
        });

        this.centerDialog();
        this.bindDragging();

        overlay.querySelector('.os-file-dialog-close').addEventListener('click', function() {
            self.close();
        });

        overlay.querySelector('[data-action="cancel"]').addEventListener('click', function() {
            self.close();
        });

        overlay.querySelector('[data-action="save"]').addEventListener('click', function() {
            self.confirmSave();
        });

        overlay.querySelector('.os-file-dialog-up').addEventListener('click', function() {
            self.goUp();
        });

        overlay.querySelector('.os-file-dialog-new-folder').addEventListener('click', function() {
            self.createFolder();
        });

        overlay.querySelectorAll('.os-file-dialog-drive-btn').forEach(function(button) {
            button.addEventListener('click', function() {
                self.loadFolder(button.getAttribute('data-drive'));
            });
        });

        pathInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                self.loadFolder(pathInput.value);
            }
        });

        filterInput.addEventListener('input', function() {
            if (!self.activeDialog) {
                return;
            }
            self.activeDialog.filter = filterInput.value || '';
            self.applyFilter();
        });

        extensionSelect.addEventListener('change', function() {
            if (!self.activeDialog) {
                return;
            }
            self.activeDialog.selectedExtension = self.normalizeExtension(extensionSelect.value) || self.activeDialog.allowedExtensions[0];
        });

        filenameInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                self.confirmSave();
            } else if (e.key === 'Escape') {
                e.preventDefault();
                self.close();
            }
        });

        window._saveDialogLoadFolder = function(path) {
            if (self.activeDialog) {
                self.loadFolder(path);
            }
        };

        this.loadFolder(state.currentPath);

        setTimeout(function() {
            if (filenameInput) {
                filenameInput.focus();
                filenameInput.select();
            }
        }, 10);
    },

    centerDialog: function() {
        if (!this.activeDialog || !this.activeDialog.dialog) {
            return;
        }

        var dialog = this.activeDialog.dialog;
        var rect = dialog.getBoundingClientRect();
        var left = Math.max(24, Math.round((window.innerWidth - rect.width) / 2));
        var top = Math.max(24, Math.round((window.innerHeight - rect.height) / 2));

        dialog.style.left = left + 'px';
        dialog.style.top = top + 'px';
    },

    clampDialogPosition: function(left, top) {
        if (!this.activeDialog || !this.activeDialog.dialog) {
            return { left: left, top: top };
        }

        var dialog = this.activeDialog.dialog;
        var rect = dialog.getBoundingClientRect();
        var minVisible = 56;
        var minLeft = Math.min(24, Math.max(0, window.innerWidth - rect.width));
        var maxLeft = Math.max(minLeft, window.innerWidth - minVisible);
        var minTop = 24;
        var maxTop = Math.max(minTop, window.innerHeight - minVisible);

        return {
            left: Math.min(Math.max(left, minLeft), maxLeft),
            top: Math.min(Math.max(top, minTop), maxTop)
        };
    },

    bindDragging: function() {
        if (!this.activeDialog || !this.activeDialog.dialog) {
            return;
        }

        var self = this;
        var state = this.activeDialog;
        var dialog = state.dialog;
        var header = dialog.querySelector('.os-file-dialog-header');
        if (!header) {
            return;
        }

        var onMouseMove = null;
        var onMouseUp = null;

        var startDrag = function(e) {
            if (e.button !== 0) {
                return;
            }

            if (e.target.closest('button, input')) {
                return;
            }

            e.preventDefault();

            var rect = dialog.getBoundingClientRect();
            var offsetX = e.clientX - rect.left;
            var offsetY = e.clientY - rect.top;

            onMouseMove = function(moveEvent) {
                var clamped = self.clampDialogPosition(
                    moveEvent.clientX - offsetX,
                    moveEvent.clientY - offsetY
                );

                dialog.style.left = clamped.left + 'px';
                dialog.style.top = clamped.top + 'px';
            };

            onMouseUp = function() {
                document.removeEventListener('mousemove', onMouseMove);
                document.removeEventListener('mouseup', onMouseUp);
                onMouseMove = null;
                onMouseUp = null;
            };

            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
        };

        header.addEventListener('mousedown', startDrag);

        state.dragCleanup = function() {
            header.removeEventListener('mousedown', startDrag);
            if (onMouseMove) {
                document.removeEventListener('mousemove', onMouseMove);
            }
            if (onMouseUp) {
                document.removeEventListener('mouseup', onMouseUp);
            }
        };
    },

    updateChrome: function() {
        if (!this.activeDialog) {
            return;
        }

        var state = this.activeDialog;
        var overlay = state.overlay;
        var readOnly = this.isSystemPath(state.currentPath);

        overlay.querySelector('.os-file-dialog-path').value = state.currentPath;
        overlay.querySelectorAll('.os-file-dialog-drive-btn').forEach(function(button) {
            button.classList.toggle('active', state.currentPath.toLowerCase().indexOf(button.getAttribute('data-drive').toLowerCase()) === 0);
        });

        var readOnlyLabel = overlay.querySelector('.os-file-dialog-readonly');
        var newFolderBtn = overlay.querySelector('.os-file-dialog-new-folder');
        if (readOnlyLabel) {
            readOnlyLabel.style.display = readOnly && newFolderBtn ? 'block' : 'none';
        }
        if (newFolderBtn) {
            newFolderBtn.disabled = readOnly;
        }
    },

    goUp: function() {
        if (!this.activeDialog) {
            return;
        }

        var current = this.normalizeFolderPath(this.activeDialog.currentPath);
        var drive = window.getDriveFromPath(current);
        var withoutDrive = current.substring(drive.length);
        var trimmed = withoutDrive.replace(/\/+$/, '');
        if (!trimmed || trimmed === '/') {
            this.loadFolder(drive + '/');
            return;
        }

        var segments = trimmed.split('/').filter(function(part) { return part; });
        segments.pop();
        this.loadFolder(drive + '/' + (segments.length ? segments.join('/') + '/' : ''));
    },

    createFolder: function() {
        if (!this.activeDialog) {
            return;
        }

        if (this.isSystemPath(this.activeDialog.currentPath)) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('System folders are read-only', 'warning', 2000);
            }
            return;
        }

        var self = this;
        if (window.osFileOperations && window.osFileOperations.createNewFolder) {
            window.osFileOperations.createNewFolder(this.activeDialog.currentPath, null, function(success, folderPath) {
                if (success) {
                    self.loadFolder(self.activeDialog.currentPath);
                    if (folderPath) {
                        self.activeDialog.selectedPath = folderPath;
                    }
                }
            });
        }
    },

    loadFolder: function(path) {
        if (!this.activeDialog || !window.filesystem) {
            return;
        }

        var state = this.activeDialog;
        state.currentPath = this.normalizeFolderPath(path);
        state.selectedPath = null;
        state.allFiles = [];
        state.filteredFiles = [];
        window._saveDialogCurrentFolder = state.currentPath;

        this.updateChrome();

        var content = state.overlay.querySelector('.os-file-dialog-content');
        content.innerHTML = '<div class="os-file-dialog-loading">Loading...</div>';

        window.filesystem.listDirectory(state.currentPath, function(files) {
            if (!window.osFileDialogs.activeDialog || window.osFileDialogs.activeDialog !== state) {
                return;
            }

            state.allFiles = Array.isArray(files) ? files.slice() : [];
            window.osFileDialogs.applyFilter();
        });
    },

    applyFilter: function() {
        if (!this.activeDialog) {
            return;
        }

        var state = this.activeDialog;
        var query = String(state.filter || '').toLowerCase().trim();
        var visibleFiles = state.allFiles.filter(function(file) {
            var isDirectory = file.type === 'directory' || file.fileType === 'directory';
            if (state.mode === 'open') {
                if (isDirectory) {
                    return true;
                }
                var fileName = String(file.name || '').toLowerCase();
                var displayName = String(file.displayName || '').toLowerCase();
                var fileType = String(file.fileType || file.type || '').toLowerCase();
                return state.allowedExtensions.some(function(ext) {
                    if (fileName.endsWith(ext) || displayName.endsWith(ext)) {
                        return true;
                    }

                    if (fileType === 'image' && (ext === '.image' || ext === '.png' || ext === '.jpg' || ext === '.jpeg')) {
                        return displayName.endsWith(ext);
                    }

                    return false;
                });
            }
            return window.osFileDialogs.isVisibleSaveEntry(file);
        });

        if (!query) {
            state.filteredFiles = visibleFiles.slice();
        } else {
            state.filteredFiles = visibleFiles.filter(function(file) {
                return String(file.displayName || file.name || '').toLowerCase().indexOf(query) !== -1;
            });
        }

        state.filteredFiles.sort(function(a, b) {
            var aDir = a.type === 'directory' || a.fileType === 'directory';
            var bDir = b.type === 'directory' || b.fileType === 'directory';
            if (aDir !== bDir) {
                return aDir ? -1 : 1;
            }
            return String(a.displayName || a.name || '').localeCompare(String(b.displayName || b.name || ''));
        });

        this.render();
    },

    render: function() {
        if (!this.activeDialog) {
            return;
        }

        var state = this.activeDialog;
        var content = state.overlay.querySelector('.os-file-dialog-content');

        if (!state.filteredFiles.length) {
            content.innerHTML = '<div class="os-file-dialog-empty">This folder is empty</div>';
            return;
        }

        var html = '<div class="os-file-dialog-list">';
        state.filteredFiles.forEach(function(file) {
            var isDirectory = file.type === 'directory' || file.fileType === 'directory';
            var filepath = state.currentPath + file.name + (isDirectory ? '/' : '');
            html += window.osFileItemRenderer.renderFileItem({
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
            }, 'filebrowser');
        });
        html += '</div>';

        content.innerHTML = html;
        if (window.osFileItemRenderer && window.osFileItemRenderer.hydrateImagePreviews) {
            window.osFileItemRenderer.hydrateImagePreviews(content);
        }

        var self = this;
        content.querySelectorAll('.os-file-item').forEach(function(item) {
            item.addEventListener('click', function() {
                content.querySelectorAll('.os-file-item').forEach(function(other) {
                    other.classList.remove('os-item-selected');
                });
                item.classList.add('os-item-selected');

                var filepath = item.getAttribute('data-filepath');
                var filetype = item.getAttribute('data-filetype');
                state.selectedPath = filepath;
                if (state.mode === 'open') {
                    return;
                }
                if (filetype !== 'directory') {
                    var parts = self.splitFileName(item.getAttribute('data-name') || '');
                    state.overlay.querySelector('.os-file-dialog-filename').value = parts.baseName || '';
                    state.selectedExtension = state.allowedExtensions.indexOf(parts.extension) >= 0 ? parts.extension : state.allowedExtensions[0];
                    state.overlay.querySelector('.os-file-dialog-extension').value = state.selectedExtension;
                }
            });

            item.addEventListener('dblclick', function() {
                var filepath = item.getAttribute('data-filepath');
                var filetype = item.getAttribute('data-filetype');
                if (filetype === 'directory') {
                    self.loadFolder(filepath);
                    return;
                }

                if (state.mode === 'open') {
                    state.selectedPath = filepath;
                    self.confirmOpen();
                    return;
                }

                var parts = self.splitFileName(item.getAttribute('data-name') || '');
                state.overlay.querySelector('.os-file-dialog-filename').value = parts.baseName || '';
                state.selectedExtension = state.allowedExtensions.indexOf(parts.extension) >= 0 ? parts.extension : state.allowedExtensions[0];
                state.overlay.querySelector('.os-file-dialog-extension').value = state.selectedExtension;
                self.confirmSave();
            });
        });
    },

    confirmSave: function() {
        if (!this.activeDialog) {
            return;
        }

        var state = this.activeDialog;
        var filenameInput = state.overlay.querySelector('.os-file-dialog-filename');
        var extensionSelect = state.overlay.querySelector('.os-file-dialog-extension');
        var rawFilename = String(filenameInput.value || '').trim();
        var selectedExtension = this.normalizeExtension(extensionSelect.value) || state.allowedExtensions[0];

        if (!rawFilename) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Enter a file name', 'warning', 2000);
            }
            return;
        }

        if (this.isSystemPath(state.currentPath)) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('System folders are read-only', 'warning', 2000);
            }
            return;
        }

        var finalName = this.sanitizeFileName(rawFilename, selectedExtension, state.allowedExtensions);
        var finalPath = this.normalizeFolderPath(state.currentPath) + finalName;
        var self = this;

        window.filesystem.listDirectory(state.currentPath, function(files) {
            var existing = null;
            var finalDisplayName = self.getDisplayName(finalName);
            (files || []).forEach(function(file) {
                var fileName = String(file.name || '').toLowerCase();
                var displayName = String(file.displayName || '').toLowerCase();
                if (!existing && (fileName === finalName.toLowerCase() || displayName === finalDisplayName.toLowerCase())) {
                    existing = file;
                }
            });

            var finish = function() {
                state.onSave(finalPath, self.getDisplayName(finalName), finalName);
                self.close();
            };

            if (existing && !confirm('Overwrite "' + finalName + '"?')) {
                return;
            }

            finish();
        });
    },

    confirmOpen: function() {
        if (!this.activeDialog) {
            return;
        }

        var state = this.activeDialog;
        var selectedPath = String(state.selectedPath || '');
        if (!selectedPath) {
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Select a file to open', 'warning', 2000);
            }
            return;
        }

        if (selectedPath.endsWith('/')) {
            this.loadFolder(selectedPath);
            return;
        }

        state.onOpen(selectedPath);
        this.close();
    }
};
]]
end

return MODULE
