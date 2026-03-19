-- Main HTML Index - Builds the complete WebOS interface
HALOARMORY.COMPUTER.INTERFACE = HALOARMORY.COMPUTER.INTERFACE or {}

local scriptPath = HALOARMORY.GetOwnScriptPath()

-- Load HTML builder modules
local HTML = include(scriptPath .. "html_builder.lua")
local CONSTANTS = include(scriptPath .. "modules/os_constants.lua")
local CLEANUP = include(scriptPath .. "modules/os_cleanup.lua")
local ERROR_HANDLER = include(scriptPath .. "modules/os_error_handler.lua")
local FILE_DIALOGS = include(scriptPath .. "modules/os_file_dialogs.lua")
local WINDOW = include(scriptPath .. "window_manager.lua")
local SHELL = include(scriptPath .. "os_shell.lua")
local PROGRAMS = include(scriptPath .. "programs/programs_registry.lua")

-- Load all programs
local Notes = include(scriptPath .. "programs/notes.lua")
local Paint = include(scriptPath .. "programs/paint.lua")
local Minesweeper = include(scriptPath .. "programs/minesweeper.lua")
local Email = include(scriptPath .. "programs/email.lua")
local Settings = include(scriptPath .. "programs/settings.lua")
local Calculator = include(scriptPath .. "programs/calculator.lua")
local FileBrowser = include(scriptPath .. "programs/filebrowser.lua")
local ExternalDrive = include(scriptPath .. "programs/external_drive.lua")

-- Register all programs
PROGRAMS.Register("notes", Notes)
PROGRAMS.Register("paint", Paint)
PROGRAMS.Register("minesweeper", Minesweeper)
PROGRAMS.Register("email", Email)
PROGRAMS.Register("settings", Settings)
PROGRAMS.Register("calculator", Calculator)
PROGRAMS.Register("filebrowser", FileBrowser)
PROGRAMS.Register("externaldrive", ExternalDrive)

-- Load filesystem bridge
-- Get parent directory (remove /html from path)
local fsScriptPath = HALOARMORY.GetOwnScriptPath()
local fsParentPath = string.gsub(fsScriptPath, "/html/$", "")
local FILESYSTEM = include(fsParentPath .. "/cl_filesystem_bridge.lua")

-- Create HTML builder
local builder = HTML.NewBuilder()

-- Add constants as CSS variables
builder:AddStyle(CONSTANTS.GetCSS())

