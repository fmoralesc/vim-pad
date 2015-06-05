if !exists('g:pad#plugin#hypertext') || g:pad#plugin#hypertext == 0
    finish
endif

nnoremap <localleader>pf :call pad#hypertext#FollowLink()<cr>
