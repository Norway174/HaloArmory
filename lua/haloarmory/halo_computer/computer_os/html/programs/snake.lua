local SNAKE = {}

function SNAKE.GetContent()
    return [[
<div class="program-snake">
    <div class="snake-topbar">
        <div class="snake-stat"><span>Score</span><strong id="snake-score">0</strong></div>
        <div class="snake-stat"><span>Length</span><strong id="snake-length">3</strong></div>
        <div class="snake-stat snake-stat-wide"><span>Status</span><strong id="snake-status">Press an arrow key to start</strong></div>
        <div class="snake-actions">
            <button class="snake-btn snake-btn-primary" onclick="snakeApp.togglePause()">Pause</button>
            <button class="snake-btn" onclick="snakeApp.newGame()">New Game</button>
        </div>
    </div>
    <div class="snake-playfield">
        <canvas id="snake-canvas" class="snake-canvas" width="640" height="640"></canvas>
    </div>
    <div class="snake-footer">
        <span>Use <strong>WASD</strong> or <strong>Arrow Keys</strong></span>
        <span>Food speeds the run up slightly</span>
        <span>Press <strong>Space</strong> to pause</span>
    </div>
</div>
]]
end

function SNAKE.GetInitScript()
    return [[
        snakeApp.init(windowId);
    ]]
end

function SNAKE.GetJavaScript()
    return [[
var snakeApp = {
    windowId: null,
    canvas: null,
    ctx: null,
    gridSize: 18,
    snake: [],
    direction: { x: 1, y: 0 },
    pendingDirection: { x: 1, y: 0 },
    food: { x: 10, y: 10 },
    score: 0,
    tickMs: 140,
    minTickMs: 70,
    timer: null,
    paused: false,
    gameOver: false,
    started: false,

    init: function(windowId) {
        this.windowId = windowId;
        this.canvas = document.getElementById('snake-canvas');
        if (!this.canvas) return;
        this.ctx = this.canvas.getContext('2d');

        var self = this;
        this.handleKeyDown = function(e) {
            if (!self.isActiveWindow()) return;
            var key = e.key.toLowerCase();
            if (key === ' ' || e.code === 'Space') {
                e.preventDefault();
                self.togglePause();
                return;
            }

            var next = null;
            if (key === 'arrowup' || key === 'w') next = { x: 0, y: -1 };
            if (key === 'arrowdown' || key === 's') next = { x: 0, y: 1 };
            if (key === 'arrowleft' || key === 'a') next = { x: -1, y: 0 };
            if (key === 'arrowright' || key === 'd') next = { x: 1, y: 0 };

            if (!next) return;
            e.preventDefault();
            if (self.direction.x + next.x === 0 && self.direction.y + next.y === 0 && self.started) {
                return;
            }
            self.pendingDirection = next;
            if (!self.started) {
                self.started = true;
                self.updateStatus('Run live');
            }
        };

        this.handleWindowClosing = function(e) {
            if (e.detail && e.detail.id === self.windowId) {
                self.destroy();
            }
        };

        document.addEventListener('keydown', this.handleKeyDown);
        document.addEventListener('windowclosing', this.handleWindowClosing);
        this.newGame();
    },

    destroy: function() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
        document.removeEventListener('keydown', this.handleKeyDown);
        document.removeEventListener('windowclosing', this.handleWindowClosing);
    },

    isActiveWindow: function() {
        return !window.windowManager || window.windowManager.activeWindow === this.windowId;
    },

    newGame: function() {
        this.snake = [
            { x: 7, y: 10 },
            { x: 6, y: 10 },
            { x: 5, y: 10 }
        ];
        this.direction = { x: 1, y: 0 };
        this.pendingDirection = { x: 1, y: 0 };
        this.score = 0;
        this.tickMs = 140;
        this.paused = false;
        this.gameOver = false;
        this.started = false;
        this.spawnFood();
        this.updateHud();
        this.updateStatus('Press an arrow key to start');

        if (this.timer) clearInterval(this.timer);
        var self = this;
        this.timer = setInterval(function() {
            self.step();
        }, this.tickMs);
        this.draw();
    },

    restartTimer: function() {
        if (this.timer) clearInterval(this.timer);
        var self = this;
        this.timer = setInterval(function() {
            self.step();
        }, this.tickMs);
    },

    updateHud: function() {
        var scoreEl = document.getElementById('snake-score');
        var lengthEl = document.getElementById('snake-length');
        if (scoreEl) scoreEl.textContent = this.score;
        if (lengthEl) lengthEl.textContent = this.snake.length;
    },

    updateStatus: function(text) {
        var statusEl = document.getElementById('snake-status');
        if (statusEl) statusEl.textContent = text;
    },

    togglePause: function() {
        if (this.gameOver) {
            this.newGame();
            return;
        }
        if (!this.started) return;
        this.paused = !this.paused;
        this.updateStatus(this.paused ? 'Paused' : 'Run live');
        this.draw();
    },

    spawnFood: function() {
        var occupied = {};
        this.snake.forEach(function(segment) {
            occupied[segment.x + ',' + segment.y] = true;
        });

        var cols = Math.floor(this.canvas.width / this.gridSize);
        var rows = Math.floor(this.canvas.height / this.gridSize);
        var x = 0;
        var y = 0;

        do {
            x = Math.floor(Math.random() * cols);
            y = Math.floor(Math.random() * rows);
        } while (occupied[x + ',' + y]);

        this.food = { x: x, y: y };
    },

    step: function() {
        if (!this.started || this.paused || this.gameOver) {
            this.draw();
            return;
        }

        this.direction = { x: this.pendingDirection.x, y: this.pendingDirection.y };
        var head = this.snake[0];
        var nextHead = {
            x: head.x + this.direction.x,
            y: head.y + this.direction.y
        };

        var cols = Math.floor(this.canvas.width / this.gridSize);
        var rows = Math.floor(this.canvas.height / this.gridSize);
        if (nextHead.x < 0 || nextHead.y < 0 || nextHead.x >= cols || nextHead.y >= rows) {
            this.endGame();
            return;
        }

        for (var i = 0; i < this.snake.length; i++) {
            if (this.snake[i].x === nextHead.x && this.snake[i].y === nextHead.y) {
                this.endGame();
                return;
            }
        }

        this.snake.unshift(nextHead);

        if (nextHead.x === this.food.x && nextHead.y === this.food.y) {
            this.score += 10;
            this.tickMs = Math.max(this.minTickMs, this.tickMs - 4);
            this.restartTimer();
            this.spawnFood();
            this.updateStatus('Nice bite');
        } else {
            this.snake.pop();
        }

        this.updateHud();
        this.draw();
    },

    endGame: function() {
        this.gameOver = true;
        this.paused = false;
        this.updateStatus('Crashed - press New Game or Space');
        this.draw();
    },

    draw: function() {
        if (!this.ctx || !this.canvas) return;
        var ctx = this.ctx;
        var w = this.canvas.width;
        var h = this.canvas.height;
        ctx.clearRect(0, 0, w, h);

        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-window-bg').trim() || '#1d2329';
        ctx.fillRect(0, 0, w, h);

        ctx.strokeStyle = 'rgba(255,255,255,0.05)';
        ctx.lineWidth = 1;
        for (var x = 0; x <= w; x += this.gridSize) {
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, h);
            ctx.stroke();
        }
        for (var y = 0; y <= h; y += this.gridSize) {
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(w, y);
            ctx.stroke();
        }

        for (var i = this.snake.length - 1; i >= 0; i--) {
            var segment = this.snake[i];
            var isHead = i === 0;
            ctx.fillStyle = isHead
                ? (getComputedStyle(document.documentElement).getPropertyValue('--color-highlight').trim() || '#4a9eff')
                : (getComputedStyle(document.documentElement).getPropertyValue('--color-secondary').trim() || '#6f8ab8');
            ctx.fillRect(segment.x * this.gridSize + 2, segment.y * this.gridSize + 2, this.gridSize - 4, this.gridSize - 4);
        }

        ctx.fillStyle = '#ff8c42';
        ctx.beginPath();
        ctx.arc(this.food.x * this.gridSize + this.gridSize / 2, this.food.y * this.gridSize + this.gridSize / 2, this.gridSize / 2.8, 0, Math.PI * 2);
        ctx.fill();

        if (!this.started || this.paused || this.gameOver) {
            ctx.fillStyle = 'rgba(0,0,0,0.38)';
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-text-primary').trim() || '#fff';
            ctx.textAlign = 'center';
            ctx.font = '600 24px Segoe UI';
            var message = 'Press an arrow key to start';
            if (this.paused) message = 'Paused';
            if (this.gameOver) message = 'Game over';
            ctx.fillText(message, w / 2, h / 2);
        }
    }
};
]]
end

