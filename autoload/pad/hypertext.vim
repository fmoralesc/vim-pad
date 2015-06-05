function! pad#hypertext#FollowLink()
    let l:o_isfname = &isfname
    set isfname+=:
    let note = expand('<cfile>')
    let &isfname = l:o_isfname
    " TODO: make the pattern to extract the path from configurable
    let link_data = split(note, 'note:', 1)
    if len(link_data) > 1
        bdelete
        call pad#Open(g:pad#dir . '/'. link_data[1], '', '')
    endif
endfunction
