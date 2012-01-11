import vim
from os.path import expanduser

def get_save_dir():
	return expanduser(vim.eval("g:pad_dir")).replace("\\", "\\\\")
