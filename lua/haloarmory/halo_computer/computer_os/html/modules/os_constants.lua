-- WebOS Constants and Configuration
-- Centralized location for all magic numbers, timeouts, and system constants

local CONSTANTS = {}

-- ============================================================================
-- TIMING CONSTANTS
-- ============================================================================

-- Boot sequence timing
CONSTANTS.BOOT_INTERVAL_MS = 800           -- Time between boot steps
CONSTANTS.BOOT_READY_DELAY_MS = 500        -- Delay before showing desktop
CONSTANTS.BOOT_FADE_DURATION_MS = 500      -- Boot screen fade out duration

-- Filesystem timing
CONSTANTS.FS_CALLBACK_TIMEOUT_MS = 5000    -- Filesystem operation timeout
CONSTANTS.FS_RETRY_DELAY_MS = 200          -- Retry delay for filesystem
CONSTANTS.FS_SYNC_CHECK_INTERVAL_MS = 100  -- Check interval for filesystem sync

-- Window management timing
CONSTANTS.WINDOW_RESIZE_DEBOUNCE_MS = 50   -- Debounce for window resize
CONSTANTS.WINDOW_MIN_RESTORE_DELAY_MS = 100 -- Delay for minimize/restore
CONSTANTS.WINDOW_FORCE_REFLOW_MS = 100     -- Force reflow timeout

-- UI timing
CONSTANTS.CLOCK_UPDATE_INTERVAL_MS = 1000  -- Clock update frequency
CONSTANTS.TOOLTIP_DELAY_MS = 500           -- Tooltip show delay
CONSTANTS.ANIMATION_DURATION_MS = 300      -- Standard animation duration
CONSTANTS.TIMEOUT_DEBOUNCE = 300           -- Debounce timeout for UI actions
CONSTANTS.TIMEOUT_INSTANT = 10             -- Instant timeout for immediate actions
CONSTANTS.TIMEOUT_NAVIGATION = 100         -- Navigation delay timeout
CONSTANTS.TIMEOUT_FALLBACK = 1000          -- Fallback timeout for operations
CONSTANTS.TIMEOUT_RETRY = 500              -- Retry timeout for failed operations
CONSTANTS.TIMEOUT_LONG = 2000              -- Long timeout for slow operations

-- ============================================================================
-- SIZE CONSTANTS
-- ============================================================================

-- Window sizes
CONSTANTS.WINDOW_MIN_WIDTH = 300
CONSTANTS.WINDOW_MIN_HEIGHT = 200
CONSTANTS.WINDOW_DEFAULT_WIDTH = 600
CONSTANTS.WINDOW_DEFAULT_HEIGHT = 400
CONSTANTS.WINDOW_RESIZE_HANDLE_SIZE = 10

-- Icon sizes
CONSTANTS.DESKTOP_ICON_SIZE = 64
CONSTANTS.DESKTOP_ICON_SPACING = 20
CONSTANTS.TASKBAR_ICON_SIZE = 32

-- Taskbar
CONSTANTS.TASKBAR_HEIGHT = 40

-- ============================================================================
-- Z-INDEX CONSTANTS
-- ============================================================================

CONSTANTS.Z_INDEX_DESKTOP = 1
CONSTANTS.Z_INDEX_WINDOW_BASE = 100
CONSTANTS.Z_INDEX_WINDOW_MAX = 10000
CONSTANTS.Z_INDEX_CONTEXT_MENU = 10001
CONSTANTS.Z_INDEX_DIALOG = 10002
CONSTANTS.Z_INDEX_TASKBAR = 10003

-- ============================================================================
-- COLOR CONSTANTS
-- ============================================================================

-- Desktop
CONSTANTS.COLOR_DESKTOP_DEFAULT = "#1a1a1a"

-- Window colors
CONSTANTS.COLOR_WINDOW_BG = "#2d2d2d"
CONSTANTS.COLOR_WINDOW_BORDER = "#444444"
CONSTANTS.COLOR_TITLEBAR_ACTIVE = "#3d3d3d"
CONSTANTS.COLOR_TITLEBAR_INACTIVE = "#2d2d2d"

