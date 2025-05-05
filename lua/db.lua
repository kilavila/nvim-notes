local sqlite = require("sqlite")

--- Database module.
--- Functions for connecting, creating,
--- updating and removing items from
--- SQLite database.
local M = {}

---@type SQLiteConfig
M.config = {
  db = nil,
  url = nil,
}

---@type fun(): nil Tell SQLite which DB to use
---@param url string SQLite DB file path
M.setup = function(url)
  M.config.url = url
end

---@type fun(): table|nil Connect to SQLite DB
M.connect = function()
  M.db = sqlite:open(M.config.url)

  if not M.db then
    print("Could not connect to database!")
    return
  end

  return M.db
end

---@type fun(): nil Close connection to SQLite DB
M.disconnect = function()
  M.db:close()
end

---@type fun(): nil Create notes table if not exists
M.create_table = function()
  M.connect()

  M.db:eval([[
		CREATE TABLE IF NOT EXISTS notes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			file TEXT NOT NULL,
			line TEXT NOT NULL,
			note TEXT NOT NULL
		);
	]])

  M.disconnect()
end

---@type fun(): boolean|nil Update a note in DB
---@param id number Note ID
---@param note string Note to save, should be concatenated with ;;
M.update = function(id, note)
  M.connect()

  note = "'" .. note .. "'"

  ---@type boolean
  local ok = M.db:eval("UPDATE notes SET note = " .. note .. " WHERE id = " .. id .. ";")
  if not ok then
    M.disconnect()
    print("Could not update note!")
    return
  end

  M.disconnect()
  return ok
end

---@type fun(): boolean|nil Create new note in DB
---@param current Current
M.create = function(current)
  M.connect()

  current.file = "'" .. current.file .. "'"
  current.line = "'" .. current.line .. "'"
  current.note = "'" .. current.note .. "'"

  ---@type string
  local sql_str = current.file .. ", " .. current.line .. ", " .. current.note
  ---@type boolean
  local ok = M.db:eval("INSERT INTO notes (file, line, note) VALUES (" .. sql_str .. ")")

  if not ok then
    M.disconnect()
    print("Could not create note!")
    return
  end

  M.disconnect()
  return ok
end

---@type fun(): table|nil Get all notes from DB
M.get_all = function()
  M.connect()

  ---@type table|boolean|nil
  local notes = M.db:eval("SELECT * FROM notes;")
  if type(notes) == "boolean" then
    M.disconnect()
    return
  end

  M.disconnect()
  return notes
end

---@type fun(): boolean|nil Delete a note from DB
---@param id number Note ID
M.delete = function(id)
  M.connect()

  ---@type boolean
  local ok = M.db:eval("DELETE FROM notes WHERE id = " .. id .. ";")

  if not ok then
    M.disconnect()
    print("Could not delete note!")
    return
  end

  M.disconnect()
  return ok
end

return M
