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
end


// Programs
HALOARMORY.COMPUTER.Programs = {
    ["note"] = {
        ["name"] = "Note",
        ["description"] = "A simple note program.",
        ["icon"] = "icon16/note.png",
    },
    ["email"] = {
        ["name"] = "Email",
        ["description"] = "A simple email program.",
        ["icon"] = "icon16/email.png",
    },
    ["external_drive"] = {
        ["name"] = "ExternalDrive:/",
        ["description"] = "Your personal external drive. Notes saved here are stored locally.",
        ["icon"] = "icon16/drive.png",
    },
}


// Default Files
HALOARMORY.COMPUTER.Files = {
    ["welcome_note"] = {
        ["name"] = "Welcome Note",
        ["description"] = "Welcome to your new HALO computer! This computer can be used to store notes and communicate with other personnel.",
        ["file"] = "welcome_note.txt",
    },
}	