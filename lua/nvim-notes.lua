local sqlite = require("sqlite")
local db

local floating_window = require("floating-window")
local api = vim.api

local M = {}
local current = {}
local delimiter = ";;"

-- TODO: CREATE "IS EDITING" LOGIC
-- ON SAVE CHECK TO INSERT OR UPDATE

M.config = {
	db_url = "nvim-notes.db",
	note_symbol = "⭐",
}

M.setup = function(config)
	if config and config.db_url then
		M.config.db_url = config.db_url
	end

	db = sqlite:open(M.config.db_url)

	if not db then
		print("Could not connect to database...")
		return
	end

	vim.fn.sign_define("Note", {
		text = M.config.note_symbol,
		texthl = "Note",
		numhl = "Note",
	})

	db:eval([[
		CREATE TABLE IF NOT EXISTS notes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			file TEXT NOT NULL,
			line TEXT NOT NULL,
			note TEXT NOT NULL
		);
	]])
	db:close()

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(ev)
			M.load(ev.file)
		end,
	})
end

M.new = function()
	current.file = api.nvim_buf_get_name(0)
	current.line = api.nvim_win_get_cursor(0)[1]

	floating_window.open()
end

M.save = function()
	db = sqlite:open(M.config.db_url)

	if not db then
		print("Could not connect to database...")
		return
	end

	local txt = api.nvim_buf_get_lines(0, 0, -1, false)
	current.note = table.concat(txt, ";;")

	current.file = "'" .. current.file .. "'"
	current.line = "'" .. current.line .. "'"
	current.note = "'" .. current.note .. "'"

	local sql_str = current.file .. ", " .. current.line .. ", " .. current.note
	local ok = db:eval("INSERT INTO notes (file, line, note) VALUES (" .. sql_str .. ")")

	if not ok then
		return
	end

	local notes = db:eval("SELECT * FROM notes;")

	floating_window.close()
	current = {}
	db:close()

	if type(notes) == "boolean" then
		return
	end

	local all_notes = {}
	for _, v in ipairs(notes) do
		table.insert(all_notes, v)
	end

	local last_note = all_notes[table.maxn(all_notes)]
	vim.fn.sign_place(last_note.id, "Note", "Note", last_note.file, { lnum = last_note.line })
end

M.edit = function()
	db = sqlite:open(M.config.db_url)

	if not db then
		print("Could not connect to database...")
		return
	end

	local notes = db:eval("SELECT * FROM notes;")
	db:close()

	if type(notes) == "boolean" then
		return
	end

	local all_notes = {}
	for _, v in ipairs(notes) do
		table.insert(all_notes, v)
	end

	current.file = api.nvim_buf_get_name(0)
	current.line = api.nvim_win_get_cursor(0)[1]

	local buf = floating_window.open()

	if not buf then
		return
	end

	for _, note in ipairs(all_notes) do
		if note.file == current.file and tonumber(note.line) == tonumber(current.line) then
			local lines = {}

			for part in string.gmatch(note.note, "([^" .. delimiter .. "]+)") do
				table.insert(lines, part)
			end

			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		end
	end
end

M.delete = function()
	db = sqlite:open(M.config.db_url)

	if not db then
		print("Could not connect to database...")
		return
	end

	local notes = db:eval("SELECT * FROM notes;")
	local all_notes = {}

	if type(notes) == "boolean" then
		return
	end

	for _, v in ipairs(notes) do
		table.insert(all_notes, v)
	end

	current.file = api.nvim_buf_get_name(0)
	current.line = api.nvim_win_get_cursor(0)[1]

	for _, note in ipairs(all_notes) do
		if note.file == current.file and tonumber(note.line) == tonumber(current.line) then
			vim.fn.sign_unplace("Note", { buffer = current.file, id = note.id })
			db:eval("DELETE FROM notes WHERE id = " .. note.id .. ";")
			db:close()
		end
	end
end

M.load = function(file)
	db = sqlite:open(M.config.db_url)

	if not db then
		print("Could not connect to database...")
		return
	end

	local notes = db:eval("SELECT * FROM notes;")
	db:close()

	if type(notes) == "boolean" then
		return
	end

	local all_notes = {}
	for _, v in ipairs(notes) do
		table.insert(all_notes, v)
	end

	for _, note in ipairs(all_notes) do
		if note.file == file then
			vim.fn.sign_place(note.id, "Note", "Note", note.file, { lnum = note.line })
		end
	end
end

return M
