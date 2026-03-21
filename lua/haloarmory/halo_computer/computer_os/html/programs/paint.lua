-- Paint Program - Image editor
local PAINT = {}

function PAINT.GetContent()
    return [[
<div class="program-paint">
    <div class="paint-toolbar">
        <div class="paint-tool-group">
            <button class="paint-tool-btn active" data-tool="brush" onclick="paintApp.selectTool('brush')">Brush</button>
            <button class="paint-tool-btn" data-tool="eraser" onclick="paintApp.selectTool('eraser')">Eraser</button>
            <button class="paint-tool-btn" data-tool="line" onclick="paintApp.selectTool('line')">Line</button>
            <button class="paint-tool-btn" data-tool="rect" onclick="paintApp.selectTool('rect')">Rect</button>
            <button class="paint-tool-btn" data-tool="circle" onclick="paintApp.selectTool('circle')">Circle</button>
            <button class="paint-tool-btn" data-tool="fill" onclick="paintApp.selectTool('fill')">Fill</button>
        </div>
        <div class="paint-toolbar-divider"></div>
        <div class="paint-tool-group">
            <button class="paint-btn" onclick="paintApp.undo()">Undo</button>
            <button class="paint-btn" onclick="paintApp.redo()">Redo</button>
            <button class="paint-btn" onclick="paintApp.clearCanvas()">Clear</button>
        </div>
        <div class="paint-toolbar-divider"></div>
        <div class="paint-tool-group">
            <button class="paint-btn" onclick="paintApp.loadImage()">Load</button>
            <button class="paint-btn paint-btn-primary" onclick="paintApp.saveImage()">Save</button>
            <button class="paint-btn" onclick="paintApp.saveImageAs()">Save As</button>
        </div>
        <div class="paint-toolbar-spacer"></div>
        <label class="paint-control">
            <span>Color</span>
            <input id="paint-color" type="color" value="#000000" onchange="paintApp.setColor(this.value)">
        </label>
        <label class="paint-control">
            <span>Size</span>
            <input id="paint-size" type="range" min="1" max="48" value="4" oninput="paintApp.setSize(this.value)">
        </label>
        <span class="paint-size-label" id="paint-size-label">4 px</span>
    </div>
    <div class="paint-statusbar">
        <span id="paint-tool-label">Brush</span>
        <span id="paint-file-label">untitled.image</span>
    </div>
    <div class="paint-canvas-container">
        <canvas id="paint-canvas"></canvas>
    </div>
</div>
]]
end

function PAINT.GetInitScript()
    return [[
        paintApp.init(windowId);
        if (window.osFileTypeRegistry) {
            window.osFileTypeRegistry.registerProgram('.png', 'paint');
            window.osFileTypeRegistry.registerProgram('.jpg', 'paint');
            window.osFileTypeRegistry.registerProgram('.jpeg', 'paint');
            window.osFileTypeRegistry.registerProgram('.image.dat', 'paint');
        }
    ]]
end

