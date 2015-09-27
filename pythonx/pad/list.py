# coding=utf-8

from sys import version_info
import vim
import re
from os import remove, mkdir
from shutil import move
from os.path import exists, getmtime, join, isfile, basename

from .pad import PadInfo
from .timestamps import natural_timestamp
from .collator import NotesCollator
from .vim_interface import *
from .utils import make_sure_dir_is_empty, U

cached_data = []
cached_timestamps = []
cached_filenames = []

class NotesListBuffer(object):#{{{1
    @property
    def selected_path(self):#{{{2
        return join(get_save_dir(), vim.current.line.split(" @")[0])

    def show(self, files, queried=False):#{{{2
        if len(files) > 0:
            if vim.eval("bufexists('__pad__')") == "1":
                V + "bw __pad__"
            if get_setting('position["list"]') == "right":
                V + ("silent! rightbelow " + get_setting('window_width') + "vnew __pad__")
            elif get_setting('position["list"]') == "full":
                V + "silent! new __pad__  | only"
            else:
                V + ("silent! botright " + get_setting('window_height') + "new __pad__")
            self.fill(files, queried)
            V + "set filetype=pad"
            V + "setlocal nomodifiable"
        else:
            V + "echom 'vim-pad: no pads'"

    def fill(self, filelist, queried=False, custom_order=False):#{{{2
        global cached_filenames, cached_timestamps, cached_data

        # we won't want to touch the cache
        if custom_order:
            queried = True

        files = list(filter(exists, [join(get_save_dir(), f) for f in filelist]))

        timestamps = [getmtime(join(get_save_dir(), f)) for f in files]

        # we will have a new list only on the following cases
        if queried or files != cached_filenames or timestamps != cached_timestamps:
            lines = []
            if not custom_order:
                files = reversed(sorted(files, key=lambda i: getmtime(join(get_save_dir(), i))))
            for pad in files:
                pad_path = join(get_save_dir(), pad)
                if isfile(pad_path):
                    pad_path = join(get_save_dir(), pad)
                    with open(pad_path) as pad_file:
                        info = PadInfo(pad_file)
                        if info.isEmpty:
                            if get_setting("show_dir", bool):
                                tail = info.folder + \
                                    U(u'\u2e25 ') + "[EMPTY]"
                            else:
                                tail = "[EMPTY]"
                        else:
                            if get_setting("show_dir", bool):
                                tail = U(info.folder) + \
                                    U(u'\u2e25 ') + \
                                    U(u'\u21b2').join((info.summary, info.body))
                            else:
                                tail = U(u'\u21b2').join((info.summary, info.body))
                        try:
                            pad = str(pad)
                        except:
                            pad = pad.encode('utf-8')
                        lines.append(pad + " @ " + tail)
                else:
                    pass

            # we only update the cache if we are not queried, to preserve the global cache
            if not queried:
                cached_data = lines
                cached_timestamps = timestamps
                cached_filenames = files

        # update natural timestamps
        def add_natural_timestamp(matchobj):
            id_string = matchobj.group("id")
            mtime = str(int(getmtime(join(get_save_dir(), matchobj.group("id")))*1000000))
            return id_string + " @ " + natural_timestamp(mtime).ljust(19) + " │"

        if not queried: # we use the cache
            lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in cached_data]
        else: # we use the new values in lines
            lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in lines]

        # we now show the list
        if vim.eval('&modifiable') != '1':
            vim.current.buffer.options['modifiable'] = True
        del vim.current.buffer[:] # clear the buffer
        vim.current.buffer.append(list(lines))
        V + "normal! dd"

    def edit(self):#{{{2
        query = vim.eval('b:pad_query')
        path = self.selected_path
        V + "bdelete"
        V + ("call pad#Open('" + path + "', '', '" + query + "')")

    def delete(self):#{{{2
        confirm = vim.eval('input("really delete? (y/n): ")')
        if confirm.lower() == "y":
            remove(self.selected_path)
            make_sure_dir_is_empty(self.selected_path)
            V + ("Pad" + ('!' if vim.eval('b:using_archive') == '1' else '') + " ls")
            V + "redraw!"

    def move_to_folder(self, path=None):#{{{2
        if not path and path != "":
            path = vim.eval('input("move to: ")')
        if not exists(join(get_save_dir(), path)):
            mkdir(join(get_save_dir(), path))
        try:
            move(self.selected_path, join(get_save_dir(), path, basename(self.selected_path)))
        except IOError as e:
            if e.errno == 20:
                V + "redraw!"
                V + ("echom 'vim-pad: cannot use that path'")
                return
        make_sure_dir_is_empty(path)
        V + ("Pad" + ('!' if vim.eval('b:using_archive') == '1' else '') + " ls")
        if path is None:
            V + "redraw!"

    def move_to_savedir(self):#{{{2
        self.move_to_folder("")

    def archive(self):#{{{2
        self.move_to_folder("archive")

    def unarchive(self):#{{{2
        self.move_to_savedir()

    def incremental_search(self):#{{{2
        """ Provides incremental search within the __pad__ buffer.
        """
        query = ""
        should_create_on_enter = False

        V + "echohl None"
        V + 'echo ">> "'
        while True:
            try:
                raw_char = vim.eval("getchar()")
                if raw_char in ("13", "27"):
                    if raw_char == "13" and should_create_on_enter:
                        V + "bwipeout"
                        V + ("call pad#Open('', '" + query + "', '')")
                        V + "echohl None"
                    V + "redraw!"
                    break
                else:
                    try:   # if we can convert to an int, we have a regular key
                        int(raw_char)   # we bring up an error on nr2char
                        last_char = vim.eval("nr2char(" + raw_char + ")")
                        query = query + last_char
                    except:  # if we don't, we have some special key
                        keycode = unicode(raw_char, errors="ignore")
                        if keycode == "kb":  # backspace
                            query = query[:-len(last_char)]
            except UnicodeDecodeError:
                query = query[:-1]
            V + "setlocal modifiable"
            pad_files = NotesCollator(get_setting('sources')).get_filelist(query)
            if pad_files != []:
                V + ("let b:pad_query = '" + query + "'")
                self.fill(pad_files, query != "")
                V + "setlocal nomodifiable"
                info = ""
                V + "echohl None"
                should_create_on_enter = False
            else:  # we will create a new pad
                del vim.current.buffer[:]
                info = "[NEW] "
                V + "echohl WarningMsg"
                should_create_on_enter = True
            V + "redraw"
            V + ('echo ">> ' + info + query + '"')

    def sort(self):#{{{2
        SORT_TYPES = {
                "1": "title",
                "2": "tags",
                "3": "date"
                }

        key = vim.eval('input("[pad] sort list by (title=1, tags=2, date=3): ", "1")')

        if key not in SORT_TYPES:
            return

        key = SORT_TYPES[key]
        if key == "date":
            V + ("Pad" + ('!' if vim.eval('b:using_archive') == '1' else '') + " ls")
            return

        tuples = []
        if key == "tags":
            view_files = [line.split()[0] for line in vim.current.buffer]
            for pad_id in view_files:
                with open(pad_id) as fi:
                    tags = sorted([tag.lower().replace("@", "")
                                    for tag in re.findall("@\w*", fi.read(200))])
                tuples.append((pad_id, tags))
            tuples = sorted(tuples, key=lambda f: f[1])
            tuples = list(filter(lambda i: i[1] != [], tuples)) + \
                     list(filter(lambda i: i[1] == [], tuples))
        elif key == "title":
            l = 1
            for line in vim.current.buffer:
                pad_id = line.split()[0]
                title = vim.eval('''split(split(substitute(getline(''' + str(l) + '''), '↲','\n', "g"), '\n')[0], ' │ ')[1]''')
                tuples.append((pad_id, title))
                l += 1
            tuples = sorted(tuples, key=lambda f: f[1])

        V + "setlocal modifiable"
        self.fill([f[0] for f in tuples], custom_order=True)
        V + "setlocal nomodifiable"
        V + "redraw!"

# vim: set fdm=marker :
