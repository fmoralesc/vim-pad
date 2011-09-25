syn match PadTimestamp /^.\{-}│/ contains=PadName
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadFT /\%u25aa.*\%u25aa/
syn match PadHashTag /\(@\|#\)\a\+/
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\)\@=/ contains=PadHashTag,PadFT

hi! link PadTimestamp Comment
hi! link Conceal PadTimestamp
hi! link PadHashTag Identifier
hi! link PadFT Type
hi! PadSummary gui=bold
hi! link PadNewLine Comment

let b:buffer_syntax = "pad"
