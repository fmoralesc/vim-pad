import vim
import re
from os.path import abspath, basename, dirname, relpath
from vim_pad.timestamps import timestamp
from vim_pad.utils import get_save_dir


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
        elif source.__class__ == file:
            save_dir = get_save_dir()
            if abspath(source.name).startswith(save_dir):
                pos = len(get_save_dir()), len(basename(source.name))
                self.folder = abspath(source.name)[pos[0]:-pos[1]]
            else:
                self.folder = dirname(relpath(source.name, vim.eval('getcwd()')))
            source = source.read(nchars).split("\n")

        data = [line.strip() for line in source if line != ""]

        if data != []:
            # we discard modelines
            if re.match("^.* vim: set .*:.*$", data[0]):
                data = data[1:]

            self.summary = data[0].strip()
            # vim-orgmode adds tags after whitespace
            org_tags_data = re.search("\s+(?P<tags>:.*$)", self.summary)
            if org_tags_data:
                self.summary = re.sub("\s+:.*$", "", self.summary)
            if self.summary[0] in ("%", "#"):  # pandoc and markdown titles
                self.summary = str(self.summary[1:]).strip()

            self.body = u'\u21b2'.encode('utf-8').join(data[1:]).strip()
            # if we have orgmode tag data, add it to the body
            if org_tags_data:
                self.body = ' '.join(\
                    [" ".join(\
                              map(lambda a: "@" + a, \
                                  filter(lambda a: a != "", \
                                         org_tags_data.group("tags").split(":")))), \
                     self.body])
            # remove extra spaces in bodies
            self.body = re.sub("\s{2,}", "", self.body)

        if self.summary != "":
            self.isEmpty = False
            self.id = self.summary.lower().replace(" ", "_")
            # remove ilegal characters from names (using rules for windows
            # systems to err on the side of precaution)
            self.id = re.sub("[*:<>/\|^]", "", self.id)

        if self.id.startswith("."):
            self.id = re.sub("^\.*", "", self.id)
