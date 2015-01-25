# coding=utf-8
import vim
from os.path import join
from .vim_interface import *

def set_vim_globals():
    """ Sets global vim preferences and commands.
    """
    # To update the date when files are modified
    if get_save_dir() == "":
        V + 'echom "vim-pad: IMPORTANT: please set g:pad#dir to a valid path in your vimrc."'
        V + "redraw"

    # vim-pad pollutes the MRU.vim list quite a lot, if let alone.
    # This should fix that.
    if vim.eval('exists(":MRU")') == "2":
        mru_exclude_files = vim.eval("MRU_Exclude_Files")
        if mru_exclude_files != '':
            tail = "\|" + mru_exclude_files
        else:
            tail = ''
        V + ("let MRU_Exclude_Files = '^" +
                join(get_save_dir(), ".*") + tail + "'")

    # we forbid writing backups of the notes
    orig_backupskip = vim.eval("&backupskip")
    V + ("let &backupskip='" +
            ",".join([orig_backupskip, join(get_save_dir(), "*")]) + "'")

