syn match PadTimestamp /^.\{-}│/ contains=PadName,PadTimestampDelimiter,PadTimestampTime
syn match PadTimestampTime /\d\d:\d\d:\d\d/ contained
syn match PadTimestampDelimiter /│/ contained
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn match PadFolder / .*\%u2e25/ms=s+1 contained
syn match PadFolderStop /\%u2e25/ containedin=PadFolder conceal
syn match PadArchived /\/archive\// containedin=PadFolder
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\|[.,]\)\@=/ contains=PadHashTag,PadEmptyLabel,PadFolder

hi! link PadTimestamp Number
hi! link PadTimestampTime Comment
hi! link PadTimestampDelimiter Delimiter
hi! link PadHashTag Label
hi! link PadEmptyLabel Error
hi! link PadSummary Title
hi! link PadNewLine Comment
hi! link PadFolder Directory
hi! link PadArchived Special

let b:buffer_syntax = "pad"
