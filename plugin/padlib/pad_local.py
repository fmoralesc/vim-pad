import vim
from shutil import move
from os import remove
from os.path import expanduser, exists, join
from padlib.pad import PadInfo
from padlib.timestamps import protect
from padlib.utils import get_save_dir
from padlib.modelines import format_modeline

def update():
	""" Moves a note to a new location if its contents are modified.

	Called on the BufLeave event for the notes.

	"""
	modified = bool(int(vim.eval("b:pad_modified")))
	if modified:
		old_path = expanduser(vim.current.buffer.name)
		new_path = protect(expanduser(join(get_save_dir(), PadInfo(vim.current.buffer).id)))
		if old_path != new_path:
			vim.command("bw")
			move(old_path, new_path)

def delete():
	""" (Local command) Deletes the current note.
	"""
	path = vim.current.buffer.name
	if exists(path):
		confirm = vim.eval('input("really delete? (y/n): ")')
		if confirm in ("y", "Y"):
			remove(path)
			vim.command("bd!")
			vim.command("redraw!")

def add_modeline():
	""" (Local command) Add a modeline to the current note.
	"""
	mode = vim.eval('input("filetype: ", "", "filetype")')
	if mode:
		args = [format_modeline(mode)]
		if vim.eval('g:pad_modeline_position') == 'top':
			args.append(0)
		vim.current.buffer.append(*args)
		vim.command("set filetype=" + mode)
		vim.command("set nomodified")

