" vim: set fdm=marker fdc=2:

" File:                 pad.vim
" Description:          Quick-notetaking for vim.
" Author:               Felipe Morales
" Version:              1.1

" Must we load? {{{1
if (exists("g:loaded_pad") && g:loaded_pad) || &cp || (!has("python") && !has("python3"))
    finish
endif
let g:loaded_pad = 1 "}}}

" Default Settings: {{{1
"
" Dirs: {{{2
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
if !exists('g:pad#sources')
    let g:pad#sources = ['dir', 'local']
endif
if !exists('g:pad#local_dir')
    let g:pad#local_dir = 'notes'
endif
" Files: {{{2
if !exists('g:pad#default_format')
    let g:pad#default_format = "markdown"
endif
if !exists('g:pad#default_file_extension')
    let g:pad#default_file_extension = ''
endif
if !exists('g:pad#ignored_extensions')
    let g:pad#ignored_extensions = ["pdf", "odt", "docx", "doc"]
endif
if !exists('g:pad#rename_files')
    let g:pad#rename_files = 1
endif
if !exists('g:pad#title_first_line')
    let g:pad#title_first_line = 0
endif
if !exists('g:pad#modeline_position')
    let g:pad#modeline_position = 'bottom'
endif
" Window: {{{2
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
" Search: {{{2
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
if !exists('g:pad#exclude_dirnames')
    let g:pad#exclude_dirnames = ''
endif
" Display: {{{2
if !exists('g:pad#read_nchars_from_files')
    let g:pad#read_nchars_from_files = 200
endif
if !exists('g:pad#highlighting_variant')
    let g:pad#highlighting_variant = 0
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
" Mappings: {{{2
if !exists('g:pad#set_mappings')
    let g:pad#set_mappings = 1
endif
if !exists('g:pad#silent_on_mappings_fail')
    let g:pad#silent_on_mappings_fail = 0
endif
if !exists('g:pad#maps#list')
    let g:pad#maps#list = ["<leader><esc>", "<C-esc>"]
endif
if !exists('g:pad#maps#new')
    let g:pad#maps#new = ["<leader>n", "<S-esc>"]
endif
if !exists('g:pad#maps#search')
    let g:pad#maps#search = "<leader>ss"
endif
if !exists('g:pad#maps#incsearch')
    let g:pad#maps#incsearch = "<leader>s<leader>"
endif
if !exists('g:pad#maps#newsilent')
    let g:pad#maps#newsilent = "<leader>s!"
endif

" Commands: {{{1
"
" Creates a new note
command! -nargs=+ -bang -complete=custom,pad#PadCmdComplete Pad call pad#PadCmd('<args>', '<bang>')

" Autocommands: {{{1
" allow multiple vim instances to open the notes, deleting the swap file.
exe "au! SwapExists ".g:pad#dir."/* let v:swapchoice='d'"

" Key Mappings: {{{1

" <Plug> maps: {{{2
noremap <silent> <unique> <Plug>(pad-list) <esc>:Pad ls<CR>
noremap <silent> <unique> <Plug>(pad-new) <esc>:Pad new<CR>
noremap <silent> <unique> <Plug>(pad-search) :call pad#SearchPads()<cr>
noremap <silent> <unique> <Plug>(pad-incremental-search) :call pad#GlobalIncrementalSearch(1)<cr>
noremap <silent> <unique> <Plug>(pad-incremental-new-note) :call pad#GlobalIncrementalSearch(0)<cr>
if g:pad#set_mappings > 1
    inoremap <silent> <unique> <Plug>(pad-new) <esc>:Pad new<CR>
    inoremap <silent> <unique> <Plug>(pad-list) <esc>:Pad ls<CR>
endif

" You can set custom bindings by re-mapping the previous ones.
" For example, you can add the following to your vimrc:
"
"     nmap ,pl <Plug>(pad-list)
"
" If you want disable the default_mappings, set
" g:pad#use_default_mappings to 0

function! s:CreateMapping(key, action, ...) "{{{2
    if type(a:key) == type([]) && len(a:key) == 2
        let l:key = a:key[has("gui_running")]
    else
        let l:key = a:key
    endif

    " this allows calling this function to create insert-mode only mappings
    "   call s:CreateMapping(",pl", "pad-list", [2])
    " (this is currently unused)
    if a:0 > 0
        let l:modes_range = a:1
    else
        let l:modes_range = range(1, g:pad#set_mappings)
    endif

    for l:mode_idx in l:modes_range
        let l:mode = l:mode_idx == 1 ? "nmap" : "imap"
        try
            execute "silent " . l:mode . " <unique> " . l:key . " <Plug>(" . a:action . ")"
        catch /E227/
            if g:pad#silent_on_mappings_fail < 1
                echom "[vim-pad] " . l:key . " in " . (l:mode_idx == 1 ? "normal" : "insert") . " mode is already mapped."
            endif
        endtry
    endfor
endfunction

" Set maps, if wanted: {{{2
if g:pad#set_mappings > 0
    call s:CreateMapping(g:pad#maps#search, "pad-search")
    call s:CreateMapping(g:pad#maps#incsearch, "pad-incremental-search")
    call s:CreateMapping(g:pad#maps#newsilent, "pad-incremental-new-note")
    call s:CreateMapping(g:pad#maps#list, "pad-list")
    call s:CreateMapping(g:pad#maps#new, "pad-new")
endif
