import vim
from shutil import move
from os import remove, mkdir
from os.path import expanduser, exists, join, splitext, isfile, basename
from padlib.pad import PadInfo
from padlib.utils import get_save_dir
from padlib.modelines import format_modeline
from glob import glob

def update():
	""" Moves a note to a new location if its contents are modified.

	Called on the BufLeave event for the notes.

	"""
	modified = bool(int(vim.eval("b:pad_modified")))
	if modified:
		id = PadInfo(vim.current.buffer).id
		old_path = expanduser(vim.current.buffer.name)

		fs = filter(isfile, glob(expanduser(join(get_save_dir(), id))+"*"))
		if old_path not in fs:
			if fs == []:
				new_path = expanduser(join(get_save_dir(), id))
			else:
				exts = map(lambda i: '0' if i == '' else i[1:], map(lambda i: splitext(i)[1], fs))
				new_path = ".".join([expanduser(join(get_save_dir(), id)), str(int(max(exts)) + 1)])
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

def archive():
    new_path = join(get_save_dir(), "archive", basename(vim.current.buffer.name))
    if not exists(join(get_save_dir(), "archive")):
        mkdir(join(get_save_dir(), "archive"))
    move(vim.current.buffer.name, new_path)
    vim.command("q")

def unarchive():
    new_path = join(get_save_dir(), basename(vim.current.buffer.name))
    move(vim.current.buffer.name, new_path)
    vim.command("q")

