local PINGPONG = {}

function PINGPONG.GetContent()
    return [[
<div class="program-pingpong">
    <div class="pingpong-topbar">
        <div class="pingpong-scoreboard">
            <div class="pingpong-score-card">
                <span class="pingpong-score-label">You</span>
                <span class="pingpong-score-value" id="pingpong-player-score">0</span>
            </div>
            <div class="pingpong-score-card">
                <span class="pingpong-score-label">CPU</span>
                <span class="pingpong-score-value" id="pingpong-ai-score">0</span>
            </div>
            <div class="pingpong-score-card pingpong-score-card-wide">
                <span class="pingpong-score-label">Status</span>
                <span class="pingpong-score-value pingpong-status" id="pingpong-status">Press Space to serve</span>
            </div>
        </div>
        <div class="pingpong-controls">
            <button class="pingpong-btn pingpong-btn-primary" onclick="pingPongApp.togglePause()">Pause</button>
            <button class="pingpong-btn" onclick="pingPongApp.resetMatch()">New Match</button>
        </div>
    </div>
    <div class="pingpong-playfield">
        <canvas id="pingpong-canvas" class="pingpong-canvas" width="900" height="520"></canvas>
    </div>
    <div class="pingpong-footer">
        <span>Move with <strong>W / S</strong> or <strong>↑ / ↓</strong></span>
        <span>First to <strong>7</strong> wins</span>
        <span><strong>Space</strong> pauses and serves</span>
    </div>
</div>
]]
end

function PINGPONG.GetInitScript()
    return [[
        pingPongApp.init(windowId);
    ]]
end

