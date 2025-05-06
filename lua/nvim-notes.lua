local sql = require("db")
local floating_window = require("floating-window")

local api = vim.api

--- nvim-notes module.
--- Functions and config for
--- using nvim-notes plugin.
local M = {}

---@type Current|table<nil>
local current_note = {}

---@type boolean
local is_editing = false

---@type number
local editing_id

---@type NvimNotesConfig
M.config = {
  db_url = "nvim-notes.db",
  delimiter = ";;",
  empty_line = "||EMPTY-LINE||",
  symbol = "⭐",
  window = {
    height = 0.7,
    width = 0.8,
  },
}

---@type fun(): nil Merge M.config and user config
---@param default NvimNotesConfig
---@param user_config NvimNotesConfig
M._merge_tables = function(default, user_config)
  for idx, value in pairs(user_config) do
    if type(value) == "table" and type(default[idx]) == "table" then
      -- merge nested tables
      M._merge_tables(default[idx], value)
    else
      default[idx] = value
    end
  end
end

---@type fun(): nil
---@param config NvimNotesConfig
M.setup = function(config)
  if config then
    M._merge_tables(M.config, config)
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
  current_note.file = api.nvim_buf_get_name(0)
  current_note.line = api.nvim_win_get_cursor(0)[1]

  floating_window.open(M.config.window)
end

---@type fun(): boolean|nil Update existing note(if is_editing) or save new note
local _save = function()
  ---@type boolean|nil
  local ok

  if is_editing then
    ok = sql.update(editing_id, current_note.note)
  else
    ok = sql.create(current_note)
  end

  return ok
end

---@type fun(): nil Save current note
M.save = function()
  ---@type string[]
  local txt = api.nvim_buf_get_lines(0, 0, -1, false)
  for idx, line in ipairs(txt) do
    if string.len(line) == 0 then
      -- Replace all empty lines with ||EMPTY-LINE|| to preserve empty lines
      txt[idx] = M.config.empty_line
    end
  end

  -- Escape " with \
  -- Replace ' and ` with \"
  -- TODO: Find a better solution
  -- preferably escaping rather than replacing
  -- in order to keep the notes in their original state
  current_note.note = table.concat(txt, ";;")
  current_note.note = string.gsub(current_note.note, '"', '\\"')
  current_note.note = string.gsub(current_note.note, "'", '\\"')
  current_note.note = string.gsub(current_note.note, "`", '\\"')

  ---@type boolean|nil
  local saved = _save()
  if not saved then
    return
  end

  floating_window.close()
  current_note = {}

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

  current_note.file = api.nvim_buf_get_name(0)
  current_note.line = api.nvim_win_get_cursor(0)[1]

  ---@type number
  local buf = floating_window.open(M.config.window)
  if not buf then
    return
  end

  for _, note in ipairs(all_notes) do
    if note.file == current_note.file and tonumber(note.line) == tonumber(current_note.line) then
      editing_id = note.id

      note.note = string.gsub(note.note, '\\"', '"')

      ---@type table<string>
      local lines = {}

      for part in string.gmatch(note.note, "([^" .. M.config.delimiter .. "]+)") do
        table.insert(lines, part)
      end

      -- show empty lines as empty
      for idx, line in ipairs(lines) do
        if line == M.config.empty_line then
          lines[idx] = ""
        end
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

  current_note.file = api.nvim_buf_get_name(0)
  current_note.line = api.nvim_win_get_cursor(0)[1]

  for _, note in ipairs(all_notes) do
    if note.file == current_note.file and tonumber(note.line) == tonumber(current_note.line) then
      ---@type boolean|nil
      local ok = sql.delete(note.id)
      if not ok then
        return
      end

      vim.fn.sign_unplace("Note", { buffer = current_note.file, id = note.id })
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