-- Text colors
CONSTANTS.COLOR_TEXT_PRIMARY = "#ffffff"
CONSTANTS.COLOR_TEXT_SECONDARY = "#aaaaaa"
CONSTANTS.COLOR_TEXT_DISABLED = "#666666"

-- Accent colors
CONSTANTS.COLOR_ACCENT = "#4a9eff"
CONSTANTS.COLOR_ACCENT_HOVER = "#5aaeff"
CONSTANTS.COLOR_ACCENT_ACTIVE = "#3a8eef"

-- Status colors
CONSTANTS.COLOR_SUCCESS = "#4caf50"
CONSTANTS.COLOR_ERROR = "#f44336"
CONSTANTS.COLOR_WARNING = "#ff9800"

-- ============================================================================
-- FILESYSTEM CONSTANTS
-- ============================================================================

-- Drive names
CONSTANTS.DRIVE_C = "C"
CONSTANTS.DRIVE_EXTERNAL = "ExternalDrive"

-- File extensions
CONSTANTS.EXT_TEXT = ".txt"
CONSTANTS.EXT_SHORTCUT = ".shortcut.dat"
CONSTANTS.EXT_CONFIG = ".dat"

-- Protected files/folders
CONSTANTS.PROTECTED_FILES = {
    "config.dat"
}

-- Default paths
CONSTANTS.PATH_DESKTOP = "C:/desktop/"
CONSTANTS.PATH_CONFIG = "C:/config.dat"  -- Config is in root

-- ============================================================================
-- PROGRAM CONSTANTS
-- ============================================================================

-- Program IDs
CONSTANTS.PROGRAM_FILE_BROWSER = "filebrowser"
CONSTANTS.PROGRAM_NOTES = "notes"
CONSTANTS.PROGRAM_SETTINGS = "settings"
CONSTANTS.PROGRAM_EMAIL = "email"
CONSTANTS.PROGRAM_TERMINAL = "terminal"
CONSTANTS.PROGRAM_PAINT = "paint"
CONSTANTS.PROGRAM_CALCULATOR = "calculator"
CONSTANTS.PROGRAM_MINESWEEPER = "minesweeper"

-- ============================================================================
-- CONTEXT MENU CONSTANTS
-- ============================================================================

-- Context menu actions
CONSTANTS.ACTION_OPEN = "open"
CONSTANTS.ACTION_EDIT = "edit"
CONSTANTS.ACTION_RENAME = "rename"
CONSTANTS.ACTION_COPY = "copy"
CONSTANTS.ACTION_CUT = "cut"
CONSTANTS.ACTION_PASTE = "paste"
CONSTANTS.ACTION_DELETE = "delete"
CONSTANTS.ACTION_NEW_FILE = "new_file"
CONSTANTS.ACTION_NEW_FOLDER = "new_folder"
CONSTANTS.ACTION_PROPERTIES = "properties"

-- ============================================================================
-- FILE TYPE CONSTANTS
-- ============================================================================

CONSTANTS.FILE_TYPE_TEXT = "text"
CONSTANTS.FILE_TYPE_SHORTCUT = "shortcut"
CONSTANTS.FILE_TYPE_CONFIG = "config"
CONSTANTS.FILE_TYPE_DIRECTORY = "directory"
CONSTANTS.FILE_TYPE_DATA = "data"
CONSTANTS.FILE_TYPE_UNKNOWN = "unknown"

-- ============================================================================
-- NETWORK CONSTANTS (from sh_filesystem_network.lua)
-- ============================================================================

CONSTANTS.ACTION_SAVE_FILE = 1
CONSTANTS.ACTION_READ_FILE = 2
CONSTANTS.ACTION_LIST_DIR = 3
CONSTANTS.ACTION_CREATE_DIR = 4
CONSTANTS.ACTION_DELETE_FILE = 5
CONSTANTS.ACTION_REQUEST_PC_FILES = 6
CONSTANTS.ACTION_SYNC_PC_FILES = 7
CONSTANTS.ACTION_FILES_CHANGED = 8

-- ============================================================================
-- DIALOG TYPES
-- ============================================================================

CONSTANTS.DIALOG_CONFIRM = "confirm"
CONSTANTS.DIALOG_ALERT = "alert"
CONSTANTS.DIALOG_PROMPT = "prompt"
CONSTANTS.DIALOG_SAVE = "save"
CONSTANTS.DIALOG_OPEN = "open"

