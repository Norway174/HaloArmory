local CONWAY = {}

function CONWAY.GetContent()
    return [[
<div class="program-conway">
    <div class="conway-topbar">
        <div class="conway-stats">
            <div class="conway-stat"><span>Generation</span><strong id="conway-generation">0</strong></div>
            <div class="conway-stat"><span>Living</span><strong id="conway-living">0</strong></div>
            <div class="conway-stat conway-stat-wide"><span>Status</span><strong id="conway-status">Paint cells and press Start</strong></div>
        </div>
        <div class="conway-actions">
            <button class="conway-btn conway-btn-primary" onclick="conwayApp.toggleRunning()">Start</button>
            <button class="conway-btn" onclick="conwayApp.step()">Step</button>
            <button class="conway-btn" onclick="conwayApp.randomize()">Randomize</button>
            <button class="conway-btn" onclick="conwayApp.clearBoard()">Clear</button>
            <select class="conway-select" onchange="conwayApp.loadPreset(this.value)">
                <option value="">Preset</option>
                <option value="glider">Glider</option>
                <option value="pulsar">Pulsar</option>
                <option value="gun">Glider Gun</option>
                <option value="acorn">Acorn</option>
            </select>
            <label class="conway-speed">
                <span>Speed</span>
                <input id="conway-speed-range" type="range" min="60" max="320" step="10" value="140" oninput="conwayApp.setSpeed(parseInt(this.value, 10))">
            </label>
        </div>
    </div>
    <div class="conway-board-wrap">
        <canvas id="conway-canvas" class="conway-canvas" width="920" height="560"></canvas>
    </div>
    <div class="conway-footer">
        <span>Click or drag to paint cells</span>
        <span>Patterns wrap around edges</span>
        <span>Great for screensaver chaos</span>
    </div>
</div>
]]
end

function CONWAY.GetInitScript()
    return [[
        conwayApp.init(windowId);
    ]]
end

