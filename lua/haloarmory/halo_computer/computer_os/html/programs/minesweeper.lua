-- Minesweeper Game
local MINESWEEPER = {}

function MINESWEEPER.GetContent()
    return [[
<div class="program-minesweeper">
    <div class="minesweeper-header">
        <div class="minesweeper-info">
            <span>Mines: <span id="mines-count">10</span></span>
            <button onclick="minesweeperApp.newGame()" class="btn btn-primary">New Game</button>
            <span>Time: <span id="mines-time">0</span></span>
        </div>
    </div>
    <div class="minesweeper-board-container">
        <div id="minesweeper-board" class="minesweeper-board"></div>
    </div>
</div>
]]
end

function MINESWEEPER.GetInitScript()
    return [[
        minesweeperApp.init(windowId);
    ]]
end

function MINESWEEPER.GetJavaScript()
    return [[
var minesweeperApp = {
    board: [],
    revealed: [],
    flagged: [],
    rows: 10,
    cols: 10,
    mines: 10,
    gameOver: false,
    gameWon: false,
    time: 0,
    timerInterval: null,
    windowId: null,
    
    init: function(windowId) {
        this.windowId = windowId;
        this.newGame();
    },
    
    newGame: function() {
        this.gameOver = false;
        this.gameWon = false;
        this.time = 0;
        this.revealed = [];
        this.flagged = [];
        this.board = [];
        
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
        }
        
        // Initialize board
        for (var i = 0; i < this.rows; i++) {
            this.board[i] = [];
            this.revealed[i] = [];
            this.flagged[i] = [];
            for (var j = 0; j < this.cols; j++) {
                this.board[i][j] = 0;
                this.revealed[i][j] = false;
                this.flagged[i][j] = false;
            }
        }
        
        // Place mines
        var placed = 0;
        while (placed < this.mines) {
            var row = Math.floor(Math.random() * this.rows);
            var col = Math.floor(Math.random() * this.cols);
            if (this.board[row][col] !== -1) {
                this.board[row][col] = -1;
                placed++;
                
                // Update numbers around mine
                for (var dr = -1; dr <= 1; dr++) {
                    for (var dc = -1; dc <= 1; dc++) {
                        var nr = row + dr;
                        var nc = col + dc;
                        if (nr >= 0 && nr < this.rows && nc >= 0 && nc < this.cols && this.board[nr][nc] !== -1) {
                            this.board[nr][nc]++;
                        }
                    }
                }
            }
        }
        
        this.render();
        this.startTimer();
    },
    
    startTimer: function() {
        this.timerInterval = setInterval(function() {
            if (!minesweeperApp.gameOver && !minesweeperApp.gameWon) {
                minesweeperApp.time++;
                document.getElementById('mines-time').textContent = minesweeperApp.time;
            }
        }, 1000);
    },
    
    render: function() {
        var boardEl = document.getElementById('minesweeper-board');
        boardEl.innerHTML = '';
        boardEl.style.gridTemplateColumns = 'repeat(' + this.cols + ', 1fr)';
        
        for (var i = 0; i < this.rows; i++) {
            for (var j = 0; j < this.cols; j++) {
                var cell = document.createElement('div');
                cell.className = 'minesweeper-cell';
                cell.dataset.row = i;
                cell.dataset.col = j;
                
                if (this.revealed[i][j]) {
                    if (this.board[i][j] === -1) {
                        cell.textContent = '💣';
                        cell.classList.add('mine');
                    } else if (this.board[i][j] > 0) {
                        cell.textContent = this.board[i][j];
                        cell.classList.add('revealed', 'number-' + this.board[i][j]);
                    } else {
                        cell.classList.add('revealed');
                    }
                } else if (this.flagged[i][j]) {
                    cell.textContent = '🚩';
                    cell.classList.add('flagged');
                }
                
                cell.addEventListener('click', function(e) {
                    if (e.button === 0) {
                        minesweeperApp.reveal(parseInt(this.dataset.row), parseInt(this.dataset.col));
                    }
                });
                
                cell.addEventListener('contextmenu', function(e) {
                    e.preventDefault();
                    minesweeperApp.flag(parseInt(this.dataset.row), parseInt(this.dataset.col));
                });
                
                boardEl.appendChild(cell);
            }
        }
        
        var flaggedCount = 0;
        for (var i = 0; i < this.rows; i++) {
            for (var j = 0; j < this.cols; j++) {
                if (this.flagged[i][j]) flaggedCount++;
            }
        }
        document.getElementById('mines-count').textContent = this.mines - flaggedCount;
    },
    
    reveal: function(row, col) {
        if (this.gameOver || this.gameWon || this.revealed[row][col] || this.flagged[row][col]) return;
        
        this.revealed[row][col] = true;
        
        if (this.board[row][col] === -1) {
            this.gameOver = true;
            clearInterval(this.timerInterval);
            alert('Game Over! You hit a mine!');
            this.revealAll();
            return;
        }
        
        if (this.board[row][col] === 0) {
            // Reveal adjacent cells
            for (var dr = -1; dr <= 1; dr++) {
                for (var dc = -1; dc <= 1; dc++) {
                    var nr = row + dr;
                    var nc = col + dc;
                    if (nr >= 0 && nr < this.rows && nc >= 0 && nc < this.cols && !this.revealed[nr][nc]) {
                        this.reveal(nr, nc);
                    }
                }
            }
        }
        
        this.render();
        this.checkWin();
    },
    
    flag: function(row, col) {
        if (this.gameOver || this.gameWon || this.revealed[row][col]) return;
        this.flagged[row][col] = !this.flagged[row][col];
        this.render();
    },
    
    checkWin: function() {
        var revealedCount = 0;
        for (var i = 0; i < this.rows; i++) {
            for (var j = 0; j < this.cols; j++) {
                if (this.revealed[i][j]) revealedCount++;
            }
        }
        
        if (revealedCount === (this.rows * this.cols - this.mines)) {
            this.gameWon = true;
            clearInterval(this.timerInterval);
            alert('Congratulations! You won in ' + this.time + ' seconds!');
        }
    },
    
    revealAll: function() {
        for (var i = 0; i < this.rows; i++) {
            for (var j = 0; j < this.cols; j++) {
                this.revealed[i][j] = true;
            }
        }
        this.render();
    }
};
]]
end

