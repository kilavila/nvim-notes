local api = vim.api
---@type number
local buf
---@type number
local win

M = {}

---@type fun(): number Open a floating buffer
---@param window NvimWindowConfig
M.open = function(window)
  buf = api.nvim_create_buf(false, true)
  ---@type number
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "bufferlist")

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  ---@type number
  local win_height = math.ceil(height * window.height - 4)
  ---@type number
  local win_width = math.ceil(width * window.width)
  ---@type number
  local row = math.ceil((height - win_height) / 2 - 1)
  ---@type number
  local col = math.ceil((width - win_width) / 2)

  ---@type vim.api.keyset.win_config
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }

  ---@type vim.api.keyset.win_config
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  ---@type string
  local border_title = " nvim-notes "
  ---@type table<string>
  local border_lines = { "╭" .. border_title .. string.rep("─", win_width - string.len(border_title)) .. "╮" }
  ---@type string
  local middle_line = "│" .. string.rep(" ", win_width) .. "│"
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, "╰" .. string.rep("─", win_width) .. "╯")
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

  api.nvim_win_set_option(win, "cursorline", true)

  return buf
end

---@type fun(): nil Close the floating buffer
M.close = function()
  api.nvim_win_close(win, true)
end

return M
