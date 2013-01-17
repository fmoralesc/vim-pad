import vim
import re
from os.path import abspath, basename
from padlib.timestamps import timestamp
from padlib.utils import get_save_dir


class PadInfo(object):
    __slots__ = "id", "summary", "body", "isEmpty", "folder"

    def __init__(self, source):
        """

        source can be:

        * a vim buffer
        * a file object
        * a list of strings, one per line
        """

        nchars = int(vim.eval("g:pad_read_nchars_from_files"))
        self.summary = ""
        self.body = ""
        self.isEmpty = True
        self.folder = ""
        self.id = timestamp()

        if source is vim.current.buffer:
            source = source[:10]
        elif source.__class__ == file:
            pos = len(get_save_dir()), len(basename(source.name))
            self.folder = abspath(source.name)[pos[0]:-pos[1]]
            source = source.read(nchars).split("\n")

        data = [line.strip() for line in source if line != ""]

        if data != []:
            # we discard modelines
            if re.match("^.* vim: set .*:.*$", data[0]):
                data = data[1:]

            self.summary = data[0].strip()
            if self.summary[0] in ("%", "#"):  # pandoc and markdown titles
                self.summary = str(self.summary[1:]).strip()

            self.body = u'\u21b2'.encode('utf-8').join(data[1:]).strip()

        if self.summary != "":
            self.isEmpty = False
            self.id = self.summary.lower().replace(" ", "_")
            # remove ilegal characters from names (using rules for windows
            # systems to err on the side of precaution)
            self.id = re.sub("[*:<>/\|^]", "", self.id)

        if self.id.startswith("."):
            self.id = re.sub("^\.*", "", self.id)
