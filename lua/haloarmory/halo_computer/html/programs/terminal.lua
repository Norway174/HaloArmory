-- Terminal Program
local TERMINAL = {}

function TERMINAL.GetContent()
    return [[
<div class="program-terminal">
    <div id="terminal-output" class="terminal-output"></div>
    <div class="terminal-input-line">
        <span class="terminal-prompt">C:\&gt;</span>
        <input type="text" id="terminal-input" class="terminal-input" autocomplete="off">
    </div>
</div>
]]
end

function TERMINAL.GetInitScript()
    return [[
        terminalApp.init(windowId);
    ]]
end

function TERMINAL.GetJavaScript()
    return [[
var terminalApp = {
    output: null,
    input: null,
    history: [],
    historyIndex: -1,
    windowId: null,
    
    init: function(windowId) {
        this.windowId = windowId;
        this.output = document.getElementById('terminal-output');
        this.input = document.getElementById('terminal-input');
        
        if (!this.output || !this.input) return;
        
        this.print('HALO Computer Terminal v1.0');
        this.print('Type "help" for available commands.');
        this.print('');
        
        this.input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                terminalApp.executeCommand();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                terminalApp.navigateHistory(-1);
            } else if (e.key === 'ArrowDown') {
                e.preventDefault();
                terminalApp.navigateHistory(1);
            }
        });
        
        this.input.focus();
    },
    
    print: function(text, className) {
        var line = document.createElement('div');
        line.className = 'terminal-line' + (className ? ' ' + className : '');
        line.textContent = text;
        this.output.appendChild(line);
        this.output.scrollTop = this.output.scrollHeight;
    },
    
    executeCommand: function() {
        var command = this.input.value.trim();
        if (!command) return;
        
        this.print('C:\\&gt; ' + command);
        this.history.push(command);
        this.historyIndex = this.history.length;
        this.input.value = '';
        
        var parts = command.split(' ');
        var cmd = parts[0].toLowerCase();
        var args = parts.slice(1);
        
        switch(cmd) {
            case 'help':
                this.print('Available commands:');
                this.print('  help - Show this help message');
                this.print('  clear - Clear the terminal');
                this.print('  echo [text] - Print text');
                this.print('  ls [path] - List directory');
                this.print('  cd [path] - Change directory');
                this.print('  cat [file] - Read file');
                if (window.filesystem) {
                    this.print('  rm [path] - Delete file/directory');
                }
                break;
            case 'clear':
                this.output.innerHTML = '';
                break;
            case 'echo':
                this.print(args.join(' '));
                break;
            case 'ls':
                var path = args[0] || 'C:/';
                if (window.filesystem) {
                    window.filesystem.listDirectory(path, function(files) {
                        if (files && files.length > 0) {
                            files.forEach(function(file) {
                                var name = file.displayName || file.name || '[unnamed]';
                                if (file.type === 'directory') {
                                    name = name + '/';
                                }
                                terminalApp.print('  ' + name);
                            });
                        } else {
                            terminalApp.print('Directory is empty');
                        }
                    });
                } else {
                    this.print('Filesystem not available');
                }
                break;
            case 'cd':
                this.print('Directory change not implemented yet');
                break;
            case 'cat':
                if (args[0] && window.filesystem) {
                    window.filesystem.readFile(args[0], function(content) {
                        if (content !== null) {
                            terminalApp.print(content);
                        } else {
                            terminalApp.print('File not found: ' + args[0], 'error');
                        }
                    });
                } else {
                    this.print('Usage: cat [file]', 'error');
                }
                break;
            case 'mkdir':
                this.print('Directory creation is currently disabled', 'error');
                break;
            case 'rm':
                if (args[0] && window.filesystem) {
                    window.filesystem.deleteFile(args[0], function(success) {
                        terminalApp.print(success ? 'Deleted' : 'Failed to delete', success ? '' : 'error');
                    });
                } else {
                    this.print('Usage: rm [path]', 'error');
                }
                break;
            default:
                this.print('Command not found: ' + cmd, 'error');
                this.print('Type "help" for available commands.');
        }
    },
    
    navigateHistory: function(direction) {
        if (this.history.length === 0) return;
        
        this.historyIndex += direction;
        
        if (this.historyIndex < 0) {
            this.historyIndex = 0;
        } else if (this.historyIndex >= this.history.length) {
            this.historyIndex = this.history.length;
            this.input.value = '';
            return;
        }
        
        this.input.value = this.history[this.historyIndex];
    }
};
]]
end

function TERMINAL.GetCSS()
    return [[
.program-terminal {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--color-window-bg, #0c0c0c);
    color: var(--color-text-primary, #cccccc);
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 14px;
}

.terminal-output {
    flex: 1;
    padding: 8px;
    overflow-y: auto;
    background: linear-gradient(180deg, var(--color-window-bg, #101010), var(--color-surface-1, #0c0c0c));
}

.terminal-line {
    margin: 2px 0;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.terminal-line.error {
    color: #ff6b6b;
}

.terminal-input-line {
    display: flex;
    padding: 8px;
    border-top: 1px solid var(--color-window-border, #333);
    background: var(--color-primary-surface-alt, #1a1a1a);
    align-items: center;
}

.terminal-prompt {
    color: var(--color-accent, #00ff00);
    margin-right: 8px;
    user-select: none;
}

.terminal-input {
    flex: 1;
    background: transparent;
    border: none;
    color: var(--color-text-on-primary-surface, #cccccc);
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 14px;
    outline: none;
}

.terminal-input:focus {
    outline: none;
}
]]
end

return {
    title = "Terminal",
    icon = "💻",
    width = 700,
    height = 500,
    getContent = TERMINAL.GetContent,
    getInitScript = TERMINAL.GetInitScript,
    getJavaScript = TERMINAL.GetJavaScript,
    getCSS = TERMINAL.GetCSS
}