function CONWAY.GetJavaScript()
    return [=[
var conwayApp = {
    windowId: null,
    canvas: null,
    ctx: null,
    cols: 52,
    rows: 30,
    cellSize: 16,
    board: [],
    running: false,
    generation: 0,
    speedMs: 140,
    timer: null,
    drawing: false,
    drawValue: 1,

    init: function(windowId) {
        this.windowId = windowId;
        this.canvas = document.getElementById('conway-canvas');
        if (!this.canvas) return;
        this.ctx = this.canvas.getContext('2d');

        var self = this;
        this.handleMouseDown = function(e) {
            if (!self.isActiveWindow()) return;
            self.drawing = true;
            var pos = self.getCellFromEvent(e);
            if (!pos) return;
            self.drawValue = self.board[pos.y][pos.x] ? 0 : 1;
            self.applyPaint(pos.x, pos.y, self.drawValue);
        };
        this.handleMouseMove = function(e) {
            if (!self.drawing) return;
            var pos = self.getCellFromEvent(e);
            if (!pos) return;
            self.applyPaint(pos.x, pos.y, self.drawValue);
        };
        this.handleMouseUp = function() {
            self.drawing = false;
        };
        this.handleResize = function() {
            self.resizeCanvas();
            self.draw();
        };
        this.handleWindowClosing = function(e) {
            if (e.detail && e.detail.id === self.windowId) {
                self.destroy();
            }
        };

        this.canvas.addEventListener('mousedown', this.handleMouseDown);
        this.canvas.addEventListener('mousemove', this.handleMouseMove);
        document.addEventListener('mouseup', this.handleMouseUp);
        window.addEventListener('resize', this.handleResize);
        document.addEventListener('windowclosing', this.handleWindowClosing);

        this.resetBoard();
        this.resizeCanvas();
        this.draw();
    },

    destroy: function() {
        this.stopTimer();
        if (this.canvas) {
            this.canvas.removeEventListener('mousedown', this.handleMouseDown);
            this.canvas.removeEventListener('mousemove', this.handleMouseMove);
        }
        document.removeEventListener('mouseup', this.handleMouseUp);
        window.removeEventListener('resize', this.handleResize);
        document.removeEventListener('windowclosing', this.handleWindowClosing);
    },

    isActiveWindow: function() {
        return !window.windowManager || window.windowManager.activeWindow === this.windowId;
    },

    resetBoard: function() {
        this.board = [];
        for (var y = 0; y < this.rows; y++) {
            var row = [];
            for (var x = 0; x < this.cols; x++) {
                row.push(0);
            }
            this.board.push(row);
        }
        this.generation = 0;
        this.updateHud('Paint cells and press Start');
    },

    resizeCanvas: function() {
        if (!this.canvas) return;
        var rect = this.canvas.parentElement.getBoundingClientRect();
        var width = Math.max(720, Math.floor(rect.width - 18));
        var height = Math.max(420, Math.floor(rect.height - 18));
        this.cellSize = Math.max(10, Math.floor(Math.min(width / this.cols, height / this.rows)));
        this.canvas.width = this.cols * this.cellSize;
        this.canvas.height = this.rows * this.cellSize;
    },

    startTimer: function() {
        this.stopTimer();
        var self = this;
        this.timer = setInterval(function() {
            self.step();
        }, this.speedMs);
    },

    stopTimer: function() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
    },

    setSpeed: function(value) {
        this.speedMs = Math.max(60, Math.min(320, value || 140));
        if (this.running) {
            this.startTimer();
        }
    },

    toggleRunning: function() {
        this.running = !this.running;
        if (this.running) {
            this.startTimer();
            this.updateHud('Simulation running');
        } else {
            this.stopTimer();
            this.updateHud('Simulation paused');
        }
        this.updateRunButton();
    },

    updateRunButton: function() {
        var btn = document.querySelector('.conway-btn-primary');
        if (btn) {
            btn.textContent = this.running ? 'Pause' : 'Start';
        }
    },

    updateHud: function(statusText) {
        var generationEl = document.getElementById('conway-generation');
        var livingEl = document.getElementById('conway-living');
        var statusEl = document.getElementById('conway-status');
        if (generationEl) generationEl.textContent = this.generation;
        if (livingEl) livingEl.textContent = this.countLiving();
        if (statusEl) statusEl.textContent = statusText || '';
    },

    countLiving: function() {
        var count = 0;
        for (var y = 0; y < this.rows; y++) {
            for (var x = 0; x < this.cols; x++) {
                count += this.board[y][x];
            }
        }
        return count;
    },

    getCellFromEvent: function(e) {
        if (!this.canvas) return null;
        var rect = this.canvas.getBoundingClientRect();
        var x = Math.floor((e.clientX - rect.left) / this.cellSize);
        var y = Math.floor((e.clientY - rect.top) / this.cellSize);
        if (x < 0 || y < 0 || x >= this.cols || y >= this.rows) return null;
        return { x: x, y: y };
    },

    applyPaint: function(x, y, value) {
        this.board[y][x] = value ? 1 : 0;
        this.updateHud(this.running ? 'Simulation running' : 'Painting board');
        this.draw();
    },

    clearBoard: function() {
        this.running = false;
        this.stopTimer();
        this.updateRunButton();
        this.resetBoard();
        this.draw();
    },

    randomize: function() {
        this.running = false;
        this.stopTimer();
        this.updateRunButton();
        for (var y = 0; y < this.rows; y++) {
            for (var x = 0; x < this.cols; x++) {
                this.board[y][x] = Math.random() > 0.73 ? 1 : 0;
            }
        }
        this.generation = 0;
        this.updateHud('Randomized fresh field');
        this.draw();
    },

    loadPreset: function(name) {
        if (!name) return;
        this.clearBoard();
        var cx = Math.floor(this.cols / 2);
        var cy = Math.floor(this.rows / 2);
        var cells = [];

        if (name === 'glider') {
            cells = [[0,0],[1,0],[2,0],[2,-1],[1,-2]];
        } else if (name === 'pulsar') {
            cells = [
                [-4,-6],[-3,-6],[-2,-6],[2,-6],[3,-6],[4,-6],
                [-6,-4],[-1,-4],[1,-4],[6,-4],
                [-6,-3],[-1,-3],[1,-3],[6,-3],
                [-6,-2],[-1,-2],[1,-2],[6,-2],
                [-4,-1],[-3,-1],[-2,-1],[2,-1],[3,-1],[4,-1],
                [-4,1],[-3,1],[-2,1],[2,1],[3,1],[4,1],
                [-6,2],[-1,2],[1,2],[6,2],
                [-6,3],[-1,3],[1,3],[6,3],
                [-6,4],[-1,4],[1,4],[6,4],
                [-4,6],[-3,6],[-2,6],[2,6],[3,6],[4,6]
            ];
        } else if (name === 'gun') {
            cells = [
                [-18,-4],[-18,-3],[-17,-4],[-17,-3],
                [-8,-4],[-8,-3],[-8,-2],[-7,-5],[-7,-1],[-6,-6],[-6,0],[-5,-6],[-5,0],[-4,-3],[-3,-5],[-3,-1],[-2,-4],[-2,-3],[-2,-2],[-1,-3],
                [2,-6],[2,-5],[2,-4],[3,-6],[3,-5],[3,-4],[4,-7],[4,-3],[6,-8],[6,-7],[6,-3],[6,-2],
                [16,-6],[16,-5],[17,-6],[17,-5]
            ];
        } else if (name === 'acorn') {
            cells = [[-3,0],[-1,1],[-3,2],[0,2],[1,2],[2,2],[3,2]];
        }

        for (var i = 0; i < cells.length; i++) {
            var x = (cx + cells[i][0] + this.cols) % this.cols;
            var y = (cy + cells[i][1] + this.rows) % this.rows;
            this.board[y][x] = 1;
        }

        this.updateHud('Loaded ' + name + ' preset');
        this.draw();
        var presetSelect = document.querySelector('.conway-select');
        if (presetSelect) presetSelect.value = '';
    },

    step: function() {
        var next = [];
        for (var y = 0; y < this.rows; y++) {
            var row = [];
            for (var x = 0; x < this.cols; x++) {
                var neighbors = this.countNeighbors(x, y);
                var alive = this.board[y][x] === 1;
                if (alive && (neighbors === 2 || neighbors === 3)) {
                    row.push(1);
                } else if (!alive && neighbors === 3) {
                    row.push(1);
                } else {
                    row.push(0);
                }
            }
            next.push(row);
        }
        this.board = next;
        this.generation++;
        this.updateHud(this.running ? 'Simulation running' : 'Advanced one step');
        this.draw();
    },

    countNeighbors: function(x, y) {
        var count = 0;
        for (var oy = -1; oy <= 1; oy++) {
            for (var ox = -1; ox <= 1; ox++) {
                if (ox === 0 && oy === 0) continue;
                var nx = (x + ox + this.cols) % this.cols;
                var ny = (y + oy + this.rows) % this.rows;
                count += this.board[ny][nx];
            }
        }
        return count;
    },

    draw: function() {
        if (!this.ctx || !this.canvas) return;
        var rootStyle = getComputedStyle(document.documentElement);
        var bg = rootStyle.getPropertyValue('--color-window-bg').trim() || '#1f252d';
        var panel = rootStyle.getPropertyValue('--color-input-bg').trim() || '#161b22';
        var accent = rootStyle.getPropertyValue('--color-highlight').trim() || '#4a9eff';
        var muted = rootStyle.getPropertyValue('--color-border').trim() || 'rgba(255,255,255,0.1)';

        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.fillStyle = panel;
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        for (var y = 0; y < this.rows; y++) {
            for (var x = 0; x < this.cols; x++) {
                var px = x * this.cellSize;
                var py = y * this.cellSize;

                this.ctx.fillStyle = this.board[y][x] ? accent : bg;
                this.ctx.fillRect(px + 1, py + 1, this.cellSize - 2, this.cellSize - 2);
            }
        }

        this.ctx.strokeStyle = muted;
        this.ctx.lineWidth = 1;
        for (var gx = 0; gx <= this.cols; gx++) {
            this.ctx.beginPath();
            this.ctx.moveTo(gx * this.cellSize + 0.5, 0);
            this.ctx.lineTo(gx * this.cellSize + 0.5, this.canvas.height);
            this.ctx.stroke();
        }
        for (var gy = 0; gy <= this.rows; gy++) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, gy * this.cellSize + 0.5);
            this.ctx.lineTo(this.canvas.width, gy * this.cellSize + 0.5);
            this.ctx.stroke();
        }
    }
};
]=]
end

