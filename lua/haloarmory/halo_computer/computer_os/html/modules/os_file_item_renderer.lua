--[[
    File: modules/os_file_item_renderer.lua
    Purpose: Shared file/folder icon HTML generator
    
    Generates consistent HTML for file/folder items used by both Desktop and File Browser.
    Uses full paths (data-filepath) as unique identifiers to prevent navigation bugs.
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// FILE ITEM RENDERER - Shared HTML Generator
// ============================================================================

window.osFileItemRenderer = {
    previewCache: {},
    previewPending: {},

    invalidatePreviewCache: function(path) {
        var normalizedPath = String(path || '').toLowerCase();
        if (!normalizedPath) {
            this.previewCache = {};
            this.previewPending = {};
            return;
        }

        var isDirectory = /\/$/.test(normalizedPath);

        for (var cacheKey in this.previewCache) {
            if (!Object.prototype.hasOwnProperty.call(this.previewCache, cacheKey)) {
                continue;
            }

            var normalizedCacheKey = String(cacheKey || '').toLowerCase();
            if ((isDirectory && normalizedCacheKey.indexOf(normalizedPath) === 0) ||
                (!isDirectory && normalizedCacheKey === normalizedPath)) {
                delete this.previewCache[cacheKey];
            }
        }

        for (var pendingKey in this.previewPending) {
            if (!Object.prototype.hasOwnProperty.call(this.previewPending, pendingKey)) {
                continue;
            }

            var normalizedPendingKey = String(pendingKey || '').toLowerCase();
            if ((isDirectory && normalizedPendingKey.indexOf(normalizedPath) === 0) ||
                (!isDirectory && normalizedPendingKey === normalizedPath)) {
                delete this.previewPending[pendingKey];
            }
        }
    },

    /**
     * Render a file or folder item
     * @param {Object} file - File data object
     * @param {string} location - 'desktop' or 'filebrowser'
     * @returns {string} HTML string
     */
    renderFileItem: function(file, location) {
        if (!file) return '';
        
        var name = file.name || 'Untitled';
        var displayName = file.displayName || name;
        var filetype = file.fileType || file.type || 'file';
        if (typeof window.cleanDisplayName === 'function') {
            displayName = window.cleanDisplayName(displayName);
        }
        if (filetype === 'image' && !/\.image$/i.test(String(displayName || ''))) {
            displayName = String(displayName || '')
                .replace(/\.(png|jpg|jpeg|image|dat)$/i, '') + '.image';
        }
        var filepath = file.path || file.filepath || '';
        var icon = file.icon || this.getDefaultIcon(filetype);
        var isProtected = file.protected || file.readOnly || false;
        
        var itemClass = 'os-file-item';
        if (location === 'desktop') {
            itemClass += ' os-desktop-icon';
        } else if (location === 'filebrowser') {
            itemClass += ' filebrowser-item';
        }
        
        var html = '<div class="' + itemClass + '"';
        html += ' data-filepath="' + this.escapeHtml(filepath) + '"';
        html += ' data-filename="' + this.escapeHtml(name) + '"';
        html += ' data-filetype="' + this.escapeHtml(filetype) + '"';
        html += ' data-name="' + this.escapeHtml(displayName) + '"';
        html += ' data-display-name="' + this.escapeHtml(displayName) + '"';
        if (file.programId) {
            html += ' data-program-id="' + this.escapeHtml(file.programId) + '"';
        }
        if (file.folder) {
            html += ' data-folder="' + this.escapeHtml(file.folder) + '"';
        }
        if (isProtected) {
            html += ' data-protected="true"';
        }
        html += '>';
        
        html += '<div class="os-item-icon' + (filetype === 'image' ? ' os-item-icon-preview' : '') + '"';
        if (filetype === 'image') {
            html += ' data-preview-path="' + this.escapeHtml(filepath) + '"';
            html += ' data-preview-name="' + this.escapeHtml(name) + '"';
        }
        html += '>';
        html += this.escapeHtml(icon);
        html += '</div>';
        
        html += '<div class="os-item-label">';
        html += this.escapeHtml(displayName);
        html += '</div>';
        
        html += '</div>';
        
        return html;
    },

    getImagePreviewSource: function(filepath, filename, content) {
        var source = String(content || '');
        if (!source) {
            return '';
        }

        if (String(filepath || '').toLowerCase().endsWith('.image.dat')) {
            try {
                var payload = JSON.parse(source);
                if (payload && payload.filename) {
                    filename = payload.filename;
                }
                if (payload && payload.content) {
                    source = String(payload.content);
                }
            } catch (e) {
            }
        }

        if (source.indexOf('data:image/') === 0) {
            return source;
        }

        var lowerName = String(filename || filepath || '').toLowerCase();
        var mime = 'image/png';
        if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
            mime = 'image/jpeg';
        }
        return 'data:' + mime + ';base64,' + source;
    },

    hydrateImagePreviews: function(root) {
        if (!root || !window.filesystem) {
            return;
        }

        var self = this;
        root.querySelectorAll('.os-item-icon-preview[data-preview-path]').forEach(function(iconEl) {
            if (iconEl.getAttribute('data-preview-state') === 'ready') {
                return;
            }

            var filepath = iconEl.getAttribute('data-preview-path');
            var filename = iconEl.getAttribute('data-preview-name') || '';
            if (!filepath) {
                return;
            }

            if (self.previewCache[filepath]) {
                iconEl.innerHTML = '<img class="os-item-icon-image-preview" src="' + self.escapeHtml(self.previewCache[filepath]) + '" alt="">';
                iconEl.setAttribute('data-preview-state', 'ready');
                return;
            }

            if (self.previewPending[filepath]) {
                return;
            }

            self.previewPending[filepath] = true;
            iconEl.setAttribute('data-preview-state', 'loading');

            window.filesystem.readFile(filepath, function(content) {
                delete self.previewPending[filepath];

                var src = self.getImagePreviewSource(filepath, filename, content);
                if (!src) {
                    iconEl.setAttribute('data-preview-state', 'failed');
                    return;
                }

                self.previewCache[filepath] = src;
                root.querySelectorAll('.os-item-icon-preview[data-preview-path]').forEach(function(match) {
                    if (match.getAttribute('data-preview-path') !== filepath) {
                        return;
                    }
                    match.innerHTML = '<img class="os-item-icon-image-preview" src="' + self.escapeHtml(src) + '" alt="">';
                    match.setAttribute('data-preview-state', 'ready');
                });
            });
        });
    },
    
    /**
     * Get default icon for file type
     * @param {string} filetype - File type
     * @returns {string} Icon emoji
     */
    getDefaultIcon: function(filetype) {
        switch (filetype) {
            case 'directory': return String.fromCodePoint(0x1F4C1);
            case 'shortcut': return String.fromCodePoint(0x1F517);
            case 'text': return String.fromCodePoint(0x1F4C4);
            case 'image': return String.fromCodePoint(0x1F5BC, 0xFE0F);
            case 'audio': return String.fromCodePoint(0x1F3B5);
            case 'config': return String.fromCodePoint(0x2699, 0xFE0F);
            case 'data': return String.fromCodePoint(0x1F5C4, 0xFE0F);
            case 'program': return String.fromCodePoint(0x2699, 0xFE0F);
            default: return String.fromCodePoint(0x1F4C4);
        }
    },
    
    /**
     * Escape HTML to prevent XSS
     * @param {string} text - Text to escape
     * @returns {string} Escaped text
     */
    escapeHtml: function(text) {
        if (!text) return '';
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;'
        };
        return String(text).replace(/[&<>"']/g, function(m) { return map[m]; });
    },
    
    /**
     * Render multiple file items
     * @param {Array} files - Array of file objects
     * @param {string} location - 'desktop' or 'filebrowser'
     * @returns {string} Combined HTML string
     */
    renderFileItems: function(files, location) {
        if (!files || !files.length) return '';
        
        var html = '';
        for (var i = 0; i < files.length; i++) {
            html += this.renderFileItem(files[i], location);
        }
        return html;
    },
    
    /**
     * Update a container with rendered items
     * @param {Element} container - Container element
     * @param {Array} files - Array of file objects
     * @param {string} location - 'desktop' or 'filebrowser'
     */
    updateContainer: function(container, files, location) {
        if (!container) return;
        
        container.innerHTML = this.renderFileItems(files, location);
        this.hydrateImagePreviews(container);
    }
};
]]
end

return MODULE
