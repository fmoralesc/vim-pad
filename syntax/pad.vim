syn match PadTimestamp /^.\{-}│/ contains=PadName,PadTimestampDelimiter
syn match PadTimestampDelimiter /│/ contained
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn match PadFolder / .*\%u2e25/ms=s+1 contained
syn match PadFolderStop /\%u2e25/ containedin=PadFolder conceal
syn match PadArchived /\/archive\// containedin=PadFolder
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\|[.,]\)\@=/ contains=PadHashTag,PadEmptyLabel,PadFolder

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
hi! link PadFolder Directory
hi! link PadArchived Special

let b:buffer_syntax = "pad"
