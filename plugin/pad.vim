if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif

let g:loaded_pad = 0
let g:pad_dir = "~/notes/"
let g:pad_format = "markdown"

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
		grep_search = [line for line in Popen(["grep", "-r", query, expanduser(save_dir)], 
							stdout=PIPE, stderr=PIPE).communicate()[0].\
							replace(expanduser("~/notes/"), "").\
							split("\n")
							if line != '']
		if len(grep_search) > 0:
			vim.command("5split /tmp/pad-search")
			lines = []
			for line in grep_search:
				timestamp, match = line.split(":")
				#				print get_natural_timestamp(timestamp)
				lines.append(timestamp + " @" + get_natural_timestamp(timestamp) + " | " + match)
			vim.current.buffer.append(lines)
			vim.command("normal dd")
			vim.command("setlocal nomodified")
			vim.command("setlocal cursorline")
			vim.command("setlocal conceallevel=2")
			vim.command('setlocal concealcursor="vi"')
			# We italize the timestamp and the query
			vim.command('syn match PadTimestamp /^.*|/ contains=PadName')
			vim.command('syn match PadName /^.*@/ contained conceal cchar=@')
			vim.command('syn match PadQuery /'+ query + '/')
			vim.command('hi! PadTimestamp guifg=grey')
			vim.command('hi! PadName guifg=#505050 gui=italic')
			vim.command('hi! PadQuery guifg=red gui=underline')
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
