import vim
from os.path import expanduser

class Vim(object):
    def __add__(self, cmd):
        """
        The idea is to allow using

            Vim() + command

        to execute vim commands, instead of using vim.command().
        Mainly aesthetics, but it cleans up the python code.

        Note:

            Vim() + "string" + var

        doesn't work as expected, you need to use

            Vim() + ("string" + var)

        """
        if isinstance(cmd, str):
            vim.command(cmd)

V = Vim()

def prevent_invalid_dir(fn):
    from functools import wraps
    @wraps(fn)
    def wrapped(*args, **kw):
        if get_save_dir() == "":
            V + 'echom "vim-pad: IMPORTANT: please set g:pad#dir to a valid path"'
            return
        fn(*args, **kw)
    return wrapped

def get_setting(setting, kind=None):
    s_data = vim.eval('g:pad#'+setting)
    if kind == bool:
        s_data = bool(int(s_data))
    return s_data

def get_save_dir():
    return expanduser(vim.eval("g:pad#dir")).replace("\\", "\\\\")
