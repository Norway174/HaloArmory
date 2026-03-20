--[[
    File: os_shell.lua (NEW MODULAR VERSION)
    Purpose: WebOS Shell - Module aggregator
    
    This file loads all OS shell modules and combines them into a cohesive system.
    Previously this was 7000+ lines in one file. Now it's modular!
]]--

HALOARMORY.COMPUTER.INTERFACE.SHELL = HALOARMORY.COMPUTER.INTERFACE.SHELL or {}

local SHELL = HALOARMORY.COMPUTER.INTERFACE.SHELL
local HTML = HALOARMORY.COMPUTER.INTERFACE.HTML

local scriptPath = HALOARMORY.GetOwnScriptPath()

-- Load all modules in correct order
-- Foundation modules
local UTIL_JS = include(scriptPath .. "modules/os_utilities_js.lua")
local FILE_TYPE = include(scriptPath .. "modules/os_file_type_registry.lua")

-- File and UI management
local FILE_RENDERER = include(scriptPath .. "modules/os_file_item_renderer.lua")
local SELECTION = include(scriptPath .. "modules/os_selection_manager.lua")
local FILE_OPS = include(scriptPath .. "modules/os_file_operations.lua")
local DRAG_DROP = include(scriptPath .. "modules/os_drag_drop.lua")
local CONTEXT_MENU = include(scriptPath .. "modules/os_context_menu.lua")

-- Core shell
local BOOT = include(scriptPath .. "modules/os_boot_sequence.lua")
local CORE = include(scriptPath .. "modules/os_shell_core.lua")

-- Desktop background CSS generator
function SHELL.GetDesktopBackgroundCSS(background)
    background = background or { type = "color", value = "#1a1a1a" }
    
    if background.type == "color" then
        return "background-color: " .. (background.value or "#1a1a1a") .. ";"
    elseif background.type == "gradient" then
        local colors = background.colors or { "#1a1a1a", "#2d2d2d" }
        local direction = background.direction or "to bottom"
        return "background: linear-gradient(" .. direction .. ", " .. table.concat(colors, ", ") .. ");"
    elseif background.type == "url" then
        return "background-color: " .. (background.backgroundColor or "#111111") .. "; background-image: url('" .. (background.value or "") .. "'); background-size: " .. (background.size or "cover") .. "; background-position: center center; background-repeat: " .. (background["repeat"] or "no-repeat") .. ";"
    else
        return "background-color: #1a1a1a;"
    end
end

-- Generate desktop HTML
function SHELL.GetDesktopHTML(background)
    local bgStyle = SHELL.GetDesktopBackgroundCSS(background)
    
    return [[
<div id="os-boot-screen" class="os-boot-screen">
    <div class="os-boot-content">
        <div class="os-boot-logo">&gt;//HALOARMORY//OS™</div>
        <div class="os-boot-status" id="os-boot-status">Initializing system...</div>
        <div class="os-boot-progress">
            <div class="os-boot-progress-bar" id="os-boot-progress-bar"></div>
        </div>
    </div>
</div>
<div id="os-desktop" class="os-desktop" style="]] .. bgStyle .. [[; display: none;">
    <div id="os-desktop-icons" class="os-desktop-icons">
        <!-- Desktop icons will be populated here -->
    </div>
    <!-- Windows will be added here -->
</div>
]]
end

-- Generate taskbar HTML
function SHELL.GetTaskbarHTML()
    return [[
<div id="os-taskbar" class="os-taskbar">
    <button id="os-start-btn" class="os-start-button">
        <span class="os-start-icon">☰</span>
        <span class="os-start-text">START</span>
    </button>
    <div id="os-taskbar-programs" class="os-taskbar-programs">
        <!-- Running programs will appear here -->
    </div>
    <div class="os-taskbar-tray">
        <div id="os-clock" class="os-clock"></div>
    </div>
</div>
<div id="os-start-menu" class="os-start-menu">
    <div class="os-start-menu-header">
        <h2>Programs</h2>
    </div>
    <div class="os-start-menu-programs" id="os-start-menu-programs">
        <!-- Programs will be populated here -->
    </div>
    <div class="os-start-menu-footer">
        <button class="os-start-menu-item os-start-menu-logout">
            🚪 Logout
        </button>
    </div>
</div>
]]
end

