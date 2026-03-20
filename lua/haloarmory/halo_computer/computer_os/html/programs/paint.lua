-- Paint Program - Simple image editor
local PAINT = {}

function PAINT.GetContent()
    return [[
<div class="program-paint">
    <div class="paint-toolbar">
        <button onclick="paintApp.clearCanvas()" class="btn">Clear</button>
        <button onclick="paintApp.saveImage()" class="btn btn-primary">Save</button>
        <button onclick="paintApp.loadImage()" class="btn">Load</button>
        <select id="paint-color" onchange="paintApp.setColor(this.value)">
            <option value="#000000">Black</option>
            <option value="#ff0000">Red</option>
            <option value="#00ff00">Green</option>
            <option value="#0000ff">Blue</option>
            <option value="#ffff00">Yellow</option>
            <option value="#ff00ff">Magenta</option>
            <option value="#00ffff">Cyan</option>
            <option value="#ffffff">White</option>
        </select>
        <input type="range" id="paint-size" min="1" max="20" value="3" oninput="paintApp.setSize(this.value)">
        <span id="paint-size-label">Size: 3</span>
    </div>
    <div class="paint-canvas-container">
        <canvas id="paint-canvas" width="800" height="500"></canvas>
    </div>
</div>
]]
end

function PAINT.GetInitScript()
    return [[
        paintApp.init(windowId);
        
        // Register .paint file handler (if applicable)
        if (window.osFileTypeRegistry) {
            window.osFileTypeRegistry.registerProgram('.paint', 'paint');
        }
    ]]
end