-- ============================================================================
-- LIMITS
-- ============================================================================

CONSTANTS.MAX_FILENAME_LENGTH = 64
CONSTANTS.MAX_PATH_DEPTH = 10
CONSTANTS.MAX_FILE_SIZE = 1024 * 1024  -- 1MB
CONSTANTS.MAX_DIRECTORY_ITEMS = 1000

-- ============================================================================
-- DEBUG
-- ============================================================================

CONSTANTS.DEBUG_ENABLED = false  -- Set to true to enable debug logging
CONSTANTS.VERBOSE_LOGGING = false  -- Set to true for verbose logs

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get CSS function to inject constants into stylesheets
function CONSTANTS.GetCSS()
    return string.format([[
:root {
    --taskbar-height: %dpx;
    --desktop-icon-size: %dpx;
    --window-min-width: %dpx;
    --window-min-height: %dpx;
    --radius-ui: 6px;
    --radius-ui-small: 4px;
    --radius-ui-large: 10px;
    
    --color-desktop-bg: %s;
    --color-window-bg: %s;
    --color-window-border: %s;
    --color-titlebar-active: %s;
    --color-titlebar-inactive: %s;
    
    --color-text-primary: %s;
    --color-text-secondary: %s;
    --color-text-disabled: %s;
    
    --color-accent: %s;
    --color-accent-hover: %s;
    --color-accent-active: %s;
    
    --color-success: %s;
    --color-error: %s;
    --color-warning: %s;
    
    --animation-duration: %dms;
}
]], 
        CONSTANTS.TASKBAR_HEIGHT,
        CONSTANTS.DESKTOP_ICON_SIZE,
        CONSTANTS.WINDOW_MIN_WIDTH,
        CONSTANTS.WINDOW_MIN_HEIGHT,
        
        CONSTANTS.COLOR_DESKTOP_DEFAULT,
        CONSTANTS.COLOR_WINDOW_BG,
        CONSTANTS.COLOR_WINDOW_BORDER,
        CONSTANTS.COLOR_TITLEBAR_ACTIVE,
        CONSTANTS.COLOR_TITLEBAR_INACTIVE,
        
        CONSTANTS.COLOR_TEXT_PRIMARY,
        CONSTANTS.COLOR_TEXT_SECONDARY,
        CONSTANTS.COLOR_TEXT_DISABLED,
        
        CONSTANTS.COLOR_ACCENT,
        CONSTANTS.COLOR_ACCENT_HOVER,
        CONSTANTS.COLOR_ACCENT_ACTIVE,
        
        CONSTANTS.COLOR_SUCCESS,
        CONSTANTS.COLOR_ERROR,
        CONSTANTS.COLOR_WARNING,
        
        CONSTANTS.ANIMATION_DURATION_MS
    )
end

