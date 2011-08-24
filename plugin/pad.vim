if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif

let g:loaded_pad = 0
let g:pad_dir = "~/notes/"
let g:pad_format = "markdown"
let g:pad_search_backend = "ack"

command! OpenPad exec('py open_pad()')
command! SearchPad exec('py search_pad()')

noremap  <esc>:OpenPad<CR>
noremap <C-esc> <esc>:SearchPad<CR>

python <<EOF
import vim
import time
import datetime
from os.path import expanduser
from subprocess import Popen, PIPE

search_backend = vim.eval("g:pad_search_backend")
save_dir = vim.eval("g:pad_dir")
filetype = vim.eval("g:pad_format")

def splitbelow(fun):
	def new(*args):
		splitbelow = bool(int(vim.eval("&splitbelow")))
		if not splitbelow:
			vim.command("set splitbelow")
		fun(*args)
		if not splitbelow:
			vim.command("set splitbelow")
	return new

@splitbelow
def open_pad(path=None):
	if not path:
		path = save_dir + str(int(time.time() * 1000000))
	vim.command("5split " + path)
	vim.command("set filetype=" + filetype)

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
			return str(tmp_datetime)
		else:
			minutes_diff = minutes - (hours * 60)
			if minutes_diff != 0:
				return str(hours) + "h and " + str(minutes_diff) + "m ago"
			else:
				return str(minutes) + "m ago"

@splitbelow
def search_pad():
	query = vim.eval('input("pad-search: ")')
	if query:
		if search_backend == "grep":
			command = ["grep", "-n",  "-r", query, expanduser(save_dir)]
		elif search_backend == "ack":
			command = ["/usr/bin/vendor_perl/ack", query, expanduser(save_dir), "--type=text"]
		grep_search = [line for line in Popen(command, 
							stdout=PIPE, stderr=PIPE).communicate()[0].\
							replace(expanduser("~/notes/"), "").\
							split("\n")
							if line != '']
		if len(grep_search) > 0:
			vim.command("5split /tmp/pad-search")
			lines = []
			for line in grep_search:
				timestamp, lineno, match = line.split(":")
				lines.append(timestamp + " @" + get_natural_timestamp(timestamp) + " | " + lineno + ":" + match)
			vim.current.buffer.append(lines)
			vim.command("normal dd")
			vim.command("setlocal nomodified")
			# vim.command("setlocal cursorline")
			vim.command("setlocal conceallevel=2")
			vim.command('setlocal concealcursor="nc"')
			# We italize the timestamp and the query
			vim.command('syn match PadTimestamp /^.*|/ contains=PadName')
			vim.command('syn match PadName /^.*@/ contained conceal cchar=@')
			vim.command('syn match PadLineno / \d*:/')
			vim.command('syn match PadQuery /'+ query + '/')
			vim.command('hi! PadTimestamp guifg=grey gui=italic')
			vim.command('hi! link PadName Comment')
			vim.command('hi! link PadLineno Number')
			vim.command('hi! link PadQuery Search')
			vim.command('hi! link Conceal PadTimestamp')
			# We open the note when prssing <Enter> over a line
			vim.command("map <enter> :py edit_pad()<cr>")
			if len(grep_search) == 1:
				edit_pad()
		else:
			print "no matches found"

def edit_pad():
	path = save_dir + vim.current.line.split(" @")[0]
	vim.command("bd")
	open_pad(path)
EOF