-- Add global styles
builder:AddStyle([[
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

html, body {
    width: 100%;
    height: 100%;
    overflow: hidden;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    font-size: 13px;
    color: var(--color-text-primary, #ffffff);
    background: var(--color-desktop-bg, #1a1a1a);
}
]])

-- Add window styles
builder:AddStyle(WINDOW.GetCSS and WINDOW.GetCSS() or include(scriptPath .. "window_styles.lua").GetCSS())

-- Add shell styles
builder:AddStyle(SHELL.GetCSS())
builder:AddStyle(FILE_DIALOGS.GetCSS())

-- Add all program CSS
for id, program in pairs(PROGRAMS.GetAll()) do
    if program.getCSS then
        builder:AddStyle(program.getCSS())
    end
end

-- Load desktop background from localStorage (will be set by JavaScript)
local desktopBackground = { type = "color", value = "#1a1a1a" }

-- Add desktop and taskbar HTML
builder:Add(SHELL.GetDesktopHTML(desktopBackground))
builder:Add(SHELL.GetTaskbarHTML())

-- Add constants as JavaScript globals
builder:AddScript(CONSTANTS.GetJavaScript())

-- Add cleanup utilities
builder:AddScript(CLEANUP.GetJavaScript())

-- Add error handling
builder:AddScript(ERROR_HANDLER.GetJavaScript())
builder:AddScript(FILE_DIALOGS.GetJavaScript())

-- Add window manager JavaScript
builder:AddScript(WINDOW.GetJavaScript())

-- Add shell JavaScript
builder:AddScript(SHELL.GetJavaScript())

-- Add filesystem bridge JavaScript
builder:AddScript(FILESYSTEM.GetJavaScript())

-- Add shared config/theme helpers
builder:AddScript([[
window.osConfigManager = {
    defaults: {
        background: { type: 'color', value: '#1a1a1a' },
        primaryColor: '#3a3a3a',
        secondaryColor: '#4f5f78',
        highlightColor: '#4a9eff',
        textColor: '#ffffff',
        roundness: 0
    },

    cloneBackground: function(background) {
        if (!background || typeof background !== 'object') {
            return {
                type: 'color',
                value: this.defaults.background.value
            };
        }

        var cloned = {
            type: background.type || 'color'
        };

        if (cloned.type === 'gradient') {
            var colors = Array.isArray(background.colors) ? background.colors.slice(0, 2) : [];
            cloned.colors = [
                colors[0] || '#1a1a1a',
                colors[1] || '#2d2d2d'
            ];
            cloned.direction = background.direction || 'to bottom';
        } else if (cloned.type === 'url') {
            cloned.value = background.value || '';
            cloned.size = background.size || 'cover';
            cloned.repeat = background.repeat || 'no-repeat';
            cloned.backgroundColor = background.backgroundColor || '#111111';
        } else {
            cloned.value = background.value || this.defaults.background.value;
        }

        return cloned;
    },

    normalizeConfig: function(rawConfig) {
        var parseRoundness = function(value, fallback) {
            var parsed = parseInt(value, 10);
            if (isNaN(parsed)) {
                return fallback;
            }
            return Math.min(24, Math.max(0, parsed));
        };

        if (!rawConfig || typeof rawConfig !== 'object') {
            return {
                background: this.cloneBackground(this.defaults.background),
                primaryColor: this.defaults.primaryColor,
                secondaryColor: this.defaults.secondaryColor,
                highlightColor: this.defaults.highlightColor,
                textColor: this.defaults.textColor,
                roundness: this.defaults.roundness
            };
        }

        if (rawConfig.type) {
            return {
                background: this.cloneBackground(rawConfig),
                primaryColor: this.defaults.primaryColor,
                secondaryColor: this.defaults.secondaryColor,
                highlightColor: this.defaults.highlightColor,
                textColor: this.defaults.textColor,
                roundness: this.defaults.roundness
            };
        }

        var primaryColor = rawConfig.primaryColor || rawConfig.uiColor || rawConfig.windowColor || this.defaults.primaryColor;
        var secondaryColor = rawConfig.secondaryColor;
        if (!secondaryColor) {
            secondaryColor = window.osThemeManager
                ? window.osThemeManager.lighten(primaryColor, 0.18)
                : this.defaults.secondaryColor;
        }
        var highlightColor = rawConfig.highlightColor || rawConfig.accentColor || this.defaults.highlightColor;

        return {
            background: this.cloneBackground(rawConfig.background || this.defaults.background),
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            highlightColor: highlightColor,
            textColor: rawConfig.textColor || rawConfig.iconTextColor || this.defaults.textColor,
            roundness: parseRoundness(rawConfig.roundness, this.defaults.roundness)
        };
    },

    parseConfigContent: function(configContent) {
        if (!configContent) {
            return this.normalizeConfig(null);
        }

        try {
            return this.normalizeConfig(JSON.parse(configContent));
        } catch (e) {
            console.error('Error parsing config:', e);
            return this.normalizeConfig(null);
        }
    },

    serializeConfig: function(config) {
        return JSON.stringify(this.normalizeConfig(config));
    }
};

window.osThemeManager = {
    clamp: function(value, min, max) {
        return Math.min(max, Math.max(min, value));
    },

    sanitizeHex: function(color, fallback) {
        if (typeof color !== 'string') {
            return fallback;
        }

        var hex = color.trim();
        if (!/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(hex)) {
            return fallback;
        }

        if (hex.length === 4) {
            hex = '#' + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2) + hex.charAt(3) + hex.charAt(3);
        }

        return hex.toLowerCase();
    },

    hexToRgb: function(hex) {
        var sanitized = this.sanitizeHex(hex, '#000000');
        return {
            r: parseInt(sanitized.substr(1, 2), 16),
            g: parseInt(sanitized.substr(3, 2), 16),
            b: parseInt(sanitized.substr(5, 2), 16)
        };
    },

    rgbToHex: function(rgb) {
        var toHex = function(value) {
            var clamped = Math.round(Math.min(255, Math.max(0, value)));
            var hex = clamped.toString(16);
            return hex.length === 1 ? '0' + hex : hex;
        };

        return '#' + toHex(rgb.r) + toHex(rgb.g) + toHex(rgb.b);
    },

    mix: function(colorA, colorB, ratio) {
        var a = this.hexToRgb(colorA);
        var b = this.hexToRgb(colorB);
        var t = this.clamp(ratio, 0, 1);

        return this.rgbToHex({
            r: a.r + (b.r - a.r) * t,
            g: a.g + (b.g - a.g) * t,
            b: a.b + (b.b - a.b) * t
        });
    },

    lighten: function(color, amount) {
        return this.mix(color, '#ffffff', amount);
    },

    darken: function(color, amount) {
        return this.mix(color, '#000000', amount);
    },

    toRgba: function(color, alpha) {
        var rgb = this.hexToRgb(color);
        return 'rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', ' + alpha + ')';
    },

    rgbToHsl: function(rgb) {
        var r = rgb.r / 255;
        var g = rgb.g / 255;
        var b = rgb.b / 255;
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var h = 0;
        var s = 0;
        var l = (max + min) / 2;

        if (max !== min) {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

            switch (max) {
                case r:
                    h = (g - b) / d + (g < b ? 6 : 0);
                    break;
                case g:
                    h = (b - r) / d + 2;
                    break;
                default:
                    h = (r - g) / d + 4;
                    break;
            }

            h = h / 6;
        }

        return {
            h: h * 360,
            s: s * 100,
            l: l * 100
        };
    },

    hslToRgb: function(hsl) {
        var h = ((hsl.h % 360) + 360) % 360 / 360;
        var s = this.clamp(hsl.s, 0, 100) / 100;
        var l = this.clamp(hsl.l, 0, 100) / 100;

        if (s === 0) {
            var gray = Math.round(l * 255);
            return { r: gray, g: gray, b: gray };
        }

        var hueToRgb = function(p, q, t) {
            if (t < 0) t = t + 1;
            if (t > 1) t = t - 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };

        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;

        return {
            r: Math.round(hueToRgb(p, q, h + 1 / 3) * 255),
            g: Math.round(hueToRgb(p, q, h) * 255),
            b: Math.round(hueToRgb(p, q, h - 1 / 3) * 255)
        };
    },

    getBrightness: function(color) {
        var rgb = this.hexToRgb(color);
        return (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
    },

    adaptTextColor: function(baseColor, backgroundColor, options) {
        var base = this.rgbToHsl(this.hexToRgb(baseColor));
        var brightness = this.getBrightness(backgroundColor);
        var opts = options || {};
        var adjusted = {
            h: base.h,
            s: base.s,
            l: base.l
        };

        if (brightness < 138) {
            adjusted.s = this.clamp(base.s * 0.90 + 4, 10, 96);
            adjusted.l = this.clamp(Math.max(base.l, opts.darkMinLightness || 74), 62, 94);
        } else {
            adjusted.s = this.clamp(base.s * 0.94 + 2, 8, 92);
            adjusted.l = this.clamp(Math.min(base.l, opts.lightMaxLightness || 26), 10, 38);
        }

        return this.rgbToHex(this.hslToRgb(adjusted));
    },

    applyBackground: function(background) {
        var desktop = document.getElementById('os-desktop');
        if (!desktop) {
            return;
        }

        var bg = window.osConfigManager.normalizeConfig({ background: background }).background;
        var style = '';

        if (bg.type === 'color') {
            style = 'background-color: ' + (bg.value || '#1a1a1a') + ';';
        } else if (bg.type === 'gradient') {
            var colors = Array.isArray(bg.colors) ? bg.colors : ['#1a1a1a', '#2d2d2d'];
            var direction = bg.direction || 'to bottom';
            style = 'background: linear-gradient(' + direction + ', ' + colors[0] + ', ' + colors[1] + ');';
        } else if (bg.type === 'url') {
            style = 'background-color: ' + (bg.backgroundColor || '#111111') + '; ' +
                'background-image: url(' + (bg.value || '') + '); ' +
                'background-size: ' + (bg.size || 'cover') + '; ' +
                'background-position: center center; ' +
                'background-repeat: ' + (bg.repeat || 'no-repeat') + ';';
        } else {
            style = 'background-color: #1a1a1a;';
        }

        desktop.style.cssText = style;
    },

    applyInterfaceColors: function(config) {
        var normalized = window.osConfigManager.normalizeConfig(config);
        var root = document.documentElement;
        var primaryColor = this.sanitizeHex(normalized.primaryColor, '#3a3a3a');
        var secondaryColor = this.sanitizeHex(normalized.secondaryColor, '#4f5f78');
        var highlightColor = this.sanitizeHex(normalized.highlightColor, '#4a9eff');
        var textColor = this.sanitizeHex(normalized.textColor, '#ffffff');
        var roundness = this.clamp(parseInt(normalized.roundness, 10) || 0, 0, 24);
        var smallRadius = this.clamp(roundness - 2, 0, 24);
        var largeRadius = this.clamp(roundness + 4, 0, 32);
        var surface1 = this.mix(primaryColor, '#000000', 0.14);
        var surface2 = this.mix(primaryColor, secondaryColor, 0.22);
        var surface3 = this.mix(primaryColor, secondaryColor, 0.34);
        var primarySurfaceAlt = this.getBrightness(primaryColor) < 138
            ? this.lighten(primaryColor, 0.10)
            : this.darken(primaryColor, 0.10);
        var secondarySurface = this.mix(secondaryColor, primaryColor, 0.34);
        var secondarySurfaceAlt = this.mix(secondaryColor, primaryColor, 0.18);
        var border = this.lighten(this.mix(primaryColor, secondaryColor, 0.42), 0.10);
        var borderSoft = this.toRgba(this.lighten(secondaryColor, 0.12), 0.32);
        var accent = highlightColor;
        var accentHover = this.lighten(highlightColor, 0.14);
        var accentActive = this.darken(highlightColor, 0.08);
        var hoverBg = this.toRgba(highlightColor, 0.22);
        var buttonBg = this.mix(primaryColor, secondaryColor, 0.30);
        var buttonHoverBg = this.mix(primaryColor, secondaryColor, 0.42);
        var taskbarBg = this.mix(primaryColor, '#000000', 0.20);
        var startMenuBg = this.toRgba(this.mix(primaryColor, secondaryColor, 0.18), 0.98);
        var titlebarActiveTop = this.mix(primaryColor, highlightColor, 0.16);
        var titlebarActiveBottom = this.mix(primaryColor, secondaryColor, 0.26);
        var titlebarInactive = this.mix(primaryColor, '#000000', 0.10);
        var textPrimary = this.adaptTextColor(textColor, surface1, { darkMinLightness: 78, lightMaxLightness: 24 });
        var textSecondary = this.adaptTextColor(textColor, surface2, { darkMinLightness: 68, lightMaxLightness: 32 });
        var textMuted = this.mix(textSecondary, surface2, 0.30);
        var textOnPrimarySurface = this.adaptTextColor(textColor, primarySurfaceAlt, { darkMinLightness: 74, lightMaxLightness: 26 });
        var textOnAccent = this.adaptTextColor(textColor, accent, { darkMinLightness: 84, lightMaxLightness: 18 });
        var textOnButton = this.adaptTextColor(textColor, buttonBg, { darkMinLightness: 80, lightMaxLightness: 22 });

        root.style.setProperty('--color-primary', primaryColor);
        root.style.setProperty('--color-secondary', secondaryColor);
        root.style.setProperty('--color-highlight', highlightColor);
        root.style.setProperty('--color-primary-light', this.lighten(highlightColor, 0.08));
        root.style.setProperty('--color-surface-1', surface1);
        root.style.setProperty('--color-surface-2', surface2);
        root.style.setProperty('--color-surface-3', surface3);
        root.style.setProperty('--color-primary-surface-alt', primarySurfaceAlt);
        root.style.setProperty('--color-secondary-surface', secondarySurface);
        root.style.setProperty('--color-secondary-surface-alt', secondarySurfaceAlt);
        root.style.setProperty('--color-text-primary', textPrimary);
        root.style.setProperty('--color-text-secondary', textMuted);
        root.style.setProperty('--color-text-on-primary-surface', textOnPrimarySurface);
        root.style.setProperty('--color-text-on-accent', textOnAccent);
        root.style.setProperty('--color-text-on-button', textOnButton);
        root.style.setProperty('--color-window-bg', surface1);
        root.style.setProperty('--color-window-content-bg', surface2);
        root.style.setProperty('--color-window-border', border);
        root.style.setProperty('--color-titlebar-active', titlebarActiveTop);
        root.style.setProperty('--color-titlebar-active-bottom', titlebarActiveBottom);
        root.style.setProperty('--color-titlebar-inactive', titlebarInactive);
        root.style.setProperty('--color-accent', accent);
        root.style.setProperty('--color-accent-hover', accentHover);
        root.style.setProperty('--color-accent-active', accentActive);
        root.style.setProperty('--color-icon-text', textColor);
        root.style.setProperty('--color-icon-hover-bg', hoverBg);
        root.style.setProperty('--color-taskbar-bg', taskbarBg);
        root.style.setProperty('--color-taskbar-border', borderSoft);
        root.style.setProperty('--color-start-btn-bg', buttonBg);
        root.style.setProperty('--color-start-btn-hover', buttonHoverBg);
        root.style.setProperty('--color-start-menu-bg', startMenuBg);
        root.style.setProperty('--color-shell-separator', borderSoft);
        root.style.setProperty('--color-button-bg', buttonBg);
        root.style.setProperty('--color-button-hover-bg', buttonHoverBg);
        root.style.setProperty('--color-button-border', border);
        root.style.setProperty('--color-button-muted-bg', this.toRgba('#ffffff', 0.08));
        root.style.setProperty('--color-button-muted-border', this.toRgba('#ffffff', 0.16));
        root.style.setProperty('--color-taskbar-item-bg', this.toRgba('#ffffff', 0.08));
        root.style.setProperty('--color-taskbar-item-border', this.toRgba('#ffffff', 0.12));
        root.style.setProperty('--color-taskbar-item-hover-bg', this.toRgba('#ffffff', 0.14));
        root.style.setProperty('--color-taskbar-item-hover-border', this.toRgba('#ffffff', 0.20));
        root.style.setProperty('--color-selection-bg', hoverBg);
        root.style.setProperty('--radius-ui', roundness + 'px');
        root.style.setProperty('--radius-ui-small', smallRadius + 'px');
        root.style.setProperty('--radius-ui-large', largeRadius + 'px');
    },

    applyConfig: function(config) {
        var normalized = window.osConfigManager.normalizeConfig(config);
        this.applyBackground(normalized.background);
        this.applyInterfaceColors(normalized);
        window.currentOSConfig = normalized;
        return normalized;
    }
};
]])

-- Add all program JavaScript
for id, program in pairs(PROGRAMS.GetAll()) do
    if program.getJavaScript then
        builder:AddScript(program.getJavaScript())
    end
end

-- Add programs registry JavaScript
builder:AddScript(PROGRAMS.GetJavaScriptRegistry())

-- Add initialization script to load appearance config from config.dat
builder:AddScript([[
document.addEventListener('DOMContentLoaded', function() {
    function loadAppearanceConfig() {
        if (window.filesystem) {
            window.filesystem.readFile('C:/config.dat', function(configContent) {
                var config = window.osConfigManager
                    ? window.osConfigManager.parseConfigContent(configContent)
                    : {
                        background: { type: 'color', value: '#1a1a1a' },
                        primaryColor: '#3a3a3a',
                        secondaryColor: '#4f5f78',
                        highlightColor: '#4a9eff',
                        textColor: '#ffffff',
                        roundness: 6
                    };

                if (window.osThemeManager) {
                    window.osThemeManager.applyConfig(config);
                }
            });
        } else {
            setTimeout(loadAppearanceConfig, 200);
        }
    }

    setTimeout(loadAppearanceConfig, 500);
});
]])

-- Build and return the complete HTML
return builder:Build("HALO Computer OS")
