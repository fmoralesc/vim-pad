import vim
from shutil import move
from os import remove
from os.path import expanduser, exists, join
from padlib.timestamps import timestamp
from padlib.utils import get_save_dir

def update():
	""" Moves a note to a new location if its contents are modified.

	Called on the BufLeave event for the notes.

	"""
	modified = bool(int(vim.eval("b:pad_modified")))
	if modified:
		old_path = expanduser(vim.current.buffer.name)
		new_path = expanduser(join(get_save_dir(), timestamp()))
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
		vim.current.buffer.append("<!-- vim: set ft=" + mode + ": -->", 0)
		vim.command("set filetype=" + mode)
		vim.command("set nomodified")

