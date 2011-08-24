if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif

let g:loaded_pad = 0
let g:pad_dir = "~/notes"
let g:pad_format = "markdown"

command! OpenPad exec('py open_pad()')
command! SearchPad exec('py search_pad()')

noremap <F8> <esc>:OpenPad<CR>
noremap <S-F8> <esc>:SearchPad<CR>

python <<EOF
import vim
import time
from os.path import expanduser
from subprocess import Popen, PIPE

save_dir = vim.eval("g:pad_dir")
filetype = vim.eval("g:pad_format")

def open_pad(path=None):
	if not path:
		path = save_dir + "/" + str(int(time.time() * 1000000))
	vim.command("5split " + path)
	vim.command("set filetype=" + filetype)

def search_pad():
	vim.command("5split /tmp/pad-search")
	query = vim.eval('input("//")')
	if query:
		grep_search = Popen(["grep", 
							"-r", 
							query, 
							expanduser(save_dir)], 
							stdout=PIPE, 
							stderr=PIPE).communicate()[0].replace(expanduser("~") + "/notes/", "").split()
		vim.current.buffer.append(grep_search)
		vim.command("normal dd")
		vim.command("set nomodified")
		vim.command("map <enter> :py edit_pad()<cr>")
	else:
		vim.command("bd")

def edit_pad():
	path = save_dir + "/" + vim.current.line.split(":")[0]
	vim.command("bd")
	open_pad(path)
EOF
