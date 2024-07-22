local PersistantStorage = require("plugins.persistantStorage.persistantStorage")

---@type Plugin
local plugin = ...
plugin.name = "persistantStorage"
plugin.author = "gart"

PersistantStorage.defaultSettings = {
	musicEnabled = "true",
	colorblindModeEnabled = "false",
}
