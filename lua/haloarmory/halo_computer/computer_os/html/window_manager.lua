-- Window Manager Module - Provides window management utilities
HALOARMORY.COMPUTER.INTERFACE.WINDOW = HALOARMORY.COMPUTER.INTERFACE.WINDOW or {}

local WINDOW = HALOARMORY.COMPUTER.INTERFACE.WINDOW

-- Window ID counter
WINDOW.nextWindowId = 0

function WINDOW.GetNextId()
    WINDOW.nextWindowId = WINDOW.nextWindowId + 1
    return "window_" .. WINDOW.nextWindowId
end

-- Generate HTML for a draggable window
function WINDOW.Create(id, title, content, options)
    options = options or {}
    local width = options.width or 600
    local height = options.height or 400
    local x = options.x or 100
    local y = options.y or 100
    local minWidth = options.minWidth or 300
    local minHeight = options.minHeight or 200
    local resizable = options.resizable ~= false
    local icon = options.icon or ""
    
    id = id or WINDOW.GetNextId()
    
    local html = [[
<div id="]] .. id .. [[" class="os-window" style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; left: ]] .. x .. [[px; top: ]] .. y .. [[px;">
    <div class="os-window-titlebar" id="]] .. id .. [[_titlebar">
        ]] .. (icon ~= "" and "<span class='os-window-icon'>" .. icon .. "</span>" or "") .. [[
        <span class="os-window-title">]] .. HALOARMORY.COMPUTER.INTERFACE.HTML.Escape(title) .. [[</span>
        <div class="os-window-controls">
            <button class="os-window-btn os-window-minimize" onclick="windowManager.minimize(']] .. id .. [[')">−</button>
            <button class="os-window-btn os-window-maximize" onclick="windowManager.maximize(']] .. id .. [[')">□</button>
            <button class="os-window-btn os-window-close" onclick="windowManager.close(']] .. id .. [[')">×</button>
        </div>
    </div>
    <div class="os-window-content" id="]] .. id .. [[_content">
        ]] .. content .. [[
    </div>
]] .. (resizable and [[
    <div class="os-window-resize-handle"></div>
]] or "") .. [[
</div>
]]
    
    return html
end