-- Get combined JavaScript from all modules
function SHELL.GetJavaScript()
    local js = ""
    
    -- Add each module's JavaScript in correct order
    -- Foundation utilities
    js = js .. UTIL_JS.GetJavaScript() .. "\n\n"
    js = js .. FILE_TYPE.GetJavaScript() .. "\n\n"
    
    -- File and UI management (dependencies: each depends on previous ones)
    js = js .. FILE_RENDERER.GetJavaScript() .. "\n\n"
    js = js .. SELECTION.GetJavaScript() .. "\n\n"
    js = js .. FILE_OPS.GetJavaScript() .. "\n\n"
    js = js .. DRAG_DROP.GetJavaScript() .. "\n\n"
    js = js .. CONTEXT_MENU.GetJavaScript() .. "\n\n"
    
    -- Core shell (depends on all above)
    js = js .. BOOT.GetJavaScript() .. "\n\n"
    js = js .. CORE.GetJavaScript() .. "\n\n"
    
    -- Add initialization
    js = js .. [[
// ============================================================================
// INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', function() {
    // Initialize OS shell
    if (window.osShell) {
        osShell.init();
    }
});

window.handleFolderChange = function(folderPath) {
    if (!folderPath) {
        return;
    }

    if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
        window.fileBrowserApp.refreshPath('C:' + folderPath);
    }

    if ((folderPath === '/desktop/' || folderPath === '/desktop') &&
        window.osShell && window.osShell.loadDesktopIcons) {
        window.osShell.loadDesktopIcons(true);
    }

    if (window._saveDialogCurrentFolder) {
        var saveDialogPath = window._saveDialogCurrentFolder;
        var normalizedDialogPath = 'C:' + folderPath;

        if (!saveDialogPath.endsWith('/')) {
            saveDialogPath = saveDialogPath + '/';
        }
        if (!normalizedDialogPath.endsWith('/')) {
            normalizedDialogPath = normalizedDialogPath + '/';
        }

        if (saveDialogPath === normalizedDialogPath && window._saveDialogLoadFolder) {
            window._saveDialogLoadFolder(normalizedDialogPath);
        }
    }
};

window.osShellFilesSynced = function() {
    document.dispatchEvent(new CustomEvent('filesystemsynced'));
};

// Handle filesystem sync completion
document.addEventListener('filesystemsynced', function() {
    if (window.osBootSequence) {
        window.osBootSequence.markFilesSynced();
    }
});
]]
    
    return js
end

-- Get CSS
function SHELL.GetCSS()
    return [[
/* Boot Screen */
.os-boot-screen {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: #000000;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10000;
}

.os-boot-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: auto;
    max-width: 90vw;
    padding: 0 24px;
    margin: 0 auto;
    text-align: center;
    color: #ffffff;
}

.os-boot-logo {
    display: block;
    width: max-content;
    max-width: 100%;
    margin: 0 auto 40px;
    font-size: clamp(42px, 6vw, 72px);
    font-weight: bold;
    line-height: 1;
    white-space: nowrap;
    color: #4a9eff;
}

.os-boot-status {
    font-size: 16px;
    margin-bottom: 20px;
    color: #aaaaaa;
}

.os-boot-progress {
    width: min(420px, 100%);
    height: 20px;
    background: #333333;
    overflow: hidden;
    margin: 0 auto;
    border-radius: var(--radius-ui-small, 4px);
}

.os-boot-progress-bar {
    height: 100%;
    background: #4a9eff;
    width: 0%;
    transition: width 0.3s ease;
}

/* Desktop */
.os-desktop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 40px;
    overflow: hidden;
}

.os-desktop-icons {
    display: grid;
    grid-template-columns: repeat(auto-fill, 80px);
    grid-auto-flow: column;
    grid-template-rows: repeat(auto-fill, 100px);
    padding: 20px;
    gap: 20px;
    height: calc(100vh - 60px);
    align-content: start;
}

.os-desktop-icon {
    width: 80px;
    text-align: center;
    cursor: pointer;
    user-select: none;
}

.os-desktop-icon:hover {
    background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.3));
    border-radius: var(--radius-ui-small, 4px);
}

.os-desktop-icon-image {
    font-size: 48px;
    margin-bottom: 5px;
}

.os-desktop-icon-label {
    font-size: 12px;
    word-wrap: break-word;
    color: var(--color-icon-text, #ffffff);
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
}

.os-desktop-icon .os-item-label {
    color: var(--color-icon-text, #ffffff);
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
}

.os-desktop-icon:hover .os-desktop-icon-label {
    background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.3));
    border-radius: var(--radius-ui-small, 4px);
}