function PINGPONG.GetJavaScript()
    return [[
var pingPongApp = {
    windowId: null,
    canvas: null,
    ctx: null,
    animationFrame: null,
    lastFrameTime: 0,
    keyState: {},
    playerScore: 0,
    aiScore: 0,
    winningScore: 7,
    paddleHeight: 88,
    paddleWidth: 12,
    ballSize: 12,
    arenaPadding: 18,
    player: null,
    ai: null,
    ball: null,
    paused: false,
    waitingForServe: true,
    winner: null,

    init: function(windowId) {
        this.windowId = windowId;
        this.canvas = document.getElementById('pingpong-canvas');
        if (!this.canvas) return;
        this.ctx = this.canvas.getContext('2d');

        var self = this;
        this.handleKeyDown = function(e) {
            if (!self.isActiveWindow()) return;
            if (e.key === ' ' || e.code === 'Space') {
                e.preventDefault();
                if (self.winner) {
                    self.resetMatch();
                } else if (self.waitingForServe) {
                    self.serveBall();
                } else {
                    self.togglePause();
                }
                return;
            }
            self.keyState[e.key.toLowerCase()] = true;
        };
        this.handleKeyUp = function(e) {
            self.keyState[e.key.toLowerCase()] = false;
        };
        this.handleResize = function() {
            self.resizeCanvas();
        };
        this.handleWindowClosing = function(e) {
            if (e.detail && e.detail.id === self.windowId) {
                self.destroy();
            }
        };

        document.addEventListener('keydown', this.handleKeyDown);
        document.addEventListener('keyup', this.handleKeyUp);
        window.addEventListener('resize', this.handleResize);
        document.addEventListener('windowclosing', this.handleWindowClosing);

        this.resizeCanvas();
        this.resetMatch();
        this.startLoop();
    },

    destroy: function() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
            this.animationFrame = null;
        }
        document.removeEventListener('keydown', this.handleKeyDown);
        document.removeEventListener('keyup', this.handleKeyUp);
        window.removeEventListener('resize', this.handleResize);
        document.removeEventListener('windowclosing', this.handleWindowClosing);
    },

    isActiveWindow: function() {
        return !window.windowManager || window.windowManager.activeWindow === this.windowId;
    },

    resizeCanvas: function() {
        if (!this.canvas) return;
        var container = this.canvas.parentElement;
        if (!container) return;
        var rect = container.getBoundingClientRect();
        var width = Math.max(520, Math.floor(rect.width - 16));
        var height = Math.max(280, Math.floor(rect.height - 16));
        this.canvas.width = width;
        this.canvas.height = height;
        if (this.player && this.ai) {
            this.player.x = this.arenaPadding;
            this.ai.x = width - this.arenaPadding - this.paddleWidth;
            this.player.y = Math.min(this.player.y, height - this.paddleHeight - this.arenaPadding);
            this.ai.y = Math.min(this.ai.y, height - this.paddleHeight - this.arenaPadding);
        }
        if (this.ball) {
            this.ball.x = width / 2;
            this.ball.y = height / 2;
        }
    },

    resetMatch: function() {
        this.playerScore = 0;
        this.aiScore = 0;
        this.winner = null;
        this.paused = false;
        this.waitingForServe = true;
        this.player = {
            x: this.arenaPadding,
            y: (this.canvas.height - this.paddleHeight) / 2,
            speed: 410
        };
        this.ai = {
            x: this.canvas.width - this.arenaPadding - this.paddleWidth,
            y: (this.canvas.height - this.paddleHeight) / 2,
            speed: 360
        };
        this.ball = {
            x: this.canvas.width / 2,
            y: this.canvas.height / 2,
            vx: 0,
            vy: 0,
            baseSpeed: 350,
            speedBoost: 18
        };
        this.updateHud('Press Space to serve');
        this.draw();
    },

    updateHud: function(statusText) {
        var playerScoreEl = document.getElementById('pingpong-player-score');
        var aiScoreEl = document.getElementById('pingpong-ai-score');
        var statusEl = document.getElementById('pingpong-status');
        if (playerScoreEl) playerScoreEl.textContent = this.playerScore;
        if (aiScoreEl) aiScoreEl.textContent = this.aiScore;
        if (statusEl) statusEl.textContent = statusText || '';
    },

    togglePause: function() {
        if (this.winner || this.waitingForServe) return;
        this.paused = !this.paused;
        this.updateHud(this.paused ? 'Paused' : 'Volley live');
    },

    serveBall: function() {
        if (this.winner) return;
        this.waitingForServe = false;
        this.paused = false;
        var direction = Math.random() > 0.5 ? 1 : -1;
        var angle = (Math.random() * 0.9 - 0.45);
        this.ball.x = this.canvas.width / 2;
        this.ball.y = this.canvas.height / 2;
        this.ball.vx = Math.cos(angle) * this.ball.baseSpeed * direction;
        this.ball.vy = Math.sin(angle) * this.ball.baseSpeed;
        this.updateHud('Volley live');
    },

    scorePoint: function(scoredByPlayer) {
        if (scoredByPlayer) {
            this.playerScore++;
        } else {
            this.aiScore++;
        }

        if (this.playerScore >= this.winningScore || this.aiScore >= this.winningScore) {
            this.winner = this.playerScore > this.aiScore ? 'You win the match' : 'CPU wins the match';
            this.waitingForServe = true;
            this.ball.vx = 0;
            this.ball.vy = 0;
            this.updateHud(this.winner + ' - press Space to restart');
            return;
        }

        this.waitingForServe = true;
        this.ball.vx = 0;
        this.ball.vy = 0;
        this.ball.x = this.canvas.width / 2;
        this.ball.y = this.canvas.height / 2;
        this.updateHud((scoredByPlayer ? 'Point for you' : 'Point for CPU') + ' - press Space to serve');
    },

    getPlayerInput: function() {
        if (this.keyState['w'] || this.keyState['arrowup']) return -1;
        if (this.keyState['s'] || this.keyState['arrowdown']) return 1;
        return 0;
    },

    update: function(dt) {
        if (!this.player || !this.ai || !this.ball || this.paused || this.waitingForServe || this.winner) {
            return;
        }

        var moveDirection = this.getPlayerInput();
        this.player.y += moveDirection * this.player.speed * dt;
        this.player.y = Math.max(this.arenaPadding, Math.min(this.canvas.height - this.paddleHeight - this.arenaPadding, this.player.y));

        var aiTarget = this.ball.y - this.paddleHeight / 2;
        var aiDiff = aiTarget - this.ai.y;
        var aiStep = Math.max(-this.ai.speed * dt, Math.min(this.ai.speed * dt, aiDiff));
        this.ai.y += aiStep;
        this.ai.y = Math.max(this.arenaPadding, Math.min(this.canvas.height - this.paddleHeight - this.arenaPadding, this.ai.y));

        this.ball.x += this.ball.vx * dt;
        this.ball.y += this.ball.vy * dt;

        if (this.ball.y <= this.arenaPadding + this.ballSize / 2 || this.ball.y >= this.canvas.height - this.arenaPadding - this.ballSize / 2) {
            this.ball.vy *= -1;
            this.ball.y = Math.max(this.arenaPadding + this.ballSize / 2, Math.min(this.canvas.height - this.arenaPadding - this.ballSize / 2, this.ball.y));
        }

        this.checkPaddleCollision(this.player, 1);
        this.checkPaddleCollision(this.ai, -1);

        if (this.ball.x < -this.ballSize) {
            this.scorePoint(false);
        } else if (this.ball.x > this.canvas.width + this.ballSize) {
            this.scorePoint(true);
        }
    },

    checkPaddleCollision: function(paddle, direction) {
        var paddleLeft = paddle.x;
        var paddleRight = paddle.x + this.paddleWidth;
        var paddleTop = paddle.y;
        var paddleBottom = paddle.y + this.paddleHeight;
        var ballLeft = this.ball.x - this.ballSize / 2;
        var ballRight = this.ball.x + this.ballSize / 2;
        var ballTop = this.ball.y - this.ballSize / 2;
        var ballBottom = this.ball.y + this.ballSize / 2;

        if (ballRight < paddleLeft || ballLeft > paddleRight || ballBottom < paddleTop || ballTop > paddleBottom) {
            return;
        }

        var impact = ((this.ball.y - paddle.y) / this.paddleHeight) - 0.5;
        var speed = Math.min(860, Math.abs(this.ball.vx) + this.ball.speedBoost);
        this.ball.vx = direction * speed;
        this.ball.vy = impact * 520;
        this.ball.x = direction > 0
            ? paddleRight + this.ballSize / 2 + 1
            : paddleLeft - this.ballSize / 2 - 1;
    },

    draw: function() {
        if (!this.ctx || !this.canvas) return;
        var ctx = this.ctx;
        var w = this.canvas.width;
        var h = this.canvas.height;

        ctx.clearRect(0, 0, w, h);
        var gradient = ctx.createLinearGradient(0, 0, 0, h);
        gradient.addColorStop(0, getComputedStyle(document.documentElement).getPropertyValue('--color-primary-surface-alt').trim() || '#27303a');
        gradient.addColorStop(1, getComputedStyle(document.documentElement).getPropertyValue('--color-window-bg').trim() || '#1f252b');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, w, h);

        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-window-border').trim() || 'rgba(255,255,255,0.18)';
        ctx.lineWidth = 2;
        ctx.strokeRect(this.arenaPadding, this.arenaPadding, w - this.arenaPadding * 2, h - this.arenaPadding * 2);

        ctx.setLineDash([10, 14]);
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-highlight').trim() || '#4a9eff';
        ctx.beginPath();
        ctx.moveTo(w / 2, this.arenaPadding);
        ctx.lineTo(w / 2, h - this.arenaPadding);
        ctx.stroke();
        ctx.setLineDash([]);

        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-highlight').trim() || '#4a9eff';
        ctx.globalAlpha = 0.9;
        ctx.fillRect(this.player.x, this.player.y, this.paddleWidth, this.paddleHeight);
        ctx.fillRect(this.ai.x, this.ai.y, this.paddleWidth, this.paddleHeight);
        ctx.globalAlpha = 1;

        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-text-primary').trim() || '#ffffff';
        ctx.fillRect(this.ball.x - this.ballSize / 2, this.ball.y - this.ballSize / 2, this.ballSize, this.ballSize);

        ctx.fillStyle = 'rgba(255,255,255,0.07)';
        ctx.font = '700 72px Segoe UI';
        ctx.textAlign = 'center';
        ctx.fillText(String(this.playerScore), w * 0.25, 86);
        ctx.fillText(String(this.aiScore), w * 0.75, 86);

        if (this.waitingForServe && !this.winner) {
            ctx.fillStyle = 'rgba(0,0,0,0.32)';
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-text-primary').trim() || '#ffffff';
            ctx.font = '600 22px Segoe UI';
            ctx.fillText('Press Space to serve', w / 2, h / 2);
        }

        if (this.paused) {
            ctx.fillStyle = 'rgba(0,0,0,0.34)';
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--color-text-primary').trim() || '#ffffff';
            ctx.font = '600 24px Segoe UI';
            ctx.fillText('Paused', w / 2, h / 2);
        }
    },

    startLoop: function() {
        var self = this;
        var step = function(timestamp) {
            if (!self.lastFrameTime) {
                self.lastFrameTime = timestamp;
            }
            var dt = Math.min(0.03, (timestamp - self.lastFrameTime) / 1000);
            self.lastFrameTime = timestamp;
            self.update(dt);
            self.draw();
            self.animationFrame = requestAnimationFrame(step);
        };
        this.animationFrame = requestAnimationFrame(step);
    }
};
]]
end