-- Generate window manager JavaScript
function WINDOW.GetJavaScript()
    return [[
var windowManager = {
    windows: {},
    activeWindow: null,
    zIndex: 1000,
    
    /**
     * Create a new window dynamically
     * @param {string} id - Window ID
     * @param {string} title - Window title
     * @param {string} content - Window content HTML
     * @param {object} options - Window options (width, height, x, y, icon, etc.)
     */
    create: function(id, title, content, options) {
        options = options || {};
        var width = options.width || 600;
        var height = options.height || 400;
        var x = options.x || 100;
        var y = options.y || 100;
        var icon = options.icon || '';
        var resizable = options.resizable !== false;
        
        // Create window HTML
        var windowHTML = '<div id="' + id + '" class="os-window" style="width: ' + width + 'px; height: ' + height + 'px; left: ' + x + 'px; top: ' + y + 'px;">' +
            '<div class="os-window-titlebar" id="' + id + '_titlebar">' +
            (icon ? '<span class="os-window-icon">' + icon + '</span>' : '') +
            '<span class="os-window-title">' + title + '</span>' +
            '<div class="os-window-controls">' +
            '<button class="os-window-btn os-window-minimize" onclick="windowManager.minimize(\'' + id + '\')">−</button>' +
            '<button class="os-window-btn os-window-maximize" onclick="windowManager.maximize(\'' + id + '\')">□</button>' +
            '<button class="os-window-btn os-window-close" onclick="windowManager.close(\'' + id + '\')">×</button>' +
            '</div>' +
            '</div>' +
            '<div class="os-window-content" id="' + id + '_content">' +
            content +
            '</div>' +
            (resizable ? '<div class="os-window-resize-handle"></div>' : '') +
            '</div>';
        
        // Add to DOM
        var container = document.getElementById('os-windows-container') || document.body;
        var tempDiv = document.createElement('div');
        tempDiv.innerHTML = windowHTML;
        var windowElement = tempDiv.firstChild;
        container.appendChild(windowElement);
        
        // Register the window
        this.register(id, windowElement);
        
        return windowElement;
    },
    
    register: function(id, element) {
        var titleEl = element.querySelector('.os-window-title');
        var iconEl = element.querySelector('.os-window-icon');

        this.windows[id] = {
            element: element,
            minimized: false,
            maximized: false,
            originalSize: { width: 0, height: 0, x: 0, y: 0 },
            taskbarButton: null,
            titleObserver: null,
            title: titleEl ? titleEl.textContent : id,
            icon: iconEl ? iconEl.textContent : ''
        };

        this.addTaskbarButton(id);
        this.observeWindowTitle(id);
        this.makeActive(id);
        this.initDragging(id);
        this.initWindowClick(id);
        if (element.querySelector('.os-window-resize-handle')) {
            this.initResizing(id);
        }
        this.refreshTaskbarButtonStates();
    },
    
    initWindowClick: function(id) {
        var window = this.windows[id];
        var element = window.element;
        
        // Make window active when clicking anywhere on it
        element.addEventListener('mousedown', function(e) {
            // Don't interfere with buttons or resize handle
            if (e.target.classList.contains('os-window-btn') || 
                e.target.classList.contains('os-window-resize-handle') ||
                e.target.closest('.os-window-btn') ||
                e.target.closest('.os-window-resize-handle')) {
                return;
            }
            windowManager.makeActive(id);
        });
    },
    
    initDragging: function(id) {
        var window = this.windows[id];
        var titlebar = window.element.querySelector('.os-window-titlebar');
        var isDragging = false;
        var startX, startY, startLeft, startTop;
        
        titlebar.addEventListener('mousedown', function(e) {
            if (e.target.classList.contains('os-window-btn')) return;
            isDragging = true;
            windowManager.makeActive(id);
            startX = e.clientX;
            startY = e.clientY;
            startLeft = window.element.offsetLeft;
            startTop = window.element.offsetTop;
            e.preventDefault();
        });
        
        document.addEventListener('mousemove', function(e) {
            if (!isDragging) return;
            var dx = e.clientX - startX;
            var dy = e.clientY - startY;
            window.element.style.left = (startLeft + dx) + 'px';
            window.element.style.top = (startTop + dy) + 'px';
        });
        
        document.addEventListener('mouseup', function() {
            isDragging = false;
        });
    },
    
    initResizing: function(id) {
        var window = this.windows[id];
        var handle = window.element.querySelector('.os-window-resize-handle');
        var isResizing = false;
        var startX, startY, startWidth, startHeight, startLeft, startTop;
        
        handle.addEventListener('mousedown', function(e) {
            isResizing = true;
            windowManager.makeActive(id);
            startX = e.clientX;
            startY = e.clientY;
            startWidth = window.element.offsetWidth;
            startHeight = window.element.offsetHeight;
            startLeft = window.element.offsetLeft;
            startTop = window.element.offsetTop;
            e.preventDefault();
        });
        
        var resizeTimeout = null;
        document.addEventListener('mousemove', function(e) {
            if (!isResizing) return;
            var dx = e.clientX - startX;
            var dy = e.clientY - startY;
            var newWidth = Math.max(300, startWidth + dx);
            var newHeight = Math.max(200, startHeight + dy);
            window.element.style.width = newWidth + 'px';
            window.element.style.height = newHeight + 'px';
            
            // Debounce content recalculation during resize for performance
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(function() {
                windowManager.updateContentSize(id);
            }, 10);
        });
        
        document.addEventListener('mouseup', function() {
            if (isResizing) {
                isResizing = false;
                // Final content size update after resize completes
                windowManager.updateContentSize(id);
            }
        });
    },
    
    updateContentSize: function(id) {
        var window = this.windows[id];
        if (!window) return;
        
        var element = window.element;
        var content = element.querySelector('.os-window-content');
        
        if (!content) return;
        
        // Ensure window element is visible and has dimensions
        if (element.style.display === 'none') {
            element.style.display = 'flex';
        }
        
        // Force reflow to get actual window dimensions
        element.offsetHeight;
        var windowHeight = element.offsetHeight;
        var titlebarHeight = 32; // Titlebar is 32px fixed height
        
        // Calculate expected content height
        var expectedContentHeight = windowHeight - titlebarHeight;
        
        // Always set explicit height to ensure content fills available space
        // This is necessary because flexbox doesn't always recalculate after display:none
        if (expectedContentHeight > 0) {
            content.style.height = expectedContentHeight + 'px';
            content.style.minHeight = expectedContentHeight + 'px';
            content.style.maxHeight = expectedContentHeight + 'px';
            
            // Force reflow
            element.offsetHeight;
            content.offsetHeight;
            
            // Trigger resize event so programs can recalculate
            var resizeEvent = new Event('resize', { bubbles: true });
            element.dispatchEvent(resizeEvent);
            content.dispatchEvent(resizeEvent);
        }
    },
    
    makeActive: function(id) {
        // Remove active class from previous window
        Object.keys(this.windows).forEach(function(windowId) {
            var otherWindow = windowManager.windows[windowId];
            if (otherWindow && otherWindow.element) {
                otherWindow.element.classList.remove('os-window-active');
                otherWindow.element.style.zIndex = windowManager.zIndex;
            }
        });

        if (this.activeWindow && this.windows[this.activeWindow]) {
            this.windows[this.activeWindow].element.style.zIndex = this.zIndex;
        }
        this.zIndex++;
        this.activeWindow = id;
        if (this.windows[id]) {
            this.windows[id].element.style.zIndex = this.zIndex;
            this.windows[id].element.classList.add('os-window-active');
        }
        this.refreshTaskbarButtonStates();
        var event = new CustomEvent('windowactivated', { detail: { id: id } });
        document.dispatchEvent(event);
    },

    clearActive: function() {
        Object.keys(this.windows).forEach(function(windowId) {
            var otherWindow = windowManager.windows[windowId];
            if (otherWindow && otherWindow.element) {
                otherWindow.element.classList.remove('os-window-active');
                otherWindow.element.style.zIndex = windowManager.zIndex;
            }
        });

        this.activeWindow = null;
        this.refreshTaskbarButtonStates();
        var event = new CustomEvent('windowactivated', { detail: { id: null } });
        document.dispatchEvent(event);
    },
    
    minimize: function(id) {
        var window = this.windows[id];
        if (!window) return;
        if (window.minimized) {
            // Restore from minimized - use 'flex' to maintain proper window layout
            window.element.style.display = 'flex';
            window.minimized = false;
            this.makeActive(id);
            
            // Force layout recalculation after restoring from minimized state
            // Use longer timeout to ensure DOM has updated
            setTimeout(function() {
                // Force reflow before updating content size
                window.element.offsetHeight;
                windowManager.updateContentSize(id);
            }, 100);
        } else {
            window.element.style.display = 'none';
            window.minimized = true;
        }
        this.refreshTaskbarButtonStates();
        var event = new CustomEvent('windowminimized', { detail: { id: id, minimized: window.minimized } });
        document.dispatchEvent(event);
    },
    
    maximize: function(id) {
        var window = this.windows[id];
        if (!window) return;
        var self = this;
        if (window.maximized) {
            window.element.style.width = window.originalSize.width + 'px';
            window.element.style.height = window.originalSize.height + 'px';
            window.element.style.left = window.originalSize.x + 'px';
            window.element.style.top = window.originalSize.y + 'px';
            window.maximized = false;
        } else {
            window.originalSize = {
                width: window.element.offsetWidth,
                height: window.element.offsetHeight,
                x: window.element.offsetLeft,
                y: window.element.offsetTop
            };
            window.element.style.width = '100%';
            window.element.style.height = 'calc(100% - 40px)';
            window.element.style.left = '0px';
            window.element.style.top = '0px';
            window.maximized = true;
        }
        // Update content size after maximize/restore
        setTimeout(function() {
            self.updateContentSize(id);
        }, 50);
    },
    
    close: function(id) {
        var window = this.windows[id];
        if (!window) return;
        var event = new CustomEvent('windowclosing', { detail: { id: id } });
        document.dispatchEvent(event);
        this.removeTaskbarButton(id);
        if (window.titleObserver) {
            window.titleObserver.disconnect();
            window.titleObserver = null;
        }
        window.element.remove();
        delete this.windows[id];
        if (this.activeWindow === id) {
            this.activeWindow = null;
        }
        this.refreshTaskbarButtonStates();
    },
    
    open: function(id, title, content, options) {
        var html = this.generateWindowHTML(id, title, content, options);
        var temp = document.createElement('div');
        temp.innerHTML = html;
        var windowElement = temp.firstElementChild;
        document.getElementById('os-desktop').appendChild(windowElement);
        this.register(id, windowElement);
        return windowElement;
    },
    
    generateWindowHTML: function(id, title, content, options) {
        options = options || {};
        var width = options.width || 600;
        var height = options.height || 400;
        var x = options.x || 100;
        var y = options.y || 100;
        var icon = options.icon || '';
        
        return '<div id="' + id + '" class="os-window" style="width: ' + width + 'px; height: ' + height + 'px; left: ' + x + 'px; top: ' + y + 'px;">' +
            '<div class="os-window-titlebar" id="' + id + '_titlebar">' +
            (icon ? '<span class="os-window-icon">' + icon + '</span>' : '') +
            '<span class="os-window-title">' + this.escapeHtml(title) + '</span>' +
            '<div class="os-window-controls">' +
            '<button class="os-window-btn os-window-minimize" onclick="windowManager.minimize(\'' + id + '\')">−</button>' +
            '<button class="os-window-btn os-window-maximize" onclick="windowManager.maximize(\'' + id + '\')">□</button>' +
            '<button class="os-window-btn os-window-close" onclick="windowManager.close(\'' + id + '\')">×</button>' +
            '</div></div>' +
            '<div class="os-window-content" id="' + id + '_content">' + content + '</div>' +
            '<div class="os-window-resize-handle"></div>' +
            '</div>';
    },
    
    escapeHtml: function(text) {
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text || '').replace(/[&<>"']/g, function(m) { return map[m]; });
    },

    addTaskbarButton: function(id) {
        var window = this.windows[id];
        var taskbar = document.getElementById('os-taskbar-programs');
        if (!window || !taskbar) return;

        if (taskbar.querySelector('[data-window-id="' + id + '"]')) {
            window.taskbarButton = taskbar.querySelector('[data-window-id="' + id + '"]');
            this.updateTaskbarButtonLabel(id);
            this.updateTaskbarButtonState(id);
            return;
        }

        var button = document.createElement('button');
        button.className = 'os-taskbar-program';
        button.setAttribute('type', 'button');
        button.setAttribute('data-window-id', id);

        var icon = document.createElement('span');
        icon.className = 'os-taskbar-program-icon';
        icon.textContent = window.icon || ' ';

        var label = document.createElement('span');
        label.className = 'os-taskbar-program-label';
        label.textContent = window.title || id;

        button.appendChild(icon);
        button.appendChild(label);
        button.addEventListener('click', function() {
            var targetWindow = windowManager.windows[id];
            if (!targetWindow) return;

            if (targetWindow.minimized) {
                windowManager.minimize(id);
                return;
            }

            if (windowManager.activeWindow === id) {
                windowManager.minimize(id);
                return;
            }

            windowManager.makeActive(id);
        });

        taskbar.appendChild(button);
        window.taskbarButton = button;
        this.updateTaskbarButtonState(id);
    },

    removeTaskbarButton: function(id) {
        var window = this.windows[id];
        if (!window || !window.taskbarButton) return;
        window.taskbarButton.remove();
        window.taskbarButton = null;
    },

    updateTaskbarButtonLabel: function(id) {
        var window = this.windows[id];
        if (!window || !window.taskbarButton) return;

        var titleEl = window.element.querySelector('.os-window-title');
        var iconEl = window.element.querySelector('.os-window-icon');
        var label = window.taskbarButton.querySelector('.os-taskbar-program-label');
        var icon = window.taskbarButton.querySelector('.os-taskbar-program-icon');

        window.title = titleEl ? titleEl.textContent : (window.title || id);
        window.icon = iconEl ? iconEl.textContent : (window.icon || '');

        if (label) {
            label.textContent = window.title;
            window.taskbarButton.title = window.title;
        }

        if (icon) {
            icon.textContent = window.icon || ' ';
        }
    },

    updateTaskbarButtonState: function(id) {
        var window = this.windows[id];
        if (!window || !window.taskbarButton) return;

        window.taskbarButton.classList.toggle('active', this.activeWindow === id && !window.minimized);
        window.taskbarButton.classList.toggle('minimized', !!window.minimized);
    },

    refreshTaskbarButtonStates: function() {
        var self = this;
        Object.keys(this.windows).forEach(function(id) {
            self.updateTaskbarButtonState(id);
        });
    },

    observeWindowTitle: function(id) {
        var window = this.windows[id];
        if (!window) return;

        var titleEl = window.element.querySelector('.os-window-title');
        if (!titleEl || typeof MutationObserver === 'undefined') {
            this.updateTaskbarButtonLabel(id);
            return;
        }

        var self = this;
        var observer = new MutationObserver(function() {
            self.updateTaskbarButtonLabel(id);
        });

        observer.observe(titleEl, {
            childList: true,
            characterData: true,
            subtree: true
        });

        window.titleObserver = observer;
        this.updateTaskbarButtonLabel(id);
    }
};

// Initialize windows after page load
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.os-window').forEach(function(window) {
        windowManager.register(window.id, window);
    });
});
]]
end

return WINDOW

