if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif
let g:loaded_pad = 1

if !exists('g:pad_dir')
	let g:pad_dir = "~/notes/"
endif
if !exists('g:pad_format')
	let g:pad_format = "markdown"
endif
if !exists('g:pad_window_height')
	let g:pad_window_height = 5
endif
if !exists('g:pad_search_backend')
	let g:pad_search_backend = "ack"
endif
if !exists('g:pad_search_ignorecase')
	let g:pad_search_ignorecase = 1
endif
if !exists('g:pad_search_show_only_first')
	let g:pad_search_show_only_first = 1
endif
if !exists('g:pad_search_hightlight')
	let g:pad_search_hightlight = 0
endif

command! OpenPad exec 'py open_pad()'
command! SearchPad exec 'py search_pad()'
command! ListPads exec 'py list_pads()'

noremap <silent> <C-esc> <esc>:ListPads<CR>
inoremap <silent> <C-esc> <esc>:ListPads<CR>
noremap <silent> <S-esc> <esc>:OpenPad<CR>
inoremap <silent> <S-esc> <esc>:OpenPad<CR>
noremap <silent>  <esc>:SearchPad<CR>

" To update the date when files are modified
execute "au! BufEnter" printf("%s*", g:pad_dir) ":let pad_modified = 0"
execute "au! BufWritePre" printf("%s*", g:pad_dir) ":let pad_modified = eval(&modified)"
execute "au! BufLeave" printf("%s*", g:pad_dir) ":py update_pad()"

python <<EOF
import vim
import time
import datetime
import re
from os import remove
from os.path import expanduser, exists
from shutil import move
from glob import glob
from subprocess import Popen, PIPE

save_dir = vim.eval("g:pad_dir")
filetype = vim.eval("g:pad_format")
window_height = str(vim.eval("g:pad_window_height"))
search_backend = vim.eval("g:pad_search_backend")
ignore_case = bool(int((vim.eval("g:pad_search_ignorecase"))))
only_first = bool(int(vim.eval("g:pad_search_show_only_first")))
search_hightlight = bool(int(vim.eval("g:pad_search_hightlight")))

# vim-pad pollutes the MRU.vim list quite a lot, if let alone.
# This should fix that.
mru_exclude_files = vim.eval("MRU_Exclude_Files")
if mru_exclude_files != '':
	tail = "\|" + mru_exclude_files
else:
	tail = ''
vim.command("let MRU_Exclude_Files = '^" + save_dir.replace("~", expanduser("~")) + "*" + tail + "'")

# we forbid writing backups of the notes
orig_backupskip = vim.eval("&backupskip")
vim.command("set backupskip=" + ",".join([orig_backupskip, save_dir.replace("~", expanduser("~")) + "*"]))

def get_natural_timestamp(timestamp):
	f_timestamp = float(int(timestamp)) / 1000000
	tmp_datetime = datetime.datetime.fromtimestamp(f_timestamp)
	diff = datetime.datetime.now() - tmp_datetime
	days = diff.days
	seconds = diff.seconds
	minutes = seconds/60
	hours = minutes/60
	if days > 0:
		return tmp_datetime.strftime("%Y-%m-%d %H:%M:%S")
	if hours < 1:
		if minutes < 1:
			return str(seconds) + "s ago"
		else:
			seconds_diff = seconds - (minutes * 60)
			if seconds_diff != 0:
				return str(minutes) + "m and " + str(seconds_diff) + "s ago"
			else:
				return str(minutes) + "m ago"
	else:
		minutes_diff = minutes - (hours * 60)
		if minutes_diff != 0:
			return str(hours) + "h and " + str(minutes_diff) + "m ago"
		else:
			return str(hours) + "h ago"

def splitbelow(fun):
	def new(*args):
		splitbelow = bool(int(vim.eval("&splitbelow")))
		if not splitbelow:
			vim.command("set splitbelow")
		fun(*args)
		if not splitbelow:
			vim.command("set nosplitbelow")
	return new

