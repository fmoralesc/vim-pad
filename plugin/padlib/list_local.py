import vim
from os import remove
from os.path import join
from padlib.handler import open_pad, get_filelist, fill_list
from padlib.utils import get_save_dir

def incremental_search():
	""" Provides incremental search within the __pad__ buffer.
	"""
	query = ""
	should_create_on_enter = False
	
	vim.command("echohl None")
	vim.command('echo ">> "')
	while True:
		raw_char = vim.eval("getchar()")
		if raw_char in ("13", "27"):
			if raw_char == "13" and should_create_on_enter:
				vim.command("bw")
				open_pad(first_line=query)
				vim.command("echohl None")
			vim.command("redraw!")
			break
		else:
			try: # if we can convert to an int, we have a regular key
				int(raw_char) # we check this way so we bring up an error on nr2char
				last_char = vim.eval("nr2char(" + raw_char + ")")
				query = query + last_char
			except: # if we don't, we have some special key
				keycode = unicode(raw_char, errors="ignore")
				if keycode == "kb": # backspace
					query = query[:-len(last_char)]
		vim.command("setlocal modifiable")
		pad_files = get_filelist(query)
		if pad_files != []:
			fill_list(pad_files, query != "")
			info = ""
			vim.command("echohl None")
			should_create_on_enter = False
		else: # we will create a new pad
			del vim.current.buffer[:]
			info = "[NEW] "
			vim.command("echohl WarningMsg")
			should_create_on_enter = True
		vim.command("redraw")
		vim.command('echo ">> ' + info + query + '"')

def edit_pad():
	""" Opens the currently selected note in the __pad__ buffer.
	"""
	path = join(get_save_dir(), vim.current.line.split(" @")[0])
	vim.command("bd")
	open_pad(path=path)

def delete_pad():
	""" Deletes the currently selected note in the __pad__ buffer.
	"""
	confirm = vim.eval('input("really delete? (y/n): ")')
	if confirm in ("y", "Y"):
		path = join(get_save_dir(), vim.current.line.split(" @")[0])
		remove(path)
		vim.command("bd")
		vim.command("redraw!")