function PAINT.GetJavaScript()
    return [=[
var paintApp = {
    canvas: null,
    ctx: null,
    windowId: null,
    tool: 'brush',
    color: '#000000',
    size: 4,
    isDrawing: false,
    startPoint: null,
    lastPoint: null,
    previewSnapshot: null,
    history: [],
    redoHistory: [],
    currentFilePath: null,
    currentFileName: 'untitled',
    currentFileExtension: '.image',
    lastSaveFolder: 'C:/desktop/',

    init: function(windowId) {
        this.windowId = windowId;
        this.canvas = document.getElementById('paint-canvas');
        if (!this.canvas) return;
        this.ctx = this.canvas.getContext('2d');

        this.resizeCanvas(true);
        this.bindEvents();
        this.pushHistory();
        this.updateUiLabels();
        this.updateWindowTitle();

        var self = this;
        setTimeout(function() {
            var handledPendingOpen = false;
            var windowEl = document.getElementById(windowId);
            if (windowEl) {
                var pendingFileId = windowEl.getAttribute('data-pending-file');
                if (pendingFileId && window.pendingFileOpen && window.pendingFileOpen[pendingFileId]) {
                    var fileData = window.pendingFileOpen[pendingFileId];
                    self.importImageContent(fileData.content, fileData.path || null, fileData.displayName || null);
                    delete window.pendingFileOpen[pendingFileId];
                    windowEl.removeAttribute('data-pending-file');
                    handledPendingOpen = true;
                }
            }

            if (!handledPendingOpen && window.pendingFileOpen &&
                (window.pendingFileOpen.path !== undefined || window.pendingFileOpen.content !== undefined || window.pendingFileOpen.displayName !== undefined) &&
                !window.pendingFileOpen[windowId]) {
                var pfo = window.pendingFileOpen;
                self.importImageContent(pfo.content, pfo.path || null, pfo.displayName || null);
                window.pendingFileOpen = null;
                handledPendingOpen = true;
            }

            if (handledPendingOpen) {
                return;
            }

            if (window.programInitialPaths && window.programInitialPaths[windowId]) {
                self.openImageFromPath(window.programInitialPaths[windowId]);
            }
        }, 100);
    },

    bindEvents: function() {
        var self = this;
        this.handleMouseDown = function(e) { self.startAction(e); };
        this.handleMouseMove = function(e) { self.moveAction(e); };
        this.handleMouseUp = function() { self.endAction(); };
        this.handleResize = function() { self.resizeCanvas(false); };

        this.canvas.addEventListener('mousedown', this.handleMouseDown);
        this.canvas.addEventListener('mousemove', this.handleMouseMove);
        document.addEventListener('mouseup', this.handleMouseUp);
        window.addEventListener('resize', this.handleResize);

        this.canvas.addEventListener('touchstart', function(e) {
            e.preventDefault();
            self.startAction(e.touches[0]);
        }, { passive: false });

        this.canvas.addEventListener('touchmove', function(e) {
            e.preventDefault();
            if (e.touches[0]) {
                self.moveAction(e.touches[0]);
            }
        }, { passive: false });

        this.canvas.addEventListener('touchend', function(e) {
            e.preventDefault();
            self.endAction();
        }, { passive: false });
    },

    resizeCanvas: function(initial) {
        if (!this.canvas) return;
        var container = this.canvas.parentElement;
        if (!container) return;

        var width = Math.max(480, container.clientWidth - 16);
        var height = Math.max(320, container.clientHeight - 16);
        var snapshot = null;

        if (!initial && this.canvas.width && this.canvas.height) {
            snapshot = document.createElement('canvas');
            snapshot.width = this.canvas.width;
            snapshot.height = this.canvas.height;
            snapshot.getContext('2d').drawImage(this.canvas, 0, 0);
        }

        this.canvas.width = width;
        this.canvas.height = height;
        this.ctx = this.canvas.getContext('2d');
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(0, 0, width, height);

        if (snapshot) {
            this.ctx.drawImage(snapshot, 0, 0, width, height);
        }
    },

    isActiveWindow: function() {
        return !window.windowManager || window.windowManager.activeWindow === this.windowId;
    },

    getPointer: function(e) {
        var rect = this.canvas.getBoundingClientRect();
        return {
            x: Math.max(0, Math.min(this.canvas.width, e.clientX - rect.left)),
            y: Math.max(0, Math.min(this.canvas.height, e.clientY - rect.top))
        };
    },

    startAction: function(e) {
        if (!this.isActiveWindow()) return;
        var point = this.getPointer(e);
        this.isDrawing = true;
        this.startPoint = point;
        this.lastPoint = point;
        this.previewSnapshot = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);

        if (this.tool === 'fill') {
            this.floodFill(Math.floor(point.x), Math.floor(point.y), this.hexToRgba(this.color));
            this.isDrawing = false;
            this.previewSnapshot = null;
            this.pushHistory();
            return;
        }

        if (this.tool === 'brush' || this.tool === 'eraser') {
            this.ctx.beginPath();
            this.ctx.lineCap = 'round';
            this.ctx.lineJoin = 'round';
            this.ctx.strokeStyle = this.tool === 'eraser' ? '#ffffff' : this.color;
            this.ctx.lineWidth = this.size * 2;
            this.ctx.moveTo(point.x, point.y);
            this.ctx.lineTo(point.x, point.y);
            this.ctx.stroke();
        }
    },

    moveAction: function(e) {
        if (!this.isDrawing) return;
        var point = this.getPointer(e);

        if (this.tool === 'brush' || this.tool === 'eraser') {
            this.ctx.strokeStyle = this.tool === 'eraser' ? '#ffffff' : this.color;
            this.ctx.lineWidth = this.size * 2;
            this.ctx.lineTo(point.x, point.y);
            this.ctx.stroke();
            this.lastPoint = point;
            return;
        }

        if (!this.previewSnapshot) return;
        this.ctx.putImageData(this.previewSnapshot, 0, 0);
        this.ctx.strokeStyle = this.color;
        this.ctx.fillStyle = this.color;
        this.ctx.lineWidth = Math.max(1, this.size);
        this.ctx.lineCap = 'round';
        this.ctx.lineJoin = 'round';

        if (this.tool === 'line') {
            this.ctx.beginPath();
            this.ctx.moveTo(this.startPoint.x, this.startPoint.y);
            this.ctx.lineTo(point.x, point.y);
            this.ctx.stroke();
        } else if (this.tool === 'rect') {
            var rw = point.x - this.startPoint.x;
            var rh = point.y - this.startPoint.y;
            this.ctx.strokeRect(this.startPoint.x, this.startPoint.y, rw, rh);
        } else if (this.tool === 'circle') {
            var radius = Math.sqrt(Math.pow(point.x - this.startPoint.x, 2) + Math.pow(point.y - this.startPoint.y, 2));
            this.ctx.beginPath();
            this.ctx.arc(this.startPoint.x, this.startPoint.y, radius, 0, Math.PI * 2);
            this.ctx.stroke();
        }
    },

    endAction: function() {
        if (!this.isDrawing) return;
        this.isDrawing = false;
        this.previewSnapshot = null;
        this.pushHistory();
    },

    floodFill: function(startX, startY, fillColor) {
        var imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
        var data = imageData.data;
        var width = imageData.width;
        var height = imageData.height;
        var stack = [[startX, startY]];
        var startIndex = (startY * width + startX) * 4;
        var target = [data[startIndex], data[startIndex + 1], data[startIndex + 2], data[startIndex + 3]];

        if (target[0] === fillColor[0] && target[1] === fillColor[1] && target[2] === fillColor[2] && target[3] === fillColor[3]) {
            return;
        }

        while (stack.length) {
            var node = stack.pop();
            var x = node[0];
            var y = node[1];

            if (x < 0 || y < 0 || x >= width || y >= height) {
                continue;
            }

            var index = (y * width + x) * 4;
            if (data[index] !== target[0] || data[index + 1] !== target[1] || data[index + 2] !== target[2] || data[index + 3] !== target[3]) {
                continue;
            }

            data[index] = fillColor[0];
            data[index + 1] = fillColor[1];
            data[index + 2] = fillColor[2];
            data[index + 3] = fillColor[3];

            stack.push([x + 1, y]);
            stack.push([x - 1, y]);
            stack.push([x, y + 1]);
            stack.push([x, y - 1]);
        }

        this.ctx.putImageData(imageData, 0, 0);
    },

    hexToRgba: function(hex) {
        var value = String(hex || '#000000').replace('#', '');
        if (value.length === 3) {
            value = value.charAt(0) + value.charAt(0) + value.charAt(1) + value.charAt(1) + value.charAt(2) + value.charAt(2);
        }
        return [
            parseInt(value.substring(0, 2), 16) || 0,
            parseInt(value.substring(2, 4), 16) || 0,
            parseInt(value.substring(4, 6), 16) || 0,
            255
        ];
    },

    pushHistory: function() {
        this.history.push(this.canvas.toDataURL('image/png'));
        if (this.history.length > 30) {
            this.history.shift();
        }
        this.redoHistory = [];
    },

    restoreFromDataUrl: function(dataUrl, callback) {
        var self = this;
        var img = new Image();
        img.onload = function() {
            self.ctx.fillStyle = '#ffffff';
            self.ctx.fillRect(0, 0, self.canvas.width, self.canvas.height);
            self.ctx.drawImage(img, 0, 0, self.canvas.width, self.canvas.height);
            if (callback) callback(true);
        };
        img.onerror = function() {
            if (callback) callback(false);
        };
        img.src = dataUrl;
    },

    undo: function() {
        if (this.history.length <= 1) return;
        this.redoHistory.push(this.history.pop());
        this.restoreFromDataUrl(this.history[this.history.length - 1]);
    },

    redo: function() {
        if (!this.redoHistory.length) return;
        var next = this.redoHistory.pop();
        this.history.push(next);
        this.restoreFromDataUrl(next);
    },

    selectTool: function(tool) {
        this.tool = tool;
        document.querySelectorAll('.paint-tool-btn').forEach(function(button) {
            button.classList.toggle('active', button.getAttribute('data-tool') === tool);
        });
        this.updateUiLabels();
    },

    setColor: function(color) {
        this.color = color;
    },

    setSize: function(size) {
        this.size = parseInt(size, 10) || 1;
        this.updateUiLabels();
    },

    updateUiLabels: function() {
        var sizeLabel = document.getElementById('paint-size-label');
        var toolLabel = document.getElementById('paint-tool-label');
        var fileLabel = document.getElementById('paint-file-label');
        if (sizeLabel) sizeLabel.textContent = this.size + ' px';
        if (toolLabel) toolLabel.textContent = this.tool.charAt(0).toUpperCase() + this.tool.slice(1);
        if (fileLabel) {
            var displayExtension = /\.image(\.dat)?$/i.test(String(this.currentFilePath || '')) ? '.image' : (this.currentFileExtension || '.image');
            fileLabel.textContent = (this.currentFileName || 'untitled') + displayExtension;
        }
    },

    clearCanvas: function() {
        this.isDrawing = false;
        this.startPoint = null;
        this.lastPoint = null;
        this.previewSnapshot = null;
        this.ctx.save();
        this.ctx.setTransform(1, 0, 0, 1, 0, 0);
        this.ctx.globalCompositeOperation = 'source-over';
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.restore();
        this.pushHistory();
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
        if (!window.osFileDialogs || !window.osFileDialogs.showSaveAs) {
            alert('Save dialog is not available');
            return;
        }

        window.osFileDialogs.showSaveAs({
            title: 'Save Image As...',
            initialPath: this.lastSaveFolder || 'C:/desktop/',
            defaultName: this.currentFileName || 'drawing',
            defaultExtension: '.image',
            allowedExtensions: ['.image'],
            onSave: function(filePath, displayName) {
                self.writeImage(filePath, displayName || 'drawing');
            }
        });
    },

    getStoragePath: function(filePath) {
        var normalizedPath = String(filePath || '');
        if (!normalizedPath) {
            return '';
        }

        if (/\.image\.dat$/i.test(normalizedPath)) {
            return normalizedPath;
        }

        if (/\.image$/i.test(normalizedPath)) {
            return normalizedPath + '.dat';
        }

        return normalizedPath.replace(/\.[^.]+$/i, '') + '.image.dat';
    },

    getDisplayImageName: function(name) {
        var baseName = String(name || 'drawing');
        baseName = baseName.replace(/\.image\.dat$/i, '');
        baseName = baseName.replace(/\.(png|jpg|jpeg|image|dat)$/i, '');
        if (!baseName) {
            baseName = 'drawing';
        }
        return baseName + '.image';
    },

    writeImage: function(filePath, displayName) {
        var storagePath = this.getStoragePath(filePath);
        var finalDisplayName = this.getDisplayImageName(displayName || window.getFileNameFromPath(storagePath));
        var lowerPath = String(filePath || '').toLowerCase();
        var extension = this.currentFileExtension || '.image';
        var mime = 'image/png';
        if (lowerPath.endsWith('.jpg')) {
            extension = '.jpg';
            mime = 'image/jpeg';
        } else if (lowerPath.endsWith('.jpeg')) {
            extension = '.jpeg';
            mime = 'image/jpeg';
        } else if (lowerPath.endsWith('.png')) {
            extension = '.png';
        } else if (lowerPath.endsWith('.image.dat') || lowerPath.endsWith('.image')) {
            if (extension === '.jpg' || extension === '.jpeg') {
                mime = 'image/jpeg';
            } else {
                extension = '.image';
                mime = 'image/png';
            }
        }

        var dataUrl = this.canvas.toDataURL(mime);
        var self = this;

        if (!window.filesystem) {
            alert('Filesystem is not available');
            return;
        }

        window.filesystem.writeFile(storagePath, dataUrl, function(success) {
            if (!success) {
                alert('Failed to save image');
                return;
            }

            self.currentFilePath = storagePath;
            self.currentFileName = finalDisplayName.replace(/\.image$/i, '');
            self.currentFileExtension = '.image';
            self.lastSaveFolder = storagePath.substring(0, storagePath.lastIndexOf('/') + 1);
            self.updateUiLabels();
            self.updateWindowTitle();
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Image saved', 'success', 1800);
            }
        });
    },

    loadImage: function() {
        var self = this;
        if (!window.osFileDialogs || !window.osFileDialogs.showOpen) {
            alert('Open dialog is not available');
            return;
        }

        window.osFileDialogs.showOpen({
            title: 'Open Image...',
            initialPath: this.lastSaveFolder || 'C:/desktop/',
            allowedExtensions: ['.image'],
            onOpen: function(filePath) {
                self.openImageFromPath(filePath);
            }
        });
    },

    openImageFromPath: function(filePath) {
        var self = this;
        if (!window.filesystem || !filePath) {
            return;
        }

        window.filesystem.readFile(filePath, function(content) {
            if (!content) {
                alert('Failed to load image');
                return;
            }

            self.importImageContent(content, filePath);
        });
    },

    importImageContent: function(content, filePath, displayNameOverride) {
        var self = this;
        var lowerPath = String(filePath || '').toLowerCase();
        var mime = 'image/png';
        var displayName = displayNameOverride || window.getFileNameFromPath(filePath || '');
        var payload = null;

        if (lowerPath.endsWith('.image.dat') || (typeof content === 'string' && String(content || '').charAt(0) === '{')) {
            try {
                payload = JSON.parse(String(content || ''));
            } catch (e) {
                payload = null;
            }

            if (payload && payload.filename) {
                displayName = payload.filename;
            }

            if (payload && payload.content) {
                content = payload.content;
            }
        }

        if (String(displayName || '').toLowerCase().endsWith('.jpg') || String(displayName || '').toLowerCase().endsWith('.jpeg')) {
            mime = 'image/jpeg';
        }

        var source = String(content || '');
        if (source.indexOf('data:image/') !== 0) {
            source = 'data:' + mime + ';base64,' + source;
        }

        var image = new Image();
        image.onload = function() {
            self.ctx.fillStyle = '#ffffff';
            self.ctx.fillRect(0, 0, self.canvas.width, self.canvas.height);

            var scale = Math.min(self.canvas.width / image.width, self.canvas.height / image.height, 1);
            var drawWidth = image.width * scale;
            var drawHeight = image.height * scale;
            var drawX = (self.canvas.width - drawWidth) / 2;
            var drawY = (self.canvas.height - drawHeight) / 2;

            self.ctx.drawImage(image, drawX, drawY, drawWidth, drawHeight);
            self.currentFilePath = filePath || null;
            self.currentFileName = self.stripExtension(displayName || 'untitled.image');
            self.currentFileExtension = '.image';
            if (filePath) {
                self.lastSaveFolder = filePath.substring(0, filePath.lastIndexOf('/') + 1);
            }
            self.history = [];
            self.redoHistory = [];
            self.pushHistory();
            self.updateUiLabels();
            self.updateWindowTitle();
            if (window.osErrorHandler) {
                window.osErrorHandler.showNotification('Image loaded', 'success', 1800);
            }
        };
        image.onerror = function() {
            alert('Failed to decode image');
        };
        image.src = source;
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
    }
};
]=]
end

