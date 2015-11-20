import vim
from sys import version_info
import re
from os.path import abspath, basename, dirname, expanduser, splitext, isfile, relpath, exists, join
from os import remove, mkdir
from shutil import move
from glob import glob

from .timestamps import timestamp
from .vim_interface import *
from .modelines import format_modeline
from .utils import U

def update():
    if not bool(int(vim.eval('exists("b:pad_modified")'))):
        return

    modified = bool(int(vim.eval("b:pad_modified")))
    can_rename = get_setting("rename_files", bool)
    if modified and can_rename:
        _id = PadInfo(vim.current.buffer).id
        old_path = expanduser(vim.current.buffer.name)

        # if the file already has an extension
        ext = splitext(old_path)[1]
        if ext != '' and ext != get_setting("default_file_extension"):
            return

        fs = filter(isfile, \
                glob(expanduser(join(dirname(vim.current.buffer.name), _id)) + "*"))
        if old_path not in fs:
            if fs == []:
                new_path = expanduser(join(get_save_dir(), _id))
            else:
                exts = map(lambda i: '0' if i == '' else i[1:], \
                        map(lambda i: splitext(i)[1], fs))
                new_path = ".".join([
                                    expanduser(join(get_save_dir(), _id)),
                                    str(int(max(exts)) + 1)])
            new_path = new_path + vim.eval("g:pad#default_file_extension")
            V + "bwipeout"
            move(old_path, new_path)

def delete():
    path = vim.current.buffer.name
    if exists(path):
        confirm = vim.eval('input("really delete? (y/n): ")')
        if confirm.lower() == "y":
            remove(path)
            V + "bdelete!"
            V + "redraw!"

def add_modeline():
    mode = vim.eval('input("filetype: ", "", "filetype")')
    if mode:
        args = [format_modeline(mode)]
        if get_setting('modeline_position') == 'top':
            args.append(0)
        vim.current.buffer.append(*args)
        V + ("set filetype=" + mode)
        V + "set nomodified"

def move_to_folder(path=None):
    if path is None:
        path = vim.eval("input('move to: ')")
    new_path = join(get_save_dir(), path, basename(vim.current.buffer.name))
    if not exists(join(get_save_dir(), path)):
        mkdir(join(get_save_dir(), path))
    try:
        move(vim.current.buffer.name, new_path)
    except IOError as e:
        if e.errno == 20:
            V + "redraw"
            V + "echom 'vim-pad: cannot use that path'"
            return
    V + "bdelete"

def move_to_savedir():
    move_to_folder("")

def archive():
    move_to_folder("archive")

def unarchive():
    move_to_savedir()

def isfileobject(o):
    if version_info.major == 2:
        return isinstance(o, file)
    elif version_info.major == 3:
        import io
        return isinstance(o, io.IOBase)

class PadInfo(object):
    __slots__ = "id", "summary", "body", "isEmpty", "folder"

    def __init__(self, source):
        """

        source can be:

        * a vim buffer
        * a file object
        * a list of strings, one per line
        """

        nchars = int(vim.eval("g:pad#read_nchars_from_files"))
        self.summary = ""
        self.body = ""
        self.isEmpty = True
        self.folder = ""
        self.id = timestamp()

        if source is vim.current.buffer:
            source = source[:10]
        elif isfileobject(source):
            save_dir = get_save_dir()
            if abspath(source.name).startswith(save_dir):
                pos = len(get_save_dir()), len(basename(source.name))
                self.folder = abspath(source.name)[pos[0]:-pos[1]]
            else:
                self.folder = dirname(relpath(source.name, vim.eval('getcwd()')))
            if vim.eval("g:pad#title_first_line") == '1':
                source = source.readline().split("\n")
            elif nchars > 0:
                source = source.read(nchars).split('\n')
            else:
                source = [basename(source.name)]

        data = [line.strip() for line in source if line != ""]

        if data != []:
            # we discard modelines
            if re.match("^.* vim: set .*:.*$", data[0]):
                data = data[1:]

            self.summary = data[0].strip()
            org_tags_data = None
            if len(self.summary) > 0:
                # vim-orgmode adds tags after whitespace
                org_tags_data = re.search("\s+(?P<tags>:.*$)", self.summary)
                if org_tags_data:
                    self.summary = re.sub("\s+:.*$", "", self.summary)
                if self.summary[0] in ("%", "#"):  # pandoc and markdown titles
                    self.summary = str(self.summary[1:]).strip()

            self.body = U(u'\u21b2').join(data[1:]).strip()
            # if we have orgmode tag data, add it to the body
            if org_tags_data:
                self.body = ' '.join(\
                    [" ".join(\
                              map(lambda a: "@" + a, \
                                  filter(lambda a: a != "", \
                                         org_tags_data.group("tags").split(":")))), \
                     self.body])
            # remove extra spaces in bodies
            self.body = re.sub("\s{2,}", "", str(self.body))

        if self.summary != "":
            self.isEmpty = False
            self.id = self.summary.lower().replace(" ", "_")
            # remove ilegal characters from names (using rules for windows
            # systems to err on the side of precaution)
            self.id = re.sub("[*:<>/\|^]", "", self.id)

        if self.id.startswith("."):
            self.id = re.sub("^\.*", "", self.id)