-- Get JavaScript function to inject constants into JavaScript
function CONSTANTS.GetJavaScript()
    return string.format([[
// WebOS Constants (auto-generated from os_constants.lua)
window.OS_CONSTANTS = {
    // Timing
    BOOT_INTERVAL_MS: %d,
    BOOT_READY_DELAY_MS: %d,
    BOOT_FADE_DURATION_MS: %d,
    FS_CALLBACK_TIMEOUT_MS: %d,
    FS_RETRY_DELAY_MS: %d,
    WINDOW_RESIZE_DEBOUNCE_MS: %d,
    CLOCK_UPDATE_INTERVAL_MS: %d,
    ANIMATION_DURATION_MS: %d,
    TIMEOUT_DEBOUNCE: %d,
    TIMEOUT_INSTANT: %d,
    TIMEOUT_NAVIGATION: %d,
    TIMEOUT_FALLBACK: %d,
    TIMEOUT_RETRY: %d,
    TIMEOUT_LONG: %d,
    
    // Sizes
    WINDOW_MIN_WIDTH: %d,
    WINDOW_MIN_HEIGHT: %d,
    WINDOW_DEFAULT_WIDTH: %d,
    WINDOW_DEFAULT_HEIGHT: %d,
    TASKBAR_HEIGHT: %d,
    DESKTOP_ICON_SIZE: %d,
    
    // Z-Index
    Z_INDEX_WINDOW_BASE: %d,
    Z_INDEX_CONTEXT_MENU: %d,
    Z_INDEX_DIALOG: %d,
    
    // Colors
    COLOR_DESKTOP_DEFAULT: '%s',
    COLOR_ACCENT: '%s',
    
    // Paths
    PATH_DESKTOP: '%s',
    PATH_CONFIG: '%s',
    
    // File Types
    FILE_TYPE_TEXT: '%s',
    FILE_TYPE_SHORTCUT: '%s',
    FILE_TYPE_CONFIG: '%s',
    FILE_TYPE_DIRECTORY: '%s',
    
    // Programs
    PROGRAM_FILE_BROWSER: '%s',
    PROGRAM_NOTES: '%s',
    PROGRAM_SETTINGS: '%s',
    
    // Limits
    MAX_FILENAME_LENGTH: %d,
    MAX_PATH_DEPTH: %d,
    
    // Debug
    DEBUG_ENABLED: %s
};

// Backward compatibility - expose common constants globally
window.TIMEOUT_DEBOUNCE = window.OS_CONSTANTS.TIMEOUT_DEBOUNCE;
window.TIMEOUT_INSTANT = window.OS_CONSTANTS.TIMEOUT_INSTANT;
window.TIMEOUT_NAVIGATION = window.OS_CONSTANTS.TIMEOUT_NAVIGATION;
window.TIMEOUT_FALLBACK = window.OS_CONSTANTS.TIMEOUT_FALLBACK;
window.TIMEOUT_RETRY = window.OS_CONSTANTS.TIMEOUT_RETRY;
window.TIMEOUT_LONG = window.OS_CONSTANTS.TIMEOUT_LONG;
window.FILE_TYPE_DIRECTORY = window.OS_CONSTANTS.FILE_TYPE_DIRECTORY;
window.FILE_TYPE_SHORTCUT = window.OS_CONSTANTS.FILE_TYPE_SHORTCUT;
window.FILE_TYPE_TEXT = window.OS_CONSTANTS.FILE_TYPE_TEXT;
window.FILE_TYPE_CONFIG = window.OS_CONSTANTS.FILE_TYPE_CONFIG;
window.FILE_TYPE_PROGRAM = 'program';
window.FILE_TYPE_UNKNOWN = 'unknown';
window.DRIVE_C = 'C:';
window.DRIVE_EXTERNAL = 'ExternalDrive:';
window.FOLDER_DESKTOP = 'desktop';
window.FOLDER_SYSTEM = '.system';
window.FOLDER_PROGRAMS = 'programs';
window.LOCATION_DESKTOP = 'desktop';
window.LOCATION_FILEBROWSER = 'filebrowser';
window.PROGRAM_FILEBROWSER = window.OS_CONSTANTS.PROGRAM_FILE_BROWSER;
window.PROGRAM_NOTES = window.OS_CONSTANTS.PROGRAM_NOTES;
window.PROGRAM_SETTINGS = window.OS_CONSTANTS.PROGRAM_SETTINGS;
window.DRAG_THRESHOLD = 5;

// Debug logging helpers
window.debugLog = function() {
    if (window.OS_CONSTANTS.DEBUG_ENABLED && console && console.log) {
        console.log.apply(console, arguments);
    }
};
window.debugWarn = function() {
    if (window.OS_CONSTANTS.DEBUG_ENABLED && console && console.warn) {
        console.warn.apply(console, arguments);
    }
};
window.debugError = function() {
    if (console && console.error) {
        console.error.apply(console, arguments);
    }
};

// Pointer Handler (stub for compatibility)
window.osPointerHandler = {
    gestureState: 'idle',
    justCompletedBoxSelection: false,
    currentDragItems: null,
    PRIORITY_APP_CANVAS: 100,
    
    /**
     * Register a handler (stub - just adds a regular event listener)
     */
    register: function(selector, eventType, handler, options) {
        options = options || {};
        
        // Add event listener to matching elements
        document.addEventListener(eventType, function(e) {
            var target = e.target;
            var matchedElement = target.closest(selector);
            
            if (matchedElement) {
                // Check guard if provided
                if (options.guard && !options.guard(e, { matchedElement: matchedElement })) {
                    return;
                }
                
                handler(e, { matchedElement: matchedElement });
            } else if (target.matches && target.matches(selector)) {
                // Check guard if provided
                if (options.guard && !options.guard(e, { matchedElement: target })) {
                    return;
                }
                
                handler(e, { matchedElement: target });
            }
        }, true);
    }
};

// Double-click tracker for preventing single-click navigation
window.osDoubleClickTracker = {
    lastClickTime: 0,
    lastClickElement: null,
    doubleClickConsumed: false,
    consumedTime: 0,
    consumedElementId: null,
    doubleClickThreshold: 300, // ms
    
    /**
     * Check if a click is a double-click
     * @param {HTMLElement} element - The clicked element
     * @returns {boolean} True if this is a double-click
     */
    isDoubleClick: function(element) {
        var now = Date.now();
        var elementId = element.id || element.getAttribute('data-filepath') || element.getAttribute('data-filename');
        var timeSinceLastClick = now - this.lastClickTime;
        
        var isDouble = (
            timeSinceLastClick < this.doubleClickThreshold &&
            this.lastClickElement === elementId
        );
        
        if (isDouble) {
            // Mark as consumed
            this.doubleClickConsumed = true;
            this.consumedTime = now;
            this.consumedElementId = elementId;
            
            // Reset tracking
            this.lastClickTime = 0;
            this.lastClickElement = null;
            
            return true;
        } else {
            // Update tracking for next potential double-click
            this.lastClickTime = now;
            this.lastClickElement = elementId;
            this.doubleClickConsumed = false;
            
            return false;
        }
    }
};
]],
        CONSTANTS.BOOT_INTERVAL_MS,
        CONSTANTS.BOOT_READY_DELAY_MS,
        CONSTANTS.BOOT_FADE_DURATION_MS,
        CONSTANTS.FS_CALLBACK_TIMEOUT_MS,
        CONSTANTS.FS_RETRY_DELAY_MS,
        CONSTANTS.WINDOW_RESIZE_DEBOUNCE_MS,
        CONSTANTS.CLOCK_UPDATE_INTERVAL_MS,
        CONSTANTS.ANIMATION_DURATION_MS,
        CONSTANTS.TIMEOUT_DEBOUNCE,
        CONSTANTS.TIMEOUT_INSTANT,
        CONSTANTS.TIMEOUT_NAVIGATION,
        CONSTANTS.TIMEOUT_FALLBACK,
        CONSTANTS.TIMEOUT_RETRY,
        CONSTANTS.TIMEOUT_LONG,
        
        CONSTANTS.WINDOW_MIN_WIDTH,
        CONSTANTS.WINDOW_MIN_HEIGHT,
        CONSTANTS.WINDOW_DEFAULT_WIDTH,
        CONSTANTS.WINDOW_DEFAULT_HEIGHT,
        CONSTANTS.TASKBAR_HEIGHT,
        CONSTANTS.DESKTOP_ICON_SIZE,
        
        CONSTANTS.Z_INDEX_WINDOW_BASE,
        CONSTANTS.Z_INDEX_CONTEXT_MENU,
        CONSTANTS.Z_INDEX_DIALOG,
        
        CONSTANTS.COLOR_DESKTOP_DEFAULT,
        CONSTANTS.COLOR_ACCENT,
        
        CONSTANTS.PATH_DESKTOP,
        CONSTANTS.PATH_CONFIG,
        
        CONSTANTS.FILE_TYPE_TEXT,
        CONSTANTS.FILE_TYPE_SHORTCUT,
        CONSTANTS.FILE_TYPE_CONFIG,
        CONSTANTS.FILE_TYPE_DIRECTORY,
        
        CONSTANTS.PROGRAM_FILE_BROWSER,
        CONSTANTS.PROGRAM_NOTES,
        CONSTANTS.PROGRAM_SETTINGS,
        
        CONSTANTS.MAX_FILENAME_LENGTH,
        CONSTANTS.MAX_PATH_DEPTH,
        
        CONSTANTS.DEBUG_ENABLED and "true" or "false"
    )
end

return CONSTANTS