@splitbelow
def open_pad(path=None, highlight=None):
	if not path:
		path = save_dir + str(int(time.time() * 1000000))
	vim.command(window_height + "split " + path)
	if vim.eval('&filetype') in ('', 'conf'):
		vim.command("set filetype=" + filetype)
	vim.command("map <silent> <buffer> <localleader><delete> :py delete_current_pad()<cr>")
	vim.command("map <silent> <buffer> <localleader>+m :py add_modeline()<cr>")
	if search_hightlight and highlight:
		vim.command('execute "normal /'+ highlight + '/\<CR>"')

def delete_current_pad():
	path = vim.current.buffer.name
	if exists(path):
		confirm = vim.eval('input("really delete? (Y/n): ")')
		if confirm in ("y", "Y"):
			remove(path)
			vim.command("bd!")
			vim.command("unmap <leader><delete>")

def add_modeline():
	mode = vim.eval('input("filetype: ", "", "filetype")')
	if mode:
		vim.current.buffer[0] = "<!-- vim: set ft=" + mode + ": -->"
		ft = re.search("ft=.*(?=:)", vim.current.line).group().split("=")[1]
		vim.command("set filetype=" + ft)
		vim.command("set nomodified")

@splitbelow
def search_pad():
	query = vim.eval('input("pad-search: ")')
	if query:
		if search_backend == "grep":
			command = ["grep", "-n",  "-r", query, expanduser(save_dir)]
		elif search_backend == "ack":
			command = ["/usr/bin/vendor_perl/ack", query, expanduser(save_dir), "--type=text"]
		if ignore_case:
			command.append("-i")
		if only_first:
			command.append("--max-count=1")
		search_results = [line for line in Popen(command,
							stdout=PIPE, stderr=PIPE).communicate()[0].\
							replace(expanduser(save_dir), "").\
							split("\n")
							if line != '']
		if len(search_results) > 0:
			vim.command("5new")
			lines = []
			for line in reversed(sorted(search_results)): # MRU-style ordering
				data = line.split(":")
				timestamp, lineno, match = data[0], data[1], ":".join(data[2:])
				
				with open(expanduser(save_dir) + timestamp) as pad_file:
					file_data = pad_file.read(200).split("\n")
				if re.match("^.* vim: set .*:.*$", file_data[0]): #we have a modeline
					file_data = file_data[1:]
				summary = file_data[0].strip()
				if summary[0] in ("%", "#"): #pandoc and markdown titles
					summary = "".join(summary[1:]).strip()
				tail = ''
				if file_data[1:]:
					tail = "…"

				lines.append(timestamp + " @" + get_natural_timestamp(timestamp).ljust(19) + " │ "
							+ lineno + ":" + match + " 「 " + summary + tail)
			vim.current.buffer.append(lines)
			vim.command("normal dd")
			vim.command("set nowrap")
			vim.command("set listchars=extends:◢,precedes:◣")
			vim.command("set nomodified")
			vim.command("setlocal conceallevel=2")
			vim.command('setlocal concealcursor=nc')
			vim.command('syn match PadTimestamp /^.\{-}│/ contains=PadName')
			vim.command('syn match PadName /^.\{-}@/ contained conceal cchar=@')
			vim.command('syn match PadLineno / \d*:/')
			vim.command(r'syn match PadHashTag /\(@\|#\)\a\+/')
			vim.command('syn match PadSummary /「.*$/hs=s+1 contains=PadHashTag')
			vim.command('syn match PadQuery /'+ query + '/')
			vim.command('hi! link PadTimestamp Comment')
			vim.command('hi! link PadLineno Number')
			vim.command('hi! PadSummary gui=bold')
			vim.command('hi! link PadHashTag Identifier')
			vim.command('hi! link PadQuery Search')
			vim.command('hi! link Conceal PadTimestamp')
			
			vim.command('map <buffer> <silent> <enter> :py edit_pad("' + query +'")<cr>')
			vim.command("map <buffer> <silent> <delete> :py delete_pad()<cr>")
			vim.command("map <buffer> <silent> <esc> :bd<cr>")
	
			vim.command("setlocal nomodifiable")
			if len(search_results) == 1:
				edit_pad(query)
		else:
			print "no matches found"

