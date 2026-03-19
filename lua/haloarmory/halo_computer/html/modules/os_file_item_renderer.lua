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
    /**
     * Render a file or folder item
     * @param {Object} file - File data object
     * @param {string} location - 'desktop' or 'filebrowser'
     * @returns {string} HTML string
     */
    renderFileItem: function(file, location) {
        if (!file) return '';
        
        // Extract file properties
        var name = file.name || 'Untitled';
        var displayName = file.displayName || name;
        var filepath = file.path || file.filepath || '';
        var filetype = file.fileType || file.type || 'file';
        var icon = file.icon || this.getDefaultIcon(filetype);
        var isProtected = file.protected || file.readOnly || false;
        var isDirectory = filetype === 'directory';
        
        // Determine CSS classes based on location
        var itemClass = 'os-file-item';
        if (location === 'desktop') {
            itemClass += ' os-desktop-icon';
        } else if (location === 'filebrowser') {
            itemClass += ' filebrowser-item';
        }
        
        // Build HTML with all critical data attributes
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
        
        // Icon
        html += '<div class="os-item-icon">';
        html += this.escapeHtml(icon);
        html += '</div>';
        
        // Label
        html += '<div class="os-item-label">';
        html += this.escapeHtml(displayName);
        html += '</div>';
        
        html += '</div>';
        
        return html;
    },
    
    /**
     * Get default icon for file type
     * @param {string} filetype - File type
     * @returns {string} Icon emoji
     */
    getDefaultIcon: function(filetype) {
        switch(filetype) {
            case 'directory': return '📁';
            case 'shortcut': return '🔗';
            case 'text': return '📄';
            case 'config': return '⚙️';
            default: return '📄';
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
    }
};
]]
end

return MODULE