function SNAKE.GetCSS()
    return [[
.program-snake {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #1e242a);
    color: var(--color-text-primary, #fff);
}

.snake-topbar,
.snake-footer {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 9px 10px;
    flex-wrap: wrap;
    background: var(--color-primary-surface-alt, #27303a);
    border-bottom: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
}

.snake-footer {
    border-top: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-bottom: none;
    justify-content: space-between;
    color: var(--color-text-muted, rgba(255,255,255,0.74));
    font-size: 11px;
}

.snake-stat {
    min-width: 70px;
    padding: 6px 9px;
    border-radius: var(--radius-ui, 8px);
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    display: flex;
    flex-direction: column;
    gap: 2px;
}

.snake-stat-wide {
    flex: 1;
}

.snake-stat span {
    font-size: 10px;
    color: var(--color-text-muted, rgba(255,255,255,0.72));
    text-transform: uppercase;
    letter-spacing: 0.06em;
}

.snake-stat strong {
    font-size: 16px;
}

.snake-actions {
    display: flex;
    gap: 6px;
    margin-left: auto;
}

.snake-btn {
    padding: 6px 10px;
    border-radius: var(--radius-ui-small, 6px);
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.16));
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    color: var(--color-text-primary, #fff);
    font: inherit;
    cursor: pointer;
}

.snake-btn:hover {
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.snake-btn-primary {
    background: var(--color-secondary-button-bg, var(--color-secondary, #556b88));
}

.snake-btn-primary:hover {
    background: var(--color-secondary-button-hover-bg, var(--color-secondary, #62799a));
}

.snake-playfield {
    flex: 1;
    min-height: 0;
    padding: 8px;
}

.snake-canvas {
    width: 100%;
    height: 100%;
    display: block;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-radius: var(--radius-ui, 8px);
    background: var(--color-window-bg, #1e242a);
}
]]
end

return {
    title = "Snake",
    icon = "🐍",
    width = 620,
    height = 680,
    getContent = SNAKE.GetContent,
    getInitScript = SNAKE.GetInitScript,
    getJavaScript = SNAKE.GetJavaScript,
    getCSS = SNAKE.GetCSS
}
