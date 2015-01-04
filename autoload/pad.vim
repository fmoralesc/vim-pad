" vim: set fdm=marker fdc=2 :

" Pad Information:  {{{1
 
" Gets the title of the currently selected pad
function! pad#GetPadTitle()
    if getline('.') != ""
        try
            let retval = split(split(substitute(getline('.'), '↲','\n', "g"), '\n')[0], '\%u2e25 ')[1]
        catch /E684/
            let retval "EMPTY"
        endtry
        return retval
    endif
    return ""
endfunction

" Gets the human readable date of the currently selected pad
function! pad#GetPadHumanDate()
    if getline('.') != ""
        return split(split(getline('.'), ' │')[0], '@')[1]
    endif
    return ""
endfunction

" Gets the id of the currently selected pad
function! pad#GetPadId()
    if getline('.') != ""
        return split(getline('.'))[0]
    endif
    return ""
endfunction

" Operations: {{{1
if has("python")
    python import vim_pad

" Global {{{2

function! pad#PadCmd(args, bang)
    let arg_data = split(a:args, ' ')
    if arg_data[0] =~ '\(new\|ls\|this\)'
        let l:args = join(arg_data[1:], ' ')
        if arg_data[0] == 'ls'
            execute "python vim_pad.handler.display('".l:args."', '".a:bang."')"
        elseif arg_data[0] == 'new'
            execute "python vim_pad.handler.open_pad(first_line='".l:args."')"
        elseif arg_data[0] == 'this' && g:pad#local_dir != '' "only allow this if g:pad#local_dir is set
            let pth = expand('%:p:h'). '/' . g:pad#local_dir . "/" . expand('%:t'). '.txt' 
            execute "python vim_pad.handler.open_pad(path='".pth."', first_line='".expand('%:t')."')"
            " make sure the directory exists when we try to save
            exe "au! BufWritePre,FileWritePre <buffer> call mkdir(fnamemodify('".pth."', ':h'), 'p')"
        endif
    endif
endfunction

function! pad#PadCmdComplete(A,L,P)
    let cmd_args = split(a:L, ' ', 1)[1:]
    echom string(cmd_args)
    if len(cmd_args) == 1
        let options = "ls\nnew"
        if g:pad#local_dir != '' "only complete 'this' is g:pad#local_dir is set
            let options .= "\nthis"
        endif
        return options
    else
        return ""
    endif
endfunction

function! pad#OpenPad(title)
    call pad#PadCmd('new '.a:title, '')
endfunction

function! pad#ListPads(query, archive)
    call pad#PadCmd('ls '.a:query, a:archive)
endfunction

function! pad#SearchPads()
    python vim_pad.handler.search_pads()
endfunction

function! pad#GlobalIncrementalSearch(open)
    python import vim
    python vim_pad.handler.global_incremental_search(bool(int(vim.eval('a:open'))))
endfunction

" Pad local {{{2

function! pad#UpdatePad()
    python vim_pad.pad_local.update()
endfunction

function! pad#DeleteThis()
    python vim_pad.pad_local.delete()
endfunction

function! pad#AddModeline()
    python vim_pad.pad_local.add_modeline()
endfunction

function! pad#MoveToFolder()
    python vim_pad.pad_local.move_to_folder()
endfunction

function! pad#MoveToSaveDir()
    python vim_pad.pad_local.move_to_savedir()
endfunction

function! pad#Archive()
    python vim_pad.pad_local.archive()
endfunction

function! pad#Unarchive()
    python vim_pad.pad_local.unarchive()
endfunction

" List local {{{2

function! pad#EditPad()
    python vim_pad.list_local.edit_pad()
endfunction

function! pad#DeletePad()
    python vim_pad.list_local.delete_pad()
endfunction

function! pad#MovePad()
    python vim_pad.list_local.move_to_folder()
endfunction

function! pad#MovePadToSaveDir()
    python vim_pad.list_local.move_to_savedir()
endfunction

function! pad#ArchivePad()
    python vim_pad.list_local.archive_pad()
endfunction

function! pad#UnarchivePad()
    python vim_pad.list_local.unarchive_pad()
endfunction

function! pad#IncrementalSearch()
    python vim_pad.list_local.incremental_search()
endfunction

function! pad#Sort()
    let s:sort_type = input("[pad] sort list by (title=1, tags=2, date=3): ", "1")
    if s:sort_type != ""
            execute "python vim_pad.list_local.sort('".s:sort_type."')"
    endif
    redraw!
endfunction

endif