def edit_pad(highlight=None):
	path = save_dir + vim.current.line.split(" @")[0]
	vim.command("bd")
	open_pad(path, highlight)

def delete_pad():
	confirm = vim.eval('input("really delete? (Y/n): ")')
	if confirm in ("y", "Y"):
		path = expanduser(save_dir) + vim.current.line.split(" @")[0]
		remove(path)
		vim.command("bd")

def update_pad():
	modified = bool(int(vim.eval("pad_modified")))
	if modified:
		old_path = expanduser(vim.current.buffer.name)
		new_path = expanduser(save_dir + str(int(time.time() * 1000000)))
		vim.command("bd")
		move(old_path, new_path)

@splitbelow
def list_pads():
	pad_files = [path.replace(expanduser(save_dir), "") for path in glob(expanduser(save_dir) + "*")]
	if len(pad_files) > 0:
		vim.command(window_height + "new")
		lines = []
		for pad in pad_files:
			with open(expanduser(save_dir) + pad) as pad_file:
				data = pad_file.read(200).split("\n")
			
			head = ''
			if re.match("^.* vim: set .*:.*$", data[0]): #we have a modeline
				ft = re.search("ft=.*(?=:)", data[0]).group().split("=")[1]
				if ft == "vo_base":
					ft = "vo"
				elif ft == "pandoc":
					ft = "pd"
				elif ft == "markdown":
					ft = "md"
				head = '▪' + ft + '▪ '
				data = data[1:] #we discard it
			
			summary = data[0].strip()
			if summary[0] in ("%", "#"): #pandoc and markdown titles
				summary = "".join(summary[1:]).strip()
			
			body = "\n".join([line.strip() for line in data[1:] if line != '']).\
					replace("\n", u'\u21b2 '.encode('utf-8'))
			
			tail = ''
			if data[1:] != ['']:
				tail = u'\u21b2'.encode('utf-8') + ' ' +  body

			lines.append(pad + " @" + get_natural_timestamp(pad).ljust(19) + " │ " + head + summary + tail)
		vim.current.buffer.append(list(reversed(sorted(lines))))
		vim.command("normal dd")
		vim.command("set nowrap")
		vim.command("set listchars=extends:◢,precedes:◣")
		vim.command("set nomodified")
		vim.command("setlocal conceallevel=2")
		vim.command('setlocal concealcursor=nc')
		vim.command('syn match PadTimestamp /^.\{-}│/ contains=PadName')
		vim.command('syn match PadName /^.\{-}@/ contained conceal cchar=@')
		vim.command('syn match PadNewLine /\%u21b2/' )
		vim.command('syn match PadFT /\%u25aa.*\%u25aa/')
		vim.command(r'syn match PadHashTag /\(@\|#\)\a\+/')
		vim.command('syn region PadSummary start=/│\@<= /hs=s+1 end=/\(\%u21b2\|$\)\@=/ contains=PadHashTag,PadFT')
		vim.command('hi! link PadTimestamp Comment')
		vim.command('hi! link Conceal PadTimestamp')
		vim.command('hi! link PadHashTag Identifier')
		vim.command('hi! link PadFT Type')
		vim.command('hi! PadSummary gui=bold')
		vim.command('hi! link PadNewLine Comment')
		vim.command("map <buffer> <silent> <enter> :py edit_pad()<cr>")
		vim.command("map <buffer> <silent> <delete> :py delete_pad()<cr>")
		vim.command("map <buffer> <silent> <esc> :bd<cr>")
	else:
		print "no pads"
EOF
