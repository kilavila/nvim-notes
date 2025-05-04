if exists('g:loaded_nvim_notes') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! NotesNew lua require'nvim-notes'.new()
command! NotesSave lua require'nvim-notes'.save()
command! NotesLoad lua require'nvim-notes'.load()
command! NotesEdit lua require'nvim-notes'.edit()
command! NotesDelete lua require'nvim-notes'.delete()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_nvim_notes = 1
