setlocal cursorline
setlocal buftype=nofile
setlocal noswapfile
setlocal nowrap
setlocal listchars=extends:…,precedes:…
setlocal nomodified
setlocal conceallevel=2
setlocal concealcursor=nc
noremap <buffer> <silent> <enter> :py pad.edit_pad()<cr>
noremap <buffer> <silent> <delete> :py pad.delete_pad()<cr>
noremap <buffer> <silent> <esc> :bw<cr>
noremap <buffer> <silent> <S-f> :py pad.incremental_search()<cr>
