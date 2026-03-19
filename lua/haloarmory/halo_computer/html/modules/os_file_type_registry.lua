--[[
    File: modules/os_file_type_registry.lua
    Purpose: File type registry system for handling different file types
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// FILE TYPE REGISTRY SYSTEM
// ============================================================================

/**
 * File type registry - maps extensions to handler functions
 */
window.osFileTypeRegistry = {
    handlers: {},
    programMap: {}, // Maps extensions to program IDs
    
    /**
     * Register a file type handler
     * @param {string} extension - File extension (e.g., '.txt', '.exe')
     * @param {Function} handler - Handler function(filePath, fileData, editMode)
     */
    register: function(extension, handler) {
        this.handlers[extension.toLowerCase()] = handler;
    },
    
    /**
     * Register a program for a file extension (simpler API)
     * @param {string} extension - File extension (e.g., '.txt', '.exe', '')
     * @param {string} programId - Program ID to open files with this extension
     */
    registerProgram: function(extension, programId) {
        var ext = extension.toLowerCase();
        this.programMap[ext] = programId;
        
        // Create a handler that opens the program
        this.register(ext, function(filePath, fileData, editMode) {
            if (window.osShell && window.osShell.openProgram) {
                window.osShell.openProgram(programId, filePath, editMode);
            }
        });
    },
    
    /**
     * Get handler for file extension
     * @param {string} extension - File extension
     * @returns {Function|null} Handler function or null
     */
    getHandler: function(extension) {
        return this.handlers[extension.toLowerCase()] || null;
    },
    
    /**
     * Check if extension has a handler
     * @param {string} extension - File extension
     * @returns {boolean} True if handler exists
     */
    hasHandler: function(extension) {
        return !!this.handlers[extension.toLowerCase()];
    },
    
    /**
     * Handle file open based on extension
     * @param {string} filePath - Full file path
     * @param {Object} fileData - File data object
     * @param {boolean} editMode - Whether to open in edit mode
     * @returns {boolean} True if handled
     */
    handleFile: function(filePath, fileData, editMode) {
        var extension = this.getExtensionFromPath(filePath);
        var handler = this.getHandler(extension);
        
        if (handler) {
            handler(filePath, fileData, editMode);
            return true;
        }
        
        return false;
    },
    
    /**
     * Handle shortcut file opening
     * @param {string} filePath - Path to shortcut file
     */
    handleShortcut: function(filePath) {
        var self = this;
        // Read the shortcut file to get its data
        if (window.filesystem) {
            window.filesystem.readFile(filePath, function(content) {
                if (!content) {
                    window.debugError('[FileTypeRegistry] Failed to read shortcut:', filePath);
                    return;
                }
                
                try {
                    var shortcutData = JSON.parse(content);
                    
                    if (shortcutData.program) {
                        // It's a program shortcut
                        if (shortcutData.folder) {
                            // Open program with folder argument
                            window.osShell.openProgram(shortcutData.program, shortcutData.folder);
                        } else {
                            // Open program normally
                            window.osShell.openProgram(shortcutData.program);
                        }
                    } else if (shortcutData.folder) {
                        // It's a folder shortcut
                        window.osShell.openProgram('filebrowser', shortcutData.folder);
                    } else {
                        window.debugWarn('[FileTypeRegistry] Invalid shortcut data:', shortcutData);
                    }
                } catch (e) {
                    window.debugError('[FileTypeRegistry] Error parsing shortcut:', e);
                }
            });
        }
    },
    
    /**
     * Get file extension from path
     * @param {string} path - File path
     * @returns {string} Extension (including dot)
     */
    getExtensionFromPath: function(path) {
        if (!path) return '';

        if (path.endsWith('config.dat')) {
            return 'config.dat';
        }

        // Handle .shortcut.dat special case
        if (path.endsWith('.shortcut.dat')) {
            return '.shortcut.dat';
        }
        
        var lastDot = path.lastIndexOf('.');
        return lastDot >= 0 ? path.substring(lastDot) : '';
    }
};

// Register system file type handlers
(function() {
    // .exe - Program files (shortcuts)
    window.osFileTypeRegistry.register('.exe', function(filePath, fileData, editMode) {
        if (fileData && fileData.program) {
            var folder = fileData.folder || null;
            if (folder) {
                window.osShell.openProgram(fileData.program, folder, editMode);
            } else {
                window.osShell.openProgram(fileData.program, filePath, editMode);
            }
        }
    });
    
    // .shortcut.dat - Shortcut files
    window.osFileTypeRegistry.register('.shortcut.dat', function(filePath, fileData, editMode) {
        if (fileData && fileData.program) {
            var folder = fileData.folder || null;
            if (folder) {
                window.osShell.openProgram(fileData.program, folder, editMode);
            } else {
                window.osShell.openProgram(fileData.program, filePath, editMode);
            }
        }
    });
    
    // .txt - Text files
    window.osFileTypeRegistry.register('.txt', function(filePath, fileData, editMode) {
        window.osShell.openProgram('notes', filePath, editMode);
    });
    
    // config.dat - Opens settings
    window.osFileTypeRegistry.register('config.dat', function(filePath, fileData, editMode) {
        window.osShell.openProgram('settings', filePath, editMode);
    });
})();
]]
end

return MODULE