.os-desktop-icon:hover .os-item-label {
    /*background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.3));*/
    border-radius: var(--radius-ui-small, 4px);
}

/* Taskbar */
.os-taskbar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 40px;
    background: var(--color-taskbar-bg, #2d2d2d);
    border-top: 1px solid var(--color-taskbar-border, #444444);
    display: flex;
    align-items: center;
    padding: 0 5px;
    z-index: 9999;
}

.os-start-button {
    height: 32px;
    padding: 0 15px;
    background: var(--color-start-btn-bg, #3d3d3d);
    border: 1px solid var(--color-taskbar-border, #555555);
    color: var(--color-text-primary, #ffffff);
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    border-radius: var(--radius-ui-small, 4px);
}

.os-start-button:hover {
    background: var(--color-start-btn-hover, #4d4d4d);
}

.os-start-icon {
    font-size: 18px;
}

.os-taskbar-programs {
    flex: 1;
    display: flex;
    gap: 5px;
    padding: 0 10px;
    min-width: 0;
    overflow-x: auto;
    overflow-y: hidden;
}

.os-taskbar-program {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    min-width: 0;
    max-width: 220px;
    height: 30px;
    padding: 0 12px;
    background: var(--color-taskbar-item-bg, rgba(255, 255, 255, 0.08));
    border: 1px solid var(--color-taskbar-item-border, rgba(255, 255, 255, 0.12));
    border-radius: var(--radius-ui-small, 4px);
    color: var(--color-text-primary, #ffffff);
    cursor: pointer;
    flex: 0 0 auto;
}

.os-taskbar-program:hover {
    background: var(--color-taskbar-item-hover-bg, rgba(255, 255, 255, 0.14));
    border-color: var(--color-taskbar-item-hover-border, rgba(255, 255, 255, 0.2));
}

.os-taskbar-program.active {
    background: var(--color-icon-hover-bg, rgba(102, 166, 255, 0.28));
    border-color: var(--color-accent, rgba(102, 166, 255, 0.55));
}

.os-taskbar-program.minimized {
    opacity: 0.72;
}

.os-taskbar-program-icon {
    font-size: 15px;
    line-height: 1;
    flex: 0 0 auto;
}

.os-taskbar-program-label {
    font-size: 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
}

.os-taskbar-program.minimized .os-taskbar-program-icon,
.os-taskbar-program.minimized .os-taskbar-program-label {
    color: var(--color-text-secondary, rgba(255, 255, 255, 0.58));
}

.os-taskbar-program.active .os-taskbar-program-icon,
.os-taskbar-program.active .os-taskbar-program-label {
    color: var(--color-text-primary, #ffffff);
}

.os-taskbar-tray {
    display: flex;
    align-items: center;
    gap: 10px;
}

.os-clock {
    font-size: 13px;
    color: var(--color-text-primary, #ffffff);
    padding: 0 10px;
}

/* Start Menu */
.os-start-menu {
    position: fixed;
    bottom: 45px;
    left: 5px;
    width: 250px;
    background: var(--color-start-menu-bg, rgba(45, 45, 45, 0.98));
    border: 1px solid var(--color-taskbar-border, #555555);
    border-radius: var(--radius-ui-large, 10px);
    display: none;
    z-index: 10000;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
    padding: 8px 0;
}

.os-start-menu-header {
    padding: 12px 16px;
    border-bottom: 1px solid var(--color-shell-separator, #444444);
    margin-bottom: 4px;
}

.os-start-menu-header h2 {
    margin: 0;
    font-size: 15px;
    font-weight: 600;
    color: var(--color-text-primary, #ffffff);
}

.os-start-menu-programs {
    max-height: 400px;
    overflow-y: auto;
    padding: 4px 0;
}

.os-start-menu-item {
    width: 100%;
    padding: 8px 16px;
    background: transparent;
    border: none;
    color: var(--color-text-primary, #ffffff);
    text-align: left;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 12px;
    transition: background 0.15s ease;
}

.os-start-menu-item:hover {
    background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.2));
}

.os-start-menu-item-icon {
    font-size: 18px;
    width: 24px;
    text-align: center;
    flex-shrink: 0;
}

.os-start-menu-item-label {
    font-size: 13px;
    flex: 1;
}

.os-start-menu-separator {
    height: 1px;
    background: var(--color-shell-separator, #444444);
    margin: 8px 12px;
}

.os-start-menu-footer {
    border-top: 1px solid var(--color-shell-separator, #444444);
    margin-top: 4px;
    padding-top: 4px;
}

/* File Item Styles (Shared) */
.os-file-item {
    cursor: pointer;
    user-select: none;
    position: relative;
}

.os-item-icon {
    font-size: 48px;
    margin-bottom: 5px;
    text-align: center;
}

.os-item-label {
    font-size: 12px;
    word-wrap: break-word;
    text-align: center;
    color: var(--color-text-primary, #ffffff);
}

.os-file-item.os-item-renaming {
    z-index: 20;
}

.os-inline-rename-editor {
    display: flex;
    flex-direction: column;
    gap: 4px;
    margin-top: 4px;
    width: 100%;
}

/* Selection */
.os-item-selected {
    outline: 2px solid var(--color-accent, #4a9eff);
    outline-offset: 2px;
    background: var(--color-icon-hover-bg, rgba(74, 158, 255, 0.15));
    border-radius: var(--radius-ui-small, 4px);
}

.os-selection-marquee {
    position: fixed;
    display: none;
    pointer-events: none;
    z-index: 50000;
    border: 1px solid rgba(102, 166, 255, 0.85);
    background: var(--color-selection-bg, rgba(102, 166, 255, 0.18));
    border-radius: var(--radius-ui-small, 4px);
    box-shadow: inset 0 0 0 1px rgba(180, 215, 255, 0.16);
}

]] .. DRAG_DROP.GetCSS() .. [[


/* Rename Input */
.os-rename-input {
    width: 100%;
    padding: 2px 4px;
    background: var(--color-background-lighter, #4a4a4a);
    border: 1px solid var(--color-accent, #4a9eff);
    border-radius: var(--radius-ui-small, 4px);
    color: var(--color-text-primary, #ffffff);
    font-size: 12px;
    font-family: inherit;
    outline: none;
    text-align: center;
}

.os-rename-input.os-rename-input-invalid {
    border-color: #d32f2f;
    box-shadow: 0 0 0 2px rgba(211, 47, 47, 0.24);
}

.os-rename-input:focus {
    border-color: var(--color-primary-light, #0099ff);
    box-shadow: 0 0 0 2px rgba(74, 158, 255, 0.3);
}

.os-rename-input.os-rename-input-invalid:focus {
    border-color: #d32f2f;
    box-shadow: 0 0 0 2px rgba(211, 47, 47, 0.24);
}

.os-rename-tooltip {
    display: none;
    font-size: 11px;
    line-height: 1.25;
    color: #ff8a80;
    text-align: center;
}

.os-rename-tooltip.visible {
    display: block;
}

/* Context Menu */
.os-context-menu {
    position: fixed;
    min-width: 180px;
    background: var(--color-background-medium, #2d2d2d);
    border: 1px solid var(--color-border-medium, #444444);
    border-radius: var(--radius-ui, 6px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    padding: 4px 0;
    z-index: 60000;
}

.os-context-menu-item {
    padding: 8px 16px;
    cursor: pointer;
    color: var(--color-text-primary, #ffffff);
    font-size: 13px;
    white-space: nowrap;
    position: relative;
}

.os-context-menu-item:hover:not(.disabled) {
    background: var(--color-background-light, #3a3a3a);
}

.os-context-menu-item.disabled {
    opacity: 0.5;
    cursor: default;
    color: var(--color-text-disabled, #888888);
}

.os-context-menu-item.danger {
    color: var(--color-text-danger, #ff6b6b);
}

.os-context-menu-separator {
    height: 1px;
    background: var(--color-border-medium, #444444);
    margin: 4px 0;
}

.os-context-menu-item.has-submenu::after {
    content: '▶';
    position: absolute;
    right: 8px;
    font-size: 10px;
}

.os-context-submenu {
    position: absolute;
    left: 100%;
    top: -4px;
    min-width: 150px;
    background: var(--color-background-medium, #2d2d2d);
    border: 1px solid var(--color-border-medium, #444444);
    border-radius: var(--radius-ui, 6px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    padding: 4px 0;
    display: none;
    z-index: 60001;
}

.os-context-menu-item.has-submenu:hover .os-context-submenu {
    display: block;
}

]]
end

return SHELL

