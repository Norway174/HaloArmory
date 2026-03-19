HALOARMORY.MsgC("Shared HALO Computer Configs Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}


// Save locations
HALOARMORY.COMPUTER.Directory = "haloarmory/computer/"

if SERVER then
	// Emails are server only
    HALOARMORY.COMPUTER.Directory_Emails = HALOARMORY.COMPUTER.Directory .. "emails/{steam_id}/"
    // Persistent PC storage (only used on server)
    HALOARMORY.COMPUTER.PersistentPC = HALOARMORY.COMPUTER.Directory .. "computers/{pc_id}/"
else
    // Client-side: ExternalDrive (local storage) used in sh_storage.lua
    HALOARMORY.COMPUTER.LocalPC = HALOARMORY.COMPUTER.Directory .. "local/"
    HALOARMORY.COMPUTER.PresetsPC = HALOARMORY.COMPUTER.Directory .. "presets/"
end

// Default Files Structure
HALOARMORY.COMPUTER.DefaultFiles = {
    // Desktop shortcuts (created inside C:/desktop/ on new PCs)
    ["desktop_shortcuts"] = {
        ["email"] = {
            ["name"] = "Email",
            ["program"] = "email"
        },
        ["filebrowser"] = {
            ["name"] = "File Browser",
            ["program"] = "filebrowser",
            ["folder"] = "C:/"
        },
        ["externaldrive"] = {
            ["name"] = "ExternalDrive:/",
            ["program"] = "filebrowser",
            ["folder"] = "ExternalDrive:/",
            ["icon"] = "💽"
        }
    }
}
