" File:			pad.vim
" Description:	Quick-notetaking for vim.
" Author:		Felipe Morales
" Version:		0.4

if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif
let g:loaded_pad = 1

" Default Settings:
"
if !exists('g:pad_dir')
	if filewritable(expand("~/notes")) == 2
		let g:pad_dir = "~/notes"
	else
		let g:pad_dir = ""
	endif
else
	if filewritable(expand(eval("g:pad_dir"))) != 2
		let g:pad_dir = ""
	endif
endif
if !exists('g:pad_format')
	let g:pad_format = "markdown"
endif
if !exists('g:pad_window_height')
	let g:pad_window_height = 5
endif
if !exists('g:pad_search_backend')
	let g:pad_search_backend = "grep"
endif
if !exists('g:pad_search_ignorecase')
	let g:pad_search_ignorecase = 1
endif
if !exists('g:pad_read_nchars_from_files')
	let g:pad_read_nchars_from_files = 200
endif
if !exists('g:pad_highlighting_variant')
	let g:pad_highlighting_variant = 0
endif

" Commands:
"
command! OpenPad exec 'py pad.pad_open()'
command! -nargs=? ListPads exec "py pad.list_pads('<args>')"

" Key Mappings:
"
" IMPORTANT: Change this to your linking

if !exists('g:pad_custom_mappings') || g:pad_custom_mappings == 0
	noremap <silent> <C-esc> <esc>:ListPads<CR>
	inoremap <silent> <C-esc> <esc>:ListPads<CR>
	noremap <silent> <S-esc> <esc>:OpenPad<CR>
	inoremap <silent> <S-esc> <esc>:OpenPad<CR>
	noremap <silent> <leader>s  :py pad.search_pads()<cr>
endif

" To update the date when files are modified
execute "au! BufEnter" printf("%s*", g:pad_dir) ":let b:pad_modified = 0"
execute "au! BufWritePre" printf("%s*", g:pad_dir) ":let b:pad_modified = eval(&modified)"
execute "au! BufLeave" printf("%s*", g:pad_dir) ":py pad.pad_update()"

pyfile <sfile>:p:h/pad.py
python pad=Pad()
