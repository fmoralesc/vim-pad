# coding=utf-8
import vim
from os.path import join
from padlib.utils import get_save_dir

def set_external():
# vim-pad pollutes the MRU.vim list quite a lot, if let alone.
# This should fix that.
	if vim.eval('exists(":MRU")') == "2":
		mru_exclude_files = vim.eval("MRU_Exclude_Files")
		if mru_exclude_files != '':
			tail = "\|" + mru_exclude_files
		else:
			tail = ''
		vim.command("let MRU_Exclude_Files = '^" + 
				join(get_save_dir(), ".*") + tail + "'")

# we forbid writing backups of the notes
	orig_backupskip = vim.eval("&backupskip")
	vim.command("set backupskip=" + 
			",".join([orig_backupskip, join(get_save_dir(), "*")]))


# we set listchars, for formatting purposes
	tmp=[i.split(":")[0] for i in vim.eval("&listchars").split(",")]
# we won't touch listchars if the values we want to change are already set
	if vim.eval('has("multi_byte_encoding")') == "1":
		if "extends" not in tmp:
			vim.command("set listchars+=extends:»")
		if "precedes" not in tmp:
			vim.command("set listchars+=precedes:«")
	else:
		if "extends" not in tmp:
			vim.command("set listchars+=extends:»")
		if "precedes" not in tmp:
			vim.command("set listchars+=precedes:«")
	del tmp


