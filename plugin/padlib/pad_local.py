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
        _id = PadInfo(vim.current.buffer).id
        old_path = expanduser(vim.current.buffer.name)

        fs = filter(isfile, glob(expanduser(join(get_save_dir(), _id)) + "*"))
        if old_path not in fs:
            if fs == []:
                new_path = expanduser(join(get_save_dir(), _id))
            else:
                exts = map(lambda i: '0' if i == '' else i[1:],
                                    map(lambda i: splitext(i)[1], fs))
                new_path = ".".join([
                                    expanduser(join(get_save_dir(), _id)),
                                    str(int(max(exts)) + 1)])
            new_path = new_path + vim.eval("g:pad_default_file_extension")
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


def move_to_folder(path=None):
    if path is None:
        path = vim.eval("input('move to: ')")
    new_path = join(get_save_dir(), path, basename(vim.current.buffer.name))
    if not exists(join(get_save_dir(), path)):
        mkdir(join(get_save_dir(), path))
    move(vim.current.buffer.name, new_path)
    vim.command("bd")


def move_to_savedir():
    move_to_folder("")


def archive():
    move_to_folder("archive")


def unarchive():
    move_to_savedir()
