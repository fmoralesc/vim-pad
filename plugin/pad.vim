if (exists("g:loaded_pad") && g:loaded_pad) || &cp
    finish
endif
let g:loaded_pad = 0

" Default Settings:
"
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

" Commands:
"
command! OpenPad exec 'py pad.open_pad()'
command! ListPads exec 'py pad.list_pads()'

" Key Mappings:
"
" IMPORTANT: Change this to your linking
"
if !exists('g:pad_custom_mappings') || g:pad_custom_mappings == 0
	noremap <silent> <C-esc> <esc>:ListPads<CR>
	inoremap <silent> <C-esc> <esc>:ListPads<CR>
	noremap <silent>  <esc>:OpenPad<CR>
	inoremap <silent>  <esc>:OpenPad<CR>
endif

" To update the date when files are modified
execute "au! BufEnter" printf("%s*", g:pad_dir) ":let b:pad_modified = 0"
execute "au! BufWritePre" printf("%s*", g:pad_dir) ":let b:pad_modified = eval(&modified)"
execute "au! BufLeave" printf("%s*", g:pad_dir) ":py pad.update_pad()"

python <<EOF
import vim
import time
import datetime
import re
from os import remove
from os.path import expanduser, exists, basename
from shutil import move
from glob import glob
from subprocess import Popen, PIPE

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

# actually, we use this mainly as a namespace of sorts
class Pad(object):
	def __init__(self):
		self.save_dir = vim.eval("g:pad_dir")
		self.filetype = vim.eval("g:pad_format")
		self.window_height = str(vim.eval("g:pad_window_height"))
		self.search_backend = vim.eval("g:pad_search_backend")
		self.ignore_case = bool(int((vim.eval("g:pad_search_ignorecase"))))
		self.only_first = bool(int(vim.eval("g:pad_search_show_only_first")))

		# vim-pad pollutes the MRU.vim list quite a lot, if let alone.
		# This should fix that.
		mru_exclude_files = vim.eval("MRU_Exclude_Files")
		if mru_exclude_files != '':
			tail = "\|" + mru_exclude_files
		else:
			tail = ''
		vim.command("let MRU_Exclude_Files = '^" + self.save_dir.replace("~", expanduser("~")) + "*" + tail + "'")

		# we forbid writing backups of the notes
		orig_backupskip = vim.eval("&backupskip")
		vim.command("set backupskip=" + ",".join([orig_backupskip, self.save_dir.replace("~", expanduser("~")) + "*"]))


	def update_pad(self):
		modified = bool(int(vim.eval("b:pad_modified")))
		if modified:
			old_path = expanduser(vim.current.buffer.name)
			new_path = expanduser(self.save_dir + str(int(time.time() * 1000000)))
			vim.command("bd")
			move(old_path, new_path)

	def open_pad(self, path=None):
		if not path:
			path = self.save_dir + str(int(time.time() * 1000000))
		vim.command("botright" + self.window_height + "split " + path)
		if vim.eval('&filetype') in ('', 'conf'):
			vim.command("set filetype=" + self.filetype)
		vim.command("noremap <silent> <buffer> <localleader><delete> :py delete_current_pad()<cr>")
		vim.command("noremap <silent> <buffer> <localleader>+m :py add_modeline()<cr>")

	def delete_current_pad(self):
		path = vim.current.buffer.name
		if exists(path):
			confirm = vim.eval('input("really delete? (Y/n): ")')
			if confirm in ("y", "Y"):
				remove(path)
				vim.command("bd!")
				vim.command("unmap <leader><delete>")

	def add_modeline(self):
		mode = vim.eval('input("filetype: ", "", "filetype")')
		if mode:
			vim.current.buffer[0] = "<!-- vim: set ft=" + mode + ": -->"
			ft = re.search("ft=.*(?=:)", vim.current.line).group().split("=")[1]
			vim.command("set filetype=" + ft)
			vim.command("set nomodified")

	def get_filelist(self, query=None):
		if not query or query == "":
			return [path.replace(expanduser(self.save_dir), "") for path in glob(expanduser(self.save_dir) + "*")]
		else:
			if self.search_backend == "grep":
				command = ["grep", "-n", "-r", query, expanduser(self.save_dir)]
			elif self.search_backend == "ack":
				command = ["/usr/bin/vendor_perl/ack", query, expanduser(self.save_dir), "--type=text"]
			if self.ignore_case:
				command.append("-i")
			if self.only_first:
				command.append("--max-count=1")
			search_results = [line.split(":")[0] for line in Popen(command, stdout=PIPE, stderr=PIPE).communicate()[0].\
												replace(expanduser(self.save_dir), "").\
												split("\n")	if line != '']	
			return list(reversed(sorted(search_results)))
	
	def fill_list(self, files):
		del vim.current.buffer[:] # clear the buffer
		lines = []
		for pad in files:
			with open(expanduser(self.save_dir) + pad) as pad_file:
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
	
	def list_pads(self):
		pad_files = self.get_filelist()
		if len(pad_files) > 0:
			if vim.eval("bufexists('__pad__')") == "1":
				vim.command("bw __pad__")
			vim.command("silent! botright " + self.window_height + "new __pad__")
			self.fill_list(pad_files)
			vim.command("set filetype=pad")
		else:
			print "no pads"

	def edit_pad(self):
		path = self.save_dir + vim.current.line.split(" @")[0]
		vim.command("bd")
		self.open_pad(path)

	def delete_pad(self):
		confirm = vim.eval('input("really delete? (Y/n): ")')
		if confirm in ("y", "Y"):
			path = expanduser(self.save_dir) + vim.current.line.split(" @")[0]
			remove(path)
			vim.command("bd")

	def incremental_search(self):
		query = ""
		vim.command('echo ">> "')
		while True:
			raw_char = vim.eval("getchar()")
			try:
				char = int(raw_char)
				if char in (13, 27): # <Enter>
					vim.command("redraw!")
					break
				else:
					query = query + vim.eval("nr2char(" + str(char) + ")")
			except:
				if list(raw_char) == ['\x80', 'k', 'b']:
					query = query[:-1]
			pad_files = self.get_filelist(query)
			if pad_files != []:
				self.fill_list(pad_files)
			else:
				break
			vim.command("redraw")
			vim.command('echo ">> ' + query + '"')

pad = Pad()
EOF
