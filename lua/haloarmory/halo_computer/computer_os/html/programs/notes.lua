-- Notes Program - Markdown-enabled note editor (Notepad)
local NOTES = {}

function NOTES.GetContent()
    return [[
<div class="program-notes">
    <div class="notes-header-bar">
        <div class="notes-menu-dropdown">
            <button class="notes-menu-btn" id="notes-file-menu-btn">File ▼</button>
            <div class="notes-dropdown-menu" id="notes-file-menu">
                <div class="notes-menu-item" onclick="notesApp.newNote()">New Note</div>
                <div class="notes-menu-item" onclick="notesApp.saveNote()">Save</div>
                <div class="notes-menu-item" onclick="notesApp.saveNoteAs()">Save As...</div>
                <div class="notes-menu-separator"></div>
                <div class="notes-menu-item" onclick="notesApp.loadNote()">Load...</div>
            </div>
        </div>
        <button class="notes-save-btn" id="notes-save-btn" onclick="notesApp.saveNote()" style="display: none;">Save</button>
        <button class="notes-discard-btn" id="notes-discard-btn" onclick="notesApp.discardChanges()" style="display: none;">Discard</button>
        <button class="notes-mode-btn" id="notes-mode-btn" onclick="notesApp.toggleMode()">Preview</button>
    </div>
    <div class="notes-formatting-toolbar" id="notes-formatting-toolbar" style="display: none;">
        <button class="notes-format-btn" onclick="notesApp.formatText('bold')" title="Bold">B</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('italic')" title="Italic">I</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('underline')" title="Underline">U</button>
        <div class="notes-toolbar-separator"></div>
        <button class="notes-format-btn" onclick="notesApp.formatText('h1')" title="Heading 1">H1</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('h2')" title="Heading 2">H2</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('h3')" title="Heading 3">H3</button>
        <div class="notes-toolbar-separator"></div>
        <button class="notes-format-btn" onclick="notesApp.formatText('bullet')" title="Bullet List">• List</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('numbered')" title="Numbered List">1. List</button>
        <button class="notes-format-btn" onclick="notesApp.formatText('code')" title="Code Block">Code</button>
    </div>
    <div class="notes-editor-container">
        <textarea id="notes-editor" class="notes-editor" placeholder="Start typing your note here... Markdown is supported!&#10;&#10;Example:&#10;# Heading&#10;**Bold text**&#10;*Italic text*&#10;- List item"></textarea>
        <div id="notes-preview" class="notes-preview"></div>
    </div>
</div>
]]
end

function NOTES.GetInitScript()
    return [[
        notesApp.init(windowId);
        // Make notesApp globally accessible for file opening
        window.notesApp = notesApp;
        
        // Register text file handler (empty extension)
        if (window.osFileTypeRegistry) {
            window.osFileTypeRegistry.registerProgram('', 'notes');
        }
    ]]
end

