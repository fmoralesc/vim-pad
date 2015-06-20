# coding=utf-8

import vim
from os.path import join

from .vim_interface import * # this introduces the 'V +' DSL
from .vim_globals import set_vim_globals
from .collator import NotesCollator
from .list import NotesListBuffer
from .pad import PadInfo

class PadPlugin(object): #{{{1
    def __init__(self): #{{{2
        sources = get_setting('sources')
        self.collator = NotesCollator(sources)
        self.list = NotesListBuffer()
        set_vim_globals()

    @prevent_invalid_dir
    def open(self, path=None, first_line=None, query=None): #{{{2
        """
        Creates or opens a note.
        """
        if not path:
            path = join(get_save_dir(),
                        PadInfo([first_line]).id + get_setting("default_file_extension"))
        path = path.replace(" ", "\ ")

        def split_for_pad():
            if get_setting('position["pads"]') == 'right':
                V + ("silent! rightbelow" + get_setting("window_width") + "vsplit " + path)
            else:
                V + ("silent! botright" + get_setting("window_height") + "split " + path)

        if get_setting("open_in_split", bool):
            split_for_pad()
        else:
            awa = int(vim.eval("&autowriteall"))
            if bool(int(vim.eval("&modified"))):
                reply = vim.eval('input("vim-pad: the current file has unsaved changes. " \
                        "do you want to save? [Yn] ", "y")')
                if reply == "y":
                    V + "set autowriteall"
                    V + ("silent! edit " + path)
                    if awa == 0:
                        V + "set noautowriteall"
                else:
                    V + 'echom "vim-pad: will have to open pad in a split"'
                    split_for_pad()
                V + "redraw!"
            else:
                V + ("silent! edit " + path)

        # we don't keep the buffer when we hide it
        V + "set bufhidden=wipe"

        # load notes functionality
        if vim.eval('&filetype') in ('', 'conf'):
            V + "set filetype=pad-notes"
        else:
            V + "runtime! ftplugin/pad-notes/*.vim"

        # reset set the filetype to our default if the pad-notes filetype is set
        if vim.eval('&filetype') == 'pad-notes':
            V + ("set filetype=" + get_setting("default_format"))

        # insert the text in first_line to the buffer, if provided
        if first_line:
            vim.current.buffer.append(first_line, 0)
            V + "normal! j"

        # highlight query and jump to it?
        if query not in ('', None):
            if get_setting('highlight_query') == '1':
                V + ("call matchadd('PadQuery', '\c" + query + "')")
            if get_setting('jumpto_query') == '1':
                V + ("call search('\c" + query + "')")

    def new(self, text=None, path=None): #{{{2
        """
        Create a new note.
        Makes sure the directory is created on writing the buffer.
        """
        self.open(path, text, None)
        if path:
            V + ("au! BufWritePre,FileWritePre <buffer> " \
                    "call mkdir(fnamemodify('" + path + "', ':h'), 'p')")

    @prevent_invalid_dir
    def display(self, query=None, use_archive=False): #{{{2
        """
        Retrieves the file list and displays it.
        """
        filelist = self.collator.get_filelist(query, use_archive)
        self.list.show(filelist, query != "")
        V + ("let b:using_archive = " + ('1' if use_archive else '0'))

    def ls(self, query=None, use_archive=False):#{{{2
        """
        Mostly, an alias for display.
        """
        self.display(query, use_archive == "!")

    @prevent_invalid_dir
    def search(self, query=None, use_archive=False):#{{{2
        """
        Prompt for a query and display a list of the matching notes.
        """
        if not query:
            query = vim.eval('input(">>> ")')
        self.display(query, use_archive == "!")
        V + "redraw!"

    @prevent_invalid_dir
    def global_incremental_search(self, should_open=True):#{{{2
        """
        Incremental search.
        """
        query = ""
        should_create_on_enter = False

        V + "echohl None"
        V + 'echo ">> "'
        while True:
            raw_char = vim.eval("getchar()")
            if raw_char in ("13", "27"):
                if raw_char == "13":
                    if should_create_on_enter:
                        if should_open == True:
                            self.open(first_line=query)
                        else:
                            path = join(get_save_dir(), \
                                    PadInfo([query]).id + \
                                    get_setting("default_file_extension"))
                            with open(path, 'w') as new_note:
                                new_note.write(query)
                        V + "echohl None"
                    else:
                        self.display(query, True)
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
            pad_files = self.collator.get_filelist(query)
            if pad_files != []:
                info = ""
                V + "echohl None"
                should_create_on_enter = False
            else:  # we will create a new pad
                info = "[NEW] "
                V + "echohl WarningMsg"
                should_create_on_enter = True
            V + "redraw"
            V + ('echo ">> ' + info + query + '"')

# vim: set fdm=marker :
