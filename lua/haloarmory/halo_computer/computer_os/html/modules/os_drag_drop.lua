--[[
    File: modules/os_drag_drop.lua
    Purpose: Shared drag and drop manager for file items and app targets
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// DRAG AND DROP MANAGER
// ============================================================================

window.osDragDropManager = {
    initialized: false,
    activeDrag: null,
    pendingDrag: null,
    dropTargets: [],
    dragPreview: null,
    suppressNextClick: false,

    init: function() {
        if (this.initialized) {
            return;
        }

        this.initialized = true;

        document.addEventListener('mousemove', function(e) {
            window.osDragDropManager.handleMouseMove(e);
        });

        document.addEventListener('mouseup', function(e) {
            window.osDragDropManager.handleMouseUp(e);
        });

        document.addEventListener('mouseleave', function() {
            window.osDragDropManager.cancelPendingDrag();
        });

        window.addEventListener('blur', function() {
            window.osDragDropManager.finishDrag(false);
        });

        document.addEventListener('click', function(e) {
            if (!window.osDragDropManager.suppressNextClick) {
                return;
            }

            window.osDragDropManager.suppressNextClick = false;
            e.preventDefault();
            e.stopPropagation();
        }, true);
    },

    registerFileSourceContainer: function(container, options) {
        if (!container) {
            return;
        }

        this.init();

        options = options || {};
        var resourceId = options.resourceId || container.id || ('drag-source-' + Date.now());
        if (container.getAttribute('data-drag-source-resource') === resourceId) {
            return;
        }

        container.setAttribute('data-drag-source-resource', resourceId);
        if (options.selectionManagerId) {
            container.setAttribute('data-selection-manager-id', options.selectionManagerId);
        }

        var self = this;
        window.osCleanup.addEventListener(resourceId, container, 'mousedown', function(e) {
            self.handleMouseDown(e, container, options);
        });

        // Block flaky native HTML drag behavior in DHTML.
        window.osCleanup.addEventListener(resourceId, container, 'dragstart', function(e) {
            e.preventDefault();
        });
    },

    registerFilesystemDropTarget: function(element, options) {
        if (!element) {
            return;
        }

        this.init();

        options = options || {};
        var resourceId = options.resourceId || element.id || ('drag-target-' + Date.now());
        if (element.getAttribute('data-drop-target-resource') === resourceId) {
            return;
        }

        element.setAttribute('data-drop-target-resource', resourceId);
        this.dropTargets.push({
            id: resourceId,
            element: element,
            type: 'filesystem',
            getTargetPath: function() {
                if (typeof options.getTargetPath === 'function') {
                    return options.getTargetPath();
                }
                return options.targetPath || '';
            }
        });
    },

    registerAttachmentDropTarget: function(element, options) {
        if (!element) {
            return;
        }

        this.init();

        options = options || {};
        var resourceId = options.resourceId || element.id || ('drag-attachment-' + Date.now());
        if (element.getAttribute('data-attachment-target-resource') === resourceId) {
            return;
        }

        element.setAttribute('data-attachment-target-resource', resourceId);
        this.dropTargets.push({
            id: resourceId,
            element: element,
            type: 'attachment',
            onDrop: options.onDrop
        });
    },

    handleMouseDown: function(e, container, options) {
        if (e.button !== 0) {
            return;
        }

        var itemElement = e.target.closest('.os-file-item');
        if (!itemElement) {
            return;
        }

        // Avoid starting drag from interactive controls inside special views.
        if (e.target.closest('input, textarea, button, select, option')) {
            return;
        }

        var dragData = this.collectDragItems(itemElement, container, options || {});
        if (!dragData.items.length) {
            return;
        }

        this.pendingDrag = {
            startX: e.clientX,
            startY: e.clientY,
            sourceEvent: e,
            data: dragData
        };
    },

    handleMouseMove: function(e) {
        if (this.pendingDrag && !this.activeDrag) {
            var dx = e.clientX - this.pendingDrag.startX;
            var dy = e.clientY - this.pendingDrag.startY;
            var distance = Math.sqrt((dx * dx) + (dy * dy));

            if (distance >= (window.DRAG_THRESHOLD || 5)) {
                this.startDrag(this.pendingDrag.data, e);
                this.pendingDrag = null;
            }
        }

        if (!this.activeDrag) {
            return;
        }

        this.updateDragPreviewPosition(e.clientX, e.clientY);
        this.updateHoveredTarget(e.clientX, e.clientY, e);
        e.preventDefault();
    },

    handleMouseUp: function(e) {
        if (this.pendingDrag) {
            this.pendingDrag = null;
            return;
        }

        if (!this.activeDrag) {
            return;
        }

        var dropHandled = this.performDrop(e);
        this.finishDrag(dropHandled);
    },

    cancelPendingDrag: function() {
        this.pendingDrag = null;
    },

    startDrag: function(dragData, event) {
        this.activeDrag = dragData;
        this.activeDrag.currentTarget = null;

        dragData.elements.forEach(function(element) {
            element.classList.add('os-item-dragging');
        });

        this.createDragPreview(dragData);
        this.updateDragPreviewPosition(event.clientX, event.clientY);
        this.updateHoveredTarget(event.clientX, event.clientY, event);
    },

    createDragPreview: function(dragData) {
        this.removeDragPreview();

        var preview = document.createElement('div');
        preview.className = 'os-drag-preview';

        var primaryItem = dragData.items[0];
        var label = document.createElement('div');
        label.className = 'os-drag-preview-label';
        label.textContent = primaryItem.displayName || primaryItem.filename || 'Item';
        preview.appendChild(label);

        if (dragData.items.length > 1) {
            var count = document.createElement('div');
            count.className = 'os-drag-preview-count';
            count.textContent = dragData.items.length + ' items';
            preview.appendChild(count);
        }

        document.body.appendChild(preview);
        this.dragPreview = preview;
    },

    updateDragPreviewPosition: function(x, y) {
        if (!this.dragPreview) {
            return;
        }

        this.dragPreview.style.left = (x + 16) + 'px';
        this.dragPreview.style.top = (y + 16) + 'px';
    },

    removeDragPreview: function() {
        if (this.dragPreview && this.dragPreview.parentNode) {
            this.dragPreview.parentNode.removeChild(this.dragPreview);
        }
        this.dragPreview = null;
    },

    updateHoveredTarget: function(x, y, event) {
        if (!this.activeDrag) {
            return;
        }

        var hoveredElement = document.elementFromPoint(x, y);
        var target = this.findDropTargetForElement(hoveredElement);
        var validation = null;

        if (target) {
            validation = this.validateDropForTarget(this.activeDrag.items, target);
            if (!validation.accepted.length) {
                target = null;
                validation = null;
            }
        }

        if (this.activeDrag.currentTarget && (!target || this.activeDrag.currentTarget.id !== target.id)) {
            this.setTargetActive(this.activeDrag.currentTarget.element, null, false);
        }

        if (target) {
            this.setTargetActive(target.element, target.type, true, validation.accepted.length, validation.rejected.length);
            this.activeDrag.currentTarget = target;
            this.activeDrag.currentValidation = validation;
            this.activeDrag.currentDropMode = target.type === 'filesystem'
                ? this.getDropEffect(validation.accepted, target.getTargetPath(), event)
                : 'copy';
            return;
        }

        this.activeDrag.currentTarget = null;
        this.activeDrag.currentValidation = null;
        this.activeDrag.currentDropMode = null;
    },

    findDropTargetForElement: function(element) {
        if (!element) {
            return null;
        }

        for (var i = this.dropTargets.length - 1; i >= 0; i--) {
            var target = this.dropTargets[i];
            if (!target || !target.element || !document.body.contains(target.element)) {
                continue;
            }

            if (target.element === element || target.element.contains(element)) {
                return target;
            }
        }

        return null;
    },

    performDrop: function(event) {
        if (!this.activeDrag || !this.activeDrag.currentTarget || !this.activeDrag.currentValidation) {
            return false;
        }

        var target = this.activeDrag.currentTarget;
        var validation = this.activeDrag.currentValidation;

        if (!validation.accepted.length) {
            return false;
        }

        if (target.type === 'attachment') {
            if (typeof target.onDrop === 'function') {
                target.onDrop(validation.accepted, validation.rejected);
            }

            if (validation.rejected.length > 0) {
                this.showRejectedItems(validation.rejected, 'Some items were not attached');
            }

            return true;
        }

        var targetPath = target.getTargetPath();
        var mode = this.activeDrag.currentDropMode === 'move' ? 'move' : 'copy';
        this.transferItemsToTarget(validation, targetPath, mode);
        return true;
    },

    transferItemsToTarget: function(validation, targetPath, mode) {
        var self = this;
        window.osFileOperations.transferItems(validation.accepted, targetPath, {
            mode: mode
        }, function(success) {
            if (success || validation.accepted.length > 0) {
                self.refreshAfterFilesystemDrop(validation.accepted, targetPath, mode);
            }
            if (validation.rejected.length > 0) {
                self.showRejectedItems(validation.rejected, success ? 'Some items were skipped' : 'Drop completed with skipped items');
            }
        });
    },

    finishDrag: function(suppressClick) {
        this.pendingDrag = null;

        if (this.activeDrag && this.activeDrag.elements) {
            this.activeDrag.elements.forEach(function(element) {
                if (element && element.classList) {
                    element.classList.remove('os-item-dragging');
                }
            });
        }

        if (suppressClick) {
            this.suppressNextClick = true;
        }

        this.activeDrag = null;
        this.removeDragPreview();
        this.clearAllTargetStates();
    },

    collectDragItems: function(itemElement, container, options) {
        var items = [];
        var elements = [];
        var selectionManagerId = options.selectionManagerId || container.getAttribute('data-selection-manager-id');
        var selectionManager = selectionManagerId && window.osSelectionManager ? window.osSelectionManager.get(selectionManagerId) : null;

        if (selectionManager && itemElement.classList.contains('os-item-selected')) {
            elements = selectionManager.getSelectedElements ? selectionManager.getSelectedElements() : [];
        }

        if (!elements.length) {
            elements = [itemElement];
        }

        items = elements.map(function(element) {
            return window.osDragDropManager.readItemFromElement(element);
        }).filter(function(item) {
            return !!item;
        });

        return {
            items: items,
            elements: elements,
            sourcePath: options.sourcePath || null,
            sourceLocation: options.location || null,
            sourceContainer: container
        };
    },

    readItemFromElement: function(element) {
        if (!element) {
            return null;
        }

        var filepath = element.getAttribute('data-filepath');
        if (!filepath) {
            return null;
        }

        return {
            filepath: filepath,
            filename: element.getAttribute('data-filename') || window.getFileNameFromPath(filepath),
            displayName: element.getAttribute('data-display-name') || element.getAttribute('data-name') || element.getAttribute('data-filename') || window.getFileNameFromPath(filepath),
            name: element.getAttribute('data-name') || element.getAttribute('data-display-name') || element.getAttribute('data-filename') || window.getFileNameFromPath(filepath),
            filetype: element.getAttribute('data-filetype') || window.getFileTypeFromPath(filepath),
            isDirectory: (element.getAttribute('data-filetype') || window.getFileTypeFromPath(filepath)) === 'directory',
            isProtected: element.getAttribute('data-protected') === 'true'
        };
    },

    validateDropForTarget: function(items, target) {
        if (!target) {
            return { accepted: [], rejected: [] };
        }

        if (target.type === 'attachment') {
            return this.validateAttachmentDrop(items);
        }

        return this.validateFilesystemDrop(items, target.getTargetPath());
    },

    validateFilesystemDrop: function(items, targetPath) {
        var accepted = [];
        var rejected = [];
        var normalizedTarget = window.osFileOperations.normalizeDirectoryPath(targetPath);

        items.forEach(function(item) {
            var reason = window.osFileOperations.getTransferValidationError(item, 'filesystem', normalizedTarget);
            var sourceDirectory = window.osFileOperations.getParentDirectory(item.filepath);

            if (!reason && sourceDirectory.toLowerCase() === normalizedTarget.toLowerCase()) {
                reason = 'Already in this location';
            }

            if (!reason && item.isDirectory && window.isSelfDrop && window.isSelfDrop(item.filepath, normalizedTarget)) {
                reason = 'Cannot move a folder into itself';
            }

            if (reason) {
                rejected.push({
                    item: item,
                    reason: reason
                });
                return;
            }

            accepted.push(item);
        });

        return {
            accepted: accepted,
            rejected: rejected
        };
    },

    validateAttachmentDrop: function(items) {
        var accepted = [];
        var rejected = [];

        items.forEach(function(item) {
            var reason = window.osFileOperations.getTransferValidationError(item, 'attachment');
            if (reason) {
                rejected.push({
                    item: item,
                    reason: reason
                });
                return;
            }

            accepted.push(item);
        });

        return {
            accepted: accepted,
            rejected: rejected
        };
    },

    getDropEffect: function(items, targetPath, event) {
        if (event && event.ctrlKey) {
            return 'copy';
        }

        var targetDrive = window.getDriveFromPath(targetPath);
        var sourceDrive = items.length > 0 ? window.getDriveFromPath(items[0].filepath) : targetDrive;

        if (sourceDrive && targetDrive && sourceDrive.toLowerCase() === targetDrive.toLowerCase()) {
            return 'move';
        }

        return 'copy';
    },

    setTargetActive: function(element, targetType, active, acceptedCount, rejectedCount) {
        if (!element) {
            return;
        }

        if (active) {
            element.classList.add('os-drop-target-active');
            element.classList.toggle('os-drop-target-partial', (rejectedCount || 0) > 0);
            element.setAttribute('data-drop-target-type', targetType || 'filesystem');
            if (acceptedCount !== undefined) {
                element.setAttribute('data-drop-accepted-count', String(acceptedCount));
            }
            if (rejectedCount !== undefined) {
                element.setAttribute('data-drop-rejected-count', String(rejectedCount));
            }
            return;
        }

        element.classList.remove('os-drop-target-active');
        element.classList.remove('os-drop-target-partial');
        element.removeAttribute('data-drop-target-type');
        element.removeAttribute('data-drop-accepted-count');
        element.removeAttribute('data-drop-rejected-count');
    },

    clearAllTargetStates: function() {
        document.querySelectorAll('.os-drop-target-active, .os-drop-target-partial').forEach(function(element) {
            window.osDragDropManager.setTargetActive(element, null, false);
        });
    },

    showRejectedItems: function(rejected, fallbackMessage) {
        if (!rejected || !rejected.length || !window.osErrorHandler) {
            return;
        }

        var firstReason = rejected[0] && rejected[0].reason ? rejected[0].reason : fallbackMessage;
        if (rejected.length === 1 && rejected[0].item) {
            window.osErrorHandler.showNotification((rejected[0].item.displayName || rejected[0].item.filename || 'Item') + ': ' + firstReason, 'warning');
            return;
        }

        window.osErrorHandler.showNotification((fallbackMessage || 'Some items were skipped') + ' (' + rejected.length + ')', 'warning');
    },

    refreshAfterFilesystemDrop: function(items, targetPath, mode) {
        var touchedPaths = [window.osFileOperations.normalizeDirectoryPath(targetPath)];

        if (mode === 'move') {
            items.forEach(function(item) {
                touchedPaths.push(window.osFileOperations.getParentDirectory(item.filepath));
            });
        }

        var refreshedDesktop = false;

        touchedPaths.forEach(function(path) {
            var normalized = window.osFileOperations.normalizeDirectoryPath(path);
            if (!normalized) {
                return;
            }

            if (normalized.toLowerCase() === (window.PATH_DESKTOP || 'c:/desktop/').toLowerCase()) {
                if (!refreshedDesktop && window.osShell && window.osShell.loadDesktopIcons) {
                    window.osShell.loadDesktopIcons(true);
                    refreshedDesktop = true;
                }
                return;
            }

            if (window.fileBrowserApp && window.fileBrowserApp.refreshPath) {
                window.fileBrowserApp.refreshPath(normalized);
            }
        });
    }
};
]]
end

function MODULE.GetCSS()
    return [[
.os-item-dragging {
    opacity: 0.45;
}

.os-drag-preview {
    position: fixed;
    left: 0;
    top: 0;
    z-index: 70000;
    pointer-events: none;
    min-width: 120px;
    max-width: 220px;
    padding: 10px 12px;
    border: 1px solid rgba(74, 158, 255, 0.55);
    border-radius: var(--radius-ui-large, 10px);
    background: rgba(18, 24, 34, 0.94);
    box-shadow: 0 10px 24px rgba(0, 0, 0, 0.35);
    color: #ffffff;
}

.os-drag-preview-label {
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.os-drag-preview-count {
    margin-top: 4px;
    font-size: 11px;
    color: #9fc8ff;
}

.os-drop-target-active {
    box-shadow: inset 0 0 0 2px rgba(74, 158, 255, 0.75);
    background: rgba(74, 158, 255, 0.08);
}

.os-drop-target-partial {
    box-shadow: inset 0 0 0 2px rgba(255, 152, 0, 0.75);
    background: rgba(255, 152, 0, 0.08);
}
]]
end

return MODULE
