import vim
from os.path import expanduser

def protect_path(path):
	if vim.eval('has("win32")') == 1:
		return path.replace("\\", "\\\\")
	else:
		return path

def get_save_dir():
	return protect_path(expanduser(vim.eval("g:pad_dir")))
