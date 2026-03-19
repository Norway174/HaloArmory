--[[
    File: os_error_handler.lua
    Purpose: Error handling and user notification system
    Realm: Client (JavaScript embedded in HTML)
    
    Description:
        Provides centralized error handling, user notifications, and retry logic
        for filesystem operations and other system functions.
]]--

local ERROR_HANDLER = {}

function ERROR_HANDLER.GetJavaScript()
    return [[
// ============================================================================
// ERROR HANDLING & NOTIFICATIONS
// ============================================================================

window.osErrorHandler = {
    /**
     * Show a user-friendly error notification
     * @param {string} title - Error title
     * @param {string} message - Error message
     * @param {Object} options - Additional options
     */
    showError: function(title, message, options) {
        options = options || {};
        var duration = options.duration || 5000;
        
        // Create error notification
        var notification = document.createElement('div');
        notification.className = 'os-notification os-notification-error';
        notification.innerHTML = 
            '<div class="os-notification-title">' + this.escapeHtml(title) + '</div>' +
            '<div class="os-notification-message">' + this.escapeHtml(message) + '</div>';
        
        // Add to document
        var container = this.getNotificationContainer();
        container.appendChild(notification);
        
        // Auto-remove after duration
        setTimeout(function() {
            notification.style.opacity = '0';
            setTimeout(function() {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, duration);
        
        // Log to console
        console.error('[OS Error]', title, message);
    },
    
    /**
     * Show a success notification
     * @param {string} message - Success message
     * @param {Object} options - Additional options
     */
    showSuccess: function(message, options) {
        options = options || {};
        var duration = options.duration || 3000;
        
        var notification = document.createElement('div');
        notification.className = 'os-notification os-notification-success';
        notification.innerHTML = 
            '<div class="os-notification-message">' + this.escapeHtml(message) + '</div>';
        
        var container = this.getNotificationContainer();
        container.appendChild(notification);
        
        setTimeout(function() {
            notification.style.opacity = '0';
            setTimeout(function() {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, duration);
    },
    
    /**
     * Show a warning notification
     * @param {string} message - Warning message
     * @param {Object} options - Additional options
     */
    showWarning: function(message, options) {
        options = options || {};
        var duration = options.duration || 4000;
        
        var notification = document.createElement('div');
        notification.className = 'os-notification os-notification-warning';
        notification.innerHTML = 
            '<div class="os-notification-message">' + this.escapeHtml(message) + '</div>';
        
        var container = this.getNotificationContainer();
        container.appendChild(notification);
        
        setTimeout(function() {
            notification.style.opacity = '0';
            setTimeout(function() {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, duration);
        
        console.warn('[OS Warning]', message);
    },
    
    /**
     * Get or create notification container
     * @returns {Element} Notification container
     */
    getNotificationContainer: function() {
        var container = document.getElementById('os-notification-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'os-notification-container';
            document.body.appendChild(container);
        }
        return container;
    },
    
    /**
     * Escape HTML to prevent XSS
     * @param {string} text - Text to escape
     * @returns {string} Escaped text
     */
    escapeHtml: function(text) {
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;'
        };
        return String(text).replace(/[&<>"']/g, function(m) { return map[m]; });
    },
    
    /**
     * Retry a function with exponential backoff
     * @param {Function} fn - Function to retry
     * @param {number} maxRetries - Maximum number of retries
     * @param {number} baseDelay - Base delay in milliseconds
     * @returns {Promise} Promise that resolves on success or rejects after all retries
     */
    retry: function(fn, maxRetries, baseDelay) {
        maxRetries = maxRetries || 3;
        baseDelay = baseDelay || 1000;
        
        return new Promise(function(resolve, reject) {
            var attempt = 0;
            
            function tryFn() {
                attempt++;
                
                try {
                    var result = fn();
                    
                    // If function returns a promise
                    if (result && typeof result.then === 'function') {
                        result.then(resolve).catch(function(error) {
                            if (attempt < maxRetries) {
                                var delay = baseDelay * Math.pow(2, attempt - 1);
                                setTimeout(tryFn, delay);
                            } else {
                                reject(error);
                            }
                        });
                    } else {
                        resolve(result);
                    }
                } catch (error) {
                    if (attempt < maxRetries) {
                        var delay = baseDelay * Math.pow(2, attempt - 1);
                        setTimeout(tryFn, delay);
                    } else {
                        reject(error);
                    }
                }
            }
            
            tryFn();
        });
    },
    
    /**
     * Show a notification (wrapper for showError, showSuccess, showWarning)
     * @param {string} message - Notification message
     * @param {string} type - Type: 'error', 'success', 'warning'
     * @param {number} duration - Duration in milliseconds (optional)
     */
    showNotification: function(message, type, duration) {
        type = type || 'error';
        duration = duration || (type === 'success' ? 3000 : type === 'warning' ? 4000 : 5000);
        
        var options = { duration: duration };
        
        if (type === 'success') {
            this.showSuccess(message, options);
        } else if (type === 'warning') {
            this.showWarning(message, options);
        } else {
            // Default to error
            this.showError('Error', message, options);
        }
    },
    
    /**
     * Wrap a filesystem operation with error handling
     * @param {Function} operation - Operation to wrap
     * @param {string} operationName - Name of operation (for error messages)
     * @returns {Function} Wrapped operation
     */
    wrapFilesystemOperation: function(operation, operationName) {
        var self = this;
        return function() {
            try {
                return operation.apply(this, arguments);
            } catch (error) {
                self.showError(
                    'Filesystem Error',
                    'Failed to ' + operationName + ': ' + error.message
                );
                console.error('[Filesystem Error]', operationName, error);
                throw error;
            }
        };
    }
};

// Add notification styles
var style = document.createElement('style');
style.textContent = `
#os-notification-container {
    position: fixed;
    top: 50px;
    right: 20px;
    z-index: 10000;
    display: flex;
    flex-direction: column;
    gap: 10px;
    pointer-events: none;
}

.os-notification {
    min-width: 300px;
    max-width: 400px;
    padding: 12px 16px;
    border-radius: var(--radius-ui, 6px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    opacity: 1;
    transition: opacity 0.3s ease;
    pointer-events: auto;
    font-size: 13px;
}

.os-notification-error {
    background: #d32f2f;
    border-left: 4px solid #b71c1c;
}

.os-notification-success {
    background: #388e3c;
    border-left: 4px solid #2e7d32;
}

.os-notification-warning {
    background: #f57c00;
    border-left: 4px solid #ef6c00;
}

.os-notification-title {
    font-weight: bold;
    margin-bottom: 4px;
}

.os-notification-message {
    opacity: 0.9;
}
`;
document.head.appendChild(style);

// Global error handler
window.addEventListener('error', function(event) {
    console.error('[Global Error]', event.error || event.message);
});

// Unhandled promise rejection handler
window.addEventListener('unhandledrejection', function(event) {
    console.error('[Unhandled Promise Rejection]', event.reason);
    window.osErrorHandler.showError(
        'Unexpected Error',
        'An unexpected error occurred. Please check the console for details.'
    );
});
]]
end

return ERROR_HANDLER

