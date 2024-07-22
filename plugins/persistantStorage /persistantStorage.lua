local QB = require("main.queryBuilder")

---@class PersistantStorage
local PersistantStorage = {}

---@type SQLite
PersistantStorage.sqlite = nil

---@type table<string, string>
PersistantStorage.defaultSettings = {}

---@param query string | SqliteQueryBuilder
function PersistantStorage.query(query)
	if type(query) == "table" then
		query = query:build()
		-- print("Database: " .. query)
		local res = PersistantStorage.sqlite:query(query)

		if not res then
			error("Database query failed: " .. query)
		end
		return res
	else
		assert(type(query) == "string", "expected string, got " .. type(query))
		-- print("Database: " .. query)
		local res = PersistantStorage.sqlite:query(query)
		if not res then
			error("Database query failed: " .. query)
		end
		return res
	end
end

---@param db SQLite
function PersistantStorage.init(db)
	local dbPath = "./plugins/persistantStorage/storage.db"

	if not db then
		if not io.open(dbPath, "r") then
			local f = io.open(dbPath, "w")

			assert(f, "Failed to create database file")

			f:close()
		end
	end

	db = db or SQLite(dbPath)
	PersistantStorage.sqlite = db

	PersistantStorage.query(QB.create():createTable("settings", {
		{
			name = "id",
			type = "INTEGER",
			primaryKey = true,
			autoIncrement = true,
		},
		{
			name = "playerId",
			type = "INTEGER",
		},
		{
			name = "key",
			type = "TEXT",
		},
		{
			name = "value",
			type = "TEXT",
		},
	}))
end

function PersistantStorage.loadPlayers()
	for _, player in ipairs(players.getNonBots()) do
		PersistantStorage.loadPlayer(player)
	end
end

---@param player Player
function PersistantStorage.loadPlayer(player)
	local settings = PersistantStorage.query(
		QB.create():select():from("settings"):where({ column = "playerId", operator = "=", value = player.phoneNumber })
	)

	if type(settings) == "table" then
		player.data.PersistantStorage = player.data.PersistantStorage or {}
		for _, setting in pairs(settings) do
			local key = setting[3]
			local value = setting[4]

			player.data.PersistantStorage[key] = value
		end
	end
end

---@param player Player
function PersistantStorage.savePlayer(player)
	local settings = player.data.PersistantStorage or {}

	for key, value in pairs(settings) do
		local existingSetting = PersistantStorage.query(QB.create():select():from("settings"):where({
			{ column = "playerId", operator = "=", value = player.phoneNumber },
			{ column = "key", operator = "=", value = key },
		}))

		-- create if not exists
		if type(existingSetting) == "table" and existingSetting[1] then
			PersistantStorage.query(QB.create()
				:update("settings", {
					value = value,
				})
				:where({
					{ column = "playerId", operator = "=", value = player.phoneNumber },
					{ column = "key", operator = "=", value = key },
				}))
		else
			PersistantStorage.query(QB.create():insert("settings", {
				playerId = player.phoneNumber,
				key = key,
				value = value,
			}))
		end
	end
end

---@param player Player
---@param key string
---@return string
function PersistantStorage.get(player, key)
	if not player.data.PersistantStorage then
		PersistantStorage.loadPlayer(player)
		return player.data.PersistantStorage[key]
	else
		return player.data.PersistantStorage[key] or PersistantStorage.defaultSettings[key]
	end
end

---@param player Player
---@param key string
---@param value string
function PersistantStorage.set(player, key, value)
	player.data.PersistantStorage = player.data.PersistantStorage or {}
	player.data.PersistantStorage[key] = value
	PersistantStorage.savePlayer(player)
end

return PersistantStorage
