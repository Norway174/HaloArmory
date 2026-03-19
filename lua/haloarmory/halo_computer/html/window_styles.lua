-- Window Styles Module
local STYLES = {}

function STYLES.GetCSS()
    return [[
/* Window Styles */
.os-window {
    position: absolute;
    background: var(--color-window-bg, #2d2d2d);
    border: 1px solid var(--color-window-border, #444444);
    border-radius: var(--radius-ui, 6px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    display: flex;
    flex-direction: column;
    overflow: hidden;
    min-width: 300px;
    min-height: 200px;
}

.os-window-active {
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.7);
    border-color: var(--color-accent, #4a9eff);
}

.os-window:not(.os-window-active) {
    opacity: 0.95;
}

.os-window-titlebar {
    background: linear-gradient(180deg, var(--color-titlebar-active, #3a3a3a) 0%, var(--color-titlebar-active-bottom, var(--color-window-bg, #2d2d2d)) 100%);
    color: var(--color-text-primary, #ffffff);
    padding: 6px 8px;
    display: flex;
    align-items: center;
    cursor: move;
    user-select: none;
    border-bottom: 1px solid var(--color-window-border, #444444);
    height: 32px;
    box-sizing: border-box;
}

.os-window-icon {
    margin-right: 8px;
    font-size: 16px;
}

.os-window-title {
    flex: 1;
    font-size: 13px;
    font-weight: 500;
}

.os-window-controls {
    display: flex;
    gap: 2px;
}

.os-window-btn {
    background: transparent;
    border: none;
    color: var(--color-text-primary, #ffffff);
    width: 28px;
    height: 20px;
    cursor: pointer;
    font-size: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-ui-small, 4px);
    transition: background 0.15s;
}

.os-window-btn:hover {
    background: var(--color-taskbar-item-bg, rgba(255, 255, 255, 0.1));
}

.os-window-close:hover {
    background: #e74c3c;
}

.os-window-content {
    flex: 1;
    overflow: auto;
    background: var(--color-window-content-bg, #252525);
    padding: 0px;
    box-sizing: border-box;
    min-height: 0;
    min-width: 0;
    width: 100%;
    position: relative;
}

.os-window-resize-handle {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 16px;
    height: 16px;
    cursor: nwse-resize;
    background: linear-gradient(-45deg, transparent 40%, rgba(255,255,255,0.3) 40%, rgba(255,255,255,0.3) 45%, transparent 45%, transparent 55%, rgba(255,255,255,0.3) 55%, rgba(255,255,255,0.3) 60%, transparent 60%);
}

.os-window:not(.os-window-active) .os-window-titlebar {
    background: linear-gradient(180deg, var(--color-titlebar-inactive, #2d2d2d) 0%, var(--color-window-bg, #2d2d2d) 100%);
}
]]
end

return STYLES
