syn match PadTimestamp /^.\{-}│/ contains=PadName
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\)\@=/ contains=PadHashTag,PadEmptyLabel

hi! link PadTimestamp Comment
hi! link Conceal PadTimestamp
hi! link PadHashTag Identifier
hi! link PadEmptyLabel Error
hi! link PadFT Type
hi! PadSummary gui=bold
hi! link PadNewLine Comment

let b:buffer_syntax = "pad"
