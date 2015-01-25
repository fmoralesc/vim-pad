" vim: set tw=100:
setlocal fileencoding=utf-8
setlocal cursorline
setlocal buftype=nofile
setlocal noswapfile
setlocal nowrap
setlocal nobuflisted
setlocal nomodified
setlocal conceallevel=2
setlocal concealcursor=nc
setlocal statusline=%#PreCondit#\ vim-pad%=%#Comment#
setlocal statusline+=%#Special#q%#Comment#:close\ 
if has("python") || has("python3")
    if has("python")
        let b:python = "python"
    else
        let b:python = "python3"
    endif
    setlocal statusline+=%#Special#dd%#Comment#:delete\ 
    setlocal statusline+=%#Special#[-+]a%#Comment#:[un]archive\ 
    setlocal statusline+=%#Special#[-+]f%#Comment#:move\ [from\|to]\ 
    setlocal statusline+=%#Special#<s-f>%#Comment#:search\ 
    setlocal statusline+=%#Special#<s-s>%#Comment#:sort\ 
    noremap <buffer> <silent> <enter> :exe b:python . " pad_plugin.list.edit()"<cr>
    noremap <buffer> <silent> dd :exe b:python . " pad_plugin.list.delete()"<cr>
    noremap <buffer> <silent> +a :exe b:python . " pad_plugin.list.archive()"<cr>
    noremap <buffer> <silent> -a :exe b:python . " pad_plugin.list.unarchive()"<cr>
    noremap <buffer> <silent> +f :exe b:python . " pad_plugin.list.move_to_folder()"<cr>
    noremap <buffer> <silent> -f :exe b:python . " pad_plugin.list.move_to_savedir()"<cr>
    noremap <buffer> <silent> <S-f> :exe b:python . " pad_plugin.list.incremental_search()"<cr>
    noremap <buffer> <silent> <S-s> :exe b:python . " pad_plugin.list.sort()"<cr>
endif
noremap <buffer> <silent> q :bw<cr>
if !exists("b:pad_query")
    let b:pad_query = ''
endif
