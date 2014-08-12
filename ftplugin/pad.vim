setlocal fileencoding=utf-8
setlocal cursorline
setlocal buftype=nofile
setlocal noswapfile
setlocal nowrap
setlocal nomodified
setlocal conceallevel=2
setlocal concealcursor=nc
noremap <buffer> <silent> <enter> :call pad#EditPad()<cr>
noremap <buffer> <silent> dd :call pad#DeletePad()<cr>
noremap <buffer> <silent> +a :call pad#ArchivePad()<cr>
noremap <buffer> <silent> -a :call pad#UnarchivePad()<cr>
noremap <buffer> <silent> +f :call pad#MovePad()<cr>
noremap <buffer> <silent> -f :call pad#MovePadToSaveDir()<cr>
noremap <buffer> <silent> q :bw<cr>
noremap <buffer> <silent> <S-f> :call pad#IncrementalSearch()<cr>
noremap <buffer> <silent> <S-s> :call pad#Sort()<cr>
if !exists("b:pad_query")
    let b:pad_query = ''
endif
