import vim
from os import rmdir
from os.path import expanduser, split


def get_save_dir():
    return expanduser(vim.eval("g:pad_dir")).replace("\\", "\\\\")


def make_sure_dir_is_empty(path):  # {{{1
    try:
        rmdir(split(path)[0])
    except:
        pass

