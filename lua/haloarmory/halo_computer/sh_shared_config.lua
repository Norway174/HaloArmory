HALOARMORY.MsgC("Shared HALO Computer Configs Loading.")

HALOARMORY.COMPUTER = HALOARMORY.COMPUTER or {}
HALOARMORY.COMPUTER.EMAIL = HALOARMORY.COMPUTER.EMAIL or {}


// Save locations
HALOARMORY.COMPUTER.Directory = "haloarmory/computer/"

// Email
HALOARMORY.COMPUTER.EMAIL.MaxEmails = 500 // How many Emails to keep per player
HALOARMORY.COMPUTER.EMAIL.DeleteTrashDays = 30 // Delete trash Emails after X amount of days

HALOARMORY.COMPUTER.EMAIL.NET_NAME = "HALOARMORY.COMPUTER.EMAIL"
HALOARMORY.COMPUTER.EMAIL.CHUNK_SIZE = 54000

HALOARMORY.COMPUTER.EMAIL.NET_REQUEST_BEGIN = 1
HALOARMORY.COMPUTER.EMAIL.NET_REQUEST_CHUNK = 2
HALOARMORY.COMPUTER.EMAIL.NET_REQUEST_COMMIT = 3
HALOARMORY.COMPUTER.EMAIL.NET_RESPONSE_BEGIN = 4
HALOARMORY.COMPUTER.EMAIL.NET_RESPONSE_CHUNK = 5
HALOARMORY.COMPUTER.EMAIL.NET_RESPONSE_COMMIT = 6

HALOARMORY.COMPUTER.EMAIL.ACTION_MAILBOX_INDEX = "mailbox_index"
HALOARMORY.COMPUTER.EMAIL.ACTION_EMAIL_DETAIL = "email_detail"
HALOARMORY.COMPUTER.EMAIL.ACTION_SEND_EMAIL = "send_email"
HALOARMORY.COMPUTER.EMAIL.ACTION_UPDATE_STATE = "update_state"
HALOARMORY.COMPUTER.EMAIL.ACTION_ONLINE_PLAYERS = "online_players"
HALOARMORY.COMPUTER.EMAIL.ACTION_CONTACTS = "contacts"

HALOARMORY.COMPUTER.EMAIL.TOAST_COMMAND = "halo_computer_toast_email"

if SERVER then
    // Emails Server
    HALOARMORY.COMPUTER.Directory_Emails = HALOARMORY.COMPUTER.Directory .. "emails/{steam_id}/"
    // Persistent PC storage (only used on server)
    HALOARMORY.COMPUTER.PersistentPC = HALOARMORY.COMPUTER.Directory .. "computers/{pc_id}/"
else
    // Emails Client
    HALOARMORY.COMPUTER.EMAIL.CLIENT_STORAGE_DIR = HALOARMORY.COMPUTER.Directory .. "email_local/"
    HALOARMORY.COMPUTER.EMAIL.CLIENT_DRAFTS_FILE = HALOARMORY.COMPUTER.EMAIL.CLIENT_STORAGE_DIR .. "drafts.json"
    HALOARMORY.COMPUTER.EMAIL.CLIENT_FAVORITES_FILE = HALOARMORY.COMPUTER.EMAIL.CLIENT_STORAGE_DIR .. "favorites.json"
    
    HALOARMORY.COMPUTER.EMAIL.JoinReminderDelay = 120
    HALOARMORY.COMPUTER.EMAIL.ToastHoldSeconds = 5

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
