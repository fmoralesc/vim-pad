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

command! OpenPad exec('py open_pad()')
command! SearchPad exec('py search_pad()')
command! ListPads exec('py list_pads()')

noremap <silent> <C-esc> <esc>:ListPads<CR>
inoremap <silent> <C-esc> <esc>:ListPads<CR>
noremap <silent> <S-esc> <esc>:OpenPad<CR>
inoremap <silent> <S-esc> <esc>:OpenPad<CR>
noremap <silent>  <esc>:SearchPad<CR>

python <<EOF
import vim
import time
import datetime
from os import remove
from os.path import expanduser, exists
from glob import glob
from subprocess import Popen, PIPE

window_height = str(vim.eval("g:pad_window_height"))
search_backend = vim.eval("g:pad_search_backend")
ignore_case = bool(vim.eval("g:pad_search_ignorecase"))
only_first = bool(vim.eval("g:pad_search_show_only_first"))
save_dir = vim.eval("g:pad_dir")
filetype = vim.eval("g:pad_format")

def get_natural_timestamp(timestamp):
	f_timestamp = float(int(timestamp)) / 1000000
	tmp_datetime = datetime.datetime.fromtimestamp(f_timestamp)
	diff = datetime.datetime.now() - tmp_datetime
	seconds = diff.seconds
	minutes = seconds/60
	hours = minutes/60
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
		if hours >= 24:
			return tmp_datetime.strftime("%Y-%m-%d %H:%M:%S")
		else:
			minutes_diff = minutes - (hours * 60)
			if minutes_diff != 0:
				return str(hours) + "h and " + str(minutes_diff) + "m ago"
			else:
				return str(minutes) + "m ago"

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
	vim.command("set filetype=" + filetype)
	vim.command("map <silent> <leader><delete> :py delete_current_pad()<cr>")
	if highlight:
		vim.command('execute "normal /'+ highlight + '/\<CR>"')

def delete_current_pad():
	path = vim.current.buffer.name
	if exists(path):
		confirm = vim.eval('input("really delete? (Y/n): ")')
		if confirm in ("y", "Y"):
			remove(path)
			vim.command("bd!")
			vim.command("unmap <leader><delete>")

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
				lines.append(timestamp + " @" + get_natural_timestamp(timestamp).ljust(20) + " | "
							+ lineno + ":" + match)
			vim.current.buffer.append(lines)
			vim.command("normal dd")
			vim.command("setlocal nomodified")
			
			vim.command("setlocal conceallevel=2")
			vim.command('setlocal concealcursor=nc')
			vim.command('syn match PadTimestamp /^.\{-}|/ contains=PadName')
			vim.command('syn match PadName /^.\{-}@/ contained conceal cchar=@')
			vim.command('syn match PadLineno / \d*:/')
			vim.command('syn match PadQuery /'+ query + '/')
			vim.command('hi! link PadTimestamp Comment')
			vim.command('hi! link PadLineno Number')
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

@splitbelow
def list_pads():
	pad_files = [path.replace(expanduser(save_dir), "") for path in glob(expanduser(save_dir) + "*")]
	if len(pad_files) > 0:
		vim.command(window_height + "new")
		lines = []
		for pad in pad_files:
			with open(expanduser(save_dir) + pad) as pad_file:
				data = pad_file.read(100).split("\n")
			summary, body = data[0], "\n".join([line for line in data[1:] if line != '']).\
											replace("\n", u'\u21b2'.encode('utf-8'))
			if data[1:] != ['']:
				tail = u'\u21b2'.encode('utf-8') + ' ' +  body
			else:
				tail = ''
			lines.append(pad + " @" + get_natural_timestamp(pad).ljust(20) + " | " + summary + tail)
		vim.current.buffer.append(list(reversed(sorted(lines))))
		vim.command("normal dd")
		vim.command("set nowrap")
		vim.command("set listchars=extends:◢,precedes:◣")
		vim.command("set nomodified")
		vim.command("setlocal conceallevel=2")
		vim.command('setlocal concealcursor=nc')
		vim.command('syn match PadTimestamp /^.\{-}|/ contains=PadName')
		vim.command('syn match PadName /^.\{-}@/ contained conceal cchar=@')
		vim.command('syn match PadNewLine /\%u21b2/' )
		vim.command('syn region PadSummary start=/|\@<= /hs=s+1 end=/.\(\%u21b2\|$\)\@=/')
		vim.command('hi! link PadTimestamp Comment')
		vim.command('hi! link Conceal PadTimestamp')
		vim.command('hi! PadSummary gui=bold')
		vim.command('hi! link PadNewLine Comment')
		vim.command("map <buffer> <silent> <enter> :py edit_pad()<cr>")
		vim.command("map <buffer> <silent> <delete> :py delete_pad()<cr>")
		vim.command("map <buffer> <silent> <esc> :bd<cr>")
	else:
		print "no pads"
EOF
