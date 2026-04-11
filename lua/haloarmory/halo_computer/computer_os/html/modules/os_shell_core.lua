--[[
    File: modules/os_shell_core.lua
    Purpose: Core os Shell object and main functions
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// OS SHELL CORE
// ============================================================================

var osShell = {
    startMenuOpen: false,
    runningPrograms: {}, // programId -> array of windowIds
    clipboard: null,
    dragState: null,
    selection: null,
    
    /**
     * Initialize the OS shell
     */
    init: function() {
        // Prevent double initialization
        if (this.initialized) {
            window.debugWarn('[osShell] Already initialized, skipping...');
            return;
        }
        this.initialized = true;
        
        var self = this;
        
        // Start clock
        this.updateClock();
        setInterval(function() {
            self.updateClock();
        }, 1000);
        
        // Populate start menu
        this.populateStartMenu();
        
        // Setup start button
        var startBtn = document.getElementById('os-start-btn');
        if (startBtn) {
            startBtn.addEventListener('click', function() {
                self.toggleStartMenu();
            });
        }
        
        // Setup logout button in footer
        var logoutBtn = document.querySelector('.os-start-menu-logout');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', function() {
                self.logout();
            });
        }
        
        // Click outside to close start menu
        document.addEventListener('click', function(e) {
            if (self.startMenuOpen) {
                var startMenu = document.getElementById('os-start-menu');
                var startBtn = document.getElementById('os-start-btn');
                if (startMenu && !startMenu.contains(e.target) && !startBtn.contains(e.target)) {
                    self.closeStartMenu();
                }
            }
        });
        
        // Initialize desktop managers
        this.initDesktopManagers();

        // Setup keyboard shortcuts for the OS clipboard
        this.initKeyboardShortcuts();
        
        // Start boot sequence
        if (window.osBootSequence) {
            window.osBootSequence.start();
        }
    },

    setClipboard: function(mode, items) {
        if (!mode || !items || !items.length) {
            this.clipboard = null;
            return;
        }

        this.clipboard = {
            mode: mode === 'cut' ? 'cut' : 'copy',
            items: items.map(function(item) {
                return {
                    filepath: item.filepath,
                    name: item.name || item.displayName || '',
                    displayName: item.displayName || item.name || '',
                    filename: item.filename || window.getFileNameFromPath(item.filepath || ''),
                    filetype: item.filetype || item.type || 'file',
                    isDirectory: !!(item.isDirectory || item.filetype === 'directory' || item.type === 'directory'),
                    isProtected: !!item.isProtected
                };
            }),
            updatedAt: Date.now()
        };
    },

    getClipboard: function() {
        return this.clipboard;
    },

    clearClipboard: function() {
        this.clipboard = null;
    },

    hasClipboardItems: function() {
        return !!(this.clipboard && this.clipboard.items && this.clipboard.items.length);
    },

    getSelectedTextForClipboard: function(target) {
        if (target) {
            var tagName = String(target.tagName || '').toUpperCase();
            if (tagName === 'TEXTAREA' || tagName === 'INPUT') {
                var start = typeof target.selectionStart === 'number' ? target.selectionStart : 0;
                var end = typeof target.selectionEnd === 'number' ? target.selectionEnd : 0;
                if (end > start) {
                    return String(target.value || '').substring(start, end);
                }
            }
        }

        var selection = null;
        try {
            selection = window.getSelection ? window.getSelection() : null;
        } catch (error) {
            selection = null;
        }

        var text = selection ? String(selection.toString() || '') : '';
        return text.trim() ? text : '';
    },

    initKeyboardShortcuts: function() {
        if (this.keyboardShortcutsInitialized) {
            return;
        }

        this.keyboardShortcutsInitialized = true;
        var self = this;

        document.addEventListener('keydown', function(e) {
            if (!(e.ctrlKey || e.metaKey) || e.altKey) {
                return;
            }

            var key = String(e.key || '').toLowerCase();
            if (key === 'c') {
                var selectedText = self.getSelectedTextForClipboard(e.target);
                if (selectedText) {
                    e.preventDefault();
                    if (window.copyTextToClipboard) {
                        window.copyTextToClipboard(selectedText, function(success) {
                            if (!success && window.osErrorHandler) {
                                window.osErrorHandler.showNotification('Failed to copy text.', 'error', 1800);
                            }
                        });
                    }
                    return;
                }
            }

            if (self.isEditableTarget(e.target)) {
                return;
            }

            if (key === 'c' || key === 'x') {
                var selectionContext = self.getClipboardSelectionContext();
                if (!selectionContext || !selectionContext.items.length) {
                    return;
                }

                e.preventDefault();
                self.setClipboard(key === 'x' ? 'cut' : 'copy', selectionContext.items);
                window.osErrorHandler.showNotification(
                    (key === 'x' ? 'Cut ' : 'Copied ') + selectionContext.items.length + ' item(s)',
                    'success',
                    2000
                );
                return;
            }

            if (key === 'v') {
                if (!self.hasClipboardItems()) {
                    return;
                }

                var pasteTarget = self.getClipboardPasteTarget();
                if (!pasteTarget || !pasteTarget.path) {
                    return;
                }

                if (window.isRestrictedSystemPath && window.isRestrictedSystemPath(pasteTarget.path)) {
                    return;
                }

                e.preventDefault();
                self.pasteClipboardToPath(pasteTarget.path);
                return;
            }

            if (key === 'a') {
                return;
            }
        });

        document.addEventListener('keydown', function(e) {
            if (self.isEditableTarget(e.target)) {
                return;
            }

            var isDeleteKey = e.key === 'Delete' || e.key === 'Del';
            if (!isDeleteKey || e.ctrlKey || e.metaKey || e.altKey) {
                return;
            }

            var selectionContext = self.getClipboardSelectionContext();
            if (!selectionContext || !selectionContext.items || !selectionContext.items.length) {
                return;
            }

            e.preventDefault();
            self.deleteSelection(selectionContext);
        });
    },

    isEditableTarget: function(target) {
        if (!target) {
            return false;
        }

        if (target.isContentEditable) {
            return true;
        }

        if (target.closest && target.closest('[contenteditable="true"]')) {
            return true;
        }

        var tagName = String(target.tagName || '').toUpperCase();
        if (tagName === 'TEXTAREA') {
            return true;
        }

        if (tagName === 'INPUT') {
            var inputType = String(target.type || 'text').toLowerCase();
            return ['text', 'search', 'url', 'tel', 'password', 'email', 'number'].indexOf(inputType) !== -1;
        }

        return false;
    },

    getFileBrowserSelectionContext: function(windowId) {
        if (!windowId || !window.fileBrowserApp || !window.fileBrowserApp.getInstance || !window.osSelectionManager) {
            return null;
        }

        var instance = window.fileBrowserApp.getInstance(windowId);
        if (!instance) {
            return null;
        }

        var selectionMgr = window.osSelectionManager.get(instance.selectionManagerId);
        if (!selectionMgr || !selectionMgr.hasSelection()) {
            return {
                type: 'filebrowser',
                path: instance.currentPath,
                items: []
            };
        }

        return {
            type: 'filebrowser',
            path: instance.currentPath,
            items: selectionMgr.getSelectedItemsData()
        };
    },

    getDesktopSelectionContext: function() {
        if (!window.osSelectionManager) {
            return null;
        }

        var selectionMgr = window.osSelectionManager.get('desktop');
        if (!selectionMgr) {
            return null;
        }

        return {
            type: 'desktop',
            path: window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/'),
            items: selectionMgr.hasSelection() ? selectionMgr.getSelectedItemsData() : []
        };
    },

    getClipboardSelectionContext: function() {
        var activeWindowId = window.windowManager ? window.windowManager.activeWindow : null;
        var activeFileBrowser = this.getFileBrowserSelectionContext(activeWindowId);
        if (activeFileBrowser && activeFileBrowser.items.length) {
            return activeFileBrowser;
        }

        var desktopContext = this.getDesktopSelectionContext();
        if (desktopContext && desktopContext.items.length) {
            return desktopContext;
        }

        return activeFileBrowser || desktopContext;
    },

    getClipboardPasteTarget: function() {
        var activeWindowId = window.windowManager ? window.windowManager.activeWindow : null;
        var activeFileBrowser = this.getFileBrowserSelectionContext(activeWindowId);
        if (activeFileBrowser && activeFileBrowser.path) {
            return {
                type: 'filebrowser',
                path: activeFileBrowser.path
            };
        }

        return {
            type: 'desktop',
            path: window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/')
        };
    },

    pasteClipboardToPath: function(targetPath) {
        var clipboard = this.getClipboard();
        if (!clipboard || !clipboard.items || !clipboard.items.length || !window.osFileOperations) {
            return;
        }

        var normalizedTarget = window.osFileOperations.normalizeDirectoryPath
            ? window.osFileOperations.normalizeDirectoryPath(targetPath)
            : targetPath;
        var operation = clipboard.mode === 'cut' ? 'moveItems' : 'copyItems';
        var self = this;

        if (!window.osFileOperations[operation]) {
            return;
        }

        window.osFileOperations[operation](clipboard.items, normalizedTarget, function(success) {
            if (success && clipboard.mode === 'cut') {
                self.clearClipboard();
            }

            if (success && window.osContextMenuManager) {
                window.osContextMenuManager.refreshSinglePath(normalizedTarget);

                if (clipboard.mode === 'cut') {
                    var refreshed = {};
                    clipboard.items.forEach(function(item) {
                        var sourcePath = window.osFileOperations.getParentDirectory
                            ? window.osFileOperations.getParentDirectory(item.filepath)
                            : null;
                        if (sourcePath && !refreshed[sourcePath]) {
                            refreshed[sourcePath] = true;
                            window.osContextMenuManager.refreshSinglePath(sourcePath);
                        }
                    });
                }
            }
        });
    },

    deleteSelection: function(selectionContext) {
        if (!selectionContext || !selectionContext.items || !selectionContext.items.length) {
            return;
        }

        if (!window.osFileOperations || !window.osFileOperations.deleteItems) {
            return;
        }

        var self = this;
        window.osFileOperations.deleteItems(selectionContext.items, false, function(success) {
            if (!success) {
                return;
            }

            if (selectionContext.type === 'filebrowser') {
                if (window.fileBrowserApp && window.fileBrowserApp.refreshPath && selectionContext.path) {
                    window.fileBrowserApp.refreshPath(selectionContext.path);
                }
                return;
            }

            if (selectionContext.type === 'desktop' && self.loadDesktopIcons) {
                self.loadDesktopIcons(true);
            }
        });
    },
    
    /**
     * Initialize desktop managers (selection, context menu)
     */
    initDesktopManagers: function() {
        // Prevent double initialization
        if (this.desktopManagersInitialized) {
            window.debugWarn('[osShell] Desktop managers already initialized, skipping...');
            return;
        }
        
        var desktop = document.getElementById('os-desktop-icons');
        if (!desktop) {
            window.debugWarn('[osShell] Desktop container not found, retrying...');
            var self = this;
            setTimeout(function() {
                self.initDesktopManagers();
            }, 100);
            return;
        }
        
        // Mark as initialized
        this.desktopManagersInitialized = true;
        
        // Initialize selection manager for desktop
        if (window.osSelectionManager) {
            this.desktopSelectionManager = window.osSelectionManager.create('desktop', desktop, 'desktop');
            desktop.setAttribute('data-selection-manager-id', 'desktop');
            window.debugLog('[osShell] Desktop selection manager initialized');
        }

        if (window.osDragDropManager) {
            window.osDragDropManager.registerFileSourceContainer(desktop, {
                resourceId: 'desktop-drag-source',
                selectionManagerId: 'desktop',
                location: 'desktop'
            });
            window.osDragDropManager.registerFilesystemDropTarget(desktop, {
                resourceId: 'desktop-drop-target',
                targetPath: window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/')
            });
        }
        
        // Setup context menu handler for desktop
        if (window.osContextMenuManager) {
            window.osCleanup.addEventListener('desktop-contextmenu', desktop, 'contextmenu', function(e) {
                e.preventDefault();
                
                var item = e.target.closest('.os-file-item');
                var selectionMgr = window.osSelectionManager.get('desktop');
                
                if (item) {
                    // Right-clicked on an item
                    var filepath = item.getAttribute('data-filepath');
                    var filetype = item.getAttribute('data-filetype');
                    var isProtected = item.getAttribute('data-protected') === 'true';
                    
                    // If item not selected, select only it
                    if (selectionMgr && !item.classList.contains('os-item-selected')) {
                        selectionMgr.clearSelection();
                        selectionMgr.selectItem(filepath);
                    }
                    
                    window.osContextMenuManager.show(e.pageX, e.pageY, {
                        type: 'file',
                        filepath: filepath,
                        filetype: filetype,
                        isProtected: isProtected,
                        location: 'desktop',
                        containerId: 'desktop',
                        selectedItems: selectionMgr ? selectionMgr.getSelectedItems() : [filepath]
                    });
                } else {
                    // Right-clicked on empty space
                    window.osContextMenuManager.show(e.pageX, e.pageY, {
                        type: 'empty',
                        location: 'desktop',
                        currentPath: window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/'),
                        containerId: 'desktop'
                    });
                }
            });
            window.debugLog('[osShell] Desktop context menu initialized');
        }
        
        // Setup double-click handler for desktop
        window.osCleanup.addEventListener('desktop-dblclick', desktop, 'dblclick', function(e) {
            var item = e.target.closest('.os-file-item');
            if (!item) return;
            
            var filepath = item.getAttribute('data-filepath');
            var filetype = item.getAttribute('data-filetype');
            
            // Handle shortcuts
            if (filetype === 'shortcut' || filetype === window.FILE_TYPE_SHORTCUT || filepath.endsWith('.shortcut.dat')) {
                if (window.osFileTypeRegistry && window.osFileTypeRegistry.handleShortcut) {
                    window.osFileTypeRegistry.handleShortcut(filepath);
                }
                return;
            }
            
            if (filetype === 'directory' || filetype === window.FILE_TYPE_DIRECTORY) {
                osShell.openProgram('filebrowser', filepath);
                return;
            }
            
            // Handle programs
            if (filetype === 'program' || filetype === window.FILE_TYPE_PROGRAM) {
                var programId = (item.getAttribute('data-filename') || item.getAttribute('data-name')).replace(/\.exe$/i, '');
                osShell.openProgram(programId);
                return;
            }
            
            // Default: open file
            var fileData = {
                name: item.getAttribute('data-name'),
                fileType: filetype,
                type: filetype
            };
            osShell.handleFileOpen(filepath, fileData, false);
        });

        window.osCleanup.addEventListener('desktop-empty-click', desktop, 'mousedown', function(e) {
            if (e.button !== 0) {
                return;
            }

            if (e.target.closest('.os-file-item')) {
                return;
            }

            if (window.windowManager && window.windowManager.clearActive) {
                window.windowManager.clearActive();
            }
        });
    },
    
    /**
     * Update clock display
     */
    updateClock: function() {
        var clock = document.getElementById('os-clock');
        if (clock) {
            var now = new Date();
            var hours = now.getHours().toString().padStart(2, '0');
            var minutes = now.getMinutes().toString().padStart(2, '0');
            clock.textContent = hours + ':' + minutes;
        }
    },
    
    /**
     * Toggle start menu
     */
    toggleStartMenu: function() {
        if (this.startMenuOpen) {
            this.closeStartMenu();
        } else {
            this.openStartMenu();
        }
    },
    
    /**
     * Open start menu
     */
    openStartMenu: function() {
        var startMenu = document.getElementById('os-start-menu');
        if (startMenu) {
            startMenu.style.display = 'block';
            this.startMenuOpen = true;
        }
    },
    
    /**
     * Close start menu
     */
    closeStartMenu: function() {
        var startMenu = document.getElementById('os-start-menu');
        if (startMenu) {
            startMenu.style.display = 'none';
            this.startMenuOpen = false;
        }
    },
    
    /**
     * Populate start menu with available programs
     */
    populateStartMenu: function() {
        var container = document.getElementById('os-start-menu-programs');
        if (!container || !window.programRegistry) return;
        
        container.innerHTML = '';
        var programs = window.programRegistry.getAll();

        var createStartSubmenuItem = function(labelText, iconText, onClick) {
            var submenuItem = document.createElement('button');
            submenuItem.className = 'os-start-submenu-item';
            submenuItem.type = 'button';

            var submenuIcon = document.createElement('span');
            submenuIcon.className = 'os-start-submenu-item-icon';
            submenuIcon.textContent = iconText || '📄';

            var submenuLabel = document.createElement('span');
            submenuLabel.className = 'os-start-submenu-item-label';
            submenuLabel.textContent = labelText;

            submenuItem.appendChild(submenuIcon);
            submenuItem.appendChild(submenuLabel);
            submenuItem.addEventListener('click', function(e) {
                e.stopPropagation();
                onClick(e);
            });
            return submenuItem;
        };
        
        for (var id in programs) {

            // Skip settings, standalone ExternalDrive alias, and games grouped elsewhere
            if (
                id === 'settings' ||
                id === 'externaldrive' ||
                id === 'minesweeper' ||
                id === 'pingpong' ||
                id === 'snake' ||
                id === 'conway' ||
                id === 'game2048'
            ) {
                continue;
            }
        
            if (programs.hasOwnProperty(id)) {
                var program = programs[id];
                var item = document.createElement('div');
                item.className = 'os-start-menu-item';
                
                var icon = document.createElement('span');
                icon.className = 'os-start-menu-item-icon';
                icon.textContent = program.icon || 'ðŸ“„';
                
                var label = document.createElement('span');
                label.className = 'os-start-menu-item-label';
                label.textContent = program.title || program.name || id;
                
                item.appendChild(icon);
                item.appendChild(label);
                item.dataset.programId = id;

                if (id === 'filebrowser') {
                    item.classList.add('has-submenu');

                    var arrow = document.createElement('span');
                    arrow.className = 'os-start-menu-item-arrow';
                    arrow.textContent = '▶';
                    item.appendChild(arrow);

                    var submenu = document.createElement('div');
                    submenu.className = 'os-start-submenu';

                    var cDriveItem = createStartSubmenuItem('C:/', '💾', function() {
                        osShell.openProgram('filebrowser', 'C:/');
                        osShell.closeStartMenu();
                    });

                    var externalDriveItem = createStartSubmenuItem('ExternalDrive:/', '💽', function() {
                        osShell.openProgram('filebrowser', 'ExternalDrive:/');
                        osShell.closeStartMenu();
                    });

                    submenu.appendChild(cDriveItem);
                    submenu.appendChild(externalDriveItem);
                    item.appendChild(submenu);
                }
                
                item.addEventListener('click', (function(programId) {
                    return function() {
                        osShell.openProgram(programId);
                        osShell.closeStartMenu();
                    };
                })(id));
                
                // Add right-click context menu
                item.addEventListener('contextmenu', (function(programId, program) {
                    return function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        
                        if (window.osContextMenuManager) {
                            window.osContextMenuManager.show(e.pageX, e.pageY, {
                                type: 'startmenu-program',
                                programId: programId,
                                program: program
                            });
                        }
                    };
                })(id, program));
                
                container.appendChild(item);
            }
        }

        var gameEntries = [
            { id: 'minesweeper', fallbackTitle: 'Minesweeper', fallbackIcon: '💣' },
            { id: 'pingpong', fallbackTitle: 'Ping Pong', fallbackIcon: '🏓' },
            { id: 'snake', fallbackTitle: 'Snake', fallbackIcon: '🐍' },
            { id: 'conway', fallbackTitle: 'Conway\'s Life', fallbackIcon: '🧬' },
            { id: 'game2048', fallbackTitle: '2048', fallbackIcon: '🔢' }
        ].filter(function(entry) {
            return !!programs[entry.id];
        });

        if (gameEntries.length) {
            var gamesItem = document.createElement('div');
            gamesItem.className = 'os-start-menu-item has-submenu';

            var gamesIcon = document.createElement('span');
            gamesIcon.className = 'os-start-menu-item-icon';
            gamesIcon.textContent = '🎮';

            var gamesLabel = document.createElement('span');
            gamesLabel.className = 'os-start-menu-item-label';
            gamesLabel.textContent = 'Games';

            var gamesArrow = document.createElement('span');
            gamesArrow.className = 'os-start-menu-item-arrow';
            gamesArrow.textContent = '▶';

            var gamesSubmenu = document.createElement('div');
            gamesSubmenu.className = 'os-start-submenu';

            var minesweeperItem = createStartSubmenuItem(
                programs.minesweeper.title || 'Minesweeper',
                programs.minesweeper.icon || '💣',
                function() {
                osShell.openProgram('minesweeper');
                osShell.closeStartMenu();
            });

            gamesSubmenu.appendChild(minesweeperItem);
            gameEntries.forEach(function(entry) {
                if (entry.id === 'minesweeper') {
                    return;
                }

                var program = programs[entry.id];
                var gameItem = createStartSubmenuItem(
                    program.title || entry.fallbackTitle,
                    program.icon || entry.fallbackIcon,
                    function() {
                        osShell.openProgram(entry.id);
                        osShell.closeStartMenu();
                    }
                );

                gamesSubmenu.appendChild(gameItem);
            });
            gamesItem.appendChild(gamesIcon);
            gamesItem.appendChild(gamesLabel);
            gamesItem.appendChild(gamesArrow);
            gamesItem.appendChild(gamesSubmenu);

            gamesItem.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
            });

            container.appendChild(gamesItem);
        }
        
        // Add separator
        var separator = document.createElement('div');
        separator.className = 'os-start-menu-separator';
        container.appendChild(separator);
        
        // Add settings button
        var settingsItem = document.createElement('div');
        settingsItem.className = 'os-start-menu-item';
        
        var settingsIcon = document.createElement('span');
        settingsIcon.className = 'os-start-menu-item-icon';
        var settingsProgram = programs.settings;
        settingsIcon.textContent = (settingsProgram && settingsProgram.icon) || '⚙️';
        
        var settingsLabel = document.createElement('span');
        settingsLabel.className = 'os-start-menu-item-label';
        settingsLabel.textContent = 'Settings';
        
        settingsItem.appendChild(settingsIcon);
        settingsItem.appendChild(settingsLabel);
        
        settingsItem.addEventListener('click', function() {
            osShell.openProgram(window.PROGRAM_SETTINGS || 'settings');
            osShell.closeStartMenu();
        });
        
        container.appendChild(settingsItem);
    },
    
    /**
     * Open a program
     * @param {string} programId - Program ID to open
     * @param {string} filePath - Optional file path to pass to program
     * @param {boolean} editMode - Optional edit mode flag
     */
    openProgram: function(programId, filePath, editMode) {
        if (programId === 'externaldrive') {
            programId = 'filebrowser';
            filePath = filePath || 'ExternalDrive:/';
        }

        if (!window.programRegistry) {
            window.debugError('[osShell] Program registry not available');
            return;
        }
        
        var program = window.programRegistry.get(programId);
        if (!program) {
            window.debugError('[osShell] Program not found:', programId);
            return;
        }
        
        window.debugLog('[osShell] Opening program:', programId, 'with file:', filePath);
        
        // Create window for program
        var windowId = 'window-' + programId + '-' + Date.now();
        var content = program.content || '<div>Program content</div>';
        
        var options = program.options || {};
        options.icon = program.icon || 'ðŸ“„';
        
        if (!window.windowManager) {
            window.debugError('[osShell] Window manager not available');
            return;
        }
        
        window.windowManager.create(windowId, program.title || programId, content, options);
        
        // Track running program
        if (!this.runningPrograms[programId]) {
            this.runningPrograms[programId] = [];
        }
        this.runningPrograms[programId].push(windowId);
        
        // Store initial path/file for the program if provided
        if (filePath) {
            if (!window.programInitialPaths) {
                window.programInitialPaths = {};
            }
            window.programInitialPaths[windowId] = filePath;
        }
        
        // Store edit mode if provided
        if (editMode !== undefined) {
            if (!window.programEditModes) {
                window.programEditModes = {};
            }
            window.programEditModes[windowId] = editMode;
        }
        
        // Initialize program if it has init function
        if (program.init) {
            setTimeout(function() {
                program.init(windowId);
            }, 100);
        }

        return windowId;
    },
    
    /**
     * Load desktop icons
     */
    loadDesktopIcons: function(forceRefresh) {
        var self = this;
        if (!window.filesystem) {
            setTimeout(function() {
                self.loadDesktopIcons(forceRefresh);
            }, 100);
            return;
        }

        if (forceRefresh && window.osFileItemRenderer && window.osFileItemRenderer.invalidatePreviewCache) {
            window.osFileItemRenderer.invalidatePreviewCache(window.PATH_DESKTOP || 'C:/desktop/');
        }
        
        window.filesystem.listDirectory(window.PATH_DESKTOP || 'C:/desktop/', function(files) {
            var container = document.getElementById('os-desktop-icons');
            if (!container) return;
            
            container.innerHTML = '';
            
            if (files && files.length > 0) {
                // Filter out protected config if it ever appears in desktop mirror
                files = files.filter(function(file) {
                    if (file.name === 'config.dat' || file.name === '.config' || file.displayName === 'config.dat' || file.displayName === '.config') {
                        return false;
                    }
                    return true;
                });
                
                if (window.osFileItemRenderer) {
                    // Use new file renderer
                    files.forEach(function(file) {
                        // Prepare file data with full path
                        var fileData = {
                            name: file.name,
                            displayName: file.displayName || file.name,
                            filepath: (window.PATH_DESKTOP || 'C:/desktop/') + file.name + ((file.type === 'directory' || file.fileType === 'directory') ? '/' : ''),
                            path: (window.PATH_DESKTOP || 'C:/desktop/') + file.name + ((file.type === 'directory' || file.fileType === 'directory') ? '/' : ''),
                            fileType: file.fileType || file.type,
                            type: file.fileType || file.type,
                            icon: file.icon,
                            programId: file.programId || file.program,
                            folder: file.folder || null,
                            protected: file.protected || file.readOnly || false
                        };
                        
                        // Render icon HTML
                        var iconHTML = window.osFileItemRenderer.renderFileItem(fileData, 'desktop');
                        
                        // Create element from HTML
                        var tempDiv = document.createElement('div');
                        tempDiv.innerHTML = iconHTML;
                        var icon = tempDiv.firstChild;
                        
                        container.appendChild(icon);
                    });

                    if (window.osFileItemRenderer.hydrateImagePreviews) {
                        window.osFileItemRenderer.hydrateImagePreviews(container);
                    }
                } else {
                    files.forEach(function(file) {
                        self.createDesktopIconOld(file, container);
                    });
                }
            }
        });
    },
    
    /**
     * Create a desktop icon (old fallback method)
     * @param {Object} file - File data
     * @param {Element} container - Container element
     */
    createDesktopIconOld: function(file, container) {
        var icon = document.createElement('div');
        icon.className = 'os-desktop-icon os-file-item';
        icon.setAttribute('data-filename', file.name);
        icon.setAttribute('data-filepath', (window.PATH_DESKTOP || 'C:/desktop/') + file.name + ((file.type === 'directory' || file.fileType === 'directory') ? '/' : ''));
        icon.setAttribute('data-filetype', file.fileType || file.type);
        icon.setAttribute('data-name', file.displayName || file.name);
        icon.setAttribute('data-display-name', file.displayName || file.name);
        if (file.protected || file.readOnly) {
            icon.setAttribute('data-protected', 'true');
        }
        
        var iconImg = document.createElement('div');
        iconImg.className = 'os-item-icon';
        iconImg.textContent = file.icon || (file.type === 'directory' ? 'ðŸ“' : 'ðŸ“„');
        
        var iconLabel = document.createElement('div');
        iconLabel.className = 'os-item-label';
        iconLabel.textContent = file.displayName || file.name;
        
        icon.appendChild(iconImg);
        icon.appendChild(iconLabel);
        
        container.appendChild(icon);
    },
    
    /**
     * Handle file open
     * @param {string} filePath - File path
     * @param {Object} fileData - File data
     * @param {boolean} editMode - Edit mode flag
     */
    handleFileOpen: function(filePath, fileData, editMode) {
        // Handle shortcuts
        if (fileData.fileType === 'shortcut' && fileData.program) {
            var folder = fileData.folder || null;
            if (folder) {
                this.openProgram(fileData.program, folder, editMode);
            } else {
                this.openProgram(fileData.program, filePath, editMode);
            }
            return;
        }
        
        if (fileData.type === 'directory') {
            this.openProgram('filebrowser', filePath);
            return;
        }
        
        // Use file type registry
        if (window.osFileTypeRegistry && window.osFileTypeRegistry.handleFile(filePath, fileData, editMode)) {
            return;
        }
        
        // Default: open in notes
        this.openProgram('notes', filePath, editMode);
    },
    
    /**
     * Logout - Close the computer interface
     */
    logout: function() {
        // Close all windows first
        if (window.windowManager && window.windowManager.closeAll) {
            window.windowManager.closeAll();
        }
        
        // Call the registered close_interface function
        if (typeof console !== 'undefined' && console.close_interface) {
            console.close_interface();
        }
    }
};

// Make globally accessible
window.osShell = osShell;
]]
end

return MODULE
