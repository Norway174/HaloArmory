local GAME2048 = {}

function GAME2048.GetContent()
    return [[
<div class="program-2048">
    <div class="game2048-topbar">
        <div class="game2048-stats">
            <div class="game2048-stat"><span>Score</span><strong id="game2048-score">0</strong></div>
            <div class="game2048-stat"><span>Best Tile</span><strong id="game2048-best">2</strong></div>
            <div class="game2048-stat game2048-stat-wide"><span>Status</span><strong id="game2048-status">Use arrow keys or WASD</strong></div>
        </div>
        <div class="game2048-actions">
            <button class="game2048-btn game2048-btn-primary" onclick="game2048App.newGame()">New Game</button>
        </div>
    </div>
    <div class="game2048-board-wrap">
        <div id="game2048-board" class="game2048-board"></div>
    </div>
    <div class="game2048-footer">
        <span>Combine tiles to reach <strong>2048</strong></span>
        <span>Moves: <strong>WASD</strong> or <strong>Arrow Keys</strong></span>
        <span>Keep the corners stable</span>
    </div>
</div>
]]
end

function GAME2048.GetInitScript()
    return [[
        game2048App.init(windowId);
    ]]
end

function GAME2048.GetJavaScript()
    return [[
var game2048App = {
    windowId: null,
    boardSize: 4,
    board: [],
    score: 0,
    won: false,
    gameOver: false,
    statusText: 'Use arrow keys or WASD',

    init: function(windowId) {
        this.windowId = windowId;
        var self = this;
        this.handleKeyDown = function(e) {
            if (!self.isActiveWindow()) return;
            var key = String(e.key || '').toLowerCase();
            var direction = null;
            if (key === 'arrowup' || key === 'w') direction = 'up';
            if (key === 'arrowdown' || key === 's') direction = 'down';
            if (key === 'arrowleft' || key === 'a') direction = 'left';
            if (key === 'arrowright' || key === 'd') direction = 'right';
            if (!direction) return;
            e.preventDefault();
            self.move(direction);
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
        document.removeEventListener('keydown', this.handleKeyDown);
        document.removeEventListener('windowclosing', this.handleWindowClosing);
    },

    isActiveWindow: function() {
        return !window.windowManager || window.windowManager.activeWindow === this.windowId;
    },

    newGame: function() {
        this.score = 0;
        this.won = false;
        this.gameOver = false;
        this.statusText = 'Fresh board ready';
        this.board = [];
        for (var y = 0; y < this.boardSize; y++) {
            var row = [];
            for (var x = 0; x < this.boardSize; x++) {
                row.push(0);
            }
            this.board.push(row);
        }
        this.spawnTile();
        this.spawnTile();
        this.updateHud(this.statusText);
        this.render();
    },

    updateHud: function(status) {
        this.statusText = status || this.statusText || '';
        var scoreEl = document.getElementById('game2048-score');
        var bestEl = document.getElementById('game2048-best');
        var statusEl = document.getElementById('game2048-status');
        if (scoreEl) scoreEl.textContent = this.score;
        if (bestEl) bestEl.textContent = this.getBestTile();
        if (statusEl) statusEl.textContent = this.statusText;
    },

    getBestTile: function() {
        var best = 2;
        for (var y = 0; y < this.boardSize; y++) {
            for (var x = 0; x < this.boardSize; x++) {
                best = Math.max(best, this.board[y][x]);
            }
        }
        return best;
    },

    spawnTile: function() {
        var empties = [];
        for (var y = 0; y < this.boardSize; y++) {
            for (var x = 0; x < this.boardSize; x++) {
                if (!this.board[y][x]) {
                    empties.push({ x: x, y: y });
                }
            }
        }

        if (!empties.length) return false;
        var pick = empties[Math.floor(Math.random() * empties.length)];
        this.board[pick.y][pick.x] = Math.random() > 0.9 ? 4 : 2;
        return true;
    },

    move: function(direction) {
        if (this.gameOver) {
            this.updateHud('Game over - start a new board');
            return;
        }

        var moved = false;
        var before = JSON.stringify(this.board);

        if (direction === 'left') {
            for (var y = 0; y < this.boardSize; y++) {
                this.board[y] = this.mergeLine(this.board[y]);
            }
        } else if (direction === 'right') {
            for (var ry = 0; ry < this.boardSize; ry++) {
                this.board[ry] = this.mergeLine(this.board[ry].slice().reverse()).reverse();
            }
        } else if (direction === 'up') {
            for (var x = 0; x < this.boardSize; x++) {
                var upCol = this.getColumn(x);
                this.setColumn(x, this.mergeLine(upCol));
            }
        } else if (direction === 'down') {
            for (var dx = 0; dx < this.boardSize; dx++) {
                var downCol = this.getColumn(dx).reverse();
                this.setColumn(dx, this.mergeLine(downCol).reverse());
            }
        }

        moved = before !== JSON.stringify(this.board);
        if (!moved) {
            this.updateHud('No move there');
            this.render();
            return;
        }

        this.spawnTile();
        if (this.getBestTile() >= 2048 && !this.won) {
            this.won = true;
            this.updateHud('2048 reached - keep going if you want');
        } else {
            this.updateHud('Board shifted ' + direction);
        }

        if (!this.canMove()) {
            this.gameOver = true;
            this.updateHud('No moves left - game over');
        }

        this.render();
    },

    mergeLine: function(line) {
        var compact = line.filter(function(value) {
            return value !== 0;
        });
        var merged = [];

        for (var i = 0; i < compact.length; i++) {
            var current = compact[i];
            if (compact[i + 1] === current) {
                current = current * 2;
                this.score += current;
                i++;
            }
            merged.push(current);
        }

        while (merged.length < this.boardSize) {
            merged.push(0);
        }

        return merged;
    },

    getColumn: function(index) {
        var column = [];
        for (var y = 0; y < this.boardSize; y++) {
            column.push(this.board[y][index]);
        }
        return column;
    },

    setColumn: function(index, values) {
        for (var y = 0; y < this.boardSize; y++) {
            this.board[y][index] = values[y];
        }
    },

    canMove: function() {
        for (var y = 0; y < this.boardSize; y++) {
            for (var x = 0; x < this.boardSize; x++) {
                var value = this.board[y][x];
                if (!value) return true;
                if (x < this.boardSize - 1 && this.board[y][x + 1] === value) return true;
                if (y < this.boardSize - 1 && this.board[y + 1][x] === value) return true;
            }
        }
        return false;
    },

    getTileClass: function(value) {
        if (!value) return 'tile-empty';
        if (value <= 8) return 'tile-low';
        if (value <= 64) return 'tile-mid';
        if (value <= 512) return 'tile-high';
        return 'tile-epic';
    },

    render: function() {
        var boardEl = document.getElementById('game2048-board');
        if (!boardEl) return;

        boardEl.innerHTML = '';
        for (var y = 0; y < this.boardSize; y++) {
            for (var x = 0; x < this.boardSize; x++) {
                var value = this.board[y][x];
                var tile = document.createElement('div');
                tile.className = 'game2048-tile ' + this.getTileClass(value);
                tile.textContent = value ? value : '';
                boardEl.appendChild(tile);
            }
        }

        this.updateHud();
    }
};
]]
end

function GAME2048.GetCSS()
    return [[
.program-2048 {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #202730);
    color: var(--color-text-primary, #f0f4f8);
}

.game2048-topbar,
.game2048-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding: 9px 10px;
    flex-wrap: wrap;
    background: var(--color-secondary-surface-alt, rgba(255, 255, 255, 0.05));
    border-bottom: 1px solid var(--color-border, rgba(255,255,255,0.08));
}

.game2048-footer {
    border-bottom: none;
    border-top: 1px solid var(--color-border, rgba(255,255,255,0.08));
    color: var(--color-text-secondary, rgba(255,255,255,0.72));
    font-size: 11px;
}

.game2048-stats,
.game2048-actions {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
}

.game2048-stat {
    min-width: 72px;
    padding: 6px 8px;
    border-radius: var(--radius-ui, 6px);
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    border: 1px solid var(--color-border, rgba(255,255,255,0.08));
    display: flex;
    flex-direction: column;
    gap: 3px;
}

.game2048-stat span {
    font-size: 10px;
    color: var(--color-text-secondary, rgba(255,255,255,0.72));
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.game2048-stat strong {
    font-size: 14px;
}

.game2048-stat-wide {
    min-width: 170px;
}

.game2048-btn {
    height: 30px;
    padding: 0 10px;
    border-radius: var(--radius-ui, 6px);
    border: 1px solid var(--color-border, rgba(255,255,255,0.12));
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
}

.game2048-btn:hover {
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.game2048-btn-primary {
    background: var(--color-secondary-button-bg, var(--color-secondary, #596c86));
}

.game2048-btn-primary:hover {
    background: var(--color-secondary-button-hover-bg, var(--color-secondary, #52627a));
}

.game2048-board-wrap {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 10px;
}

.game2048-board {
    width: min(100%, 460px);
    aspect-ratio: 1 / 1;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 9px;
    padding: 10px;
    border-radius: calc(var(--radius-ui, 6px) + 8px);
    background: var(--color-input-bg, rgba(0,0,0,0.22));
    border: 1px solid var(--color-border, rgba(255,255,255,0.12));
    box-shadow: 0 18px 34px rgba(0, 0, 0, 0.26);
}

.game2048-tile {
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: calc(var(--radius-ui, 6px) + 2px);
    font-size: clamp(18px, 3.3vw, 28px);
    font-weight: 700;
    letter-spacing: -0.02em;
    border: 1px solid rgba(255,255,255,0.08);
    transition: transform 0.12s ease, background 0.12s ease;
}

.game2048-tile.tile-empty {
    background: rgba(255, 255, 255, 0.05);
}

.game2048-tile.tile-low {
    background: rgba(116, 136, 164, 0.78);
    color: #f6f8fb;
}

.game2048-tile.tile-mid {
    background: rgba(74, 158, 255, 0.78);
    color: #ffffff;
}

.game2048-tile.tile-high {
    background: rgba(84, 134, 214, 0.88);
    color: #ffffff;
}

.game2048-tile.tile-epic {
    background: rgba(94, 176, 255, 0.94);
    color: #ffffff;
    box-shadow: 0 0 0 1px rgba(255,255,255,0.18), 0 10px 22px rgba(0, 0, 0, 0.18);
}
]]
end

GAME2048.title = "2048"
GAME2048.icon = "🔢"
GAME2048.width = 620
GAME2048.height = 660
GAME2048.content = GAME2048.GetContent
GAME2048.getContent = GAME2048.GetContent
GAME2048.getJavaScript = GAME2048.GetJavaScript
GAME2048.getCSS = GAME2048.GetCSS
GAME2048.getInitScript = GAME2048.GetInitScript

return GAME2048
