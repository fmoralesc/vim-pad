setlocal fileencoding=utf-8
setlocal cursorline
setlocal buftype=nofile
setlocal noswapfile
setlocal nowrap
setlocal nomodified
setlocal conceallevel=2
setlocal concealcursor=nc
noremap <buffer> <silent> <enter> :call pad#EditPad()<cr>
if has("gui_running")
	noremap <buffer> <silent> <delete> :call pad#DeletePad()<cr>
else
	noremap <buffer> <silent> dd :call pad#DeletePad()<cr>
endif
noremap <buffer> <silent> <localleader>+a :call pad#ArchivePad()<cr>
noremap <buffer> <silent> <localleader>-a :call pad#UnarchivePad()<cr>
noremap <buffer> <silent> <localleader>+f :call pad#MovePad()<cr>
noremap <buffer> <silent> <localleader>-f :call pad#MovePadToSaveDir()<cr>

noremap <buffer> <silent> <esc> :bw<cr>
noremap <buffer> <silent> <S-f> :call pad#IncrementalSearch()<cr>
noremap <buffer> <silent> <S-s> :call pad#Sort()<cr>