function PAINT.GetCSS()
    return [[
.program-paint {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #242b33);
    color: var(--color-text-primary, #ffffff);
}

.paint-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    padding: 8px 10px;
    border-bottom: 1px solid var(--color-window-border, rgba(255,255,255,0.12));
    background: var(--color-primary-surface-alt, #2f3945);
}

.paint-tool-group {
    display: flex;
    gap: 6px;
    align-items: center;
    flex-wrap: wrap;
}

.paint-toolbar-divider {
    width: 1px;
    height: 24px;
    background: var(--color-window-border, rgba(255,255,255,0.12));
}

.paint-toolbar-spacer {
    flex: 1;
}

.paint-btn,
.paint-tool-btn {
    padding: 6px 10px;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    font: inherit;
}

.paint-btn:hover,
.paint-tool-btn:hover {
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.paint-btn-primary {
    background: var(--color-secondary-button-bg, var(--color-secondary, #596c86));
}

.paint-btn-primary:hover {
    background: var(--color-secondary-button-hover-bg, var(--color-secondary, #52627a));
}

.paint-tool-btn.active {
    background: var(--color-secondary-button-active-bg, var(--color-secondary, #62748e));
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.paint-control {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: var(--color-text-secondary, rgba(255,255,255,0.76));
}

.paint-control input[type="color"] {
    width: 34px;
    height: 28px;
    padding: 0;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.16));
    border-radius: var(--radius-ui-small, 4px);
    background: transparent;
}

.paint-control input[type="range"] {
    width: 120px;
}

.paint-size-label,
.paint-statusbar {
    font-size: 12px;
    color: var(--color-text-secondary, rgba(255,255,255,0.76));
}

.paint-statusbar {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    padding: 6px 10px;
    border-bottom: 1px solid var(--color-window-border, rgba(255,255,255,0.08));
    background: var(--color-secondary-surface-alt, rgba(255,255,255,0.04));
}

.paint-canvas-container {
    flex: 1;
    min-height: 0;
    padding: 8px;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
    overflow: auto;
}

#paint-canvas {
    display: block;
    width: 100%;
    height: 100%;
    min-height: 320px;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-radius: var(--radius-ui, 6px);
    background: #ffffff;
    cursor: crosshair;
}
]]
end

return {
    title = "Paint",
    icon = "🎨",
    width = 860,
    height = 620,
    getContent = PAINT.GetContent,
    getInitScript = PAINT.GetInitScript,
    getJavaScript = PAINT.GetJavaScript,
    getCSS = PAINT.GetCSS
}
