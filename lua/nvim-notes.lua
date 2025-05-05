local sql = require("db")
local floating_window = require("floating-window")

local api = vim.api

--- nvim-notes module.
--- Functions and config for
--- using nvim-notes plugin.
local M = {}
---@type Current|table<nil>
local current = {}
---@type boolean
local is_editing = false
---@type number
local editing_id

---@type NvimNotesConfig
M.config = {
  db_url = "nvim-notes.db",
  symbol = "⭐",
  delimiter = ";;",
}

---@type fun(): nil
---@param config NvimNotesConfig
M.setup = function(config)
  if config then
    if config.db_url then
      M.config.db_url = config.db_url
    end

    if config.symbol then
      M.config.symbol = config.symbol
    end

    if config.delimiter then
      M.config.delimiter = config.delimiter
    end
  end

  sql.setup(M.config.db_url)
  sql.create_table()

  vim.fn.sign_define("Note", {
    text = M.config.symbol,
    texthl = "Note",
    numhl = "Note",
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function(ev)
      M.load(ev.file)
    end,
  })
end

---@type fun(): nil Open the floating buffer for creating a new note
M.new = function()
  is_editing = false
  current.file = api.nvim_buf_get_name(0)
  current.line = api.nvim_win_get_cursor(0)[1]

  floating_window.open()
end

---@type fun(): boolean|nil Update existing note(if is_editing) or save new note
local _save = function()
  ---@type boolean|nil
  local ok

  if is_editing then
    ok = sql.update(editing_id, current.note)
  else
    ok = sql.create(current)
  end

  return ok
end

---@type fun(): nil Save current note
M.save = function()
  ---@type string[]
  local txt = api.nvim_buf_get_lines(0, 0, -1, false)
  current.note = table.concat(txt, ";;")

  ---@type boolean|nil
  local saved = _save()
  if not saved then
    return
  end

  floating_window.close()
  current = {}

  ---@type table<NvimNote>|nil
  local notes = sql.get_all()
  if not notes then
    return
  end

  ---@type table<NvimNote>
  local all_notes = {}
  for _, v in ipairs(notes) do
    table.insert(all_notes, v)
  end

  ---@type NvimNote
  local last_note = all_notes[table.maxn(all_notes)]
  vim.fn.sign_place(last_note.id, "Note", "Note", last_note.file, { lnum = last_note.line })
  is_editing = false
end

---@type fun(): nil Open note from current line in floating buffer
M.edit = function()
  is_editing = true

  ---@type table<NvimNote>|nil
  local notes = sql.get_all()
  if not notes then
    return
  end

  ---@type table<NvimNote>
  local all_notes = {}
  for _, v in ipairs(notes) do
    table.insert(all_notes, v)
  end

  current.file = api.nvim_buf_get_name(0)
  current.line = api.nvim_win_get_cursor(0)[1]

  ---@type number
  local buf = floating_window.open()
  if not buf then
    return
  end

  for _, note in ipairs(all_notes) do
    if note.file == current.file and tonumber(note.line) == tonumber(current.line) then
      editing_id = note.id
      ---@type table<string>
      local lines = {}

      for part in string.gmatch(note.note, "([^" .. M.config.delimiter .. "]+)") do
        table.insert(lines, part)
      end

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end
  end
end

---@type fun(): nil Delete note from current line
M.delete = function()
  ---@type table<NvimNote>|nil
  local notes = sql.get_all()
  if not notes then
    return
  end

  ---@type table<NvimNote>
  local all_notes = {}
  for _, v in ipairs(notes) do
    table.insert(all_notes, v)
  end

  current.file = api.nvim_buf_get_name(0)
  current.line = api.nvim_win_get_cursor(0)[1]

  for _, note in ipairs(all_notes) do
    if note.file == current.file and tonumber(note.line) == tonumber(current.line) then
      ---@type boolean|nil
      local ok = sql.delete(note.id)
      if not ok then
        return
      end

      vim.fn.sign_unplace("Note", { buffer = current.file, id = note.id })
    end
  end
end

---@type fun(): nil Load notes for current buffer
---@param file string
M.load = function(file)
  ---@type table<NvimNote>|nil
  local notes = sql.get_all()
  if not notes then
    return
  end

  ---@type table<NvimNote>
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
