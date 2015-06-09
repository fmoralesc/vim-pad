" vim: set fdm=marker fdc=2 :

if !has("python") && !has("python3")
    finish
endif

if has("python")
    let s:python = "python"
else
    let s:python = "python3"
endif
exe s:python . ' import vim'
exe s:python . ' import pad.plugin'
exe s:python . ' import pad.timestamps'
exe s:python . ' pad_plugin = pad.plugin.PadPlugin()'

function! pad#PadCmd(args, bang)
    let arg_data = split(a:args, ' ')
    if arg_data[0] =~ '\(new\|ls\|search\|this\)'
        let l:args = join(arg_data[1:], ' ')
        if arg_data[0] == 'ls'
            execute s:python . " pad_plugin.ls('".l:args."', '".a:bang."')"
        elseif arg_data[0] == 'search'
            execute s:python . " pad_plugin.search('".l:args."', '".a:bang."')"
        elseif arg_data[0] == 'new'
            if a:bang != '!'
                execute s:python . ' pad_plugin.new(text="'.l:args.'")'
            else
                let pth = expand('%:p:h'). '/' . g:pad#local_dir . "/"
                execute s:python . ' pad_plugin.new(text="'.l:args.
                            \'", path="' . pth . '+ pad.timestamps.timestamp())'
            endif
        "only allow 'this' if g:pad#local_dir is set
        elseif arg_data[0] == 'this' && g:pad#local_dir != ''
            let pth = expand('%:p:h'). '/' . g:pad#local_dir . "/" .
                        \ expand('%:t'). '.txt'
            execute s:python . ' pad_plugin.new(text="' .expand('%:t').
                        \'", path="'.pth.'")'
        endif
    endif
endfunction

function! pad#PadCmdComplete(A,L,P)
    let cmd_args = split(a:L, ' ', 1)[1:]
    echom string(cmd_args)
    if len(cmd_args) == 1
        let options = "ls\nnew\nsearch"
        "only complete 'this' is g:pad#local_dir is set
        if g:pad#local_dir != ''
            let options .= "\nthis"
        endif
        return options
    else
        return ""
    endif
endfunction

function! pad#Open(path, first_line, query)
    exe s:python . ' pad_plugin.open("'. a:path .
                \'", "' . a:first_line .
                \'", "'. a:query . '")'
endfunction

function! pad#SearchPads()
    exe s:python . ' pad_plugin.search()'
endfunction

function! pad#GlobalIncrementalSearch(open)
    exe s:python . ' pad_plugin.global_incremental_search(bool(int(vim.eval("a:open"))))'
endfunction
