syn match PadTimestamp /^.\{-}│/ contains=PadName,PadTimestampDelimiter
syn match PadTimestampDelimiter /│/ contained
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\|[.,]\)\@=/ contains=PadHashTag,PadEmptyLabel

hi! link PadTimestamp Comment
" For an alternative highlighting of dates, uncomment the following line.
" hi! link PadTimestamp Number
hi! link PadTimestampDelimiter Delimiter
hi! link Conceal PadTimestamp
hi! link PadHashTag Identifier
hi! link PadEmptyLabel Error
hi! link PadSummary Title
hi! link PadNewLine Comment

let b:buffer_syntax = "pad"