function CONWAY.GetCSS()
    return [[
.program-conway {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #202730);
    color: var(--color-text-primary, #f0f4f8);
}

.conway-topbar,
.conway-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding: 9px 10px;
    flex-wrap: wrap;
    background: var(--color-secondary-surface-alt, rgba(255, 255, 255, 0.05));
    border-bottom: 1px solid var(--color-border, rgba(255, 255, 255, 0.08));
}

.conway-footer {
    border-bottom: none;
    border-top: 1px solid var(--color-border, rgba(255, 255, 255, 0.08));
    color: var(--color-text-secondary, rgba(255,255,255,0.7));
    font-size: 11px;
}

.conway-stats,
.conway-actions {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
}

.conway-stat {
    min-width: 74px;
    padding: 6px 8px;
    border-radius: var(--radius-ui, 6px);
    background: var(--color-input-bg, rgba(0, 0, 0, 0.18));
    border: 1px solid var(--color-border, rgba(255, 255, 255, 0.08));
    display: flex;
    flex-direction: column;
    gap: 3px;
}

.conway-stat span {
    font-size: 10px;
    color: var(--color-text-secondary, rgba(255,255,255,0.72));
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.conway-stat strong {
    font-size: 13px;
}

.conway-stat-wide {
    min-width: 170px;
}

.conway-btn,
.conway-select {
    height: 30px;
    border-radius: var(--radius-ui, 6px);
    border: 1px solid var(--color-border, rgba(255,255,255,0.12));
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    color: var(--color-text-primary, #fff);
    padding: 0 10px;
    cursor: pointer;
    font-size: 12px;
}

.conway-btn:hover,
.conway-select:hover {
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.conway-btn-primary {
    background: var(--color-secondary-button-bg, var(--color-secondary, #596c86));
}

.conway-btn-primary:hover {
    background: var(--color-secondary-button-hover-bg, var(--color-secondary, #52627a));
}

.conway-speed {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 0 2px;
    color: var(--color-text-secondary, rgba(255,255,255,0.72));
    font-size: 11px;
}

.conway-speed input {
    width: 110px;
}

.conway-board-wrap {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8px;
    overflow: auto;
}

.conway-canvas {
    display: block;
    max-width: 100%;
    max-height: 100%;
    border-radius: calc(var(--radius-ui, 6px) + 2px);
    border: 1px solid var(--color-border, rgba(255,255,255,0.12));
    box-shadow: 0 14px 28px rgba(0, 0, 0, 0.28);
}
]]
end

CONWAY.title = "Conway's Life"
CONWAY.icon = "🧬"
CONWAY.width = 820
CONWAY.height = 620
CONWAY.content = CONWAY.GetContent
CONWAY.getContent = CONWAY.GetContent
CONWAY.getJavaScript = CONWAY.GetJavaScript
CONWAY.getCSS = CONWAY.GetCSS
CONWAY.getInitScript = CONWAY.GetInitScript

return CONWAY
