if g:pad#position["list"] == "right"
    syn match PadTimestamp /^.\{-}│/ conceal
else
    syn match PadTimestamp /^.\{-}│/ contains=PadName,PadTimestampDelimiter,PadTimestampTime
endif
syn match PadTimestampTime /\d\d:\d\d:\d\d/ contained
syn match PadTimestampDelimiter /│/ contained
syn match PadName /^.\{-}@/ contained conceal
syn match PadNewLine /\%u21b2/
syn match PadHashTag /\(@\|#\)\a\+\(\s\|\n\|\%u21b2\)\@=/
syn match PadEmptyLabel /\[EMPTY\]/ contained
syn match PadFolder / .*\%u2e25/ contained
if g:pad#local_dir != ''
    exe 'syn match PadLocal /'.g:pad#local_dir.'/ containedin=PadFolder'
endif
syn match PadFolderStop /\%u2e25/ containedin=PadFolder conceal
syn match PadArchived /\/archive\// containedin=PadFolder
if g:pad#position["list"] == "right"
    syn match PadSummaryPad / \//me=e-1 containedin=PadFolder conceal
endif
syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\)\@=/ contains=PadHashTag,PadEmptyLabel,PadFolder

hi! link PadTimestamp Number
hi! link PadTimestampTime Comment
hi! link PadTimestampDelimiter Delimiter
hi! link PadHashTag Identifier
hi! link PadEmptyLabel Error
hi! link PadSummary Title
hi! link PadNewLine Comment
hi! link PadFolder Directory
hi! link PadLocal Special
hi! link PadArchived Special
hi! link PadQuery Search

let b:buffer_syntax = "pad"
