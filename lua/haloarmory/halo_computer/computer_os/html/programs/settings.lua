-- Settings Program - Desktop and interface customization
local SETTINGS = {}

function SETTINGS.GetContent()
    return [[
<div class="program-settings settings-layout">
    <div class="settings-sidebar">
        <div class="settings-sidebar-header">
            <div class="settings-sidebar-title">Appearance</div>
            <div class="settings-sidebar-subtitle">Desktop, interface, presets</div>
        </div>
        <button type="button" id="settings-nav-background" class="settings-nav-btn settings-nav-btn-active" onclick="settingsApp.switchPanel('background')">
            <span class="settings-nav-label">Background</span>
            <span class="settings-nav-desc">Wallpaper and gradients</span>
        </button>
        <button type="button" id="settings-nav-interface" class="settings-nav-btn" onclick="settingsApp.switchPanel('interface')">
            <span class="settings-nav-label">Interface</span>
            <span class="settings-nav-desc">Windows and text styling</span>
        </button>
        <button type="button" id="settings-nav-presets" class="settings-nav-btn" onclick="settingsApp.switchPanel('presets')">
            <span class="settings-nav-label">Presets</span>
            <span class="settings-nav-desc">Save and load looks</span>
        </button>
    </div>

    <div class="settings-main">
        <div class="settings-main-scroll">
            <div id="settings-panel-background" class="settings-panel settings-panel-active">
                <div class="settings-section">
                    <h3>Desktop Background</h3>
                    <div class="settings-option">
                        <label>Background Type:</label>
                        <select id="bg-type" onchange="settingsApp.updateAppearancePreview()">
                            <option value="color">Solid Color</option>
                            <option value="gradient">Gradient</option>
                            <option value="url">Image URL</option>
                        </select>
                    </div>
                    <div id="bg-color-option" class="settings-option">
                        <label>Color:</label>
                        <div class="settings-color-card">
                            <div class="settings-color-input-row">
                                <input type="color" id="bg-color" value="#1a1a1a" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                            </div>
                            <div id="bg-color-value" class="settings-color-value">#1A1A1A</div>
                        </div>
                    </div>
                    <div id="bg-gradient-option" class="settings-option" style="display: none;">
                        <label>Gradient Colors:</label>
                        <div class="settings-gradient-grid">
                            <div class="settings-color-card">
                                <div class="settings-color-card-title">Start Color</div>
                                <div class="settings-color-input-row">
                                    <input type="color" id="bg-gradient1" value="#1a1a1a" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                </div>
                                <div id="bg-gradient1-value" class="settings-color-value">#1A1A1A</div>
                            </div>
                            <div class="settings-color-card">
                                <div class="settings-color-card-title">End Color</div>
                                <div class="settings-color-input-row">
                                    <input type="color" id="bg-gradient2" value="#2d2d2d" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                </div>
                                <div id="bg-gradient2-value" class="settings-color-value">#2D2D2D</div>
                            </div>
                        </div>
                        <div class="settings-gradient-presets">
                            <button type="button" class="settings-preset-btn" onclick="settingsApp.applyGradientPreset('#0f2027', '#2c5364')">Ocean</button>
                            <button type="button" class="settings-preset-btn" onclick="settingsApp.applyGradientPreset('#8e2de2', '#4a00e0')">Neon</button>
                            <button type="button" class="settings-preset-btn" onclick="settingsApp.applyGradientPreset('#f7971e', '#ffd200')">Amber</button>
                            <button type="button" class="settings-preset-btn" onclick="settingsApp.applyGradientPreset('#1d976c', '#93f9b9')">Mint</button>
                        </div>
                        <label>Direction:</label>
                        <select id="bg-direction" onchange="settingsApp.updateAppearancePreview()">
                            <option value="to bottom">Top to Bottom</option>
                            <option value="to right">Left to Right</option>
                            <option value="to bottom right">Diagonal</option>
                        </select>
                    </div>
                        <div id="bg-url-option" class="settings-option" style="display: none;">
                            <label>Image URL:</label>
                            <input type="text" id="bg-url" placeholder="https://..." onchange="settingsApp.updateAppearancePreview()" style="width: 100%; padding: 4px;">
                            <div class="settings-dual-grid settings-url-options">
                                <div class="settings-option">
                                    <label>Scaling Type:</label>
                                    <select id="bg-url-size" onchange="settingsApp.updateAppearancePreview()">
                                        <option value="cover">Cover</option>
                                        <option value="contain">Contain</option>
                                        <option value="100% 100%">Stretch</option>
                                        <option value="auto">Original Size</option>
                                    </select>
                                </div>
                                <div class="settings-option">
                                    <label>Repeating:</label>
                                    <select id="bg-url-repeat" onchange="settingsApp.updateAppearancePreview()">
                                        <option value="no-repeat">No Repeat</option>
                                        <option value="repeat">Repeat Both</option>
                                        <option value="repeat-x">Repeat X</option>
                                        <option value="repeat-y">Repeat Y</option>
                                    </select>
                                </div>
                            </div>
                            <div class="settings-option">
                                <label>Background Color:</label>
                                <div class="settings-color-card">
                                    <div class="settings-color-card-title">Image Backdrop</div>
                                    <div class="settings-color-input-row">
                                        <input type="color" id="bg-url-color" value="#111111" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                    </div>
                                    <div id="bg-url-color-value" class="settings-color-value">#111111</div>
                                </div>
                            </div>
                        </div>
                </div>
            </div>

            <div id="settings-panel-interface" class="settings-panel">
                <div class="settings-section">
                    <h3>Interface Colors</h3>
                    <div class="settings-interface-grid">
                        <div class="settings-subsection">
                            <h4>Primary + Secondary + Highlight</h4>
                            <div class="settings-option">
                                <label>Primary Color:</label>
                                <div class="settings-color-card">
                                    <div class="settings-color-card-title">Primary Color</div>
                                    <div class="settings-color-input-row">
                                        <input type="color" id="primary-color" value="#3a3a3a" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                    </div>
                                    <div id="primary-color-value" class="settings-color-value">#3A3A3A</div>
                                </div>
                            </div>
                            <div class="settings-option">
                                <label>Secondary Color:</label>
                                <div class="settings-color-card">
                                    <div class="settings-color-card-title">Secondary Color</div>
                                    <div class="settings-color-input-row">
                                        <input type="color" id="secondary-color" value="#4f5f78" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                    </div>
                                    <div id="secondary-color-value" class="settings-color-value">#4F5F78</div>
                                </div>
                            </div>
                            <div class="settings-option">
                                <label>Highlight Color:</label>
                                <div class="settings-color-card">
                                    <div class="settings-color-card-title">Highlight Color</div>
                                    <div class="settings-color-input-row">
                                        <input type="color" id="highlight-color" value="#4a9eff" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                    </div>
                                    <div id="highlight-color-value" class="settings-color-value">#4A9EFF</div>
                                </div>
                            </div>
                            <div class="settings-option">
                                <label>Roundness:</label>
                                <div class="settings-roundness-card">
                                    <div class="settings-roundness-inputs">
                                        <input type="range" id="ui-roundness-slider" min="0" max="24" step="1" value="6" oninput="settingsApp.syncRoundnessFromSlider()">
                                        <input type="number" id="ui-roundness-number" min="0" max="24" step="1" value="6" oninput="settingsApp.syncRoundnessFromNumber()">
                                    </div>
                                    <div class="settings-roundness-hint">Controls window corners, menus, buttons, and shared chrome.</div>
                                </div>
                            </div>
                        </div>
                        <div class="settings-subsection">
                            <h4>Text Color</h4>
                            <div class="settings-option">
                                <label>Text Color:</label>
                                <div class="settings-color-card">
                                    <div class="settings-color-card-title">Text Color</div>
                                    <div class="settings-color-input-row">
                                        <input type="color" id="text-color" value="#ffffff" oninput="settingsApp.updateAppearancePreview()" onchange="settingsApp.updateAppearancePreview()">
                                    </div>
                                    <div id="text-color-value" class="settings-color-value">#FFFFFF</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div id="settings-panel-presets" class="settings-panel">
                <div class="settings-section">
                    <h3>Presets</h3>
                    <div class="settings-helper-text">Presets are stored locally on this client only. They include the full Background and Interface appearance settings.</div>
                    <div class="settings-preset-save-row">
                        <input type="text" id="preset-name" class="settings-preset-name" placeholder="Preset name">
                        <button type="button" class="settings-primary-btn" onclick="settingsApp.saveCurrentPreset()">Save Current Preset</button>
                    </div>
                </div>
                <div class="settings-section">
                    <div class="settings-preset-list-header">
                        <h3>Saved Presets</h3>
                        <button type="button" class="settings-secondary-btn" onclick="settingsApp.refreshPresetList()">Refresh</button>
                    </div>
                    <div id="settings-preset-list" class="settings-preset-list">
                        <div class="settings-empty-state">Loading presets...</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="settings-footer">
            <button type="button" onclick="settingsApp.saveAppearance()" class="settings-primary-btn settings-save-btn">Save Appearance</button>
        </div>
    </div>

    <div id="settings-preset-load-modal" class="settings-modal-overlay" style="display: none;">
        <div class="settings-modal">
            <h3>Load Preset</h3>
            <div id="settings-preset-load-name" class="settings-modal-subtitle"></div>
            <label class="settings-checkbox-row">
                <input type="checkbox" id="settings-load-background" checked>
                <span>Background</span>
            </label>
            <label class="settings-checkbox-row">
                <input type="checkbox" id="settings-load-interface" checked>
                <span>Interface</span>
            </label>
            <div class="settings-checkbox-children">
                <label class="settings-checkbox-row settings-checkbox-row-child">
                    <input type="checkbox" id="settings-load-primary-color" checked>
                    <span>Primary Color</span>
                </label>
                <label class="settings-checkbox-row settings-checkbox-row-child">
                    <input type="checkbox" id="settings-load-secondary-color" checked>
                    <span>Secondary Color</span>
                </label>
                <label class="settings-checkbox-row settings-checkbox-row-child">
                    <input type="checkbox" id="settings-load-highlight-color" checked>
                    <span>Highlight Color</span>
                </label>
                <label class="settings-checkbox-row settings-checkbox-row-child">
                    <input type="checkbox" id="settings-load-roundness" checked>
                    <span>Roundness</span>
                </label>
                <label class="settings-checkbox-row settings-checkbox-row-child">
                    <input type="checkbox" id="settings-load-desktop-labels" checked>
                    <span>Text Color</span>
                </label>
            </div>
            <div class="settings-modal-actions">
                <button type="button" class="settings-secondary-btn" onclick="settingsApp.hidePresetLoadDialog()">Cancel</button>
                <button type="button" class="settings-primary-btn" onclick="settingsApp.confirmPresetLoad()">Load Selected</button>
            </div>
        </div>
    </div>
</div>
]]
end

