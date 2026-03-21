--[[
    File: modules/os_file_operations.lua
    Purpose: File and folder operations
    
    Handles rename, delete, copy, move, and create operations.
    Uses full paths throughout and validates all operations.
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// FILE OPERATIONS MANAGER
// ============================================================================

window.osFileOperations = {
    TRASH_PATH: 'C:/.system/trash/',
    
    /**
     * Rename a file or folder
     * @param {string} filepath - Full path to item
     * @param {string} newName - New name (not full path, just name, already sanitized)
     * @param {Function} callback - Callback(success, newFilepath)
     */
    rename: function(filepath, newName, callback) {
        if (!filepath || !newName) {
            window.debugError('[FileOps] Rename: Missing filepath or newName');
            if (callback) callback(false, null);
            return;
        }

        if (window.isInTrashFolder && window.isInTrashFolder(filepath)) {
            window.osErrorHandler.showNotification('Trash items are read-only', 'warning', 2000);
            if (callback) callback(false, null);
            return;
        }

        var validation = window.osFilenameRules
            ? window.osFilenameRules.validateBaseName(newName)
            : {
                isValid: !!String(newName || '').trim(),
                normalizedValue: String(newName || '').trim().toLowerCase()
            };

        if (!validation.isValid) {
            window.osErrorHandler.showNotification(validation.message || 'Invalid name', 'error');
            if (callback) callback(false, null);
            return;
        }

        newName = validation.normalizedValue;
        
        // Get current name from filepath (for comparison, remove .txt extension)
        var pathParts = filepath.split('/').filter(function(p) { return p && p !== ''; });
        var currentName = (window.osFilenameRules
            ? window.osFilenameRules.normalizeBaseName(pathParts[pathParts.length - 1] || '')
            : (pathParts[pathParts.length - 1] || '').toLowerCase().replace(/\.txt$/, ''));
        
        if (newName === currentName) {
            window.debugLog('[FileOps] Name unchanged, skipping rename');
            if (callback) callback(true, filepath);
            return;
        }
        
        window.debugLog('[FileOps] Renaming', filepath, 'to', newName);
        
        // Use filesystem bridge to rename
        if (window.filesystem && window.filesystem.renameFile) {
            window.filesystem.renameFile(filepath, newName, function(success, newFilepath) {
                if (success) {
                    window.osErrorHandler.showNotification('Renamed successfully', 'success', 2000);
                } else {
                    window.osErrorHandler.showNotification('Failed to rename', 'error');
                }
                if (callback) callback(success, newFilepath);
            });
        } else {
            window.debugError('[FileOps] Filesystem rename function not available');
            window.osErrorHandler.showNotification('Rename function not available', 'error');
            if (callback) callback(false, null);
        }
    },
    
    /**
     * Delete items
     * Normal delete moves C:/ items into Trash; items already in Trash delete permanently.
     * @param {Array<Object>} items - Array of item objects {filepath, name, filetype, isDirectory}
     * @param {boolean} permanent - Force permanent deletion when true
     * @param {Function} callback - Callback(success, message)
     */
    deleteItems: function(items, permanent, callback) {
        window.debugLog('[FileOps] deleteItems called with', items ? items.length : 0, 'items');
        
        if (!items || items.length === 0) {
            window.debugWarn('[FileOps] No items to delete');
            if (callback) callback(false, 'No items selected');
            return;
        }
        
        window.debugLog('[FileOps] Items to delete:', items);
        
        // Check for protected items
        var protectedItems = items.filter(function(item) {
            return this.isProtectedPath(item.filepath);
        }.bind(this));
        
        if (protectedItems.length > 0) {
            window.debugWarn('[FileOps] Attempted to delete protected items:', protectedItems);
            window.osErrorHandler.showNotification('Cannot delete protected system files', 'error');
            if (callback) callback(false, 'Protected items');
            return;
        }

        var shouldTrashItems = !permanent && items.every(function(item) {
            return item &&
                item.filepath &&
                window.getDriveFromPath(item.filepath).toLowerCase() === window.DRIVE_C.toLowerCase() &&
                !(window.isInTrashFolder && window.isInTrashFolder(item.filepath)) &&
                !(window.isTrashPath && window.isTrashPath(item.filepath));
        });

        if (shouldTrashItems) {
            this.moveItems(items, this.TRASH_PATH, function(success, message) {
                if (success) {
                    if (callback) callback(true, 'Moved to Trash');
                    return;
                }

                if (callback) callback(false, message || 'Failed to move to Trash');
            });
            return;
        }
        
        var confirmMessage = 'Permanently delete ' + items.length + ' item(s)?';
        if (items.length === 1 && items[0].name) {
            confirmMessage = 'Permanently delete "' + items[0].name + '"?';
        }
        
        window.debugLog('[FileOps] Showing confirmation dialog:', confirmMessage);
        
        // Show confirmation dialog - use custom dialog if osDialog doesn't exist
        if (window.osDialog && window.osDialog.showConfirmDialog) {
            window.debugLog('[FileOps] Using osDialog.showConfirmDialog');
            window.osDialog.showConfirmDialog({
                title: 'Delete Items',
                message: confirmMessage,
                confirmText: 'Delete',
                confirmDanger: true,
                onConfirm: function() {
                    window.debugLog('[FileOps] User confirmed deletion');
                    this.performDelete(items, callback);
                }.bind(this)
            });
        } else {
            // Create a simple custom confirmation dialog
            window.debugLog('[FileOps] Creating custom confirmation dialog');
            this.showDeleteConfirmDialog(confirmMessage, function(confirmed) {
                if (confirmed) {
                    window.debugLog('[FileOps] User confirmed deletion');
                    this.performDelete(items, callback);
                } else {
                    window.debugLog('[FileOps] User cancelled deletion');
                    if (callback) callback(false, 'Cancelled by user');
                }
            }.bind(this));
        }
    },
    
    /**
     * Show a simple confirmation dialog for delete operations
     * @param {string} message - Confirmation message
     * @param {Function} callback - Callback(confirmed)
     */
    showDeleteConfirmDialog: function(message, callback) {
        // Create overlay
        var overlay = document.createElement('div');
        overlay.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); z-index: 20000; display: flex; align-items: center; justify-content: center;';
        
        // Create dialog
        var dialog = document.createElement('div');
        dialog.style.cssText = 'background: #2d2d2d; border: 1px solid #555; border-radius: var(--radius-ui, 6px); padding: 20px; min-width: 400px; max-width: 500px; box-shadow: 0 4px 12px rgba(0,0,0,0.5);';
        
        // Title
        var title = document.createElement('div');
        title.textContent = 'Delete Items';
        title.style.cssText = 'color: #fff; font-size: 18px; font-weight: bold; margin-bottom: 12px;';
        dialog.appendChild(title);
        
        // Message
        var msg = document.createElement('div');
        msg.textContent = message;
        msg.style.cssText = 'color: #ccc; font-size: 14px; margin-bottom: 20px;';
        dialog.appendChild(msg);
        
        // Warning text
        var warning = document.createElement('div');
        warning.textContent = 'This action cannot be undone.';
        warning.style.cssText = 'color: #ff6b6b; font-size: 12px; margin-bottom: 20px;';
        dialog.appendChild(warning);
        
        // Buttons
        var buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = 'display: flex; gap: 10px; justify-content: flex-end;';
        
        var cancelBtn = document.createElement('button');
        cancelBtn.textContent = 'Cancel';
        cancelBtn.style.cssText = 'padding: 8px 16px; background: #3a3a3a; border: 1px solid #555; border-radius: var(--radius-ui-small, 4px); color: #fff; cursor: pointer; font-size: 13px;';
        cancelBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            e.preventDefault();
            overlay.remove();
            if (callback) callback(false);
        });
        buttonContainer.appendChild(cancelBtn);
        
        var deleteBtn = document.createElement('button');
        deleteBtn.textContent = 'Delete';
        deleteBtn.style.cssText = 'padding: 8px 16px; background: #d32f2f; border: 1px solid #b71c1c; border-radius: var(--radius-ui-small, 4px); color: #fff; cursor: pointer; font-size: 13px; font-weight: bold;';
        deleteBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            e.preventDefault();
            overlay.remove();
            if (callback) callback(true);
        });
        buttonContainer.appendChild(deleteBtn);
        
        dialog.appendChild(buttonContainer);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        
        // Stop propagation on dialog clicks to prevent overlay handler from firing
        dialog.addEventListener('click', function(e) {
            e.stopPropagation();
        });
        
        // Close on overlay click (but not dialog click)
        overlay.addEventListener('click', function(e) {
            if (e.target === overlay) {
                overlay.remove();
                if (callback) callback(false);
            }
        });
        
        // Focus delete button
        setTimeout(function() {
            deleteBtn.focus();
        }, 10);
    },
    
    /**
     * Permanently delete items
     * @param {Array<Object>} items - Items to delete
     * @param {Function} callback - Callback(success, message)
     */
    performDelete: function(items, callback, options) {
        options = options || {};

        if (!window.filesystem) {
            window.osErrorHandler.showNotification('Filesystem not available', 'error');
            if (callback) callback(false, 'Filesystem not available');
            return;
        }

        if (!items || items.length === 0) {
            window.debugError('[FileOps] No items to delete');
            if (callback) callback(false, 'No items provided');
            return;
        }
        
        var deleteCount = 0;
        var failCount = 0;
        var errors = [];
        
        var deleteNext = function(index) {
            if (index >= items.length) {
                // All done
                if (failCount === 0) {
                    window.debugLog('[FileOps] Successfully deleted', deleteCount, 'item(s)');
                    if (!options.suppressNotifications) {
                        window.osErrorHandler.showNotification('Deleted ' + deleteCount + ' item(s)', 'success');
                    }
                    if (callback) callback(true, 'Deleted successfully', {
                        deleted: deleteCount,
                        failed: failCount
                    });
                } else {
                    window.debugError('[FileOps] Deletion completed with errors. Success:', deleteCount, 'Failed:', failCount);
                    window.debugError('[FileOps] Errors:', errors);
                    if (!options.suppressNotifications) {
                        window.osErrorHandler.showNotification('Deleted ' + deleteCount + ', failed ' + failCount, 'warning');
                    }
                    if (callback) callback(false, 'Some items failed', {
                        deleted: deleteCount,
                        failed: failCount
                    });
                }
                return;
            }
            
            var item = items[index];
            if (!item || !item.filepath) {
                window.debugError('[FileOps] Invalid item at index', index, ':', item);
                failCount++;
                errors.push('Invalid item at index ' + index);
                deleteNext(index + 1);
                return;
            }
            
            window.debugLog('[FileOps] Deleting:', item.filepath, 'Item:', item);
            
            try {
                window.debugLog('[FileOps] Calling deleteFile for:', item.filepath);
                
                window.filesystem.deleteFile(item.filepath, function(success) {
                    window.debugLog('[FileOps] Delete callback received for', item.filepath, 'Result type:', typeof success, 'Value:', success);
                    
                    // Handle different result formats
                    var isSuccess = false;
                    if (success === true) {
                        isSuccess = true;
                    } else if (success === 'true') {
                        isSuccess = true;
                    } else if (typeof success === 'object' && success !== null) {
                        // Check for result.result or result directly
                        if (success.result === true || success.result === 'true') {
                            isSuccess = true;
                        } else if (success === true) {
                            isSuccess = true;
                        }
                    } else if (success === false || success === 'false' || success === null || success === undefined) {
                        isSuccess = false;
                    }
                    
                    window.debugLog('[FileOps] Delete result for', item.filepath, '- isSuccess:', isSuccess);
                    
                    if (isSuccess) {
                        deleteCount++;
                        window.debugLog('[FileOps] Successfully deleted:', item.filepath);
                    } else {
                        failCount++;
                        var errorMsg = 'Failed to delete: ' + item.filepath + ' (result: ' + JSON.stringify(success) + ')';
                        errors.push(errorMsg);
                        window.debugError('[FileOps] Failed to delete:', item.filepath, 'Result:', success);
                    }
                    deleteNext(index + 1);
                });
            } catch (e) {
                window.debugError('[FileOps] Exception calling deleteFile:', e, e.stack);
                failCount++;
                errors.push('Exception: ' + (e.message || e.toString()));
                deleteNext(index + 1);
            }
        };
        
        deleteNext(0);
    },

    normalizeDirectoryPath: function(path) {
        path = normalizePath(path || '');
        if (path && !path.endsWith('/')) {
            path += '/';
        }
        return path;
    },

    getItemFileName: function(item) {
        if (!item) {
            return '';
        }

        return item.filename || window.getFileNameFromPath(item.filepath || '') || item.name || '';
    },

    getItemDisplayName: function(item) {
        if (!item) {
            return 'item';
        }

        return item.displayName || item.name || this.getItemFileName(item) || 'item';
    },

    getParentDirectory: function(filepath) {
        var normalized = normalizePath(filepath || '');
        var lastSlash = normalized.lastIndexOf('/');

        if (lastSlash === -1) {
            return '';
        }

        return this.normalizeDirectoryPath(normalized.substring(0, lastSlash + 1));
    },

    splitFileName: function(filename) {
        if (!filename) {
            return { base: 'untitled', extension: '.txt' };
        }

        var lowerName = filename.toLowerCase();
        if (lowerName.endsWith('.shortcut.dat')) {
            return {
                base: filename.slice(0, -('.shortcut.dat'.length)),
                extension: '.shortcut.dat'
            };
        }

        var lastDot = filename.lastIndexOf('.');
        if (lastDot <= 0) {
            return {
                base: filename,
                extension: ''
            };
        }

        return {
            base: filename.substring(0, lastDot),
            extension: filename.substring(lastDot)
        };
    },

    buildIndexedFileName: function(filename, index) {
        var parts = this.splitFileName(filename);
        return parts.base + '_' + index + parts.extension;
    },

    buildFallbackUniqueFileName: function(filename) {
        var parts = this.splitFileName(filename);
        var suffix = '_' + String(Date.now()).slice(-6);
        return parts.base + suffix + parts.extension;
    },

    getDefaultExtensionForItem: function(item, filename) {
        var lowerName = String(filename || '').toLowerCase();
        if (lowerName.endsWith('.shortcut.dat')) {
            return '.shortcut.dat';
        }

        if (lowerName.lastIndexOf('.') > 0) {
            return '';
        }

        var filetype = String(item && (item.filetype || item.type) || '').toLowerCase();
        if (filetype === 'text' || filetype === 'file') {
            return '.txt';
        }
        if (filetype === 'config' || filetype === 'data') {
            return '.dat';
        }
        if (filetype === 'shortcut') {
            return '.shortcut.dat';
        }

        return '';
    },

    getCollisionCandidates: function(item, filename) {
        var candidates = {};
        var rawName = String(filename || '');
        var lowerRawName = rawName.toLowerCase();

        if (lowerRawName) {
            candidates[lowerRawName] = true;
        }

        var defaultExtension = this.getDefaultExtensionForItem(item, rawName);
        if (defaultExtension && lowerRawName && !lowerRawName.endsWith(defaultExtension)) {
            candidates[(rawName + defaultExtension).toLowerCase()] = true;
        }

        return candidates;
    },

    getTransferValidationError: function(item, destinationType, targetPath) {
        if (!item || !item.filepath) {
            return 'Invalid item';
        }

        var targetDrive = targetPath ? window.getDriveFromPath(targetPath) : null;

        if (destinationType === 'filesystem' && targetPath && window.isRestrictedSystemPath && window.isRestrictedSystemPath(targetPath)) {
            return 'System folders are read-only';
        }

        if (item.filetype === 'program') {
            return 'Program files cannot be transferred';
        }

        if (item.filetype === 'shortcut') {
            if (destinationType === 'attachment') {
                return 'Shortcuts cannot be attached';
            }
            if (targetDrive &&
                targetDrive.toLowerCase() === window.DRIVE_EXTERNAL.toLowerCase()) {
                return 'Shortcuts cannot be transferred to ExternalDrive';
            }
            return null;
        }

        if (item.isDirectory || item.filetype === 'directory') {
            if (destinationType === 'attachment') {
                return 'Folders cannot be attached';
            }
        }

        if (item.isProtected || this.isProtectedPath(item.filepath)) {
            return destinationType === 'attachment'
                ? 'Protected files cannot be attached'
                : 'Protected files cannot be transferred';
        }

        return null;
    },

    resolveDestinationPath: function(item, targetPath, callback) {
        var filename = this.getItemFileName(item);
        var normalizedTarget = this.normalizeDirectoryPath(targetPath);

        if (!filename || !normalizedTarget) {
            if (callback) callback(null);
            return;
        }

        window.filesystem.listDirectory(normalizedTarget, function(files) {
            var existingNames = {};
            (files || []).forEach(function(file) {
                if (file && file.name) {
                    existingNames[file.name.toLowerCase()] = true;
                }
            });

            var resolvedName = filename;
            var index = 1;

            while (Object.keys(this.getCollisionCandidates(item, resolvedName)).some(function(candidate) {
                return !!existingNames[candidate];
            })) {
                resolvedName = this.buildIndexedFileName(filename, index);
                index++;
            }

            if (callback) {
                callback(normalizedTarget + resolvedName);
            }
        }.bind(this));
    },

    finalizeTransfer: function(mode, successCount, failCount, callback) {
        var actionLabel = mode === 'move' ? 'Moved' : 'Copied';

        if (successCount > 0 && failCount === 0) {
            window.osErrorHandler.showNotification(actionLabel + ' ' + successCount + ' item(s)', 'success');
            if (callback) callback(true, actionLabel + ' successfully');
            return;
        }

        if (successCount > 0) {
            window.osErrorHandler.showNotification(actionLabel + ' ' + successCount + ', failed ' + failCount, 'warning');
            if (callback) callback(false, 'Some items failed');
            return;
        }

        window.osErrorHandler.showNotification('Failed to ' + (mode === 'move' ? 'move' : 'copy') + ' items', 'error');
        if (callback) callback(false, 'No items were transferred');
    },

    transferItems: function(items, targetPath, options, callback) {
        if (typeof options === 'function') {
            callback = options;
            options = {};
        }

        options = options || {};

        if (!items || items.length === 0) {
            if (callback) callback(false, 'No items to transfer');
            return;
        }

        if (!window.filesystem) {
            window.osErrorHandler.showNotification('Filesystem not available', 'error');
            if (callback) callback(false, 'Filesystem not available');
            return;
        }

        var mode = options.mode === 'move' ? 'move' : 'copy';
        var normalizedTarget = this.normalizeDirectoryPath(targetPath);
        var isTrashTarget = normalizedTarget.toLowerCase() === this.normalizeDirectoryPath(this.TRASH_PATH).toLowerCase();
        var transferItems = [];
        var rejectedCount = 0;

        items.forEach(function(item) {
            var reason = this.getTransferValidationError(item, 'filesystem', normalizedTarget);
            var sourceDirectory = this.getParentDirectory(item.filepath);

            if (!reason && sourceDirectory.toLowerCase() === normalizedTarget.toLowerCase()) {
                reason = 'Already in this location';
            }

            if (!reason && item.isDirectory && window.isSelfDrop && window.isSelfDrop(item.filepath, normalizedTarget)) {
                reason = 'Cannot move a folder into itself';
            }

            if (reason) {
                rejectedCount++;
                window.debugWarn('[FileOps] Transfer rejected for', item.filepath, '-', reason);
                return;
            }

            transferItems.push(item);
        }.bind(this));

        if (!transferItems.length) {
            window.osErrorHandler.showNotification('No valid items to transfer', 'warning');
            if (callback) callback(false, 'No valid items to transfer');
            return;
        }

        var successCount = 0;
        var failCount = rejectedCount;
        var movedItems = [];

        var transferNext = function(index) {
            if (index >= transferItems.length) {
                if (mode === 'move' && movedItems.length > 0) {
                    this.performDelete(movedItems, function(deleteSuccess, deleteMessage, deleteStats) {
                        if (!deleteSuccess) {
                            failCount += deleteStats && deleteStats.failed ? deleteStats.failed : movedItems.length;
                        }
                        this.finalizeTransfer(mode, successCount, failCount, callback);
                    }.bind(this), {
                        suppressNotifications: true
                    });
                    return;
                }

                this.finalizeTransfer(mode, successCount, failCount, callback);
                return;
            }

            var item = transferItems[index];

            this.resolveDestinationPath(item, normalizedTarget, function(destPath) {
                if (!destPath) {
                    failCount++;
                    transferNext(index + 1);
                    return;
                }

                var finishTransfer = function(success) {
                    if (success) {
                        successCount++;
                        if (mode === 'move') {
                            movedItems.push(item);
                        }
                    } else {
                        failCount++;
                    }

                    transferNext(index + 1);
                };

                this.copyItemRecursive(item.filepath, destPath, item.isDirectory, function(success) {
                    if (success || !isTrashTarget) {
                        finishTransfer(success);
                        return;
                    }

                    var retryName = this.buildFallbackUniqueFileName(this.getItemFileName(item));
                    var retryPath = normalizedTarget + retryName;

                    this.copyItemRecursive(item.filepath, retryPath, item.isDirectory, function(retrySuccess) {
                        finishTransfer(retrySuccess);
                    });
                }.bind(this));
            }.bind(this));
        }.bind(this);

        transferNext(0);
    },

    /**
     * Copy items to target location
     * @param {Array<Object>} items - Items to copy
     * @param {string} targetPath - Destination path
     * @param {Object|Function} options - Optional transfer options or callback
     * @param {Function} callback - Callback(success, message)
     */
    copyItems: function(items, targetPath, options, callback) {
        if (typeof options === 'function') {
            callback = options;
            options = {};
        }

        options = options || {};
        options.mode = 'copy';
        this.transferItems(items, targetPath, options, callback);
    },
    
    /**
     * Copy a single item recursively
     * @param {string} sourcePath - Source filepath
     * @param {string} destPath - Destination filepath
     * @param {boolean} isDirectory - Is this a directory
     * @param {Function} callback - Callback(success)
     */
    copyItemRecursive: function(sourcePath, destPath, isDirectory, callback) {
        if (isDirectory) {
            // Create directory first
            window.filesystem.createDirectory(destPath, function(success) {
                if (!success) {
                    window.debugError('[FileOps] Failed to create directory:', destPath);
                    if (callback) callback(false);
                    return;
                }
                
                // List contents and copy recursively
                window.filesystem.listDirectory(sourcePath, function(contents) {
                    if (!contents || contents.length === 0) {
                        if (callback) callback(true);
                        return;
                    }
                    
                    var copyIndex = 0;
                    var copyNextItem = function() {
                        if (copyIndex >= contents.length) {
                            if (callback) callback(true);
                            return;
                        }
                        
                        var item = contents[copyIndex];
                        var itemSourcePath = sourcePath + (sourcePath.endsWith('/') ? '' : '/') + item.name;
                        var itemDestPath = destPath + (destPath.endsWith('/') ? '' : '/') + item.name;
                        
                        if (item.type === 'directory') {
                            itemSourcePath += '/';
                            itemDestPath += '/';
                        }
                        
                        this.copyItemRecursive(itemSourcePath, itemDestPath, item.type === 'directory', function(success) {
                            copyIndex++;
                            copyNextItem();
                        });
                    }.bind(this);
                    
                    copyNextItem();
                }.bind(this));
            }.bind(this));
        } else {
            // Copy file
            window.filesystem.readFile(sourcePath, function(content) {
                if (content === null) {
                    window.debugError('[FileOps] Failed to read source file:', sourcePath);
                    if (callback) callback(false);
                    return;
                }
                
                window.filesystem.writeFile(destPath, content, function(success) {
                    if (!success) {
                        window.debugError('[FileOps] Failed to write file:', destPath);
                    }
                    if (callback) callback(success);
                });
            });
        }
    },
    
    /**
     * Move items to target location
     * @param {Array<Object>} items - Items to move
     * @param {string} targetPath - Destination path
     * @param {Function} callback - Callback(success, message)
     */
    moveItems: function(items, targetPath, callback) {
        this.transferItems(items, targetPath, {
            mode: 'move'
        }, callback);
    },
    
    /**
     * Create a new file
     * @param {string} parentPath - Parent directory path
     * @param {string} fileName - File name (optional, will auto-generate new_file, new_file1, etc.)
     * @param {Function} callback - Callback(success, filepath, displayName)
     */
    createNewFile: function(parentPath, fileName, callback) {
        if (!parentPath) {
            window.debugError('[FileOps] No parent path provided');
            if (callback) callback(false, null, null);
            return;
        }

        if (window.isEditableFilesystemPath && !window.isEditableFilesystemPath(parentPath)) {
            window.osErrorHandler.showNotification('This folder is read-only', 'warning', 2000);
            if (callback) callback(false, null, null);
            return;
        }
        
        // Ensure parent path ends with /
        if (!parentPath.endsWith('/')) {
            parentPath += '/';
        }
        
        var self = this;
        
        // If fileName provided, use it; otherwise find next available new_file name
        if (fileName) {
            var filepath = parentPath + fileName;
            // Create empty file
            if (window.filesystem) {
                window.filesystem.writeFile(filepath, '', function(success) {
                    if (success) {
                        window.debugLog('[FileOps] Created file:', filepath);
                        // Extract display name (without .txt extension)
                        var displayName = fileName.replace(/\.txt$/, '');
                        if (callback) callback(true, filepath, displayName);
                    } else {
                        window.osErrorHandler.showNotification('Failed to create file', 'error');
                        if (callback) callback(false, null, null);
                    }
                });
            } else {
                window.osErrorHandler.showNotification('Filesystem not available', 'error');
                if (callback) callback(false, null, null);
            }
        } else {
            // Find next available new_file name
            this.findNextAvailableFileName(parentPath, 'new_file', function(baseFileName) {
                var filepath = parentPath + baseFileName;
                // Create empty file
                if (window.filesystem) {
                    window.filesystem.writeFile(filepath, '', function(success) {
                        if (success) {
                            window.debugLog('[FileOps] Created file:', filepath);
                            // Display name is baseFileName without .txt extension
                            var displayName = baseFileName.replace(/\.txt$/, '');
                            if (callback) callback(true, filepath, displayName);
                        } else {
                            window.osErrorHandler.showNotification('Failed to create file', 'error');
                            if (callback) callback(false, null, null);
                        }
                    });
                } else {
                    window.osErrorHandler.showNotification('Filesystem not available', 'error');
                    if (callback) callback(false, null, null);
                }
            });
        }
    },

    createNewFolder: function(parentPath, folderName, callback) {
        if (!parentPath) {
            if (callback) callback(false, null, null);
            return;
        }

        if (window.isEditableFilesystemPath && !window.isEditableFilesystemPath(parentPath)) {
            window.osErrorHandler.showNotification('This folder is read-only', 'warning', 2000);
            if (callback) callback(false, null, null);
            return;
        }

        var normalizedParent = this.normalizeDirectoryPath(parentPath);
        var self = this;

        var finishCreate = function(resolvedFolderName) {
            var folderPath = normalizedParent + resolvedFolderName + '/';
            window.filesystem.createDirectory(folderPath, function(success) {
                if (success) {
                    if (callback) callback(true, folderPath, resolvedFolderName);
                    return;
                }

                window.osErrorHandler.showNotification('Failed to create folder', 'error');
                if (callback) callback(false, null, null);
            });
        };

        if (folderName) {
            finishCreate(folderName);
            return;
        }

        window.filesystem.listDirectory(normalizedParent, function(files) {
            var existing = {};
            (files || []).forEach(function(file) {
                if (file) {
                    var existingName = window.osFilenameRules
                        ? window.osFilenameRules.normalizeBaseName(file.displayName || file.name || '')
                        : String(file.name || '').toLowerCase();
                    if (existingName) {
                        existing[existingName] = true;
                    }
                }
            });

            var baseName = 'new_folder';
            var resolved = window.osFilenameRules
                ? window.osFilenameRules.getIndexedBaseName(baseName, 0)
                : baseName;
            var index = 1;

            while (existing[resolved.toLowerCase()]) {
                resolved = window.osFilenameRules
                    ? window.osFilenameRules.getIndexedBaseName(baseName, index)
                    : (baseName + '_' + index);
                index++;
            }

            finishCreate(resolved);
        });
    },
    
    /**
     * Find next available filename (e.g., new_file, new_file1, new_file2, etc.)
     * @param {string} parentPath - Parent directory path
     * @param {string} baseName - Base name (e.g., "new_file")
     * @param {Function} callback - Callback(filename with .txt extension)
     */
    findNextAvailableFileName: function(parentPath, baseName, callback) {
        if (!window.filesystem) {
            // Fallback
            if (callback) callback(baseName + '.txt');
            return;
        }
        
        // List directory to check existing files
        window.filesystem.listDirectory(parentPath, function(files) {
            if (!files || !Array.isArray(files)) {
                // Can't check, just use base name
                if (callback) callback(baseName + '.txt');
                return;
            }
            
            // Get all existing filenames (lowercase, without extension for comparison)
            var existingNames = files.map(function(file) {
                if (window.osFilenameRules) {
                    return window.osFilenameRules.normalizeBaseName(file.displayName || file.name || '');
                }
                var name = (file.name || '').toLowerCase();
                return name.replace(/\.txt$/, '');
            });
            
            // Check if base name is available
            if (existingNames.indexOf(baseName) === -1) {
                if (callback) callback(baseName + '.txt');
                return;
            }
            
            // Find next available alphabetic suffix
            var index = 1;
            var candidate = window.osFilenameRules
                ? window.osFilenameRules.getIndexedBaseName(baseName, index)
                : (baseName + index);
            while (existingNames.indexOf(candidate) !== -1) {
                index++;
                candidate = window.osFilenameRules
                    ? window.osFilenameRules.getIndexedBaseName(baseName, index)
                    : (baseName + index);
            }
            
            if (callback) callback(candidate + '.txt');
        });
    },
    
    /**
     * Copy item to Desktop
     * @param {Object} item - Item object {filepath, name, filetype, isDirectory}
     * @param {Function} callback - Callback(success, message)
     */
    copyToDesktop: function(item, callback) {
        var desktopPath = window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/');
        this.copyItems([item], desktopPath, callback);
    },
    
    /**
     * Move item to Desktop
     * @param {Object} item - Item object {filepath, name, filetype, isDirectory}
     * @param {Function} callback - Callback(success, message)
     */
    moveToDesktop: function(item, callback) {
        var desktopPath = window.PATH_DESKTOP || (window.DRIVE_C + '/desktop/');
        this.moveItems([item], desktopPath, callback);
    },
    
    /**
     * Copy item to External Drive
     * @param {Object} item - Item object {filepath, name, filetype, isDirectory}
     * @param {Function} callback - Callback(success, message)
     */
    copyToExternal: function(item, callback) {
        var externalPath = window.DRIVE_EXTERNAL + '/';
        this.copyItems([item], externalPath, callback);
    },
    
    /**
     * Move item to External Drive
     * @param {Object} item - Item object {filepath, name, filetype, isDirectory}
     * @param {Function} callback - Callback(success, message)
     */
    moveToExternal: function(item, callback) {
        var externalPath = window.DRIVE_EXTERNAL + '/';
        this.moveItems([item], externalPath, callback);
    },
    
    /**
     * Make a copy of an item (duplicate)
     * @param {Object} item - Item object {filepath, name, filetype, isDirectory}
     * @param {Function} callback - Callback(success, newFilepath)
     */
    makeCopy: function(item, callback) {
        if (!item || !item.filepath) {
            window.debugError('[FileOps] Invalid item for copy');
            if (callback) callback(false, null);
            return;
        }
        
        var fileName = this.getItemFileName(item);
        var targetPath = this.getParentDirectory(item.filepath);

        if (!fileName || !targetPath) {
            window.debugError('[FileOps] Could not determine duplicate destination');
            if (callback) callback(false, null);
            return;
        }

        var fileParts = this.splitFileName(fileName);
        var requestedName = 'copy_of_' + fileParts.base + fileParts.extension;

        this.resolveDestinationPath({
            filepath: item.filepath,
            filename: requestedName
        }, targetPath, function(destPath) {
            if (!destPath) {
                if (callback) callback(false, null);
                return;
            }

            this.copyItemRecursive(item.filepath, destPath, item.isDirectory, function(success) {
                if (success) {
                    window.osErrorHandler.showNotification('Created copy', 'success', 2000);
                    if (callback) callback(true, destPath);
                } else {
                    window.debugError('[FileOps] Failed to copy item for duplication');
                    if (callback) callback(false, null);
                }
            });
        }.bind(this));
    },
    
    /**
     * Check if a path is protected
     * @param {string} filepath - Path to check
     * @returns {boolean} True if protected
     */
    isProtectedPath: function(filepath) {
        if (!filepath) return false;
        
        var lowerPath = window.normalizePath ? window.normalizePath(filepath).toLowerCase() : filepath.toLowerCase();
        
        // System directories
        var protectedPaths = [
            window.DRIVE_C + '/' + window.FOLDER_SYSTEM + '/',
            window.DRIVE_C + '/' + window.FOLDER_SYSTEM + '/' + window.FOLDER_PROGRAMS + '/',
            this.TRASH_PATH
        ];
        
        for (var i = 0; i < protectedPaths.length; i++) {
            var protectedPath = window.normalizePath ? window.normalizePath(protectedPaths[i]).toLowerCase() : protectedPaths[i].toLowerCase();
            if (lowerPath === protectedPath) {
                return true;
            }
        }
        
        // config.dat
        if (lowerPath.indexOf('config.dat') !== -1) {
            return true;
        }
        
        // Programs (.exe files)
        if (lowerPath.endsWith('.exe')) {
            return true;
        }
        
        return false;
    }
};
]]
end

return MODULE