function PAINT.GetJavaScript()
    return [[
var paintApp = {
    canvas: null,
    ctx: null,
    isDrawing: false,
    color: '#000000',
    size: 3,
    windowId: null,
    currentFilePath: null,
    currentFileName: null,
    lastSaveFolder: 'C:/',
    
    init: function(windowId) {
        this.windowId = windowId;
        this.canvas = document.getElementById('paint-canvas');
        if (!this.canvas) return;
        
        this.ctx = this.canvas.getContext('2d');
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Resize canvas to fit container
        var container = this.canvas.parentElement;
        this.canvas.width = container.clientWidth - 16;
        this.canvas.height = container.clientHeight - 16;
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Drawing events
        this.canvas.addEventListener('mousedown', this.startDraw.bind(this));
        this.canvas.addEventListener('mousemove', this.draw.bind(this));
        this.canvas.addEventListener('mouseup', this.stopDraw.bind(this));
        this.canvas.addEventListener('mouseout', this.stopDraw.bind(this));
        
        // Touch events for mobile
        this.canvas.addEventListener('touchstart', this.handleTouch.bind(this));
        this.canvas.addEventListener('touchmove', this.handleTouch.bind(this));
        this.canvas.addEventListener('touchend', this.stopDraw.bind(this));

        this.updateWindowTitle();
    },
    
    startDraw: function(e) {
        this.isDrawing = true;
        var rect = this.canvas.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        this.drawPoint(x, y);
    },
    
    draw: function(e) {
        if (!this.isDrawing) return;
        var rect = this.canvas.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        this.drawPoint(x, y);
    },
    
    drawPoint: function(x, y) {
        this.ctx.fillStyle = this.color;
        this.ctx.beginPath();
        this.ctx.arc(x, y, this.size, 0, Math.PI * 2);
        this.ctx.fill();
    },
    
    stopDraw: function() {
        this.isDrawing = false;
    },
    
    handleTouch: function(e) {
        e.preventDefault();
        var touch = e.touches[0];
        var rect = this.canvas.getBoundingClientRect();
        var x = touch.clientX - rect.left;
        var y = touch.clientY - rect.top;
        
        if (e.type === 'touchstart') {
            this.isDrawing = true;
        }
        
        if (this.isDrawing) {
            this.drawPoint(x, y);
        }
    },
    
    setColor: function(color) {
        this.color = color;
    },
    
    setSize: function(size) {
        this.size = parseInt(size);
        document.getElementById('paint-size-label').textContent = 'Size: ' + size;
    },
    
    clearCanvas: function() {
        if (confirm('Clear the canvas?')) {
            this.ctx.fillStyle = '#ffffff';
            this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        }
    },
    
    saveImage: function() {
        if (this.currentFilePath) {
            this.writeImage(this.currentFilePath);
            return;
        }

        this.saveImageAs();
    },

    saveImageAs: function() {
        var self = this;

        if (window.osFileDialogs && window.osFileDialogs.showSaveAs) {
            window.osFileDialogs.showSaveAs({
                title: 'Save Image As...',
                initialPath: this.lastSaveFolder || 'C:/',
                defaultName: this.currentFileName || 'drawing.png',
                allowedExtensions: ['.png'],
                onSave: function(filePath, displayName, finalName) {
                    self.writeImage(filePath, displayName || self.stripExtension(finalName || 'drawing.png'));
                }
            });
            return;
        }

        alert('Save dialog is not available');
    },

    writeImage: function(filePath, displayName) {
        var dataURL = this.canvas.toDataURL('image/png');
        var base64Data = dataURL.split(',')[1];
        var self = this;

        if (window.filesystem) {
            window.filesystem.writeFile(filePath, base64Data, function(success) {
                if (success) {
                    self.currentFilePath = filePath;
                    self.currentFileName = displayName || self.stripExtension(window.getFileNameFromPath(filePath));
                    self.lastSaveFolder = filePath.substring(0, filePath.lastIndexOf('/') + 1);
                    self.updateWindowTitle();
                    if (window.osErrorHandler) {
                        window.osErrorHandler.showNotification('Image saved', 'success', 1800);
                    }
                } else {
                    alert('Failed to save image');
                }
            });
            return;
        }

        var link = document.createElement('a');
        link.download = this.stripExtension(window.getFileNameFromPath(filePath) || 'drawing') + '.png';
        link.href = dataURL;
        link.click();
    },

    stripExtension: function(filename) {
        return String(filename || '').replace(/\.[^.]+$/, '');
    },

    updateWindowTitle: function() {
        if (!this.windowId) return;
        var windowEl = document.getElementById(this.windowId);
        if (!windowEl) return;

        var titleEl = windowEl.querySelector('.os-window-title');
        if (titleEl) {
            titleEl.textContent = 'Paint - ' + (this.currentFileName || 'untitled');
        }
    },
    
    loadImage: function() {
        // Image loading would go here
        alert('Image loading feature coming soon');
    }
};
]]
end

function PAINT.GetCSS()
    return [[
.program-paint {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #2d2d2d);
}

.paint-toolbar {
    display: flex;
    padding: 8px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: var(--color-primary-surface-alt, #2d2d2d);
    gap: 8px;
    align-items: center;
    color: var(--color-text-on-primary-surface, #ffffff);
}

.paint-toolbar .btn {
    padding: 8px 12px;
    border: 1px solid var(--color-button-border, #555);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-muted-bg, #3a3a3a);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    font: inherit;
}

.paint-toolbar .btn:hover {
    background: var(--color-button-hover-bg, #4a4a4a);
}

.paint-toolbar select,
.paint-toolbar input[type="range"] {
    padding: 4px 8px;
    background: var(--color-secondary-surface-alt, #3a3a3a);
    border: 1px solid var(--color-window-border, #555);
    color: var(--color-text-primary, #fff);
    border-radius: var(--radius-ui-small, 4px);
}

.paint-canvas-container {
    flex: 1;
    padding: 8px;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
    overflow: auto;
}

#paint-canvas {
    border: 1px solid var(--color-window-border, #444);
    background: #fff;
    cursor: crosshair;
    display: block;
    max-width: 100%;
}
]]
end

return {
    title = "Paint",
    icon = "🎨",
    width = 850,
    height = 600,
    getContent = PAINT.GetContent,
    getInitScript = PAINT.GetInitScript,
    getJavaScript = PAINT.GetJavaScript,
    getCSS = PAINT.GetCSS
}

