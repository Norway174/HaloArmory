--[[
    File: modules/os_selection_manager.lua
    Purpose: Selection management system for file items
    
    Handles single-select, multi-select (Ctrl), and range-select (Shift).
    Uses full paths (data-filepath) to ensure correct item identification.
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// SELECTION MANAGER - File Item Selection System
// ============================================================================

window.osSelectionManager = {
    instances: {}, // Store instances by container ID
    
    /**
     * Create a new selection manager instance for a container
     * @param {string} containerId - Unique ID for the container
     * @param {Element} container - The container element
     * @param {string} location - 'desktop' or 'filebrowser'
     * @returns {Object} Selection manager instance
     */
    create: function(containerId, container, location) {
        if (!container) {
            window.debugError('[SelectionManager] Container not found for ID:', containerId);
            return null;
        }
        
        var instance = {
            containerId: containerId,
            container: container,
            location: location,
            lastSelectedPath: null,
            allItems: [],
            selectionBox: null,
            pendingMarquee: null,
            marqueeState: null,
            suppressClick: false,
            
            /**
             * Initialize event listeners for this container
             */
            init: function() {
                var self = this;
                
                // Click handler for selection
                window.osCleanup.addEventListener(this.containerId + '-selection', this.container, 'click', function(e) {
                    self.handleClick(e);
                });

                window.osCleanup.addEventListener(this.containerId + '-selection', this.container, 'mousedown', function(e) {
                    self.handleMouseDown(e);
                });

                window.osCleanup.addEventListener(this.containerId + '-selection', document, 'mousemove', function(e) {
                    self.handleMouseMove(e);
                });

                window.osCleanup.addEventListener(this.containerId + '-selection', document, 'mouseup', function(e) {
                    self.handleMouseUp(e);
                });
                
                // Prevent context menu from interfering (handled separately)
                window.osCleanup.addEventListener(this.containerId + '-selection', this.container, 'contextmenu', function(e) {
                    // Context menu manager will handle this
                });
                
                window.debugLog('[SelectionManager] Initialized for:', this.containerId, this.location);
            },
            
            /**
             * Handle click events on container
             * @param {Event} e - Click event
             */
            handleClick: function(e) {
                if (this.suppressClick) {
                    this.suppressClick = false;
                    e.preventDefault();
                    e.stopPropagation();
                    return;
                }

                // Find clicked item
                var item = e.target.closest('.os-file-item');
                
                if (!item) {
                    // Clicked on empty space - clear selection unless Ctrl/Shift
                    if (!e.ctrlKey && !e.shiftKey) {
                        this.clearSelection();
                    }
                    return;
                }
                
                var filepath = item.getAttribute('data-filepath');
                if (!filepath) {
                    window.debugWarn('[SelectionManager] Item has no data-filepath:', item);
                    return;
                }
                
                // Handle different click types
                if (e.ctrlKey || e.metaKey) {
                    // Toggle selection
                    this.toggleSelection(filepath);
                } else if (e.shiftKey && this.lastSelectedPath) {
                    // Range select
                    this.rangeSelect(this.lastSelectedPath, filepath);
                } else {
                    // Single select (clear others)
                    this.clearSelection();
                    this.selectItem(filepath);
                }
                
                this.lastSelectedPath = filepath;
            },

            handleMouseDown: function(e) {
                if (e.button !== 0) {
                    return;
                }

                if (e.target.closest('.os-file-item')) {
                    return;
                }

                if (e.target.closest('input, textarea, button, select, option')) {
                    return;
                }

                this.pendingMarquee = {
                    startX: e.clientX,
                    startY: e.clientY,
                    additive: !!(e.ctrlKey || e.metaKey),
                    originalSelection: this.getSelectedItems()
                };
            },

            handleMouseMove: function(e) {
                if (!this.pendingMarquee && !this.marqueeState) {
                    return;
                }

                if (!this.marqueeState && this.pendingMarquee) {
                    var dx = e.clientX - this.pendingMarquee.startX;
                    var dy = e.clientY - this.pendingMarquee.startY;
                    var distance = Math.sqrt((dx * dx) + (dy * dy));

                    if (distance < 4) {
                        return;
                    }

                    this.startMarqueeSelection(this.pendingMarquee);
                }

                if (!this.marqueeState) {
                    return;
                }

                this.updateMarqueeSelection(e.clientX, e.clientY);
                e.preventDefault();
            },

            handleMouseUp: function() {
                if (this.marqueeState) {
                    this.finishMarqueeSelection();
                    return;
                }

                this.pendingMarquee = null;
            },

            startMarqueeSelection: function(pending) {
                this.pendingMarquee = null;
                this.marqueeState = {
                    startX: pending.startX,
                    startY: pending.startY,
                    additive: pending.additive,
                    originalSelection: pending.originalSelection || []
                };

                this.ensureSelectionBox();
                if (this.selectionBox) {
                    this.selectionBox.style.display = 'block';
                }
            },

            updateMarqueeSelection: function(currentX, currentY) {
                if (!this.marqueeState) {
                    return;
                }

                var left = Math.min(this.marqueeState.startX, currentX);
                var top = Math.min(this.marqueeState.startY, currentY);
                var width = Math.abs(currentX - this.marqueeState.startX);
                var height = Math.abs(currentY - this.marqueeState.startY);

                if (this.selectionBox) {
                    this.selectionBox.style.left = left + 'px';
                    this.selectionBox.style.top = top + 'px';
                    this.selectionBox.style.width = width + 'px';
                    this.selectionBox.style.height = height + 'px';
                }

                var selectionRect = {
                    left: left,
                    right: left + width,
                    top: top,
                    bottom: top + height
                };

                var selectedPaths = {};
                if (this.marqueeState.additive) {
                    this.marqueeState.originalSelection.forEach(function(filepath) {
                        selectedPaths[filepath] = true;
                    });
                }

                var allItems = this.container.querySelectorAll('.os-file-item');
                allItems.forEach(function(item) {
                    var filepath = item.getAttribute('data-filepath');
                    if (!filepath) {
                        return;
                    }

                    var itemRect = item.getBoundingClientRect();
                    var intersects = !(
                        itemRect.right < selectionRect.left ||
                        itemRect.left > selectionRect.right ||
                        itemRect.bottom < selectionRect.top ||
                        itemRect.top > selectionRect.bottom
                    );

                    if (intersects) {
                        selectedPaths[filepath] = true;
                    } else if (!this.marqueeState.additive) {
                        delete selectedPaths[filepath];
                    }
                }.bind(this));

                this.applySelectionMap(selectedPaths);
            },

            finishMarqueeSelection: function() {
                this.pendingMarquee = null;
                this.marqueeState = null;
                this.hideSelectionBox();
                this.suppressClick = true;
            },

            ensureSelectionBox: function() {
                if (this.selectionBox && this.selectionBox.parentNode) {
                    return;
                }

                this.selectionBox = document.createElement('div');
                this.selectionBox.className = 'os-selection-marquee';
                document.body.appendChild(this.selectionBox);
            },

            hideSelectionBox: function() {
                if (this.selectionBox) {
                    this.selectionBox.style.display = 'none';
                }
            },

            applySelectionMap: function(selectedPaths) {
                var selected = selectedPaths || {};
                this.container.querySelectorAll('.os-file-item').forEach(function(item) {
                    var filepath = item.getAttribute('data-filepath');
                    item.classList.toggle('os-item-selected', !!(filepath && selected[filepath]));
                });
            },
            
            /**
             * Select a single item by filepath
             * @param {string} filepath - Full path to the item
             */
            selectItem: function(filepath) {
                var item = this.container.querySelector('[data-filepath="' + this.escapeCSSSelector(filepath) + '"]');
                if (item) {
                    item.classList.add('os-item-selected');
                    window.debugLog('[SelectionManager] Selected:', filepath);
                }
            },
            
            /**
             * Deselect an item by filepath
             * @param {string} filepath - Full path to the item
             */
            deselectItem: function(filepath) {
                var item = this.container.querySelector('[data-filepath="' + this.escapeCSSSelector(filepath) + '"]');
                if (item) {
                    item.classList.remove('os-item-selected');
                }
            },
            
            /**
             * Toggle selection for an item
             * @param {string} filepath - Full path to the item
             */
            toggleSelection: function(filepath) {
                var item = this.container.querySelector('[data-filepath="' + this.escapeCSSSelector(filepath) + '"]');
                if (item) {
                    if (item.classList.contains('os-item-selected')) {
                        item.classList.remove('os-item-selected');
                        window.debugLog('[SelectionManager] Deselected:', filepath);
                    } else {
                        item.classList.add('os-item-selected');
                        window.debugLog('[SelectionManager] Selected:', filepath);
                    }
                }
            },
            
            /**
             * Select a range of items between two paths
             * @param {string} startPath - Starting filepath
             * @param {string} endPath - Ending filepath
             */
            rangeSelect: function(startPath, endPath) {
                // Get all items in container
                var allItems = this.container.querySelectorAll('.os-file-item');
                var startIndex = -1;
                var endIndex = -1;
                
                // Find indices
                for (var i = 0; i < allItems.length; i++) {
                    var itemPath = allItems[i].getAttribute('data-filepath');
                    if (itemPath === startPath) startIndex = i;
                    if (itemPath === endPath) endIndex = i;
                }
                
                if (startIndex === -1 || endIndex === -1) {
                    window.debugWarn('[SelectionManager] Could not find range bounds');
                    return;
                }
                
                // Swap if needed
                if (startIndex > endIndex) {
                    var temp = startIndex;
                    startIndex = endIndex;
                    endIndex = temp;
                }
                
                // Clear and select range
                this.clearSelection();
                for (var i = startIndex; i <= endIndex; i++) {
                    allItems[i].classList.add('os-item-selected');
                }
                
                window.debugLog('[SelectionManager] Range selected:', startIndex, 'to', endIndex);
            },
            
            /**
             * Clear all selections in this container
             */
            clearSelection: function() {
                var selectedItems = this.container.querySelectorAll('.os-item-selected');
                selectedItems.forEach(function(item) {
                    item.classList.remove('os-item-selected');
                });
                
                if (selectedItems.length > 0) {
                    window.debugLog('[SelectionManager] Cleared', selectedItems.length, 'selections');
                }
            },
            
            /**
             * Get all selected item filepaths
             * @returns {Array<string>} Array of filepaths
             */
            getSelectedItems: function() {
                var selectedItems = this.container.querySelectorAll('.os-item-selected');
                var filepaths = [];
                
                selectedItems.forEach(function(item) {
                    var filepath = item.getAttribute('data-filepath');
                    if (filepath) {
                        filepaths.push(filepath);
                    }
                });
                
                return filepaths;
            },
            
            /**
             * Get selected item data objects
             * @returns {Array<Object>} Array of item data
             */
            getSelectedItemsData: function() {
                var selectedItems = this.container.querySelectorAll('.os-item-selected');
                var items = [];
                
                selectedItems.forEach(function(item) {
                    var filepath = item.getAttribute('data-filepath');
                    var filetype = item.getAttribute('data-filetype');
                    var displayName = item.getAttribute('data-display-name') || item.getAttribute('data-name');
                    var filename = item.getAttribute('data-filename') || (filepath ? window.getFileNameFromPath(filepath) : '');
                    
                    if (filepath) {
                        items.push({
                            filepath: filepath,
                            filetype: filetype,
                            name: displayName || filename,
                            displayName: displayName || filename,
                            filename: filename,
                            isDirectory: filetype === 'directory',
                            isProtected: item.getAttribute('data-protected') === 'true'
                        });
                    }
                });
                
                return items;
            },

            /**
             * Get selected item elements
             * @returns {Array<Element>} Selected DOM elements
             */
            getSelectedElements: function() {
                return Array.prototype.slice.call(this.container.querySelectorAll('.os-item-selected'));
            },
            
            /**
             * Check if any items are selected
             * @returns {boolean}
             */
            hasSelection: function() {
                return this.container.querySelectorAll('.os-item-selected').length > 0;
            },
            
            /**
             * Get count of selected items
             * @returns {number}
             */
            getSelectionCount: function() {
                return this.container.querySelectorAll('.os-item-selected').length;
            },
            
            /**
             * Check if a specific item is selected
             * @param {string} filepath - Full path to check
             * @returns {boolean}
             */
            isSelected: function(filepath) {
                var item = this.container.querySelector('[data-filepath="' + this.escapeCSSSelector(filepath) + '"]');
                return item && item.classList.contains('os-item-selected');
            },
            
            /**
             * Select all items in container
             */
            selectAll: function() {
                var allItems = this.container.querySelectorAll('.os-file-item');
                allItems.forEach(function(item) {
                    item.classList.add('os-item-selected');
                });
                window.debugLog('[SelectionManager] Selected all', allItems.length, 'items');
            },
            
            /**
             * Escape special characters in CSS selector
             * @param {string} str - String to escape
             * @returns {string} Escaped string
             */
            escapeCSSSelector: function(str) {
                if (!str) return '';
                return str.replace(/([!"#$%&'()*+,.\/:;<=>?@\[\\\]^`{|}~])/g, '\\$1');
            },
            
            /**
             * Cleanup event listeners
             */
            cleanup: function() {
                if (this.selectionBox && this.selectionBox.parentNode) {
                    this.selectionBox.parentNode.removeChild(this.selectionBox);
                }
                this.selectionBox = null;
                this.pendingMarquee = null;
                this.marqueeState = null;
                window.osCleanup.cleanup(this.containerId + '-selection');
                window.debugLog('[SelectionManager] Cleaned up:', this.containerId);
            }
        };
        
        // Store instance
        this.instances[containerId] = instance;
        
        // Initialize
        instance.init();
        
        return instance;
    },
    
    /**
     * Get an existing selection manager instance
     * @param {string} containerId - Container ID
     * @returns {Object|null} Selection manager instance
     */
    get: function(containerId) {
        return this.instances[containerId] || null;
    },
    
    /**
     * Destroy a selection manager instance
     * @param {string} containerId - Container ID
     */
    destroy: function(containerId) {
        var instance = this.instances[containerId];
        if (instance) {
            instance.cleanup();
            delete this.instances[containerId];
        }
    },
    
    /**
     * Destroy all instances
     */
    destroyAll: function() {
        var self = this;
        Object.keys(this.instances).forEach(function(id) {
            self.destroy(id);
        });
    }
};
]]
end

return MODULE

