--[[
    File: modules/os_context_menu.lua
    Purpose: Context menu system for right-click interactions
    
    Provides context-sensitive menus for files, folders, and empty space.
    Integrates with selection, clipboard, and file operations managers.
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// CONTEXT MENU MANAGER
// ============================================================================

window.osContextMenuManager = {
    menu: null,
    isOpen: false,
    currentContext: null,
    outsideClickHandler: null,
    
    /**
     * Show context menu at position
     * @param {number} x - X coordinate
     * @param {number} y - Y coordinate
     * @param {Object} context - Menu context object
     */
    show: function(x, y, context) {
        // Hide any existing menu
        this.hide();
        
        // Store context
        this.currentContext = context;
        
        // Create menu element
        var menu = document.createElement('div');
        menu.className = 'os-context-menu';
        menu.style.position = 'fixed';
        menu.style.left = x + 'px';
        menu.style.top = y + 'px';
        menu.style.zIndex = (window.OS_CONSTANTS && window.OS_CONSTANTS.Z_INDEX_CONTEXT_MENU) || 10001;
        
        // Build menu based on context
        if (context.type === 'file') {
            this.buildFileMenu(menu, context);
        } else if (context.type === 'empty') {
            this.buildEmptyMenu(menu, context);
        } else if (context.type === 'startmenu-program') {
            this.buildStartMenuProgramMenu(menu, context);
        }
        
        // Add to document
        document.body.appendChild(menu);
        this.menu = menu;
        this.isOpen = true;
        
        // Adjust position if menu goes off screen
        this.adjustMenuPosition(menu);
        
        // Setup click outside to close
        var self = this;
        window.osCleanup.setTimeout('contextMenu', function() {
            if (self.outsideClickHandler) {
                document.removeEventListener('click', self.outsideClickHandler, true);
                self.outsideClickHandler = null;
            }

            self.outsideClickHandler = function(e) {
                if (!self.menu || !self.menu.contains(e.target)) {
                    e.stopPropagation();
                    e.preventDefault();
                    self.hide();
                    if (self.outsideClickHandler) {
                        document.removeEventListener('click', self.outsideClickHandler, true);
                        self.outsideClickHandler = null;
                    }
                }
            };
            document.addEventListener('click', self.outsideClickHandler, true);
        }, 10);
        
        window.debugLog('[ContextMenu] Shown at', x, y, 'type:', context.type);
    },
    
    /**
     * Build menu for file/folder
     * @param {Element} menu - Menu element
     * @param {Object} context - Context object
     */
    buildFileMenu: function(menu, context) {
        var filepath = context.filepath;
        var filetype = context.filetype || 'file';
        var isProtected = context.isProtected || false;
        var isDirectory = filetype === 'directory';
        var isProgram = filetype === 'program';
        var isShortcut = filetype === 'shortcut';
        var isTrashItem = !!(window.isInTrashFolder && window.isInTrashFolder(filepath));
        var selectedItems = context.selectedItems || [filepath];
        var multipleSelected = selectedItems.length > 1;
        
        // Open
        if (!isProgram) {
            this.addMenuItem(menu, 'Open', function() {
                this.handleOpen(context);
            }.bind(this));
        }
        
        // Program menu
        if (isProgram) {
            this.addMenuItem(menu, 'Open', function() {
                var programId = this.extractProgramId(filepath);
                if (programId && window.osShell) {
                    window.osShell.openProgram(programId);
                }
                this.hide();
            }.bind(this));

            this.addSeparator(menu);
            this.addMenuItem(menu, 'Add Shortcut', function() {
                var programId = this.extractProgramId(filepath);
                var program = window.programRegistry ? window.programRegistry.get(programId) : null;
                if (programId && program) {
                    this.handleAddToDesktop(programId, program);
                    return;
                }
                this.hide();
            }.bind(this));
            return;
        }
        
        // Edit (for files, not directories or programs)
        if (!isDirectory && !isProgram && !multipleSelected && !isTrashItem) {
            this.addMenuItem(menu, 'Edit', function() {
                var programId = window.PROGRAM_NOTES || 'notes';
                if (window.osShell) {
                    window.osShell.openProgram(programId, filepath, true); // true = edit mode
                }
                this.hide();
            }.bind(this));
        }
        
        // Separator
        this.addSeparator(menu);
        
        // Duplicate File (Make a Copy)
        if (!isProtected && !isProgram && !isDirectory && !multipleSelected && !isTrashItem) {
            this.addMenuItem(menu, 'Duplicate File', function() {
                this.handleMakeCopy(context);
            }.bind(this));
        }

        if (!isProtected && !isProgram) {
            this.addMenuItem(menu, 'Cut', function() {
                this.handleClipboardCopy(context, 'cut');
            }.bind(this));

            this.addMenuItem(menu, 'Copy', function() {
                this.handleClipboardCopy(context, 'copy');
            }.bind(this));
        }

        if (!isProtected && !isProgram && isDirectory) {
            this.addMenuItem(menu, 'Paste', function() {
                this.handlePaste(context, filepath);
            }.bind(this), false, !this.canPasteToPath(filepath));
        }
        
        // Separator
        this.addSeparator(menu);
        
        // Rename (single item only)
        if (!isProtected && !isProgram && !multipleSelected && !isTrashItem) {
            this.addMenuItem(menu, 'Rename', function() {
                this.handleRename(context);
            }.bind(this));
        }
        
        // Delete
        if (!isProtected && !isProgram) {
            this.addMenuItem(menu, 'Delete', function() {
                this.handleDelete(context);
            }.bind(this), true); // danger style
        }
        
        // Show item count if multiple selected
        if (multipleSelected) {
            this.addSeparator(menu);
            this.addMenuItem(menu, selectedItems.length + ' items selected', null, false, true);
        }
    },
    
    /**
     * Build menu for Start Menu program item
     * @param {Element} menu - Menu element
     * @param {Object} context - Context object
     */
    buildStartMenuProgramMenu: function(menu, context) {
        var programId = context.programId;
        var program = context.program;
        
        // Open
        this.addMenuItem(menu, 'Open', function() {
            if (window.osShell) {
                window.osShell.openProgram(programId);
                window.osShell.closeStartMenu();
            }
            this.hide();
        }.bind(this));
        
        // Separator
        this.addSeparator(menu);
        
        // Add Shortcut
        this.addMenuItem(menu, 'Add Shortcut', function() {
            this.handleAddToDesktop(programId, program);
        }.bind(this));
    },
    
    /**
     * Build menu for empty space
     * @param {Element} menu - Menu element
     * @param {Object} context - Context object
     */
    buildEmptyMenu: function(menu, context) {
        var location = context.location || 'desktop';
        var currentPath = context.currentPath || window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/');
        var isReadOnlyPath = window.isEditableFilesystemPath ? !window.isEditableFilesystemPath(currentPath) : false;
        
        // New submenu
        var newItem = this.addMenuItem(menu, 'New', null);
        newItem.classList.add('has-submenu');
        var submenu = document.createElement('div');
        submenu.className = 'os-context-submenu';
        newItem.appendChild(submenu);
        
        this.addMenuItem(submenu, 'File', function() {
            this.handleNewFile(currentPath, context);
        }.bind(this), false, isReadOnlyPath);
        this.addMenuItem(submenu, 'Folder', function() {
            this.handleNewFolder(currentPath, context);
        }.bind(this), false, isReadOnlyPath);
        
        // Separator
        this.addSeparator(menu);

        this.addMenuItem(menu, 'Paste', function() {
            this.handlePaste(context, currentPath);
        }.bind(this), false, !this.canPasteToPath(currentPath));
        
        // Refresh
        this.addMenuItem(menu, 'Refresh', function() {
            this.handleRefresh(context);
        }.bind(this));
        
        // Personalize (desktop only)
        if (location === 'desktop') {
            this.addMenuItem(menu, 'Personalize', function() {
                if (window.osShell) {
                    window.osShell.openProgram(window.PROGRAM_SETTINGS || 'settings');
                }
                this.hide();
            }.bind(this));
        }
    },
    
    /**
     * Add menu item
     * @param {Element} menu - Menu element
     * @param {string} label - Item label
     * @param {Function} onClick - Click handler
     * @param {boolean} danger - Danger styling
     * @param {boolean} disabled - Disabled state
     * @returns {Element} Menu item element
     */
    addMenuItem: function(menu, label, onClick, danger, disabled) {
        var item = document.createElement('div');
        item.className = 'os-context-menu-item';
        if (danger) item.classList.add('danger');
        if (disabled) item.classList.add('disabled');
        item.textContent = label;
        
        if (onClick && !disabled) {
            item.addEventListener('click', function(e) {
                e.stopPropagation();
                onClick();
            });
        }
        
        menu.appendChild(item);
        return item;
    },
    
    /**
     * Add separator
     * @param {Element} menu - Menu element
     */
    addSeparator: function(menu) {
        var sep = document.createElement('div');
        sep.className = 'os-context-menu-separator';
        menu.appendChild(sep);
    },
    
    /**
     * Handle Open action
     * @param {Object} context - Context object
     */
    handleOpen: function(context) {
        var filepath = context.filepath;
        var filetype = context.filetype;
        var location = context.location;
        
        if (filetype === 'directory') {
            if (window.osShell) {
                window.osShell.openProgram('filebrowser', filepath);
            }
            this.hide();
            return;
        } else {
            // Open file with appropriate program
            window.debugLog('[ContextMenu] Open file:', filepath);
            // Let the shell handle file opening (false = view mode)
            if (window.osShell && window.osShell.handleFileOpen) {
                window.osShell.handleFileOpen(filepath, {filetype: filetype}, false);
            }
        }
        
        this.hide();
    },
    
    /**
     * Handle Make a Copy (Duplicate File)
     * @param {Object} context - Context object
     */
    handleMakeCopy: function(context) {
        var item = {
            filepath: context.filepath,
            name: context.name || this.getNameFromPath(context.filepath),
            filetype: context.filetype,
            isDirectory: context.filetype === 'directory'
        };
        
        if (window.osFileOperations && window.osFileOperations.makeCopy) {
            window.osFileOperations.makeCopy(item, function(success, newFilepath) {
                if (success) {
                    this.handleRefresh(context);
                }
            }.bind(this));
        }
        
        this.hide();
    },

    handleClipboardCopy: function(context, mode) {
        var items = this.getContextItemsData(context);
        if (!items.length) {
            window.osErrorHandler.showNotification('No valid items selected', 'warning', 2000);
            this.hide();
            return;
        }

        if (window.osShell && window.osShell.setClipboard) {
            window.osShell.setClipboard(mode, items);
            window.osErrorHandler.showNotification(
                (mode === 'cut' ? 'Cut ' : 'Copied ') + items.length + ' item(s)',
                'success',
                2000
            );
        }

        this.hide();
    },

    handlePaste: function(context, targetPath) {
        if (!window.osShell || !window.osShell.hasClipboardItems || !window.osShell.hasClipboardItems()) {
            window.osErrorHandler.showNotification('Clipboard is empty', 'warning', 2000);
            this.hide();
            return;
        }

        var clipboard = window.osShell.getClipboard ? window.osShell.getClipboard() : null;
        if (!clipboard || !clipboard.items || !clipboard.items.length) {
            this.hide();
            return;
        }

        var normalizedTarget = window.osFileOperations && window.osFileOperations.normalizeDirectoryPath
            ? window.osFileOperations.normalizeDirectoryPath(targetPath)
            : targetPath;
        var operation = clipboard.mode === 'cut' ? 'moveItems' : 'copyItems';

        if (!window.osFileOperations || !window.osFileOperations[operation]) {
            window.osErrorHandler.showNotification('Paste is not available', 'error');
            this.hide();
            return;
        }

        window.osFileOperations[operation](clipboard.items, normalizedTarget, function(success) {
            if (success && clipboard.mode === 'cut' && window.osShell && window.osShell.clearClipboard) {
                window.osShell.clearClipboard();
            }

            if (success) {
                this.refreshPathsAfterPaste(clipboard, normalizedTarget, context);
            }
        }.bind(this));

        this.hide();
    },
    
    /**
     * Handle Copy to Desktop
     * @param {Object} context - Context object
     */
    handleCopyToDesktop: function(context) {
        var item = {
            filepath: context.filepath,
            name: context.name || this.getNameFromPath(context.filepath),
            filetype: context.filetype,
            isDirectory: context.filetype === 'directory'
        };
        
        if (window.osFileOperations && window.osFileOperations.copyToDesktop) {
            window.osFileOperations.copyToDesktop(item, function(success, message) {
                if (success) {
                    this.handleRefresh(context);
                    // Refresh desktop if visible
                    if (window.osShell && window.osShell.loadDesktopIcons) {
                        window.osShell.loadDesktopIcons();
                    }
                }
            }.bind(this));
        }
        
        this.hide();
    },
    
    /**
     * Handle Move to Desktop
     * @param {Object} context - Context object
     */
    handleMoveToDesktop: function(context) {
        var item = {
            filepath: context.filepath,
            name: context.name || this.getNameFromPath(context.filepath),
            filetype: context.filetype,
            isDirectory: context.filetype === 'directory'
        };
        
        if (window.osFileOperations && window.osFileOperations.moveToDesktop) {
            window.osFileOperations.moveToDesktop(item, function(success, message) {
                if (success) {
                    this.handleRefresh(context);
                    // Refresh desktop if visible
                    if (window.osShell && window.osShell.loadDesktopIcons) {
                        window.osShell.loadDesktopIcons();
                    }
                }
            }.bind(this));
        }
        
        this.hide();
    },
    
    /**
     * Handle Copy to External
     * @param {Object} context - Context object
     */
    handleCopyToExternal: function(context) {
        var item = {
            filepath: context.filepath,
            name: context.name || this.getNameFromPath(context.filepath),
            filetype: context.filetype,
            isDirectory: context.filetype === 'directory'
        };
        
        if (window.osFileOperations && window.osFileOperations.copyToExternal) {
            window.osFileOperations.copyToExternal(item, function(success, message) {
                if (success) {
                    this.handleRefresh(context);
                    // Refresh external drive if open
                    if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
                        window.fileBrowserApp.refreshPath('ExternalDrive:/');
                    }
                }
            }.bind(this));
        }
        
        this.hide();
    },
    
    /**
     * Handle Move to External
     * @param {Object} context - Context object
     */
    handleMoveToExternal: function(context) {
        var item = {
            filepath: context.filepath,
            name: context.name || this.getNameFromPath(context.filepath),
            filetype: context.filetype,
            isDirectory: context.filetype === 'directory'
        };
        
        if (window.osFileOperations && window.osFileOperations.moveToExternal) {
            window.osFileOperations.moveToExternal(item, function(success, message) {
                if (success) {
                    this.handleRefresh(context);
                    // Refresh external drive if open
                    if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
                        window.fileBrowserApp.refreshPath('ExternalDrive:/');
                    }
                }
            }.bind(this));
        }
        
        this.hide();
    },
    
    /**
     * Handle Rename action
     * @param {Object} context - Context object
     */
    handleRename: function(context) {
        var filepath = context.filepath;
        
        // Find the item element
        var item = this.findItemElement(filepath, context);
        if (!item) {
            window.debugError('[ContextMenu] Item not found for rename:', filepath);
            this.hide();
            return;
        }
        
        // Find label
        var label = item.querySelector('.os-item-label');
        if (!label) {
            window.debugError('[ContextMenu] Label not found for rename');
            this.hide();
            return;
        }
        
        // Start inline editing
        this.startInlineRename(item, label, filepath, context);
        this.hide();
    },
    
    /**
     * Start inline rename
     * @param {Element} item - Item element
     * @param {Element} label - Label element
     * @param {string} filepath - Full filepath
     * @param {Object} context - Context object
     */
    startInlineRename: function(item, label, filepath, context) {
        var originalName = label.textContent;
        var originalSanitized = this.sanitizeFilenameForInput(originalName);
        
        // Get parent directory to check for duplicates
        var parentPath = window.osFileOperations && window.osFileOperations.getParentDirectory
            ? window.osFileOperations.getParentDirectory(filepath)
            : filepath;
        
        // Create inline editor
        var editor = document.createElement('div');
        editor.className = 'os-inline-rename-editor';

        var input = document.createElement('input');
        input.type = 'text';
        input.className = 'os-rename-input';
        input.value = originalSanitized;

        var tooltip = document.createElement('div');
        tooltip.className = 'os-rename-tooltip';

        editor.appendChild(input);
        editor.appendChild(tooltip);

        // Replace label with editor
        label.style.display = 'none';
        item.classList.add('os-item-renaming');
        label.parentNode.insertBefore(editor, label.nextSibling);
        
        // Track if we're finishing rename to prevent double execution
        var isFinishing = false;
        var blurTimeout = null;
        var duplicateCheckTimeout = null;
        var clickOutsideHandler = null;

        var setValidationState = function(isValid, message) {
            input.classList.toggle('os-rename-input-invalid', !isValid);
            tooltip.classList.toggle('visible', !isValid && !!message);
            tooltip.textContent = (!isValid && message) ? message : '';
        };

        var applyNormalizedValue = function() {
            var cursorPos = input.selectionStart || 0;
            var originalValue = input.value;
            var normalizedValue = window.osFilenameRules
                ? window.osFilenameRules.normalizeEditableBaseName(originalValue)
                : originalValue.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_.-]/g, '').replace(/^\.+/, '').replace(/_+/g, '_');

            if (normalizedValue !== originalValue) {
                input.value = normalizedValue;
                var delta = originalValue.length - normalizedValue.length;
                var nextPos = Math.max(0, cursorPos - Math.max(0, delta));
                input.setSelectionRange(nextPos, nextPos);
            }
        };

        var validateCurrentValue = function(done) {
            var validation = window.osFilenameRules
                ? window.osFilenameRules.validateBaseName(input.value)
                : {
                    isValid: !!String(input.value || '').trim(),
                    normalizedValue: String(input.value || '').trim().toLowerCase(),
                    message: 'Invalid name'
                };

            if (!validation.isValid) {
                setValidationState(false, validation.message);
                if (done) done(validation, false);
                return;
            }

            if (validation.normalizedValue === originalSanitized) {
                setValidationState(true, '');
                if (done) done(validation, false);
                return;
            }

            this.checkDuplicateName(parentPath, validation.normalizedValue, filepath, function(isDuplicate) {
                if (isDuplicate) {
                    setValidationState(false, 'A file or folder with this name already exists.');
                } else {
                    setValidationState(true, '');
                }
                if (done) done(validation, isDuplicate);
            });
        }.bind(this);
        
        // Focus and select
        window.osCleanup.setTimeout('rename-focus', function() {
            input.focus();
            input.select();
        }, 10);

        var cancelRename = function() {
            cleanup();
            isFinishing = false;
        };

        // Finish rename function
        var finishRename = function(options) {
            if (isFinishing) return;
            isFinishing = true;
            options = options || {};
            
            // Clear any pending timeouts immediately
            if (blurTimeout) {
                clearTimeout(blurTimeout);
                blurTimeout = null;
            }
            if (duplicateCheckTimeout) {
                clearTimeout(duplicateCheckTimeout);
                duplicateCheckTimeout = null;
            }
            
            // Remove click handler if still active
            if (clickOutsideHandler) {
                document.removeEventListener('mousedown', clickOutsideHandler, true);
                clickOutsideHandler = null;
            }
            
            applyNormalizedValue();

            validateCurrentValue(function(validation, isDuplicate) {
                var newName = validation.normalizedValue;

                if (!validation.isValid || isDuplicate) {
                    if (options.cancelOnInvalid) {
                        cancelRename();
                        return;
                    }
                    isFinishing = false;
                    window.osCleanup.setTimeout('rename-refocus', function() {
                        input.focus();
                        input.select();
                    }, 10);
                    return;
                }

                if (newName === originalSanitized) {
                    cleanup();
                    isFinishing = false;
                    return;
                }

                // Perform rename operation
                if (window.osFileOperations && window.osFileOperations.rename) {
                    window.osFileOperations.rename(filepath, newName, function(success, newFilepath) {
                        if (success) {
                            // Refresh view to show new name
                            this.handleRefresh(context);
                        } else {
                            // Rename failed - show error but don't restore input
                            window.osErrorHandler.showNotification('Failed to rename file', 'error');
                        }
                        // Always cleanup after rename attempt
                        cleanup();
                        isFinishing = false;
                    }.bind(this));
                } else {
                    // Filesystem operations not available
                    window.osErrorHandler.showNotification('Rename function not available', 'error');
                    cleanup();
                    isFinishing = false;
                }
            }.bind(this));
        }.bind(this);
        
        var cleanup = function() {
            // Remove click handler
            if (clickOutsideHandler) {
                document.removeEventListener('mousedown', clickOutsideHandler, true);
                clickOutsideHandler = null;
            }
            if (blurTimeout) {
                clearTimeout(blurTimeout);
                blurTimeout = null;
            }
            if (duplicateCheckTimeout) {
                clearTimeout(duplicateCheckTimeout);
                duplicateCheckTimeout = null;
            }
            if (editor && editor.parentNode) {
                editor.remove();
            }
            if (label) {
                label.style.display = '';
            }
            item.classList.remove('os-item-renaming');
        };
        
        // Real-time input processing: normalize and validate
        input.addEventListener('input', function() {
            applyNormalizedValue();

            if (duplicateCheckTimeout) {
                clearTimeout(duplicateCheckTimeout);
            }

            var validation = window.osFilenameRules
                ? window.osFilenameRules.validateBaseName(input.value)
                : {
                    isValid: !!String(input.value || '').trim(),
                    normalizedValue: String(input.value || '').trim().toLowerCase(),
                    message: 'Invalid name'
                };

            if (!validation.isValid) {
                setValidationState(false, validation.message);
                return;
            }

            if (validation.normalizedValue === originalSanitized) {
                setValidationState(true, '');
                return;
            }

            duplicateCheckTimeout = setTimeout(function() {
                validateCurrentValue();
            }, 150);
        }.bind(this));
        
        // Handle clicks outside the input
        clickOutsideHandler = function(e) {
            // If click is outside the input and not on the input itself
            if (input && input.parentNode && !input.contains(e.target) && e.target !== input && !isFinishing) {
                // Clear blur timeout to prevent double execution
                if (blurTimeout) {
                    clearTimeout(blurTimeout);
                    blurTimeout = null;
                }
                
                // Remove handler first to prevent double execution
                document.removeEventListener('mousedown', clickOutsideHandler, true);
                clickOutsideHandler = null;
                
                // Finish rename - this will set isFinishing flag
                finishRename({ cancelOnInvalid: true });
            }
        };
        
        // Add click outside handler (use capture phase to catch it early)
        setTimeout(function() {
            document.addEventListener('mousedown', clickOutsideHandler, true);
        }, 50);
        
        // Event handlers
        input.addEventListener('blur', function(e) {
            // Clear any pending duplicate check
            if (duplicateCheckTimeout) {
                clearTimeout(duplicateCheckTimeout);
                duplicateCheckTimeout = null;
            }
            
            // Only finish if not already finishing
            if (!isFinishing) {
                // Use a short timeout to allow click events to process first
                // If click handler fires, it will set isFinishing and this will be skipped
                blurTimeout = setTimeout(function() {
                    if (!isFinishing) {
                        // Remove click handler to prevent double execution
                        if (clickOutsideHandler) {
                            document.removeEventListener('mousedown', clickOutsideHandler, true);
                        }
                        finishRename({ cancelOnInvalid: true });
                    }
                }, 150);
            }
        });
        
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                e.stopPropagation();
                
                // Clear any pending timeouts to prevent conflicts
                if (blurTimeout) {
                    clearTimeout(blurTimeout);
                    blurTimeout = null;
                }
                if (duplicateCheckTimeout) {
                    clearTimeout(duplicateCheckTimeout);
                    duplicateCheckTimeout = null;
                }
                
                // Remove click handler to prevent conflicts
                if (clickOutsideHandler) {
                    document.removeEventListener('mousedown', clickOutsideHandler, true);
                    clickOutsideHandler = null;
                }
                
                // Directly call finishRename - this will set isFinishing flag and prevent blur from interfering
                finishRename();
            } else if (e.key === 'Escape') {
                e.preventDefault();
                e.stopPropagation();
                
                // Clear all timeouts
                if (blurTimeout) {
                    clearTimeout(blurTimeout);
                    blurTimeout = null;
                }
                if (duplicateCheckTimeout) {
                    clearTimeout(duplicateCheckTimeout);
                    duplicateCheckTimeout = null;
                }
                
                // Remove click handler
                if (clickOutsideHandler) {
                    document.removeEventListener('mousedown', clickOutsideHandler, true);
                    clickOutsideHandler = null;
                }
                
                // Cancel without saving
                cleanup();
            }
        });
    },
    
    /**
     * Sanitize filename for input (when finishing rename)
     * Converts spaces to _, lowercase, removes invalid characters
     * @param {string} name - Input name
     * @returns {string} Sanitized name
     */
    sanitizeFilenameForInput: function(name) {
        if (!name) return '';
        if (window.osFilenameRules) {
            return window.osFilenameRules.normalizeBaseName(name);
        }
        return String(name || '')
            .trim()
            .toLowerCase()
            .replace(/\s+/g, '_')
            .replace(/[^a-z0-9_.-]/g, '')
            .replace(/^\.+/, '')
            .replace(/^_+/, '')
            .replace(/_+$/, '')
            .replace(/_+/g, '_');
    },
    
    /**
     * Check if a filename already exists in the directory
     * @param {string} parentPath - Parent directory path
     * @param {string} fileName - Filename to check (without extension)
     * @param {string} excludeFilePath - Filepath to exclude from check (current file being renamed)
     * @param {Function} callback - Callback(isDuplicate)
     */
    checkDuplicateName: function(parentPath, fileName, excludeFilePath, callback) {
        if (!window.filesystem) {
            if (callback) callback(false);
            return;
        }
        
        // List directory
        window.filesystem.listDirectory(parentPath, function(files) {
            if (!files || !Array.isArray(files)) {
                if (callback) callback(false);
                return;
            }
            
            // Check if any file (except the one being renamed) has this name
            var fileNameLower = window.osFilenameRules
                ? window.osFilenameRules.normalizeBaseName(fileName)
                : String(fileName || '').toLowerCase();
            var excludeName = excludeFilePath
                ? (window.osFilenameRules
                    ? window.osFilenameRules.normalizeBaseName(excludeFilePath.split('/').pop())
                    : excludeFilePath.split('/').pop().toLowerCase().replace(/\.txt$/, ''))
                : null;
            
            var isDuplicate = files.some(function(file) {
                var fileDisplayName = window.osFilenameRules
                    ? window.osFilenameRules.normalizeBaseName(file.displayName || file.name || '')
                    : (file.displayName || file.name || '').toLowerCase().replace(/\.txt$/, '');
                
                // Skip the file being renamed
                if (excludeName && fileDisplayName === excludeName) {
                    return false;
                }
                
                return fileDisplayName === fileNameLower;
            });
            
            if (callback) callback(isDuplicate);
        });
    },
    
    /**
     * Handle Delete action
     * @param {Object} context - Context object
     */
    handleDelete: function(context) {
        window.debugLog('[ContextMenu] handleDelete called with context:', context);
        
        var selectionMgr = window.osSelectionManager.get(context.containerId);
        window.debugLog('[ContextMenu] Selection manager:', selectionMgr ? 'found' : 'not found', 'containerId:', context.containerId);
        
        var itemsData = [];
        
        if (selectionMgr && selectionMgr.hasSelection()) {
            // Use selected items from selection manager
            itemsData = selectionMgr.getSelectedItemsData();
        } else {
            // No selection manager or no selection - use context item
            // Also check if context has selectedItems array (for multiple items)
            if (context.selectedItems && context.selectedItems.length > 0) {
                // Build items from selectedItems array
                var self = this;
                itemsData = context.selectedItems.map(function(filepath) {
                    // Try to find the item element to get full data
                    var item = self.findItemElement(filepath, context);
                    if (item) {
                        return {
                            filepath: filepath,
                            name: item.getAttribute('data-name') || self.getNameFromPath(filepath),
                            filetype: item.getAttribute('data-filetype') || context.filetype || 'file',
                            isDirectory: (item.getAttribute('data-filetype') || context.filetype) === 'directory'
                        };
                    } else {
                        // Fallback to context data
                        return {
                            filepath: filepath,
                            name: context.name || self.getNameFromPath(filepath),
                            filetype: context.filetype || 'file',
                            isDirectory: context.filetype === 'directory'
                        };
                    }
                });
            } else {
                // Single item from context
                itemsData = [{
                    filepath: context.filepath,
                    name: context.name || this.getNameFromPath(context.filepath),
                    filetype: context.filetype || 'file',
                    isDirectory: context.filetype === 'directory'
                }];
            }
        }
        
        // Validate items data
        if (!itemsData || itemsData.length === 0) {
            window.debugError('[ContextMenu] No items to delete');
            window.osErrorHandler.showNotification('No items selected for deletion', 'error');
            this.hide();
            return;
        }
        
        // Ensure all items have required properties
        itemsData = itemsData.filter(function(item) {
            if (!item || !item.filepath) {
                window.debugWarn('[ContextMenu] Invalid item in delete list:', item);
                return false;
            }
            // Ensure name is set
            if (!item.name) {
                item.name = this.getNameFromPath(item.filepath);
            }
            // Ensure filetype is set
            if (!item.filetype) {
                item.filetype = 'file';
            }
            // Ensure isDirectory is set
            if (item.isDirectory === undefined) {
                item.isDirectory = item.filetype === 'directory';
            }
            return true;
        }.bind(this));
        
        if (itemsData.length === 0) {
            window.debugError('[ContextMenu] No valid items to delete after filtering');
            window.osErrorHandler.showNotification('No valid items selected for deletion', 'error');
            this.hide();
            return;
        }
        
        window.debugLog('[ContextMenu] Final itemsData to delete:', itemsData);
        
        if (window.osFileOperations) {
            window.debugLog('[ContextMenu] Calling osFileOperations.deleteItems');
            window.osFileOperations.deleteItems(itemsData, false, function(success, message) {
                window.debugLog('[ContextMenu] Delete callback - success:', success, 'message:', message);
                if (success) {
                    // Refresh view
                    this.handleRefresh(context);
                }
            }.bind(this));
        } else {
            window.debugError('[ContextMenu] File operations not available');
            window.osErrorHandler.showNotification('Delete function not available', 'error');
        }
        
        this.hide();
    },
    
    /**
     * Handle New File action
     * @param {string} parentPath - Parent directory
     * @param {Object} context - Context object
     */
    handleNewFile: function(parentPath, context) {
        if (window.osFileOperations) {
            window.osFileOperations.createNewFile(parentPath, null, function(success, filepath, displayName) {
                if (success) {
                    // Refresh first
                    this.handleRefresh(context);
                    
                    // Then start rename mode on the new file
                    var self = this;
                    setTimeout(function() {
                        // Find the newly created file element
                        var item = self.findItemElement(filepath, context);
                        if (item) {
                            var label = item.querySelector('.os-item-label');
                            if (label) {
                                // Start rename mode
                                self.startInlineRename(item, label, filepath, context);
                            }
                        }
                    }, 200); // Wait for refresh to complete
                }
            }.bind(this));
        }
        
        this.hide();
    },

    canPasteToPath: function(targetPath) {
        if (!window.osShell || !window.osShell.hasClipboardItems || !window.osShell.hasClipboardItems()) {
            return false;
        }

        var normalizedTarget = window.osFileOperations && window.osFileOperations.normalizeDirectoryPath
            ? window.osFileOperations.normalizeDirectoryPath(targetPath)
            : targetPath;

        if (!normalizedTarget) {
            return false;
        }

        if (window.isRestrictedSystemPath && window.isRestrictedSystemPath(normalizedTarget)) {
            return false;
        }

        return true;
    },

    getContextItemsData: function(context) {
        var selectionMgr = context && context.containerId && window.osSelectionManager
            ? window.osSelectionManager.get(context.containerId)
            : null;

        if (selectionMgr && selectionMgr.hasSelection()) {
            return selectionMgr.getSelectedItemsData();
        }

        if (context && context.selectedItems && context.selectedItems.length) {
            var self = this;
            return context.selectedItems.map(function(filepath) {
                var item = self.findItemElement(filepath, context);
                if (item) {
                    return {
                        filepath: filepath,
                        name: item.getAttribute('data-name') || self.getNameFromPath(filepath),
                        displayName: item.getAttribute('data-display-name') || item.getAttribute('data-name') || self.getNameFromPath(filepath),
                        filename: item.getAttribute('data-filename') || self.getNameFromPath(filepath),
                        filetype: item.getAttribute('data-filetype') || context.filetype || 'file',
                        isDirectory: (item.getAttribute('data-filetype') || context.filetype) === 'directory',
                        isProtected: item.getAttribute('data-protected') === 'true'
                    };
                }

                return {
                    filepath: filepath,
                    name: context.name || self.getNameFromPath(filepath),
                    displayName: context.name || self.getNameFromPath(filepath),
                    filename: self.getNameFromPath(filepath),
                    filetype: context.filetype || 'file',
                    isDirectory: context.filetype === 'directory',
                    isProtected: context.isProtected || false
                };
            });
        }

        if (context && context.filepath) {
            return [{
                filepath: context.filepath,
                name: context.name || this.getNameFromPath(context.filepath),
                displayName: context.name || this.getNameFromPath(context.filepath),
                filename: this.getNameFromPath(context.filepath),
                filetype: context.filetype || 'file',
                isDirectory: context.filetype === 'directory',
                isProtected: context.isProtected || false
            }];
        }

        return [];
    },

    refreshSinglePath: function(path) {
        if (!path) {
            return;
        }

        var normalized = window.osFileOperations && window.osFileOperations.normalizeDirectoryPath
            ? window.osFileOperations.normalizeDirectoryPath(path)
            : path;

        var desktopPath = (window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/')).toLowerCase();
        if (normalized.toLowerCase() === desktopPath) {
            if (window.osShell && window.osShell.loadDesktopIcons) {
                window.osShell.loadDesktopIcons(true);
            }
        }

        if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
            window.fileBrowserApp.refreshPath(normalized);
        }
    },

    refreshPathsAfterPaste: function(clipboard, targetPath, context) {
        this.refreshSinglePath(targetPath);
        this.handleRefresh(context);

        if (clipboard && clipboard.mode === 'cut' && clipboard.items) {
            var refreshed = {};
            clipboard.items.forEach(function(item) {
                var sourcePath = window.osFileOperations && window.osFileOperations.getParentDirectory
                    ? window.osFileOperations.getParentDirectory(item.filepath)
                    : null;
                if (sourcePath && !refreshed[sourcePath]) {
                    refreshed[sourcePath] = true;
                    window.osContextMenuManager.refreshSinglePath(sourcePath);
                }
            });
        }
    },

    handleNewFolder: function(parentPath, context) {
        if (window.osFileOperations && window.osFileOperations.createNewFolder) {
            window.osFileOperations.createNewFolder(parentPath, null, function(success, folderPath) {
                if (success) {
                    this.handleRefresh(context);

                    var self = this;
                    setTimeout(function() {
                        var item = self.findItemElement(folderPath, context);
                        if (item) {
                            var label = item.querySelector('.os-item-label');
                            if (label) {
                                self.startInlineRename(item, label, folderPath, context);
                            }
                        }
                    }, 200);
                }
            }.bind(this));
        }

        this.hide();
    },
    
    
    /**
     * Handle Add to Desktop (from Start Menu)
     * @param {string} programId - Program ID
     * @param {Object} program - Program object
     */
    handleAddToDesktop: function(programId, program) {
        var shortcutName = programId + '.shortcut.dat';
        var shortcutPath = (window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/')) + shortcutName;
        var shortcutContent = JSON.stringify({
            program: programId,
            filename: program.title || program.name || programId,
            icon: program.icon || null
        });
        
        if (window.filesystem) {
            window.filesystem.writeFile(shortcutPath, shortcutContent, function(success) {
                if (success) {
                    window.osErrorHandler.showNotification('Added to Desktop', 'success', 2000);
                    // Refresh desktop
                    if (window.osShell && window.osShell.loadDesktopIcons) {
                        window.osShell.loadDesktopIcons();
                    }
                } else {
                    window.osErrorHandler.showNotification('Failed to add to Desktop', 'error');
                }
            });
        }
        
        this.hide();
    },
    
    /**
     * Handle Refresh action
     * @param {Object} context - Context object
     */
    handleRefresh: function(context) {
        if (typeof context.onRefresh === 'function') {
            context.onRefresh();
        } else if (context.location === 'desktop') {
            if (window.osShell && window.osShell.loadDesktopIcons) {
                window.osShell.loadDesktopIcons();
            }
        } else if (context.location === 'externaldrive') {
            if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
                window.fileBrowserApp.refreshPath('ExternalDrive:/');
            }
        }
        
        this.hide();
    },
    
    /**
     * Hide context menu
     */
    hide: function() {
        if (this.menu) {
            this.menu.remove();
            this.menu = null;
        }
        if (this.outsideClickHandler) {
            document.removeEventListener('click', this.outsideClickHandler, true);
            this.outsideClickHandler = null;
        }
        this.isOpen = false;
        this.currentContext = null;
        window.osCleanup.cleanup('contextMenu');
    },
    
    /**
     * Adjust menu position to keep on screen
     * @param {Element} menu - Menu element
     */
    adjustMenuPosition: function(menu) {
        var rect = menu.getBoundingClientRect();
        var viewportWidth = window.innerWidth;
        var viewportHeight = window.innerHeight;
        
        // Adjust horizontal position
        if (rect.right > viewportWidth) {
            menu.style.left = (viewportWidth - rect.width - 5) + 'px';
        }
        
        // Adjust vertical position
        if (rect.bottom > viewportHeight) {
            menu.style.top = (viewportHeight - rect.height - 5) + 'px';
        }
    },
    
    /**
     * Get name from filepath
     * @param {string} filepath - Full filepath
     * @returns {string} Name only
     */
    getNameFromPath: function(filepath) {
        if (!filepath) return '';
        var parts = filepath.split('/').filter(function(p) { return p; });
        return parts[parts.length - 1] || '';
    },
    
    /**
     * Extract program ID from .exe filepath
     * @param {string} filepath - Full filepath
     * @returns {string} Program ID
     */
    extractProgramId: function(filepath) {
        var name = this.getNameFromPath(filepath);
        return name.replace(/\.exe$/i, '');
    },

    /**
     * Find an item element, scoped to the originating container when available
     * @param {string} filepath - Full filepath
     * @param {Object} context - Context object
     * @returns {Element|null}
     */
    findItemElement: function(filepath, context) {
        if (!filepath) {
            return null;
        }

        var selector = '[data-filepath="' + this.escapeCSSSelector(filepath) + '"]';
        var selectionMgr = context && context.containerId && window.osSelectionManager
            ? window.osSelectionManager.get(context.containerId)
            : null;

        if (selectionMgr && selectionMgr.container) {
            var scopedItem = selectionMgr.container.querySelector(selector);
            if (scopedItem) {
                return scopedItem;
            }
        }

        return document.querySelector(selector);
    },
    
    /**
     * Escape CSS selector
     * @param {string} str - String to escape
     * @returns {string} Escaped string
     */
    escapeCSSSelector: function(str) {
        if (!str) return '';
        return str.replace(/([!"#$%&'()*+,.\/:;<=>?@\[\\\]^`{|}~])/g, '\\$1');
    }
};
]]
end

return MODULE