function SETTINGS.GetInitScript()
    return [[
        settingsApp.init(windowId);
        
        if (window.osFileTypeRegistry) {
            window.osFileTypeRegistry.registerProgram('.config', 'settings');
        }
    ]]
end

function SETTINGS.GetJavaScript()
    return [[
var settingsApp = {
    windowId: null,
    pendingPresetLoad: null,
    presetCallbacks: {},
    presetRequestCounter: 0,

    init: function(windowId) {
        this.windowId = windowId;
        this.switchPanel('background');
        this.loadConfig();
        this.refreshPresetList();
        this.setupPresetLoadSelection();

        document.getElementById('bg-type').addEventListener('change', function() {
            settingsApp.updateBackgroundMode();
            settingsApp.updateAppearancePreview();
        });
    },

    getDefaultConfig: function() {
        if (window.osConfigManager && window.osConfigManager.normalizeConfig) {
            return window.osConfigManager.normalizeConfig(null);
        }

        return {
            background: { type: 'color', value: '#1a1a1a' },
            primaryColor: '#3a3a3a',
            secondaryColor: '#4f5f78',
            highlightColor: '#4a9eff',
            textColor: '#ffffff',
            roundness: 6
        };
    },

    switchPanel: function(panelId) {
        var panelIds = ['background', 'interface', 'presets'];

        panelIds.forEach(function(id) {
            var panel = document.getElementById('settings-panel-' + id);
            var nav = document.getElementById('settings-nav-' + id);
            var isActive = id === panelId;

            if (panel) {
                panel.classList.toggle('settings-panel-active', isActive);
            }

            if (nav) {
                nav.classList.toggle('settings-nav-btn-active', isActive);
            }
        });
    },

    syncColorControl: function(inputId, valueId) {
        var input = document.getElementById(inputId);
        var value = document.getElementById(valueId);

        if (!input) {
            return;
        }

        var color = input.value || '#1a1a1a';
        if (value) {
            value.textContent = String(color).toUpperCase();
        }
    },

    normalizeRoundness: function(value) {
        var parsed = parseInt(value, 10);
        if (isNaN(parsed)) {
            return 6;
        }
        return Math.min(24, Math.max(0, parsed));
    },

    syncRoundnessInputs: function(value) {
        var normalized = this.normalizeRoundness(value);
        var slider = document.getElementById('ui-roundness-slider');
        var number = document.getElementById('ui-roundness-number');

        if (slider) {
            slider.value = normalized;
        }
        if (number) {
            number.value = normalized;
        }

        return normalized;
    },

    syncRoundnessFromSlider: function() {
        var slider = document.getElementById('ui-roundness-slider');
        var value = this.syncRoundnessInputs(slider ? slider.value : 6);
        this.updateAppearancePreview();
        return value;
    },

    syncRoundnessFromNumber: function() {
        var number = document.getElementById('ui-roundness-number');
        var value = this.syncRoundnessInputs(number ? number.value : 6);
        this.updateAppearancePreview();
        return value;
    },

    updateBackgroundMode: function() {
        var type = document.getElementById('bg-type').value;
        document.getElementById('bg-color-option').style.display = type === 'color' ? 'block' : 'none';
        document.getElementById('bg-gradient-option').style.display = type === 'gradient' ? 'block' : 'none';
        document.getElementById('bg-url-option').style.display = type === 'url' ? 'block' : 'none';
    },

    applyGradientPreset: function(color1, color2) {
        document.getElementById('bg-type').value = 'gradient';
        document.getElementById('bg-gradient1').value = color1;
        document.getElementById('bg-gradient2').value = color2;
        this.updateBackgroundMode();
        this.updateAppearancePreview();
    },

    applyConfigToControls: function(config) {
        var normalized = window.osConfigManager && window.osConfigManager.normalizeConfig
            ? window.osConfigManager.normalizeConfig(config)
            : config;

        var background = normalized.background || { type: 'color', value: '#1a1a1a' };
        document.getElementById('bg-type').value = background.type || 'color';
        document.getElementById('bg-url').value = '';
        document.getElementById('bg-url-size').value = 'cover';
        document.getElementById('bg-url-repeat').value = 'no-repeat';
        document.getElementById('bg-url-color').value = '#111111';

        if (background.type === 'color') {
            document.getElementById('bg-color').value = background.value || '#1a1a1a';
        } else if (background.type === 'gradient') {
            var colors = Array.isArray(background.colors) ? background.colors : [];
            document.getElementById('bg-gradient1').value = colors[0] || '#1a1a1a';
            document.getElementById('bg-gradient2').value = colors[1] || '#2d2d2d';
            document.getElementById('bg-direction').value = background.direction || 'to bottom';
        } else if (background.type === 'url') {
            document.getElementById('bg-url').value = background.value || '';
            document.getElementById('bg-url-size').value = background.size || 'cover';
            document.getElementById('bg-url-repeat').value = background.repeat || 'no-repeat';
            document.getElementById('bg-url-color').value = background.backgroundColor || '#111111';
        }

        document.getElementById('primary-color').value = normalized.primaryColor || '#3a3a3a';
        document.getElementById('secondary-color').value = normalized.secondaryColor || '#4f5f78';
        document.getElementById('highlight-color').value = normalized.highlightColor || '#4a9eff';
        document.getElementById('text-color').value = normalized.textColor || normalized.iconTextColor || '#ffffff';
        this.syncRoundnessInputs(normalized.roundness == null ? 6 : normalized.roundness);

        this.updateBackgroundMode();
        this.updateAppearancePreview();
    },

    loadConfig: function() {
        var self = this;

        if (!window.filesystem) {
            self.applyConfigToControls(self.getDefaultConfig());
            return;
        }

        window.filesystem.readFile('C:/config.dat', function(configContent) {
            var config = window.osConfigManager && window.osConfigManager.parseConfigContent
                ? window.osConfigManager.parseConfigContent(configContent)
                : self.getDefaultConfig();

            self.applyConfigToControls(config);
        });
    },

    buildBackgroundFromControls: function() {
        var type = document.getElementById('bg-type').value;
        var background = { type: type };

        if (type === 'color') {
            background.value = document.getElementById('bg-color').value;
        } else if (type === 'gradient') {
            background.colors = [
                document.getElementById('bg-gradient1').value,
                document.getElementById('bg-gradient2').value
            ];
            background.direction = document.getElementById('bg-direction').value;
        } else if (type === 'url') {
            background.value = document.getElementById('bg-url').value;
            background.size = document.getElementById('bg-url-size').value;
            background.repeat = document.getElementById('bg-url-repeat').value;
            background.backgroundColor = document.getElementById('bg-url-color').value;
        }

        return background;
    },

    buildConfigFromControls: function() {
        var config = {
            background: this.buildBackgroundFromControls(),
            primaryColor: document.getElementById('primary-color').value,
            secondaryColor: document.getElementById('secondary-color').value,
            highlightColor: document.getElementById('highlight-color').value,
            textColor: document.getElementById('text-color').value,
            roundness: this.normalizeRoundness(document.getElementById('ui-roundness-number').value)
        };

        if (window.osConfigManager && window.osConfigManager.normalizeConfig) {
            return window.osConfigManager.normalizeConfig(config);
        }

        return config;
    },

    updateAppearancePreview: function() {
        this.syncColorControl('bg-color', 'bg-color-value');
        this.syncColorControl('bg-gradient1', 'bg-gradient1-value');
        this.syncColorControl('bg-gradient2', 'bg-gradient2-value');
        this.syncColorControl('bg-url-color', 'bg-url-color-value');
        this.syncColorControl('primary-color', 'primary-color-value');
        this.syncColorControl('secondary-color', 'secondary-color-value');
        this.syncColorControl('highlight-color', 'highlight-color-value');
        this.syncColorControl('text-color', 'text-color-value');
    },

    updateBackgroundPreview: function() {
        this.updateAppearancePreview();
    },

    persistConfig: function(config, successMessage) {
        var normalized = window.osConfigManager && window.osConfigManager.normalizeConfig
            ? window.osConfigManager.normalizeConfig(config)
            : config;
        var serialized = window.osConfigManager && window.osConfigManager.serializeConfig
            ? window.osConfigManager.serializeConfig(normalized)
            : JSON.stringify(normalized);

        if (!window.filesystem) {
            alert('Filesystem not available. Cannot save configuration.');
            return;
        }

        window.filesystem.writeFile('C:/config.dat', serialized, function(success) {
            if (success !== false) {
                if (window.osThemeManager) {
                    window.osThemeManager.applyConfig(normalized);
                }
                if (successMessage) {
                    alert(successMessage);
                }
            } else {
                alert('Error saving appearance configuration.');
            }
        });
    },

    saveAppearance: function() {
        this.persistConfig(this.buildConfigFromControls(), 'Appearance saved!');
    },

    saveBackground: function() {
        this.saveAppearance();
    },

    toLuaString: function(value) {
        var stringValue = value == null ? '' : String(value);
        return '\'' + stringValue
            .replace(/\\/g, '\\\\')
            .replace(/\r/g, '\\r')
            .replace(/\n/g, '\\n')
            .replace(/'/g, '\\\'') + '\'';
    },

    createPresetRequestId: function(prefix) {
        this.presetRequestCounter += 1;
        return prefix + '_' + Date.now() + '_' + this.presetRequestCounter;
    },

    handlePresetCallback: function(callbackId, payloadJson) {
        var payload = {};

        if (typeof payloadJson === 'string' && payloadJson.length > 0) {
            try {
                payload = JSON.parse(payloadJson);
            } catch (e) {
                payload = {
                    success: false,
                    message: 'Preset callback parse failed.'
                };
            }
        } else if (payloadJson && typeof payloadJson === 'object') {
            payload = payloadJson;
        }

        var callback = this.presetCallbacks[callbackId];
        if (callback) {
            delete this.presetCallbacks[callbackId];
            callback(payload);
        }
    },

    callPresetBridge: function(method, args, callback) {
        if (!window.console || !window.console.lua_exec) {
            if (callback) {
                callback({
                    success: false,
                    message: 'Preset bridge unavailable.'
                });
            }
            return;
        }

        var callbackId = this.createPresetRequestId(method.toLowerCase());
        if (callback) {
            this.presetCallbacks[callbackId] = callback;
            setTimeout(function() {
                if (settingsApp.presetCallbacks[callbackId]) {
                    delete settingsApp.presetCallbacks[callbackId];
                    callback({
                        success: false,
                        message: 'Preset request timed out.'
                    });
                }
            }, 5000);
        }

        var luaArgs = [this.toLuaString(callbackId)];
        (args || []).forEach(function(arg) {
            luaArgs.push(settingsApp.toLuaString(arg));
        });

        var luaCode = "if HALOARMORY and HALOARMORY.COMPUTER and HALOARMORY.COMPUTER.INTERFACE and HALOARMORY.COMPUTER.INTERFACE.PRESETS and HALOARMORY.COMPUTER.INTERFACE.PRESETS." +
            method + " then HALOARMORY.COMPUTER.INTERFACE.PRESETS." + method + "(" + luaArgs.join(", ") + ") end";

        window.console.lua_exec(luaCode);
    },

    refreshPresetList: function() {
        var self = this;
        var list = document.getElementById('settings-preset-list');
        if (list) {
            list.innerHTML = '<div class="settings-empty-state">Loading presets...</div>';
        }

        this.callPresetBridge('List', [], function(payload) {
            if (!payload || payload.success === false) {
                self.renderPresetList([]);
                return;
            }

            self.renderPresetList(payload.presets || []);
        });
    },

    renderPresetList: function(presets) {
        var list = document.getElementById('settings-preset-list');
        if (!list) {
            return;
        }

        list.innerHTML = '';

        if (!presets || presets.length === 0) {
            list.innerHTML = '<div class="settings-empty-state">No presets saved yet.</div>';
            return;
        }

        presets.forEach(function(preset) {
            var item = document.createElement('div');
            item.className = 'settings-preset-item';

            var info = document.createElement('div');
            info.className = 'settings-preset-item-info';

            var title = document.createElement('div');
            title.className = 'settings-preset-item-title';
            title.textContent = preset.name || preset.fileName || 'Preset';

            var meta = document.createElement('div');
            meta.className = 'settings-preset-item-meta';
            meta.textContent = preset.updatedAt ? ('Saved ' + preset.updatedAt) : (preset.fileName || '');

            info.appendChild(title);
            info.appendChild(meta);

            var actions = document.createElement('div');
            actions.className = 'settings-preset-item-actions';

            var loadBtn = document.createElement('button');
            loadBtn.type = 'button';
            loadBtn.className = 'settings-secondary-btn';
            loadBtn.textContent = 'Load';
            loadBtn.addEventListener('click', function() {
                settingsApp.requestPresetLoad(preset.fileName);
            });

            var deleteBtn = document.createElement('button');
            deleteBtn.type = 'button';
            deleteBtn.className = 'settings-danger-btn';
            deleteBtn.textContent = 'Delete';
            deleteBtn.addEventListener('click', function() {
                settingsApp.deletePreset(preset.fileName, preset.name || preset.fileName);
            });

            actions.appendChild(loadBtn);
            actions.appendChild(deleteBtn);
            item.appendChild(info);
            item.appendChild(actions);
            list.appendChild(item);
        });
    },

    saveCurrentPreset: function() {
        var input = document.getElementById('preset-name');
        var presetName = input ? input.value.trim() : '';

        if (!presetName) {
            alert('Enter a preset name first.');
            return;
        }

        var config = this.buildConfigFromControls();
        var serialized = window.osConfigManager && window.osConfigManager.serializeConfig
            ? window.osConfigManager.serializeConfig(config)
            : JSON.stringify(config);

        this.callPresetBridge('Save', [presetName, serialized], function(payload) {
            if (!payload || payload.success === false) {
                alert((payload && payload.message) || 'Failed to save preset.');
                return;
            }

            if (input) {
                input.value = '';
            }

            settingsApp.refreshPresetList();
            alert('Preset saved locally.');
        });
    },

    requestPresetLoad: function(fileName) {
        this.callPresetBridge('Load', [fileName], function(payload) {
            if (!payload || payload.success === false || !payload.preset) {
                alert((payload && payload.message) || 'Failed to load preset.');
                return;
            }

            settingsApp.showPresetLoadDialog(payload.preset);
        });
    },

    setupPresetLoadSelection: function() {
        var interfaceCheckbox = document.getElementById('settings-load-interface');
        var primaryColorCheckbox = document.getElementById('settings-load-primary-color');
        var secondaryColorCheckbox = document.getElementById('settings-load-secondary-color');
        var highlightColorCheckbox = document.getElementById('settings-load-highlight-color');
        var roundnessCheckbox = document.getElementById('settings-load-roundness');
        var desktopLabelsCheckbox = document.getElementById('settings-load-desktop-labels');

        if (!interfaceCheckbox || !primaryColorCheckbox || !secondaryColorCheckbox || !highlightColorCheckbox || !roundnessCheckbox || !desktopLabelsCheckbox) {
            return;
        }

        interfaceCheckbox.addEventListener('change', function() {
            var checked = interfaceCheckbox.checked;
            interfaceCheckbox.indeterminate = false;
            primaryColorCheckbox.checked = checked;
            secondaryColorCheckbox.checked = checked;
            highlightColorCheckbox.checked = checked;
            roundnessCheckbox.checked = checked;
            desktopLabelsCheckbox.checked = checked;
        });

        var syncParent = function() {
            var checkedCount = 0;
            if (primaryColorCheckbox.checked) {
                checkedCount = checkedCount + 1;
            }
            if (secondaryColorCheckbox.checked) {
                checkedCount = checkedCount + 1;
            }
            if (highlightColorCheckbox.checked) {
                checkedCount = checkedCount + 1;
            }
            if (roundnessCheckbox.checked) {
                checkedCount = checkedCount + 1;
            }
            if (desktopLabelsCheckbox.checked) {
                checkedCount = checkedCount + 1;
            }

            interfaceCheckbox.checked = checkedCount === 5;
            interfaceCheckbox.indeterminate = checkedCount > 0 && checkedCount < 5;
        };

        primaryColorCheckbox.addEventListener('change', syncParent);
        secondaryColorCheckbox.addEventListener('change', syncParent);
        highlightColorCheckbox.addEventListener('change', syncParent);
        roundnessCheckbox.addEventListener('change', syncParent);
        desktopLabelsCheckbox.addEventListener('change', syncParent);

        syncParent();
    },

    showPresetLoadDialog: function(preset) {
        this.pendingPresetLoad = preset;

        var modal = document.getElementById('settings-preset-load-modal');
        var nameEl = document.getElementById('settings-preset-load-name');
        var backgroundCheckbox = document.getElementById('settings-load-background');
        var interfaceCheckbox = document.getElementById('settings-load-interface');
        var primaryColorCheckbox = document.getElementById('settings-load-primary-color');
        var secondaryColorCheckbox = document.getElementById('settings-load-secondary-color');
        var highlightColorCheckbox = document.getElementById('settings-load-highlight-color');
        var roundnessCheckbox = document.getElementById('settings-load-roundness');
        var desktopLabelsCheckbox = document.getElementById('settings-load-desktop-labels');

        if (nameEl) {
            nameEl.textContent = preset.name || preset.fileName || 'Preset';
        }
        if (backgroundCheckbox) {
            backgroundCheckbox.checked = true;
        }
        if (primaryColorCheckbox) {
            primaryColorCheckbox.checked = true;
        }
        if (secondaryColorCheckbox) {
            secondaryColorCheckbox.checked = true;
        }
        if (highlightColorCheckbox) {
            highlightColorCheckbox.checked = true;
        }
        if (roundnessCheckbox) {
            roundnessCheckbox.checked = true;
        }
        if (desktopLabelsCheckbox) {
            desktopLabelsCheckbox.checked = true;
        }
        if (interfaceCheckbox) {
            interfaceCheckbox.checked = true;
            interfaceCheckbox.indeterminate = false;
        }
        if (modal) {
            modal.style.display = 'flex';
        }
    },

    hidePresetLoadDialog: function() {
        var modal = document.getElementById('settings-preset-load-modal');
        if (modal) {
            modal.style.display = 'none';
        }
        this.pendingPresetLoad = null;
    },

    confirmPresetLoad: function() {
        if (!this.pendingPresetLoad || !this.pendingPresetLoad.config) {
            this.hidePresetLoadDialog();
            return;
        }

        var shouldLoadBackground = document.getElementById('settings-load-background').checked;
        var shouldLoadPrimaryColor = document.getElementById('settings-load-primary-color').checked;
        var shouldLoadSecondaryColor = document.getElementById('settings-load-secondary-color').checked;
        var shouldLoadHighlightColor = document.getElementById('settings-load-highlight-color').checked;
        var shouldLoadRoundness = document.getElementById('settings-load-roundness').checked;
        var shouldLoadDesktopLabels = document.getElementById('settings-load-desktop-labels').checked;

        if (!shouldLoadBackground && !shouldLoadPrimaryColor && !shouldLoadSecondaryColor && !shouldLoadHighlightColor && !shouldLoadRoundness && !shouldLoadDesktopLabels) {
            alert('Select at least one section to load.');
            return;
        }

        var currentConfig = this.buildConfigFromControls();
        var presetConfig = window.osConfigManager && window.osConfigManager.normalizeConfig
            ? window.osConfigManager.normalizeConfig(this.pendingPresetLoad.config)
            : this.pendingPresetLoad.config;

        if (shouldLoadBackground) {
            currentConfig.background = presetConfig.background;
        }
        if (shouldLoadPrimaryColor) {
            currentConfig.primaryColor = presetConfig.primaryColor;
        }
        if (shouldLoadSecondaryColor) {
            currentConfig.secondaryColor = presetConfig.secondaryColor;
        }
        if (shouldLoadHighlightColor) {
            currentConfig.highlightColor = presetConfig.highlightColor;
        }
        if (shouldLoadRoundness) {
            currentConfig.roundness = presetConfig.roundness;
        }
        if (shouldLoadDesktopLabels) {
            currentConfig.textColor = presetConfig.textColor || presetConfig.iconTextColor;
        }

        this.applyConfigToControls(currentConfig);
        this.persistConfig(currentConfig, 'Preset loaded!');
        this.hidePresetLoadDialog();
    },

    deletePreset: function(fileName, displayName) {
        var confirmed = confirm('Delete preset "' + (displayName || fileName || 'Preset') + '"?');
        if (!confirmed) {
            return;
        }

        this.callPresetBridge('Delete', [fileName], function(payload) {
            if (!payload || payload.success === false) {
                alert((payload && payload.message) || 'Failed to delete preset.');
                return;
            }

            settingsApp.refreshPresetList();
        });
    }
};
]]
end

