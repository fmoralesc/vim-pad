call Pl#Statusline(
	\ Pl#Match('bufname("%")', '__pad__'),
	\
	\ Pl#Segment(' %{"Pad"} ',
		\ Pl#HiCurrent(   Pl#FG(231), Pl#BG(125), Pl#Attr('bold')),
		\ Pl#HiInsert(    Pl#FG(231), Pl#BG( 31), Pl#Attr('bold')),
		\ Pl#HiNonCurrent(Pl#FG(244), Pl#BG( 236), Pl#Attr('bold'))
		\ ),
	\
	\ Pl#Segment(' %<%{pad#GetPadTitle()}',
		\ Pl#HiCurrent(   Pl#FG(231), Pl#BG( 236)),
		\ Pl#HiInsert(    Pl#FG(117), Pl#BG( 24)),
		\ Pl#HiNonCurrent(Pl#FG(244), Pl#BG( 236))
		\ ),
	\
	\ Pl#Split(
		\ Pl#HiCurrent(   Pl#BG( 236)),
		\ Pl#HiInsert(    Pl#BG( 24)),
		\ Pl#HiNonCurrent(Pl#BG( 236))
		\ ),
	\
	\ Pl#Segment(" %4(#%l%) ",
		\ Pl#HiCurrent(   Pl#FG(231), Pl#BG(125)),
		\ Pl#HiInsert(    Pl#FG(117), Pl#BG( 31)),
		\ Pl#HiNonCurrent(Pl#FG(244), Pl#BG( 236))
		\ )
	\ )
