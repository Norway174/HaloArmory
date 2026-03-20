--[[
    File: os_cleanup.lua  
    Purpose: Memory management and cleanup utilities
    Realm: Client (JavaScript embedded in HTML)
    
    Description:
        Provides utilities for proper cleanup of event listeners, timers,
        and global state to prevent memory leaks.
]]--

local CLEANUP = {}

function CLEANUP.GetJavaScript()
    return [[
// ============================================================================
// OS Cleanup Utility - Manages event listeners, timers, etc.
// ============================================================================

window.osCleanup = {
    // Track all registered resources by a unique ID (e.g., windowId, componentId)
    resources: {}, // { id: { eventListeners: [], intervals: [], timeouts: [] } }

    /**
     * Initializes cleanup tracking for a given ID.
     * @param {string} id - A unique identifier for the resource (e.g., windowId).
     */
    init: function(id) {
        if (!this.resources[id]) {
            this.resources[id] = {
                eventListeners: [],
                intervals: [],
                timeouts: []
            };
        }
    },

    /**
     * Adds an event listener to be tracked for cleanup.
     * @param {string} id - The unique identifier for the resource.
     * @param {EventTarget} target - The DOM element or EventTarget.
     * @param {string} eventType - The event type (e.g., 'click', 'mousemove').
     * @param {function} listener - The event listener function.
     * @param {object} [options] - Event listener options (e.g., { capture: true }).
     */
    addEventListener: function(id, target, eventType, listener, options) {
        if (!target || typeof target.addEventListener !== 'function') {
            window.debugError('[osCleanup] Invalid target for addEventListener:', target);
            return;
        }
        
        this.init(id);
        target.addEventListener(eventType, listener, options);
        this.resources[id].eventListeners.push({ target: target, eventType: eventType, listener: listener, options: options });
    },

    /**
     * Adds an interval to be tracked for cleanup.
     * @param {string} id - The unique identifier for the resource.
     * @param {function} callback - The function to execute.
     * @param {number} delay - The delay in milliseconds.
     * @returns {number} The interval ID.
     */
    setInterval: function(id, callback, delay) {
        this.init(id);
        var intervalId = setInterval(callback, delay);
        this.resources[id].intervals.push(intervalId);
        return intervalId;
    },

    /**
     * Adds a timeout to be tracked for cleanup.
     * @param {string} id - The unique identifier for the resource.
     * @param {function} callback - The function to execute.
     * @param {number} delay - The delay in milliseconds.
     * @returns {number} The timeout ID.
     */
    setTimeout: function(id, callback, delay) {
        this.init(id);
        var timeoutId = setTimeout(callback, delay);
        this.resources[id].timeouts.push(timeoutId);
        return timeoutId;
    },

    /**
     * Clears a specific interval.
     * @param {string} id - The unique identifier for the resource.
     * @param {number} intervalId - The ID of the interval to clear.
     */
    clearInterval: function(id, intervalId) {
        if (this.resources[id]) {
            clearInterval(intervalId);
            this.resources[id].intervals = this.resources[id].intervals.filter(function(i) {
                return i !== intervalId;
            });
        }
    },

    /**
     * Clears a specific timeout.
     * @param {string} id - The unique identifier for the resource.
     * @param {number} timeoutId - The ID of the timeout to clear.
     */
    clearTimeout: function(id, timeoutId) {
        if (this.resources[id]) {
            clearTimeout(timeoutId);
            this.resources[id].timeouts = this.resources[id].timeouts.filter(function(t) {
                return t !== timeoutId;
            });
        }
    },

    /**
     * Cleans up all tracked resources for a given ID.
     * @param {string} id - The unique identifier for the resource to clean up.
     */
    cleanup: function(id) {
        if (this.resources[id]) {
            // Remove event listeners
            this.resources[id].eventListeners.forEach(function(res) {
                if (res.target && typeof res.target.removeEventListener === 'function') {
                    res.target.removeEventListener(res.eventType, res.listener, res.options);
                }
            });
            this.resources[id].eventListeners = [];

            // Clear intervals
            this.resources[id].intervals.forEach(function(intervalId) {
                clearInterval(intervalId);
            });
            this.resources[id].intervals = [];

            // Clear timeouts
            this.resources[id].timeouts.forEach(function(timeoutId) {
                clearTimeout(timeoutId);
            });
            this.resources[id].timeouts = [];

            delete this.resources[id];
            window.debugLog('[osCleanup] Cleaned up resources for ID:', id);
        }
    },

    /**
     * Cleans up all tracked resources for all IDs.
     * Use with caution, typically only on full OS shutdown.
     */
    cleanupAll: function() {
        var self = this;
        Object.keys(this.resources).forEach(function(id) {
            self.cleanup(id);
        });
        window.debugLog('[osCleanup] Cleaned up all resources.');
    }
};

// Cleanup on page unload
window.addEventListener('beforeunload', function() {
    if (window.osCleanup) {
        window.osCleanup.cleanupAll();
    }
});
]]
end

return CLEANUP