function NOTES.GetJavaScript()
    return [=[
var notesApp = {
    currentFilePath: null,
    currentFileName: null,
    currentFileExtension: '.txt',
    editor: null,
    preview: null,
    windowId: null,
    isEditMode: true,
    hasUnsavedChanges: false,
    savedContent: '',
    lastSaveFolder: 'C:/',
    currentFileIsDetached: false,
    missingBackingFile: false,
    closeAfterSave: false,  // Flag to close window after save completes
    supportedExtensions: ['.txt', '.dat', '.json', '.xml', '.csv', '.dem', '.vcd', '.gma', '.mdl', '.phy', '.vvd', '.vtx', '.ani', '.vtf', '.vmt', '.png', '.jpg', '.jpeg', '.mp3', '.wav', '.ogg'],
    
    init: function(windowId) {
        var self = this;
        this.windowId = windowId;
        var root = this.getRootElement();
        this.editor = this.queryElement('#notes-editor');
        this.preview = this.queryElement('#notes-preview');
        
        // Store instance reference for this window
        window['notesApp_' + windowId] = this;
        this.setAsActiveInstance();
        
        if (this.editor) {
            this.editor.addEventListener('input', function() {
                self.onContentChange();
                self.updatePreview();
            });
        }

        if (root) {
            root.addEventListener('mousedown', function() {
                self.setAsActiveInstance();
            });
            root.addEventListener('focusin', function() {
                self.setAsActiveInstance();
            });
        }
        
        // Setup dropdown menu
        this.setupDropdown();
        
        // Listen for filesystem changes to detect if current file was deleted/renamed
        document.addEventListener('filesystemsynced', function() {
            // When filesystem syncs, check if our current file still exists
            if (self.currentFilePath) {
                window.filesystem.readFile(self.currentFilePath, function(content) {
                    if (content === null || content === undefined) {
                        // File no longer exists - clear currentFilePath
                        // This will cause the next save to create a new file with the same name
                        self.currentFilePath = null;
                        self.missingBackingFile = true;
                        self.currentFileIsDetached = false;
                        // Keep currentFileName so save will use the same name
                    }
                });
            }
        });
        
        // Check for pending file open
        setTimeout(function() {
            var handledPendingOpen = false;
            var windowEl = document.getElementById(windowId);
            if (windowEl) {
                var pendingFileId = windowEl.getAttribute('data-pending-file');
                if (pendingFileId && window.pendingFileOpen && window.pendingFileOpen[pendingFileId]) {
                    var fileData = window.pendingFileOpen[pendingFileId];
                    self.openFile(fileData.path, fileData.content, fileData.displayName, fileData.editMode);
                    delete window.pendingFileOpen[pendingFileId];
                    windowEl.removeAttribute('data-pending-file');
                    handledPendingOpen = true;
                }
            }
            
            // Also check for simple pendingFileOpen (backwards compatibility)
            if (window.pendingFileOpen &&
                (window.pendingFileOpen.path !== undefined || window.pendingFileOpen.content !== undefined || window.pendingFileOpen.displayName !== undefined) &&
                !window.pendingFileOpen[windowId]) {
                var pfo = window.pendingFileOpen;
                self.openFile(pfo.path, pfo.content, pfo.displayName, pfo.editMode);
                window.pendingFileOpen = null;
                handledPendingOpen = true;
            }

            if (handledPendingOpen) {
                return;
            }
            
            // Check for program initial path (from osShell.openProgram)
            if (window.programInitialPaths && window.programInitialPaths[windowId]) {
                var filePath = window.programInitialPaths[windowId];
                var editMode = window.programEditModes && window.programEditModes[windowId];
                
                // Load file content
                if (window.filesystem && filePath) {
                    window.filesystem.readFile(filePath, function(content) {
                        if (content !== null && content !== undefined) {
                            // Get display name from path
                            var pathParts = filePath.split('/');
                            var fileName = self.splitFileName(pathParts[pathParts.length - 1]).baseName;
                            self.openFile(filePath, content, fileName, editMode);
                        } else {
                            // File doesn't exist or couldn't be read - open in edit mode
                            self.openFile(null, '', null, true);
                        }
                    });
                } else {
                    // No file path - open in edit mode
                    self.openFile(null, '', null, true);
                }
            } else {
                // No file provided - open in edit mode
                self.openFile(null, '', null, true);
            }
        }, 100);
        
        // Intercept close button to warn about unsaved changes
        setTimeout(function() {
            var windowEl = document.getElementById(windowId);
            if (windowEl) {
                var closeBtn = windowEl.querySelector('.os-window-close');
                if (closeBtn) {
                    var originalOnclick = closeBtn.getAttribute('onclick');
                    closeBtn.removeAttribute('onclick');
                    closeBtn.addEventListener('click', function(e) {
                        e.stopPropagation();
                        e.preventDefault();
                        
                        if (self.hasUnsavedChanges) {
                            self.showCloseDialog();
                        } else {
                            self.closeWindow();
                        }
                        
                        return false;
                    });
                }
            }
        }, 100);
        
        // Update window title initially
        this.updateWindowTitle();
        
        // Add to taskbar
        this.addToTaskbar();
        
        // Listen for window closing event (in case window is closed via window manager)
        document.addEventListener('windowclosing', function(e) {
            if (e.detail && e.detail.id === windowId) {
                self.removeFromTaskbar();
                if (window.notesApp && window.notesApp.unregisterInstance) {
                    window.notesApp.unregisterInstance(windowId);
                }
            }
        });
    },

    getRootElement: function() {
        return this.windowId ? document.getElementById(this.windowId) : null;
    },

    queryElement: function(selector) {
        var root = this.getRootElement();
        return root ? root.querySelector(selector) : null;
    },

    setAsActiveInstance: function() {
        if (window.notesApp && window.notesApp.setActiveWindowId) {
            window.notesApp.setActiveWindowId(this.windowId);
        }
    },

    updateActionButtons: function() {
        var saveBtn = this.queryElement('#notes-save-btn');
        var discardBtn = this.queryElement('#notes-discard-btn');
        var shouldShow = this.isEditMode || this.hasUnsavedChanges;

        [saveBtn, discardBtn].forEach(function(button) {
            if (!button) {
                return;
            }

            button.style.display = shouldShow ? 'block' : 'none';
            button.disabled = !this.hasUnsavedChanges;
        }.bind(this));
    },
    
    addToTaskbar: function() {
        if (!this.windowId) return;
        
        var taskbar = document.getElementById('os-taskbar-programs');
        if (!taskbar) {
            // Taskbar not ready, try again later
            var self = this;
            setTimeout(function() {
                self.addToTaskbar();
            }, 100);
            return;
        }
        
        // Check if already added
        if (taskbar.querySelector('[data-window-id="' + this.windowId + '"]')) {
            return;
        }
        
        var button = document.createElement('button');
        button.className = 'os-taskbar-program';
        button.setAttribute('data-window-id', this.windowId);
        button.style.cssText = 'display: flex; align-items: center; gap: 8px; padding: 4px 12px; background: var(--color-button-muted-bg, #3a3a3a); border: 1px solid var(--color-window-border, #555); color: var(--color-text-on-button, #fff); cursor: pointer; border-radius: var(--radius-ui-small, 4px); font-size: 12px;';
        
        var icon = document.createElement('span');
        icon.textContent = '📝';
        icon.style.cssText = 'font-size: 16px;';
        
        var label = document.createElement('span');
        label.className = 'os-taskbar-program-label';
        var fileName = this.currentFileName || 'untitled';
        label.textContent = 'Notes - ' + fileName;
        
        button.appendChild(icon);
        button.appendChild(label);
        
        var self = this;
        button.addEventListener('click', function() {
            var windowEl = document.getElementById(self.windowId);
            if (windowEl) {
                if (window.windowManager) {
                    if (window.windowManager.windows[self.windowId] && window.windowManager.windows[self.windowId].minimized) {
                        window.windowManager.minimize(self.windowId);
                    } else {
                        window.windowManager.makeActive(self.windowId);
                    }
                }
            }
        });
        
        taskbar.appendChild(button);
    },
    
    removeFromTaskbar: function() {
        if (!this.windowId) return;
        
        var taskbar = document.getElementById('os-taskbar-programs');
        if (!taskbar) return;
        
        var button = taskbar.querySelector('[data-window-id="' + this.windowId + '"]');
        if (button) {
            button.remove();
        }
    },
    
    setupDropdown: function() {
        var menuBtn = this.queryElement('#notes-file-menu-btn');
        var menu = this.queryElement('#notes-file-menu');
        
        if (!menuBtn || !menu) return;
        
        var self = this;
        var isOpen = false;
        
        var closeMenu = function() {
            menu.style.display = 'none';
            isOpen = false;
        };
        
        menuBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            isOpen = !isOpen;
            if (isOpen) {
                menu.style.display = 'block';
            } else {
                closeMenu();
            }
        });
        
        // Close menu when clicking on any menu item
        var menuItems = menu.querySelectorAll('.notes-menu-item');
        menuItems.forEach(function(item) {
            item.addEventListener('click', function() {
                closeMenu();
            });
        });
        
        document.addEventListener('click', function(e) {
            if (!menu.contains(e.target) && e.target !== menuBtn) {
                closeMenu();
            }
        });
    },
    
    toggleMode: function() {
        // Don't toggle if we're being called to sync UI state
        if (arguments[0] === false) {
            // Force sync without toggling
            var targetMode = arguments[1];
            this.isEditMode = targetMode;
        } else {
            this.isEditMode = !this.isEditMode;
        }
        
        var editor = this.queryElement('#notes-editor');
        var preview = this.queryElement('#notes-preview');
        var toolbar = this.queryElement('#notes-formatting-toolbar');
        var modeBtn = this.queryElement('#notes-mode-btn');
        
        if (this.isEditMode) {
            if (editor) editor.style.display = 'block';
            if (preview) preview.style.display = 'none';
            if (toolbar) toolbar.style.display = 'flex';
            if (modeBtn) modeBtn.textContent = 'Preview';
        } else {
            if (editor) editor.style.display = 'none';
            if (preview) preview.style.display = 'block';
            if (toolbar) toolbar.style.display = 'none';
            if (modeBtn) modeBtn.textContent = 'Edit';
            this.updatePreview();
        }

        this.updateActionButtons();
    },
    
    formatText: function(format) {
        var editor = this.editor;
        if (!editor) return;
        
        var start = editor.selectionStart;
        var end = editor.selectionEnd;
        var selectedText = editor.value.substring(start, end);
        var beforeText = editor.value.substring(0, start);
        var afterText = editor.value.substring(end);
        
        var formatted = '';
        
        switch(format) {
            case 'bold':
                formatted = '**' + (selectedText || 'text') + '**';
                break;
            case 'italic':
                formatted = '*' + (selectedText || 'text') + '*';
                break;
            case 'underline':
                formatted = '<u>' + (selectedText || 'text') + '</u>';
                break;
            case 'h1':
                formatted = '# ' + (selectedText || 'Heading 1');
                break;
            case 'h2':
                formatted = '## ' + (selectedText || 'Heading 2');
                break;
            case 'h3':
                formatted = '### ' + (selectedText || 'Heading 3');
                break;
            case 'bullet':
                if (selectedText) {
                    var lines = selectedText.split('\n');
                    formatted = lines.map(function(line) { return '- ' + line; }).join('\n');
                } else {
                    formatted = '- List item';
                }
                break;
            case 'numbered':
                if (selectedText) {
                    var lines = selectedText.split('\n');
                    formatted = lines.map(function(line, i) { return (i + 1) + '. ' + line; }).join('\n');
                } else {
                    formatted = '1. List item';
                }
                break;
            case 'code':
                formatted = '`' + (selectedText || 'code') + '`';
                break;
        }
        
        editor.value = beforeText + formatted + afterText;
        editor.focus();
        
        // Set cursor position after formatted text
        var newPos = start + formatted.length;
        editor.setSelectionRange(newPos, newPos);
        
        this.onContentChange();
        this.updatePreview();
    },
    
    updatePreview: function() {
        if (!this.preview || !this.editor) return;
        var markdown = this.editor.value;
        
        // Simple markdown parsing (basic implementation)
        var html = markdown
            .replace(/^# (.*$)/gim, '<h1>$1</h1>')
            .replace(/^## (.*$)/gim, '<h2>$1</h2>')
            .replace(/^### (.*$)/gim, '<h3>$1</h3>')
            .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/gim, '<em>$1</em>')
            .replace(/`(.*?)`/gim, '<code>$1</code>')
            .replace(/<u>(.*?)<\/u>/gim, '<u>$1</u>')
            .replace(/^- (.*$)/gim, '<li>$1</li>')
            .replace(/^(\d+)\. (.*$)/gim, '<li>$2</li>')
            .replace(/\n/gim, '<br>');
        
        // Wrap list items
        html = html.replace(/(<li>.*?<\/li>)/gim, function(match) {
            if (!match.includes('<ul>')) {
                return '<ul>' + match + '</ul>';
            }
            return match;
        });
        
        this.preview.innerHTML = html || '<p style="color: var(--color-text-secondary, #666);">Preview will appear here...</p>';
    },
    
    onContentChange: function() {
        var currentContent = this.editor ? this.editor.value : '';
        if (currentContent !== this.savedContent) {
            this.hasUnsavedChanges = true;
        } else {
            this.hasUnsavedChanges = false;
        }
        this.updateActionButtons();
        this.updateWindowTitle();
    },
    
    updateWindowTitle: function() {
        if (!this.windowId) return;
        var windowEl = document.getElementById(this.windowId);
        if (!windowEl) return;
        
        var titleEl = windowEl.querySelector('.os-window-title');
        if (!titleEl) return;
        
        var fileName = this.currentFileName || 'untitled';
        var title = 'Notes - ' + fileName;
        if (this.hasUnsavedChanges) {
            title += ' *';
        }
        
        titleEl.textContent = title;
        
        // Also update taskbar if it exists
        this.updateTaskbar();
    },
    
    updateTaskbar: function() {
        if (!this.windowId) return;
        
        // Find taskbar button for this window
        var taskbar = document.getElementById('os-taskbar-programs');
        if (!taskbar) return;
        
        var button = taskbar.querySelector('[data-window-id="' + this.windowId + '"]');
        if (button) {
            var fileName = this.currentFileName || 'untitled';
            var title = 'Notes - ' + fileName;
            if (this.hasUnsavedChanges) {
                title += ' *';
            }
            var label = button.querySelector('.os-taskbar-program-label');
            if (label) {
                label.textContent = title;
            }
        }
    },

    normalizeExtension: function(extension) {
        var ext = String(extension || '').trim().toLowerCase();
        if (!ext) {
            return '.txt';
        }

        if (ext.charAt(0) !== '.') {
            ext = '.' + ext;
        }

        return this.supportedExtensions.indexOf(ext) >= 0 ? ext : '.txt';
    },

    splitFileName: function(filename) {
        var rawName = String(filename || '').trim();
        if (!rawName) {
            return {
                baseName: '',
                extension: '.txt'
            };
        }

        var lowerName = rawName.toLowerCase();
        var matchedExtension = '';
        for (var i = 0; i < this.supportedExtensions.length; i++) {
            var extension = this.supportedExtensions[i];
            if (lowerName.endsWith(extension) && extension.length > matchedExtension.length) {
                matchedExtension = extension;
            }
        }

        return {
            baseName: matchedExtension ? rawName.slice(0, -matchedExtension.length) : rawName,
            extension: this.normalizeExtension(matchedExtension || this.currentFileExtension || '.txt')
        };
    },

    sanitizeSaveTarget: function(filePath, fallbackExtension) {
        var pathParts = String(filePath || '').split('/');
        var fileName = pathParts.pop() || 'untitled';
        var parts = this.splitFileName(fileName);
        var validation = window.osFilenameRules
            ? window.osFilenameRules.validateBaseName(parts.baseName)
            : { normalizedValue: parts.baseName };
        var baseName = validation.normalizedValue;

        if (!baseName) {
            baseName = 'untitled';
        }

        var extension = this.normalizeExtension(parts.extension || fallbackExtension || '.txt');
        var sanitizedFileName = baseName + extension;
        var sanitizedPath = pathParts.join('/') + (pathParts.length > 0 ? '/' : '') + sanitizedFileName;

        return {
            filePath: sanitizedPath,
            displayName: baseName,
            extension: extension
        };
    },
    
    newNote: function() {
        if (this.hasUnsavedChanges) {
            if (!confirm('You have unsaved changes. Create a new note anyway?')) {
                return;
            }
        }
        
        this.editor.value = '';
        this.currentFilePath = null;
        this.currentFileName = null;
        this.currentFileExtension = '.txt';
        this.currentFileIsDetached = false;
        this.missingBackingFile = false;
        this.savedContent = '';
        this.hasUnsavedChanges = false;
        this.updatePreview();
        this.updateActionButtons();
        this.updateWindowTitle();
    },

    discardChanges: function() {
        if (!this.editor) {
            return;
        }

        this.editor.value = this.savedContent || '';
        this.hasUnsavedChanges = false;
        this.updatePreview();
        this.updateActionButtons();
        this.updateWindowTitle();
    },
    
    saveNote: function() {
        // Ensure currentFilePath is valid and sanitized
        if (this.currentFilePath && this.currentFilePath.trim() !== '') {
            // Save to existing file - save directly without checking
            var content = this.editor.value;
            var displayName = this.currentFileName || this.splitFileName(this.currentFilePath.split('/').pop()).baseName;
            this.writeFile(this.currentFilePath, content, displayName);
        } else if (this.currentFileName && this.missingBackingFile) {
            // File was deleted/renamed but we have the name - create new file with same name
            var content = this.editor.value;
            var folder = this.lastSaveFolder || 'C:/';
            if (!folder.endsWith('/')) {
                folder += '/';
            }
            var filePath = folder + this.currentFileName + (this.currentFileExtension || '.txt');
            this.writeFile(filePath, content, this.currentFileName);
        } else {
            // No current file - same as Save As
            this.saveNoteAs();
        }
    },
    
    saveNoteAs: function() {
        var self = this;
        if (window.osFileDialogs && window.osFileDialogs.showSaveAs) {
            window.osFileDialogs.showSaveAs({
                title: 'Save Note As...',
                initialPath: this.lastSaveFolder || 'C:/desktop/',
                defaultName: this.currentFileName || 'untitled',
                defaultExtension: this.currentFileExtension || '.txt',
                allowedExtensions: this.supportedExtensions.slice(),
                onSave: function(filePath, displayName) {
                    self.writeFile(filePath, self.editor.value, displayName);
                }
            });
            return;
        }

        alert('Save dialog is not available');
    },
    
    performSave: function(filePath, displayName) {
        // This function is only used by Save As now
        // Save Note directly calls writeFile for existing files
        var content = this.editor.value;
        this.writeFile(filePath, content, displayName);
    },
    
    writeFile: function(filePath, content, displayName) {
        var self = this;
        
        // Validate filePath
        if (!filePath || filePath.trim() === '') {
            console.error('[Notes] writeFile called with invalid filePath:', filePath);
            alert('Invalid file path. Cannot save file.');
            return;
        }
        
        var contentToSave = content;
        var target = this.sanitizeSaveTarget(filePath, this.currentFileExtension || '.txt');
        var sanitizedPath = target.filePath;

        if (!target.displayName) {
            console.error('[Notes] writeFile: filename became empty after sanitization, original:', filePath);
            alert('Invalid file name. Cannot save file.');
            return;
        }
        
        // Ensure path starts with drive letter or ExternalDrive
        if (!sanitizedPath.match(/^([A-Za-z]:|ExternalDrive:)/)) {
            console.error('[Notes] writeFile: sanitized path missing drive:', sanitizedPath);
            alert('Invalid file path. Cannot save file.');
            return;
        }
        
        window.filesystem.writeFile(sanitizedPath, contentToSave, function(success) {
            if (success) {
                // Update current file info with sanitized path
                self.currentFilePath = sanitizedPath;
                self.currentFileName = displayName || target.displayName;
                self.currentFileExtension = target.extension;
                self.currentFileIsDetached = false;
                self.missingBackingFile = false;
                self.savedContent = content;
                self.hasUnsavedChanges = false;
                self.lastSaveFolder = sanitizedPath.substring(0, sanitizedPath.lastIndexOf('/') + 1);
                self.updateActionButtons();
                self.updateWindowTitle();
                
                // Check if we should close after save
                if (self.closeAfterSave) {
                    self.closeAfterSave = false;
                    setTimeout(function() {
                        self.closeWindow();
                    }, 100);
                }
                // Don't show alert, just update silently
            } else {
                console.error('[Notes] writeFile failed for path:', sanitizedPath);
                alert('Failed to save note');
                self.closeAfterSave = false; // Reset flag on error
            }
        });
    },
    
    
    escapeHtml: function(text) {
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, function(m) { return map[m]; });
    },
    
    showOverwriteDialog: function(filePath, content, displayName) {
        var dialog = document.createElement('div');
        dialog.className = 'notes-overwrite-dialog-overlay';
        dialog.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); z-index: 20001; display: flex; align-items: center; justify-content: center;';
        
        var dialogContent = document.createElement('div');
        dialogContent.className = 'notes-overwrite-dialog';
        dialogContent.style.cssText = 'background: var(--color-window-bg, #2d2d2d); border: 1px solid var(--color-window-border, #555); border-radius: var(--radius-ui, 6px); padding: 20px; min-width: 400px; box-shadow: 0 4px 12px rgba(0,0,0,0.5);';
        
        var message = document.createElement('div');
        message.textContent = 'A file with this name already exists. What would you like to do?';
        message.style.cssText = 'color: var(--color-text-primary, #fff); margin-bottom: 20px; font-size: 14px;';
        
        var buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = 'display: flex; gap: 10px; justify-content: flex-end;';
        
        var self = this;
        
        var overwriteBtn = document.createElement('button');
        overwriteBtn.textContent = 'Overwrite';
        overwriteBtn.style.cssText = 'padding: 8px 16px; background: #d32f2f; border: none; border-radius: var(--radius-ui-small, 4px); color: #fff; cursor: pointer; font-size: 13px;';
        overwriteBtn.onclick = function() {
            dialog.remove();
            self.writeFile(filePath, content, displayName);
        };
        
        var renameBtn = document.createElement('button');
        renameBtn.textContent = 'Pick New Name';
        renameBtn.style.cssText = 'padding: 8px 16px; background: var(--color-button-bg, #0078d4); border: 1px solid var(--color-accent, #005a9e); border-radius: var(--radius-ui-small, 4px); color: var(--color-text-on-button, #fff); cursor: pointer; font-size: 13px;';
        renameBtn.onclick = function() {
            dialog.remove();
            // Show save dialog again to pick new name
            self.saveNoteAs();
        };
        
        var cancelBtn = document.createElement('button');
        cancelBtn.textContent = 'Cancel';
        cancelBtn.style.cssText = 'padding: 8px 16px; background: var(--color-button-muted-bg, #3a3a3a); border: 1px solid var(--color-window-border, #555); border-radius: var(--radius-ui-small, 4px); color: var(--color-text-on-button, #fff); cursor: pointer; font-size: 13px;';
        cancelBtn.onclick = function() {
            dialog.remove();
        };
        
        buttonContainer.appendChild(overwriteBtn);
        buttonContainer.appendChild(renameBtn);
        buttonContainer.appendChild(cancelBtn);
        
        dialogContent.appendChild(message);
        dialogContent.appendChild(buttonContainer);
        dialog.appendChild(dialogContent);
        document.body.appendChild(dialog);
    },
    
    loadNote: function() {
        // Show file browser for loading
        if (osShell && osShell.openProgram) {
            osShell.openProgram('filebrowser');
            alert('Please use File Browser to open a file by double-clicking or right-clicking "Open" or "Edit"');
        }
    },
    
    showCloseDialog: function() {
        var self = this;
        var dialog = document.createElement('div');
        dialog.className = 'notes-close-dialog-overlay';
        dialog.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); z-index: 20001; display: flex; align-items: center; justify-content: center;';
        
        var dialogContent = document.createElement('div');
        dialogContent.className = 'notes-close-dialog';
        dialogContent.style.cssText = 'background: var(--color-window-bg, #2d2d2d); border: 1px solid var(--color-window-border, #555); border-radius: var(--radius-ui, 6px); padding: 20px; min-width: 400px; box-shadow: 0 4px 12px rgba(0,0,0,0.5);';
        
        var message = document.createElement('div');
        message.textContent = 'You have unsaved changes. What would you like to do?';
        message.style.cssText = 'color: var(--color-text-primary, #fff); margin-bottom: 20px; font-size: 14px;';
        
        var buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = 'display: flex; gap: 10px; justify-content: flex-end;';
        
        var cancelBtn = document.createElement('button');
        cancelBtn.textContent = 'Cancel';
        cancelBtn.style.cssText = 'padding: 8px 16px; background: var(--color-button-muted-bg, #3a3a3a); border: 1px solid var(--color-window-border, #555); border-radius: var(--radius-ui-small, 4px); color: var(--color-text-on-button, #fff); cursor: pointer; font-size: 13px;';
        cancelBtn.onclick = function() {
            dialog.remove();
        };
        
        var closeWithoutSavingBtn = document.createElement('button');
        closeWithoutSavingBtn.textContent = 'Close Without Saving';
        closeWithoutSavingBtn.style.cssText = 'padding: 8px 16px; background: #d32f2f; border: 1px solid #b71c1c; border-radius: var(--radius-ui-small, 4px); color: #fff; cursor: pointer; font-size: 13px;';
        closeWithoutSavingBtn.onclick = function() {
            dialog.remove();
            self.closeWindow();
        };
        
        var saveAndCloseBtn = document.createElement('button');
        saveAndCloseBtn.textContent = 'Save & Close';
        saveAndCloseBtn.style.cssText = 'padding: 8px 16px; background: var(--color-button-bg, #0078d4); border: 1px solid var(--color-accent, #005a9e); border-radius: var(--radius-ui-small, 4px); color: var(--color-text-on-button, #fff); cursor: pointer; font-size: 13px;';
        saveAndCloseBtn.onclick = function() {
            dialog.remove();
            // Set flag to close after save
            self.closeAfterSave = true;
            
            // Save first, then close (close will happen in writeFile callback)
            if (self.currentFilePath || (self.currentFileName && self.missingBackingFile)) {
                var content = self.editor.value;
                var displayName = self.currentFileName || 'untitled';
                if (self.currentFilePath) {
                    self.writeFile(self.currentFilePath, content, displayName);
                } else {
                    var folder = self.lastSaveFolder || 'C:/';
                    if (!folder.endsWith('/')) {
                        folder += '/';
                    }
                    var filePath = folder + self.currentFileName + (self.currentFileExtension || '.txt');
                    self.writeFile(filePath, content, displayName);
                }
            } else {
                // No file path or name - use Save As
                // closeAfterSave flag is already set, so close will happen in writeFile callback after Save As completes
                self.saveNoteAs();
            }
        };
        
        buttonContainer.appendChild(cancelBtn);
        buttonContainer.appendChild(closeWithoutSavingBtn);
        buttonContainer.appendChild(saveAndCloseBtn);
        
        dialogContent.appendChild(message);
        dialogContent.appendChild(buttonContainer);
        dialog.appendChild(dialogContent);
        document.body.appendChild(dialog);
        
        // Close on Escape key
        var escapeHandler = function(e) {
            if (e.key === 'Escape') {
                dialog.remove();
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
    },
    
    closeWindow: function() {
        // Remove from taskbar
        this.removeFromTaskbar();
        if (window.notesApp && window.notesApp.unregisterInstance) {
            window.notesApp.unregisterInstance(this.windowId);
        }
        
        // Proceed with close
        if (window.windowManager && window.windowManager.close) {
            window.windowManager.close(this.windowId);
        }
        
        // Also remove from running programs
        if (window.osShell && window.osShell.runningPrograms && window.osShell.runningPrograms['notes']) {
            var index = window.osShell.runningPrograms['notes'].indexOf(this.windowId);
            if (index > -1) {
                window.osShell.runningPrograms['notes'].splice(index, 1);
            }
        }
    },
    
    openFile: function(filePath, content, displayName, editMode) {
        // .txt files contain plain text (no JSON wrapper)
        this.editor.value = content || '';
        
        var target = null;
        if (filePath) {
            target = this.sanitizeSaveTarget(filePath, '.txt');
            filePath = target.filePath;
        } else if (displayName) {
            target = this.splitFileName(displayName);
        }
        
        this.currentFilePath = filePath;
        this.currentFileName = displayName || (target ? (target.displayName || target.baseName) : null);
        this.currentFileExtension = target ? this.normalizeExtension(target.extension) : '.txt';
        this.currentFileIsDetached = !filePath && !!this.currentFileName;
        this.missingBackingFile = false;
        this.savedContent = content || '';
        this.hasUnsavedChanges = false;
        
        // Set mode based on editMode parameter
        // If editMode is explicitly true, use edit mode
        // If editMode is explicitly false or undefined, use view mode (preview)
        var targetMode = editMode === true;
        
        // Update UI - sync without toggling
        this.toggleMode(false, targetMode);
        this.updatePreview();
        this.updateActionButtons();
        this.updateWindowTitle();
    },
    
};

var notesAppPrototype = notesApp;
var notesAppManager = {
    instances: {},
    activeWindowId: null,

    init: function(windowId) {
        var instance = Object.create(notesAppPrototype);
        instance.currentFilePath = null;
        instance.currentFileName = null;
        instance.currentFileExtension = '.txt';
        instance.editor = null;
        instance.preview = null;
        instance.windowId = null;
        instance.isEditMode = true;
        instance.hasUnsavedChanges = false;
        instance.savedContent = '';
        instance.lastSaveFolder = 'C:/';
        instance.currentFileIsDetached = false;
        instance.missingBackingFile = false;
        instance.closeAfterSave = false;

        this.instances[windowId] = instance;
        notesAppPrototype.init.call(instance, windowId);
        this.activeWindowId = windowId;
        return instance;
    },

    unregisterInstance: function(windowId) {
        if (!windowId) {
            return;
        }

        delete this.instances[windowId];
        if (this.activeWindowId === windowId) {
            this.activeWindowId = null;
        }
    },

    setActiveWindowId: function(windowId) {
        if (windowId && this.instances[windowId]) {
            this.activeWindowId = windowId;
        }
    },

    getInstance: function(windowId) {
        if (windowId && this.instances[windowId]) {
            return this.instances[windowId];
        }

        var eventTarget = window.event && (window.event.target || window.event.srcElement);
        var eventWindow = eventTarget && eventTarget.closest ? eventTarget.closest('.os-window') : null;
        if (eventWindow && eventWindow.id && this.instances[eventWindow.id]) {
            this.activeWindowId = eventWindow.id;
            return this.instances[eventWindow.id];
        }

        var activeWindowId = this.activeWindowId || (window.windowManager && window.windowManager.activeWindow);
        if (activeWindowId && this.instances[activeWindowId]) {
            this.activeWindowId = activeWindowId;
            return this.instances[activeWindowId];
        }

        var windowIds = Object.keys(this.instances);
        if (windowIds.length === 1) {
            this.activeWindowId = windowIds[0];
            return this.instances[windowIds[0]];
        }

        return null;
    },

    callInstance: function(methodName, args) {
        var instance = this.getInstance();
        if (!instance || typeof instance[methodName] !== 'function') {
            return;
        }

        instance.setAsActiveInstance();
        return instance[methodName].apply(instance, args || []);
    },

    newNote: function() {
        return this.callInstance('newNote', arguments);
    },

    saveNote: function() {
        return this.callInstance('saveNote', arguments);
    },

    saveNoteAs: function() {
        return this.callInstance('saveNoteAs', arguments);
    },

    loadNote: function() {
        return this.callInstance('loadNote', arguments);
    },

    toggleMode: function() {
        return this.callInstance('toggleMode', arguments);
    },

    formatText: function(format) {
        return this.callInstance('formatText', arguments);
    },

    discardChanges: function() {
        return this.callInstance('discardChanges', arguments);
    }
};

notesApp = notesAppManager;

// Make globally accessible
window.notesApp = notesApp;
]=]
end

