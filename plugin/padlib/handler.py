# vim: set fdm=marker fdc=2 :
# coding=utf-8

# imports {{{1
import vim
import re
from os import listdir
from os.path import join, getmtime, isfile, isdir
from subprocess import Popen, PIPE
from padlib.utils import get_save_dir
from padlib.pad import PadInfo
from padlib.timestamps import timestamp, natural_timestamp

# globals (caches) {{{1
cached_data = []
cached_timestamps = []
cached_filenames = []

def open_pad(path=None, first_line=None): #{{{1
    """Creates or opens a note.

    path: a valid path for a note.

    first_line: a string to insert to a new note, if given.
    """
    # we require self.save_dir_set to be set to a valid path
    if get_save_dir() == "":
        vim.command('let tmp = confirm("IMPORTANT:\n'\
                'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
        return

    # if no path is provided, we create one using the current time
    if not path:
        path = join(get_save_dir(), timestamp())

    vim.command("silent! botright" + str(vim.eval("g:pad_window_height")) + "split " + path)

    # set the filetype to our default
    if vim.eval('&filetype') in ('', 'conf'):
        vim.command("set filetype=" + vim.eval("g:pad_default_format"))

    # map the local commands
    if bool(int(vim.eval('has("gui_running")'))):
        vim.command("noremap <silent> <buffer> <localleader><delete> :call pad#DeleteThis()<cr>")
    else:
        vim.command("noremap <silent> <buffer> <localleader>dd :call pad#DeleteThis()<cr>")

    vim.command("noremap <silent> <buffer> <localleader>+m :call pad#AddModeline()<cr>")

    # insert the text in first_line to the buffer, if provided
    if first_line:
        vim.current.buffer.append(first_line,0)
        vim.command("normal! j")


def get_filelist(query=None): # {{{1
    """ __get_filelist(query) -> list_of_notes

    Returns a list of notes. If no query is provided, all the valid filenames in
    self.save_dir are returned in a list, otherwise, return the results of grep
    or ack search for query in self.save_dir.
    """
    if not query or query == "":
        files = listdir(get_save_dir())
    else:
        search_backend = vim.eval("g:pad_search_backend")
        if search_backend == "grep":
            # we use Perl mode for grep (-P), because it is really fast
            command = ["grep", "-P", "-n", "-r", query, get_save_dir() + "/"]
        elif search_backend == "ack":
            if vim.eval("executable('ack')") == "1":
                ack_path = "ack"
            else:
                ack_path = "/usr/bin/vendor_perl/ack"
            command = [ack_path, query, get_save_dir() + "/", "--type=text"]

        if bool(int(vim.eval("g:pad_search_ignorecase"))):
            command.append("-i")
        command.append("--max-count=1")

        files = [line.split(":")[0]
                for line in Popen(command, stdout=PIPE, stderr=PIPE).communicate()[0].\
                        replace(get_save_dir() + "/", "").\
                        split("\n")	if line != '']

    return files

def fill_list(files, queried=False, custom_order=False): # {{{1
    """ Writes the list of notes to the __pad__ buffer.

    files: a list of files to process.

    queried: whether files is the result of a query or not.

    custom_order: whether we should keep the order of the list given (implies queried=True).

    Keeps a cache so we only read the notes when the files have been modified.
    """
    global cached_filenames, cached_timestamps, cached_data

    # we won't want to touch the cache
    if custom_order:
        queried = True

    timestamps = [getmtime(join(get_save_dir(), f)) for f in files]

    # we will have a new list only on the following cases
    if queried or files != cached_filenames or timestamps != cached_timestamps:
        lines = []
        if not custom_order:
            files = reversed(sorted(files, key=lambda i: getmtime(join(get_save_dir(), i))))
        for pad in files:
            pad_path = join(get_save_dir(), pad)
            if isfile(pad_path):
                with open(join(get_save_dir(), pad)) as pad_file:
                    info = PadInfo(pad_file)
                    if info.isEmpty:
                        tail = "[EMPTY]"
                    else:
                        tail = u'\u21b2'.encode('utf-8').join((info.summary, info.body))
                    lines.append(pad + " @ " + tail)
            elif isdir(pad_path):
                pass # TODO: set some behavior for directories (recurse?)
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
    del vim.current.buffer[:] # clear the buffer
    vim.current.buffer.append(list(lines))
    vim.command("normal! dd")

def display(query): # {{{1
    """ Shows a list of notes.

    query: a string representing a regex search. Can be "".

    Builds a list of files for query and then processes it to show the list in the pad format.
    """
    if get_save_dir() == "":
        vim.command('let tmp = confirm("IMPORTANT:\n'\
                'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
        return
    pad_files = get_filelist(query)
    if len(pad_files) > 0:
        if vim.eval("bufexists('__pad__')") == "1":
            vim.command("bw __pad__")
        vim.command("silent! botright " + str(vim.eval("g:pad_window_height")) + "new __pad__")
        fill_list(pad_files, query != "")
        vim.command("set filetype=pad")
        vim.command("setlocal nomodifiable")
    else:
        print "no pads"

def search_pads(): # {{{1
    """ Aks for a query and lists the matching notes.
    """
    if get_save_dir() == "":
        vim.command('let tmp = confirm("IMPORTANT:\n'\
                'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
        return
    query = vim.eval('input(">>> ")')
    display(query)
    vim.command("redraw!")

