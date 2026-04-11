--[[
    File: modules/os_utilities_js.lua
    Purpose: JavaScript utility functions for WebOS
    
    Contains: Path normalization, HTML escaping, debug logging, file type detection
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Normalize a filesystem path
 * @param {string} path - Path to normalize
 * @returns {string} Normalized path
 */
function normalizePath(path) {
    if (!path) return '';
    path = path.replace(/\\/g, '/');
    path = path.replace(/\/+/g, '/');
    if (path.length > 1 && path.endsWith('/')) {
        path = path.slice(0, -1);
    }
    return path;
}

/**
 * Normalize path for filesystem operations (ensures trailing slash for directories)
 * @param {string} path - Path to normalize
 * @returns {string} Normalized path
 */
function normalizePathForFilesystem(path) {
    path = normalizePath(path);
    if (path && !path.endsWith('/') && path.indexOf('.') === -1) {
        path += '/';
    }
    return path;
}

/**
 * Get drive from path
 * @param {string} path - Full path
 * @returns {string} Drive name
 */
function getDriveFromPath(path) {
    if (!path) return 'C:';
    var match = path.match(/^([^:\/]+):/);
    return match ? match[1] + ':' : 'C:';
}

/**
 * Normalize path for refresh operations
 * @param {string} path - Path to normalize
 * @returns {string} Normalized path
 */
function pathForRefresh(path) {
    if (!path) return '';
    path = normalizePath(path);
    if (!path.endsWith('/')) {
        path += '/';
    }
    return path;
}

/**
 * Clean display name (remove extensions)
 * @param {string} name - Filename
 * @returns {string} Cleaned name
 */
function cleanDisplayName(name) {
    if (!name) return '';
    if (/\.shortcut\.dat$/i.test(name)) {
        return name.replace(/\.shortcut\.dat$/i, '');
    }
    if (/\.image\.dat$/i.test(name)) {
        return name.replace(/\.image\.dat$/i, '.image').replace(/\.(png|jpg|jpeg)\.image$/i, '.image');
    }
    if (/\.txt$/i.test(name)) {
        return name.replace(/\.txt$/i, '');
    }
    if (/^config\.dat$/i.test(name)) {
        return '.config';
    }
    return String(name);
}

/**
 * Check if path is in system folder
 * @param {string} path - Path to check
 * @returns {boolean} True if in system folder
 */
function isInSystemFolder(path) {
    if (!path) return false;
    var normalized = normalizePath(path).toLowerCase();
    return normalized.indexOf('/.system/') !== -1 || normalized.startsWith('c:/.system');
}

function isTrashPath(path) {
    if (!path) return false;
    var normalized = normalizePath(path).toLowerCase();
    return normalized === 'c:/.system/trash' || normalized === 'c:/.system/trash/';
}

function isInTrashFolder(path) {
    if (!path) return false;
    var normalized = normalizePath(path).toLowerCase();
    return normalized.indexOf('c:/.system/trash/') === 0;
}

function isRestrictedSystemPath(path) {
    if (!path) return false;
    var normalized = normalizePath(path).toLowerCase();
    if (!normalized.startsWith('c:/.system')) {
        return false;
    }
    return !isTrashPath(normalized) && !isInTrashFolder(normalized);
}

function isEditableFilesystemPath(path) {
    if (!path) return true;
    return !isRestrictedSystemPath(path) && !isTrashPath(path) && !isInTrashFolder(path);
}

/**
 * Check if drag operation is dropping on itself
 * @param {string} sourcePath - Source path
 * @param {string} targetPath - Target path
 * @returns {boolean} True if self-drop
 */
function isSelfDrop(sourcePath, targetPath) {
    if (!sourcePath || !targetPath) return false;
    var source = normalizePath(sourcePath).toLowerCase();
    var target = normalizePath(targetPath).toLowerCase();
    return source === target || target.startsWith(source + '/');
}

/**
 * Normalize path for navigation (ensures proper format for UI)
 * @param {string} path - Path to normalize
 * @returns {string} Normalized path
 */
window.normalizePathForNavigation = function(path) {
    if (!path) return 'C:/';
    path = normalizePath(path);
    if (!path.match(/^[A-Za-z]+:/)) {
        path = 'C:/' + path;
    }
    if (!path.endsWith('/')) {
        path += '/';
    }
    return path;
};

/**
 * Parse file path into components
 * @param {string} path - Full file path
 * @returns {Object} {drive, directory, filename, extension}
 */
window.parseFilePath = function(path) {
    if (!path) return { drive: 'C:', directory: '/', filename: '', extension: '' };
    
    var drive = getDriveFromPath(path);
    var pathWithoutDrive = path.substring(drive.length);
    var lastSlash = pathWithoutDrive.lastIndexOf('/');
    var directory = lastSlash >= 0 ? pathWithoutDrive.substring(0, lastSlash + 1) : '/';
    var filename = lastSlash >= 0 ? pathWithoutDrive.substring(lastSlash + 1) : pathWithoutDrive;
    var lastDot = filename.lastIndexOf('.');
    var extension = lastDot >= 0 ? filename.substring(lastDot) : '';
    
    return {
        drive: drive,
        directory: directory,
        filename: filename,
        extension: extension
    };
};

/**
 * Get filename from path
 * @param {string} path - Full path
 * @returns {string} Filename
 */
window.getFileNameFromPath = function(path) {
    if (!path) return '';
    var parts = path.split('/');
    return parts[parts.length - 1] || parts[parts.length - 2] || '';
};

/**
 * Get path without drive
 * @param {string} path - Full path
 * @returns {string} Path without drive prefix
 */
window.getPathWithoutDrive = function(path) {
    if (!path) return '';
    return path.replace(/^[A-Za-z]+:/, '');
};

/**
 * Check if path is a directory (ends with /)
 * @param {string} path - Path to check
 * @returns {boolean} True if directory
 */
window.isDirectoryPath = function(path) {
    return path && path.endsWith('/');
};

/**
 * Get file type from path
 * @param {string} path - File path
 * @returns {string} File type
 */
window.getFileTypeFromPath = function(path) {
    if (!path) return 'unknown';
    if (path.endsWith('.shortcut.dat')) return 'shortcut';
    if (path.endsWith('.image.dat')) return 'image';
    if (path.endsWith('config.dat')) return 'config';
    if (path.endsWith('.txt')) return 'text';
    if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image';
    if (path.endsWith('.exe')) return 'program';
    if (path.endsWith('.dat')) return 'data';
    if (path.endsWith('/')) return 'directory';
    return 'file';
};

/**
 * Escape HTML to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
    var map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    };
    return String(text).replace(/[&<>"']/g, function(m) { return map[m]; });
}

/**
 * Debounce function execution
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in ms
 * @returns {Function} Debounced function
 */
function debounce(func, wait) {
    var timeout;
    return function executedFunction() {
        var context = this;
        var args = arguments;
        var later = function() {
            timeout = null;
            func.apply(context, args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function copyTextToClipboard(text, callback) {
    var normalized = String(text || '');
    if (!normalized) {
        if (callback) {
            callback(false);
        }
        return;
    }

    var finish = function(success) {
        if (callback) {
            callback(!!success);
        }
    };

    if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
        navigator.clipboard.writeText(normalized).then(function() {
            finish(true);
        }).catch(function() {
            copyTextToClipboardFallback(normalized, finish);
        });
        return;
    }

    copyTextToClipboardFallback(normalized, finish);
}

function copyTextToClipboardFallback(text, callback) {
    var helper = document.createElement('textarea');
    helper.value = text;
    helper.setAttribute('readonly', 'readonly');
    helper.style.position = 'fixed';
    helper.style.left = '-9999px';
    helper.style.top = '0';
    helper.style.opacity = '0';
    document.body.appendChild(helper);

    helper.focus();
    helper.select();

    var success = false;
    try {
        success = document.execCommand && document.execCommand('copy');
    } catch (error) {
        success = false;
    }

    if (helper.parentNode) {
        helper.parentNode.removeChild(helper);
    }

    if (callback) {
        callback(!!success);
    }
}

// Export for window scope
window.normalizePath = normalizePath;
window.normalizePathForFilesystem = normalizePathForFilesystem;
window.getDriveFromPath = getDriveFromPath;
window.pathForRefresh = pathForRefresh;
window.cleanDisplayName = cleanDisplayName;
window.isInSystemFolder = isInSystemFolder;
window.isTrashPath = isTrashPath;
window.isInTrashFolder = isInTrashFolder;
window.isRestrictedSystemPath = isRestrictedSystemPath;
window.isEditableFilesystemPath = isEditableFilesystemPath;
window.isSelfDrop = isSelfDrop;
window.copyTextToClipboard = copyTextToClipboard;
window.escapeHtml = escapeHtml;
window.debounce = debounce;

window.osFilenameRules = {
    MAX_LENGTH: 32,

    stripKnownExtension: function(name) {
        return String(name || '').replace(/(\.shortcut\.dat|\.image\.dat|\.txt|\.dat|\.json|\.xml|\.csv|\.dem|\.vcd|\.gma|\.mdl|\.phy|\.vvd|\.vtx|\.ani|\.vtf|\.vmt|\.png|\.jpg|\.jpeg|\.mp3|\.wav|\.ogg)$/i, '');
    },

    normalizeEditableBaseName: function(name) {
        var value = this.stripKnownExtension(name);
        value = value.toLowerCase();
        value = value.replace(/\s+/g, '_');
        value = value.replace(/_+/g, '_');
        value = value.replace(/[^a-z0-9_.-]/g, '');
        value = value.replace(/^\.+/, '');
        return value;
    },

    normalizeBaseName: function(name) {
        var value = this.normalizeEditableBaseName(name);
        value = value.replace(/^_+/, '').replace(/_+$/, '');
        return value;
    },

    validateBaseName: function(name) {
        var rawValue = String(name || '');
        var editableValue = this.normalizeEditableBaseName(rawValue);
        var normalizedValue = editableValue.replace(/^_+/, '').replace(/_+$/, '');

        if (!rawValue.trim()) {
            return {
                isValid: false,
                editableValue: editableValue,
                normalizedValue: normalizedValue,
                message: 'Name is required.'
            };
        }

        if (!normalizedValue) {
            return {
                isValid: false,
                editableValue: editableValue,
                normalizedValue: normalizedValue,
                message: 'Use letters a-z and numbers 0-9. Spaces become underscores. "-" and "." are allowed.'
            };
        }

        if (normalizedValue.length > this.MAX_LENGTH) {
            return {
                isValid: false,
                editableValue: editableValue,
                normalizedValue: normalizedValue,
                message: 'Name must be 32 characters or fewer.'
            };
        }

        return {
            isValid: true,
            editableValue: editableValue,
            normalizedValue: normalizedValue,
            message: ''
        };
    },

    getIndexedBaseName: function(baseName, index) {
        var normalizedBase = this.normalizeBaseName(baseName) || 'untitled';
        if (!index || index < 1) {
            return normalizedBase;
        }

        var suffix = '';
        var remaining = index;
        while (remaining > 0) {
            remaining--;
            suffix = String.fromCharCode(97 + (remaining % 26)) + suffix;
            remaining = Math.floor(remaining / 26);
        }

        var separator = normalizedBase ? '_' : '';
        var maxBaseLength = this.MAX_LENGTH - separator.length - suffix.length;
        if (maxBaseLength < 1) {
            maxBaseLength = 1;
        }

        normalizedBase = normalizedBase.slice(0, maxBaseLength).replace(/^_+/, '').replace(/_+$/, '');
        if (!normalizedBase) {
            normalizedBase = 'u';
        }

        return normalizedBase + separator + suffix;
    }
};
]]
end

return MODULE