function NOTES.GetCSS()
    return [[
.program-notes {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    width: 100%;
    box-sizing: border-box;
    background: var(--color-window-bg, #2d2d2d);
}

.notes-header-bar {
    display: flex;
    padding: 4px 8px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: var(--color-primary-surface-alt, #2d2d2d);
    gap: 8px;
    align-items: center;
    flex-shrink: 0;
}

.notes-menu-dropdown {
    position: relative;
}

.notes-menu-btn {
    padding: 6px 12px;
    background: transparent;
    border: 1px solid transparent;
    color: var(--color-text-on-primary-surface, #fff);
    cursor: pointer;
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
    transition: background 0.15s;
}

.notes-menu-btn:hover {
    background: var(--color-taskbar-item-hover-bg, rgba(255, 255, 255, 0.1));
    border-color: var(--color-window-border, #555);
}

.notes-save-btn {
    padding: 6px 12px;
    background: var(--color-button-bg, #0078d4);
    border: 1px solid var(--color-accent, #005a9e);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
    transition: background 0.15s;
}

.notes-save-btn:hover {
    background: var(--color-button-hover-bg, #106ebe);
}

.notes-discard-btn {
    padding: 6px 12px;
    background: var(--color-button-muted-bg, #3a3a3a);
    border: 1px solid var(--color-window-border, #555);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
    transition: background 0.15s;
}

.notes-discard-btn:hover {
    background: var(--color-button-hover-bg, #4a4a4a);
}

.notes-save-btn:disabled,
.notes-discard-btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.notes-save-btn:disabled:hover {
    background: var(--color-button-bg, #0078d4);
}

.notes-discard-btn:disabled:hover {
    background: var(--color-button-muted-bg, #3a3a3a);
}

.notes-dropdown-menu {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
    margin-top: 4px;
    background: var(--color-window-bg, #2d2d2d);
    border: 1px solid var(--color-window-border, #555);
    border-radius: var(--radius-ui, 6px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    min-width: 150px;
    z-index: 1000;
    padding: 4px 0;
}

.notes-menu-item {
    padding: 8px 16px;
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    font-size: 13px;
    transition: background 0.15s;
}

.notes-menu-item:hover {
    background: var(--color-taskbar-item-hover-bg, rgba(255, 255, 255, 0.1));
}

.notes-menu-separator {
    height: 1px;
    background: var(--color-window-border, #444);
    margin: 4px 0;
}

.notes-mode-btn {
    padding: 6px 12px;
    background: var(--color-button-muted-bg, #3a3a3a);
    border: 1px solid var(--color-window-border, #555);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
    transition: background 0.15s;
    margin-left: auto;
}

.notes-mode-btn:hover {
    background: var(--color-button-hover-bg, #4a4a4a);
}

.notes-formatting-toolbar {
    display: flex;
    padding: 4px 8px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
    gap: 4px;
    align-items: center;
    flex-shrink: 0;
}

.notes-format-btn {
    padding: 4px 8px;
    background: var(--color-button-muted-bg, #3a3a3a);
    border: 1px solid var(--color-window-border, #555);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    border-radius: var(--radius-ui-small, 4px);
    font-size: 11px;
    min-width: 32px;
    transition: background 0.15s;
    font-weight: bold;
}

.notes-format-btn:hover {
    background: var(--color-button-hover-bg, #4a4a4a);
}

.notes-toolbar-separator {
    width: 1px;
    height: 20px;
    background: var(--color-window-border, #444);
    margin: 0 4px;
}

.notes-editor-container {
    flex: 1;
    display: flex;
    position: relative;
    min-height: 0;
    min-width: 0;
    overflow: hidden;
}

.notes-editor {
    flex: 1;
    width: 100%;
    padding: 12px;
    background: var(--color-window-bg, #202020);
    color: var(--color-text-primary, #d4d4d4);
    border: none;
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 14px;
    resize: none;
    outline: none;
}

.notes-preview {
    flex: 1;
    padding: 12px;
    background: var(--color-window-bg, #202020);
    color: var(--color-text-primary, #d4d4d4);
    overflow-y: auto;
    display: none;
    user-select: text;
    -webkit-user-select: text;
}

.notes-preview h1, .notes-preview h2, .notes-preview h3 {
    color: var(--color-accent, #4ec9b0);
    margin-top: 16px;
    margin-bottom: 8px;
}

.notes-preview strong {
    color: var(--color-text-primary, #ce9178);
}

.notes-preview em {
    font-style: italic;
    color: var(--color-text-secondary, #c586c0);
}

.notes-preview code {
    background: var(--color-window-bg, #1e1e1e);
    padding: 2px 4px;
    border-radius: var(--radius-ui-small, 4px);
    font-family: 'Consolas', 'Monaco', monospace;
    color: var(--color-text-primary, #ce9178);
}

.notes-preview ul, .notes-preview ol {
    margin: 8px 0;
    padding-left: 24px;
}

.notes-preview u {
    text-decoration: underline;
}

.notes-save-dialog-overlay,
.notes-overwrite-dialog-overlay {
    /* Styles are inline for z-index control */
}

.notes-save-dialog,
.notes-overwrite-dialog {
    /* Styles are inline for flexibility */
}
]]
end

return {
    title = "Notes",
    icon = "📝",
    width = 600,
    height = 400,
    getContent = NOTES.GetContent,
    getInitScript = NOTES.GetInitScript,
    getJavaScript = NOTES.GetJavaScript,
    getCSS = NOTES.GetCSS
}