function PINGPONG.GetCSS()
    return [[
.program-pingpong {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #20252b);
    color: var(--color-text-primary, #fff);
}

.pingpong-topbar {
    display: flex;
    justify-content: space-between;
    gap: 10px;
    padding: 9px 10px;
    flex-wrap: wrap;
    border-bottom: 1px solid var(--color-window-border, rgba(255,255,255,0.12));
    background: var(--color-primary-surface-alt, #27303a);
}

.pingpong-scoreboard {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.pingpong-score-card {
    min-width: 70px;
    padding: 6px 9px;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-radius: var(--radius-ui, 8px);
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    display: flex;
    flex-direction: column;
    gap: 2px;
}

.pingpong-score-card-wide {
    min-width: 180px;
}

.pingpong-score-label {
    font-size: 10px;
    color: var(--color-text-muted, rgba(255,255,255,0.72));
    text-transform: uppercase;
    letter-spacing: 0.06em;
}

.pingpong-score-value {
    font-size: 17px;
    font-weight: 700;
}

.pingpong-status {
    font-size: 13px;
}

.pingpong-controls {
    display: flex;
    gap: 6px;
    align-items: center;
}

.pingpong-btn {
    padding: 6px 10px;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.16));
    border-radius: var(--radius-ui-small, 6px);
    background: var(--color-input-bg, rgba(0,0,0,0.18));
    color: var(--color-text-primary, #fff);
    cursor: pointer;
    font: inherit;
}

.pingpong-btn:hover {
    border-color: var(--color-highlight, #4a9eff);
    box-shadow: 0 0 0 1px var(--color-highlight, #4a9eff);
}

.pingpong-btn-primary {
    background: var(--color-secondary-button-bg, var(--color-secondary, #556b88));
}

.pingpong-btn-primary:hover {
    background: var(--color-secondary-button-hover-bg, var(--color-secondary, #62799a));
}

.pingpong-playfield {
    flex: 1;
    min-height: 0;
    padding: 8px;
}

.pingpong-canvas {
    width: 100%;
    height: 100%;
    border: 1px solid var(--color-window-border, rgba(255,255,255,0.14));
    border-radius: var(--radius-ui, 8px);
    background: var(--color-window-bg, #20252b);
    display: block;
}

.pingpong-footer {
    display: flex;
    justify-content: space-between;
    gap: 10px;
    padding: 8px 10px 9px;
    flex-wrap: wrap;
    border-top: 1px solid var(--color-window-border, rgba(255,255,255,0.12));
    color: var(--color-text-muted, rgba(255,255,255,0.74));
    background: var(--color-primary-surface-alt, #27303a);
    font-size: 11px;
}
]]
end

return {
    title = "Ping Pong",
    icon = "🏓",
    width = 780,
    height = 520,
    getContent = PINGPONG.GetContent,
    getInitScript = PINGPONG.GetInitScript,
    getJavaScript = PINGPONG.GetJavaScript,
    getCSS = PINGPONG.GetCSS
}
