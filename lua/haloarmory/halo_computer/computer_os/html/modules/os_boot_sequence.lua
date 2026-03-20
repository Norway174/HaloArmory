--[[
    File: modules/os_boot_sequence.lua
    Purpose: Boot sequence management
]]--

local MODULE = {}

function MODULE.GetJavaScript()
    return [[
// ============================================================================
// BOOT SEQUENCE
// ============================================================================

window.osBootSequence = {
    bootInterval: null,
    currentStep: 0,
    filesSynced: false,
    syncRequested: false,
    
    /**
     * Start the boot sequence
     */
    start: function() {
        var self = this;
        var bootScreen = document.getElementById('os-boot-screen');
        var desktop = document.getElementById('os-desktop');
        var bootStatus = document.getElementById('os-boot-status');
        var bootProgress = document.getElementById('os-boot-progress-bar');
        
        var bootSteps = [
            { text: 'Initializing system...', progress: 0 },
            { text: 'Loading drivers...', progress: 20 },
            { text: 'Synchronizing filesystem...', progress: 50 },
            { text: 'Loading desktop...', progress: 90 },
            { text: 'Ready', progress: 100 }
        ];
        
        this.currentStep = 0;
        this.filesSynced = false;
        this.syncRequested = false;

        if (window.requestPCFilesSync) {
            this.syncRequested = true;
            window.requestPCFilesSync(function(success) {
                if (success && window.osBootSequence) {
                    window.osBootSequence.markFilesSynced();
                }
            });
        } else {
            // Fallback so boot does not deadlock if the bridge is unavailable.
            setTimeout(function() {
                if (window.osBootSequence) {
                    window.osBootSequence.markFilesSynced();
                }
            }, 2000);
        }
        
        // Update boot status periodically
        this.bootInterval = setInterval(function() {
            // Only advance if we haven't reached the end
            if (self.currentStep < bootSteps.length - 1) {
                // Only advance if files are synced and we're past step 2, OR if we're still before step 2
                if (self.filesSynced && self.currentStep >= 2) {
                    self.currentStep++;
                } else if (self.currentStep < 2) {
                    self.currentStep++;
                }
                // If currentStep is 2 but files not synced yet, wait (don't advance)
            }
            
            if (bootStatus) {
                bootStatus.textContent = bootSteps[self.currentStep].text;
            }
            if (bootProgress) {
                bootProgress.style.width = bootSteps[self.currentStep].progress + '%';
            }
            
            // If files are synced and we've shown "Loading desktop..."
            if (self.filesSynced && self.currentStep >= 3) {
                clearInterval(self.bootInterval);
                
                // Mark boot sequence as completed
                window.osBootSequenceCompleted = true;
                
                // Small delay for "Ready" message
                setTimeout(function() {
                    // Load desktop icons
                    window.osShell.loadDesktopIcons();
                    
                    // Fade out boot screen
                    if (bootScreen) {
                        bootScreen.style.opacity = '0';
                        bootScreen.style.transition = 'opacity 0.5s ease-out';
                        setTimeout(function() {
                            bootScreen.style.display = 'none';
                            if (desktop) {
                                desktop.style.display = 'block';
                            }
                        }, 500);
                    }
                }, 500);
            }
        }, 800);
    },
    
    /**
     * Mark files as synced (called by filesystem when sync completes)
     */
    markFilesSynced: function() {
        this.filesSynced = true;
    }
};
]]
end

return MODULE

