" vim: set tw=100 :

let b:pad_modified = 0
au! BufWritePre <buffer> let b:pad_modified = eval(&modified)

if has("python") || has("python3")
    if has("python")
        let b:python = "python"
    else
        let b:python = "python3"
    endif
    exe b:python . " import pad.pad"
    au! BufLeave <buffer> exe b:python . " pad.pad.update()"
    noremap <silent> <buffer> <localleader>+m :exe b:python . " pad.pad.add_modeline()"<cr>
    noremap <silent> <buffer> <localleader>+f :exe b:python . " pad.pad.move_to_folder()"<cr>
    noremap <silent> <buffer> <localleader>-f :exe b:python . " pad.pad.move_to_savedir()"<cr>
    noremap <silent> <buffer> <localleader>+a :exe b:python . " pad.pad.archive()"<cr>
    noremap <silent> <buffer> <localleader>-a :exe b:python . " pad.pad.unarchive()"<cr>
    noremap <silent> <buffer> <localleader>dd :exe b:python . " pad.pad.delete()"<cr>
endif
