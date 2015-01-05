" vim: set fdm=marker fdc=2:

" File:			pad.vim
" Description:	        Quick-notetaking for vim.
" Author:		Felipe Morales
" Version:		0.8

" Must we load? {{{1
if (exists("g:loaded_pad") && g:loaded_pad)	|| &cp 	|| has("python") == 0
	finish
endif
let g:loaded_pad = 1 "}}}

" Default Settings: {{{1
"
if !exists('g:pad#dir')
    if exists('g:pad_dir')
        let g:pad#dir = g:pad_dir
        echom "vim-pad: g:pad_dir was used for g:pad#dir. Please update your configuration."
    elseif filewritable(expand("~/notes")) == 2
        let g:pad#dir = "~/notes"
    else
        let g:pad#dir = ""
    endif
else
    if filewritable(expand(eval("g:pad#dir"))) != 2
        let g:pad#dir = ""
    endif
endif
if !exists('g:pad#local_dir')
    let g:pad#local_dir = 'notes'
endif
if !exists('g:pad#default_format')
    let g:pad#default_format = "markdown"
endif
if !exists('g:pad#window_height')
    let g:pad#window_height = 5
endif
if !exists('g:pad#window_width')
    let g:pad#window_width = 40
endif
if !exists('g:pad#position')
    let g:pad#position = { "list" : "bottom", "pads": "bottom" }
endif
if !exists('g:pad#open_in_split')
    let g:pad#open_in_split = 1
endif
if !exists('g:pad#search_backend')
    let g:pad#search_backend = "grep"
endif
if !exists('g:pad#search_ignorecase')
    let g:pad#search_ignorecase = 1
endif
if !exists('g:pad#query_filenames')
    let g:pad#query_filenames = 0
endif
if !exists('g:pad#query_dirnames')
    let g:pad#query_dirnames = 1
endif
if !exists('g:pad#read_nchars_from_files')
    let g:pad#read_nchars_from_files = 200
endif
if !exists('g:pad#highlighting_variant')
    let g:pad#highlighting_variant = 0
endif
if !exists('g:pad#use_default_mappings')
    let g:pad#use_default_mappings = 1
endif
if !exists('g:pad#silent_on_mappings_fail')
    let g:pad#silent_on_mappings_fail = 0
endif
if !exists('g:pad#modeline_position')
    let g:pad#modeline_position = 'bottom'
endif
if !exists('g:pad#highlight_query')
    let g:pad#highlight_query = 1
endif
if !exists('g:pad#jumpto_query')
    let g:pad#jumpto_query = 1
endif
if !exists('g:pad#show_dir')
    let g:pad#show_dir = 1
endif
if !exists('g:pad#default_file_extension')
    let g:pad#default_file_extension = ''
endif
if !exists('g:pad#rename_files')
    let g:pad#rename_files = 1
endif
if !exists('g:pad#title_first_line')
    let g:pad#title_first_line = 0
endif

" Commands: {{{1
"
" Creates a new note
command! -nargs=? -bang -complete=custom,pad#PadCmdComplete Pad call pad#PadCmd('<args>', '<bang>')
command! -nargs=? -bang ListPads call pad#PadCmd('ls <args>', '<bang>')
command! -nargs=? OpenPad call pad#PadCmd('new <args>', '')

" Key Mappings: {{{1
"
noremap <silent> <unique> <Plug>(pad-list) <esc>:Pad ls<CR>
inoremap <silent> <unique> <Plug>(pad-list) <esc>:Pad ls<CR>
noremap <silent> <unique>  <Plug>(pad-new) <esc>:Pad new<CR>
inoremap <silent> <unique> <Plug>(pad-new) <esc>:Pad new<CR>
noremap <silent> <unique> <Plug>(pad-search) :call pad#SearchPads()<cr>
noremap <silent> <unique> <Plug>(pad-incremental-search) :call pad#GlobalIncrementalSearch(1)<cr>
noremap <silent> <unique> <PLug>(pad-incremental-new-note) :call pad#GlobalIncrementalSearch(0)<cr>

" You can set custom bindings by re-mapping the previous ones.
" For example, you can add the following to your vimrc:
" 
"     nmap ,pl <Plug>ListPads
"
" If you want disable the default_mappings, set
" g:pad#use_default_mappings to 0

function! s:CreateMapping(key, action, modename)
    let mode = a:modename == "normal" ? "nmap" : "imap"

    try
        execute "silent " . mode . " <unique> " . a:key . " <Plug>(" . a:action . ")"
    catch /E227/
        if g:pad#silent_on_mappings_fail < 1
            echom "[vim-pad] " . a:key . " in " . a:modename . " mode is already mapped."
        endif
    endtry
endfunction

if g:pad#use_default_mappings > 0
    call s:CreateMapping("<leader>ss", "pad-search", "normal")
    call s:CreateMapping("<leader>s<leader>", "pad-incremental-search", "normal")
    call s:CreateMapping("<leader>s!", "pad-incremental-new-note", "normal")
    if has("gui_running")
        call s:CreateMapping("<C-esc>", "pad-list", "normal")
        call s:CreateMapping("<S-esc>", "pad-new", "normal")
    else " the previous mappings don't work in the terminal
        call s:CreateMapping("<leader><esc>", "pad-list", "normal")
        call s:CreateMapping("<leader>n", "pad-new", "normal")
    endif

    if g:pad#use_default_mappings > 1
        if has("gui_running")
            call s:CreateMapping("<C-esc>", "pad-list", "insert")
            call s:CreateMapping("<S-esc>", "pad-new", "insert")
        else
            call s:CreateMapping("<leader><esc>", "pad-list", "insert")
            call s:CreateMapping("<leader>n", "pad-new", "insert")
        endif
    endif
endif
