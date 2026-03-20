-- ExternalDrive Program - Compatibility alias for the File Browser
local scriptPath = HALOARMORY.GetOwnScriptPath()
local FILEBROWSER = include(scriptPath .. "filebrowser.lua")

local EXTERNALDRIVE = {}

function EXTERNALDRIVE.GetInitScript()
    return [[
        window.programInitialPaths = window.programInitialPaths || {};
        window.programInitialPaths[windowId] = 'ExternalDrive:/';
        fileBrowserApp.init(windowId);
    ]]
end

return {
    title = "External Drive",
    icon = "💽",
    width = FILEBROWSER.width or 760,
    height = FILEBROWSER.height or 500,
    getContent = FILEBROWSER.getContent,
    getInitScript = EXTERNALDRIVE.GetInitScript,
    getCSS = FILEBROWSER.getCSS
}