function SETTINGS.GetCSS()
    return [[
.program-settings {
    color: var(--color-text-primary, #fff);
    height: 100%;
    overflow: hidden;
}

.settings-layout {
    display: flex;
    min-height: 100%;
    background: var(--color-window-bg, #2d2d2d);
}

.settings-sidebar {
    width: 180px;
    flex-shrink: 0;
    padding: 18px 14px;
    border-right: 1px solid var(--color-window-border, rgba(255, 255, 255, 0.08));
    background: linear-gradient(180deg, var(--color-window-bg, #334055), var(--color-secondary-surface-alt, #2a3446));
}

.settings-sidebar-header {
    margin-bottom: 18px;
}

.settings-sidebar-title {
    font-size: 18px;
    font-weight: 700;
    color: var(--color-text-primary, #ffffff);
}

.settings-sidebar-subtitle {
    margin-top: 4px;
    font-size: 12px;
    color: var(--color-text-secondary, #aeb5c1);
}

.settings-nav-btn {
    width: 100%;
    margin-bottom: 8px;
    padding: 12px 12px;
    border: 1px solid var(--color-window-border, rgba(255, 255, 255, 0.08));
    border-radius: var(--radius-ui-large, 10px);
    background: rgba(255, 255, 255, 0.02);
    color: var(--color-text-primary, #d7dce5);
    text-align: left;
    cursor: pointer;
    transition: background 0.15s ease, border-color 0.15s ease, transform 0.15s ease;
}

.settings-nav-btn:hover {
    background: var(--color-taskbar-item-hover-bg, rgba(255, 255, 255, 0.06));
    border-color: var(--color-accent, rgba(255, 255, 255, 0.14));
    transform: translateX(2px);
}

.settings-nav-btn-active {
    background: linear-gradient(180deg, var(--color-icon-hover-bg, rgba(74, 158, 255, 0.28)), var(--color-button-bg, rgba(74, 158, 255, 0.14)));
    border-color: var(--color-accent, rgba(115, 184, 255, 0.55));
    color: var(--color-text-primary, #ffffff);
}

.settings-nav-label {
    display: block;
    font-size: 13px;
    font-weight: 700;
}

.settings-nav-desc {
    display: block;
    margin-top: 4px;
    font-size: 11px;
    color: var(--color-text-secondary, #aab4c3);
}

.settings-main {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
}

.settings-main-scroll {
    flex: 1;
    overflow-y: auto;
    padding: 18px;
    background: linear-gradient(180deg, var(--color-window-bg, #232323), var(--color-surface-1, #202020));
}

.settings-panel {
    display: none;
}

.settings-panel-active {
    display: block;
}

.settings-section {
    margin-bottom: 24px;
}

.settings-section h3 {
    margin-bottom: 14px;
    color: var(--color-text-primary, #fff);
    font-size: 17px;
}

.settings-option {
    margin-bottom: 12px;
}

.settings-option label {
    display: block;
    margin-bottom: 4px;
    color: var(--color-text-secondary, #ccc);
    font-size: 13px;
}

.settings-helper-text {
    margin-bottom: 14px;
    color: var(--color-text-secondary, #b8c0ce);
    font-size: 12px;
    line-height: 1.5;
}

.settings-option select,
.settings-option input[type="text"],
.settings-preset-name {
    width: 100%;
    padding: 8px 10px;
    background: var(--color-secondary-surface-alt, #303030);
    border: 1px solid var(--color-window-border, #565656);
    color: var(--color-text-primary, #fff);
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
}

.settings-option input[type="color"] {
    width: 72px;
    height: 44px;
    padding: 0;
    border: 1px solid var(--color-window-border, #555);
    border-radius: var(--radius-ui-small, 4px);
    background: transparent;
    cursor: pointer;
}

.settings-color-card {
    padding: 10px;
    border: 1px solid var(--color-window-border, #4c4c4c);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-window-bg, #334055);
}

.settings-color-card-title {
    margin-bottom: 8px;
    color: var(--color-text-primary, #d8d8d8);
    font-size: 12px;
    font-weight: bold;
    letter-spacing: 0.04em;
    text-transform: uppercase;
}

.settings-color-input-row {
    display: flex;
    align-items: center;
}

.settings-color-value {
    margin-top: 8px;
    color: var(--color-accent, #9fd6ff);
    font-size: 12px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

.settings-gradient-grid,
.settings-dual-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
}

.settings-interface-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
}

.settings-subsection {
    padding: 14px;
    border: 1px solid var(--color-window-border, rgba(255, 255, 255, 0.08));
    border-radius: var(--radius-ui-large, 10px);
    background: var(--color-window-bg, #334055);
}

.settings-subsection h4 {
    margin-bottom: 12px;
    color: var(--color-text-primary, #eef3fa);
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 0.03em;
    text-transform: uppercase;
}

.settings-gradient-grid {
    margin-bottom: 10px;
}

.settings-gradient-presets {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 12px;
}

.settings-preset-btn,
.settings-primary-btn,
.settings-secondary-btn,
.settings-danger-btn {
    padding: 8px 12px;
    border-radius: var(--radius-ui, 6px);
    font-size: 12px;
    cursor: pointer;
    transition: background 0.15s ease, border-color 0.15s ease;
}

.settings-roundness-card {
    padding: 12px;
    border: 1px solid #4c4c4c;
    border-radius: var(--radius-ui, 6px);
    background: var(--color-window-bg, #334055);
}

.settings-roundness-inputs {
    display: flex;
    align-items: center;
    gap: 10px;
}

#ui-roundness-slider {
    flex: 1;
}

#ui-roundness-number {
    width: 78px;
    padding: 8px 10px;
    background: var(--color-secondary-surface-alt, #303030);
    border: 1px solid var(--color-window-border, #565656);
    color: var(--color-text-primary, #fff);
    border-radius: var(--radius-ui-small, 4px);
    font-size: 12px;
}

.settings-roundness-hint {
    margin-top: 10px;
    color: #b9c2cf;
    font-size: 11px;
    line-height: 1.45;
}

.settings-preset-btn,
.settings-secondary-btn {
    border: 1px solid var(--color-window-border, #5f5f5f);
    background: var(--color-button-muted-bg, #2f2f2f);
    color: var(--color-text-on-button, #e8e8e8);
}

.settings-preset-btn:hover,
.settings-secondary-btn:hover {
    background: var(--color-button-hover-bg, #3d3d3d);
    border-color: var(--color-accent, #7b7b7b);
}

.settings-primary-btn {
    border: 1px solid var(--color-accent, #4f8fd1);
    background: var(--color-button-bg, #2f7fd1);
    color: var(--color-text-on-button, #ffffff);
}

.settings-primary-btn:hover {
    background: var(--color-button-hover-bg, #3d8ce0);
    border-color: var(--color-accent-hover, #67a7e6);
}

.settings-danger-btn {
    border: 1px solid #8b4040;
    background: #6a2a2a;
    color: var(--color-text-on-button, #ffffff);
}

.settings-danger-btn:hover {
    background: #843636;
    border-color: #a34d4d;
}

.settings-preset-save-row {
    display: flex;
    gap: 10px;
    align-items: center;
}

.settings-preset-name {
    flex: 1;
}

.settings-preset-list-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 12px;
}

.settings-preset-list-header h3 {
    margin: 0;
}

.settings-preset-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.settings-preset-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 12px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: var(--radius-ui, 6px);
    background: var(--color-window-bg, #334055);
}

.settings-preset-item-info {
    min-width: 0;
}

.settings-preset-item-title {
    color: var(--color-text-primary, #ffffff);
    font-size: 13px;
    font-weight: 700;
}

.settings-preset-item-meta {
    margin-top: 4px;
    color: var(--color-text-secondary, #b2bccb);
    font-size: 11px;
}

.settings-preset-item-actions {
    display: flex;
    gap: 8px;
    flex-shrink: 0;
}

.settings-empty-state {
    padding: 18px 14px;
    border: 1px dashed rgba(255, 255, 255, 0.14);
    border-radius: var(--radius-ui, 6px);
    color: var(--color-text-secondary, #b4bcc8);
    font-size: 12px;
    text-align: center;
}

.settings-footer {
    padding: 14px 18px;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
    background: linear-gradient(180deg, var(--color-window-bg, rgba(32, 32, 32, 0.94)), var(--color-surface-2, rgba(24, 24, 24, 0.98)));
}

.settings-save-btn {
    min-width: 150px;
}

.settings-modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.72);
    z-index: 20050;
    display: none;
    align-items: center;
    justify-content: center;
}

.settings-modal {
    width: 360px;
    max-width: calc(100vw - 40px);
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.10);
    border-radius: var(--radius-ui-large, 10px);
    background: linear-gradient(180deg, rgba(53, 53, 53, 0.96), rgba(33, 33, 33, 0.98));
    box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
}

.settings-modal h3 {
    margin-bottom: 8px;
    font-size: 18px;
}

.settings-modal-subtitle {
    margin-bottom: 14px;
    color: #b4becd;
    font-size: 12px;
}

.settings-checkbox-row {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 10px;
    color: #edf1f8;
    font-size: 13px;
}

.settings-checkbox-children {
    margin: -2px 0 6px 26px;
    padding-left: 12px;
    border-left: 1px solid rgba(255, 255, 255, 0.10);
}

.settings-checkbox-row-child {
    color: #cfd8e6;
    font-size: 12px;
}

.settings-checkbox-row input {
    width: 16px;
    height: 16px;
}

.settings-modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 16px;
}
]]
end

return {
    title = "Settings",
    icon = utf8.char(0x2699, 0xFE0F),
    width = 720,
    height = 520,
    getContent = SETTINGS.GetContent,
    getInitScript = SETTINGS.GetInitScript,
    getJavaScript = SETTINGS.GetJavaScript,
    getCSS = SETTINGS.GetCSS
}