function MINESWEEPER.GetCSS()
    return [[
.program-minesweeper {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #2d2d2d);
}

.minesweeper-header {
    padding: 8px;
    border-bottom: 1px solid var(--color-window-border, #444);
    background: var(--color-primary-surface-alt, #2d2d2d);
}

.minesweeper-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    color: var(--color-text-on-primary-surface, #fff);
}

.minesweeper-header .btn {
    padding: 8px 12px;
    border: 1px solid var(--color-accent, #5e9be3);
    border-radius: var(--radius-ui-small, 4px);
    background: var(--color-button-bg, #3b74b5);
    color: var(--color-text-on-button, #fff);
    cursor: pointer;
    font: inherit;
}

.minesweeper-header .btn:hover {
    background: var(--color-button-hover-bg, #4a4a4a);
}

.minesweeper-board-container {
    flex: 1;
    padding: 16px;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
    overflow: auto;
    display: flex;
    justify-content: center;
    align-items: flex-start;
}

.minesweeper-board {
    display: grid;
    gap: 2px;
    background: var(--color-window-border, #444);
    padding: 2px;
}

.minesweeper-cell {
    width: 32px;
    height: 32px;
    background: #c0c0c0;
    border: 2px outset #ddd;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 16px;
    font-weight: bold;
    user-select: none;
}

.minesweeper-cell:active {
    border: 2px inset #999;
}

.minesweeper-cell.revealed {
    background: #e0e0e0;
    border: 1px solid #999;
}

.minesweeper-cell.number-1 { color: #0000ff; }
.minesweeper-cell.number-2 { color: #008000; }
.minesweeper-cell.number-3 { color: #ff0000; }
.minesweeper-cell.number-4 { color: #000080; }
.minesweeper-cell.number-5 { color: #800000; }
.minesweeper-cell.number-6 { color: #008080; }
.minesweeper-cell.number-7 { color: #000000; }
.minesweeper-cell.number-8 { color: #808080; }

.minesweeper-cell.mine {
    background: #ff0000;
}

.minesweeper-cell.flagged {
    background: #ffff00;
}
]]
end

return {
    title = "Minesweeper",
    icon = "💣",
    width = 400,
    height = 460,
    getContent = MINESWEEPER.GetContent,
    getInitScript = MINESWEEPER.GetInitScript,
    getJavaScript = MINESWEEPER.GetJavaScript,
    getCSS = MINESWEEPER.GetCSS
}

