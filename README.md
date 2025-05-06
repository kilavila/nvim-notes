# nvim-notes

This is a note taking plugin for Neovim(similar to <a href="https://github.com/RutaTang/quicknote.nvim">RutaTang/quicknote.nvim</a>).
Easily create, edit and delete notes related to a specific line number in a buffer.
The notes are saved in a SQLite database, either a global database or project specific databases.

<img src="./nvim-notes.jpg" />

## Installation
```lua
-- lazy

{
  "kilavila/nvim-notes",
  dependencies = { "kkharji/sqlite.lua" },
  config = function()
    require("nvim-notes").setup()
  end,
}
```

## Configuration
```lua
{
  -- All the configs are optional

  -- WARNING: By default nvim-notes creates a database in each project!
  -- the following config will make nvim-notes use a global database for all projects

  -- Path to SQLite DB
  -- "nvim-notes.db"   = new DB in each project(default)
  -- "~/nvim-notes.db" = global DB in home dir
  db_url = "~/nvim-notes.db",

  -- What symbol to show in the sign column
  -- Can be whatever: 📌 ⭐ 👉 ▶️ 🔖
  symbol = "⭐",

  -- Notes are saved in the DB as one long string
  -- the delimiter indicates line-breaks
  delimiter = ";;",

  -- Indicates empty lines in order
  -- to keep the notes format
  empty_line = "||EMPTY-LINE||",

  -- Size of the floating window
  window = {
    height = 0.7,
    width = 0.8,
  },
}
```

## Commands
There's no default keybinds for nvim-notes, but here are the available commands:

| Command | Description |
|---------|-------------|
| NotesNew | Create a new note on the current line |
| NotesEdit | Edit the note of the current line |
| NotesSave | Save the current note you are in(floating buffer) and closes the floating buffer |
| NotesDelete | Delete the note on the current line |
| NotesLoad | Reload the notes for the current buffer(happens automatically on BuffEnter) |

Exmaple mapping:
```lua
vim.keymap.set("n", "<leader>nn", ":NotesNew<cr>")
vim.keymap.set("n", "<leader>ns", ":NotesSave<cr>")
vim.keymap.set("n", "<leader>ne", ":NotesEdit<cr>")
vim.keymap.set("n", "<leader>nd", ":NotesDelete<cr>")
```

To close a note(floating buffer) without saving, just close it like any other window with `:q`.

## SQLite

You can also query the SQLite DB from the terminal if you need to.
F.ex if you deleted a file with notes in them, or if you just want to extract all notes for some reason:

```bash
sqlite3 path/to/nvim-notes.db "SELECT * FROM notes;"
```

## Issues
Single quotes: ' and backticks: ` have been a problem, so for now they will be replaced with quotes: ".

[Create a new issue](https://github.com/kilavila/nvim-notes/issues) if you have any other problems.

## Todo

- [ ] Escape special characters.
- [ ] Listing all notes/searching for/in notes.
- [ ] Jump to next/previous note in current buffer?
