---@meta

---@class NvimWindowConfig
---@field height? number
---@field width? number

---@class NvimNotesConfig
---@field db_url? string (Optional) Path to SQLite database
---@field symbol? string (Optional) Symbol to show in sign column
---@field delimiter? string (Optional) Delimiter for multiline notes
---@field empty_line? string (Optional) Indicates empty lines
---@field window? NvimWindowConfig

---@class Current
---@field file string Path to buffer
---@field line string|number Line number in buffer
---@field note string Note text

---@class SQLiteConfig
---@field url string|nil
---@field db table|nil

---@class NvimNote
---@field file string
---@field id number
---@field line string
---@field note string
