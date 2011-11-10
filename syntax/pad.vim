syn match PadTimestamp /^.\{-}│/ contains=PadName,PadTimestampDelimiter
syn match PadTimestampDelimiter /│/ contained
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\|[.,]\)\@=/ contains=PadHashTag,PadEmptyLabel

if g:pad_highlighting_variant == 1
	hi! link PadTimestamp Number
else
	hi! link PadTimestamp Comment
endif
hi! link PadTimestampDelimiter Delimiter
hi! link PadHashTag Identifier
hi! link PadEmptyLabel Error
hi! link PadSummary Title
hi! link PadNewLine Comment

let b:buffer_syntax = "pad"
