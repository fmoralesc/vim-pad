from sys import version_info
import vim
import re
from glob import glob
from os import walk
from os.path import join, isdir, basename, splitext
from subprocess import Popen, PIPE, check_output

from .vim_interface import get_setting, get_save_dir

class CollatorCache(object):
    def __init__(self):
        self.data = []
        self.timestamps = []
        self.filenames = []

class NotesSource(object):
    def __init__(self, source_dir):
        self.path_init = source_dir
        self.use_gnu_grep = False

    def path(self):
        """
        This is overriden by the source subclasses.
        """
        pass

    def __list_recursive_nohidden(self, use_archive=False, exclude_dirnames=[], path=None):
        if path == None:
            path = self.path()

        matches = []
        for root, dirnames, filenames in walk(path, topdown=True):
            for dirname in dirnames:
                if dirname.startswith('.'):
                    dirnames.remove(dirname)
                if use_archive == False:
                    if dirname == "archive":
                        dirnames.remove(dirname)
                for excluded in exclude_dirnames:
                    if dirname == excluded:
                        dirnames.remove(dirname)

            matches += [join(root, f) for f in filenames if not f.startswith('.')]
        return matches

    def __list_external(self, use_archive=False, query=None):
        search_backend = get_setting('search_backend')
        if search_backend == "grep":
            # we use Perl mode for grep (-P) if available, because it is really fast
            if self.use_gnu_grep or re.search('GNU grep', str(check_output(['grep', '--version']))):
                command = ["grep", "-P", "-n", "-r", "-l", query, self.path() + "/"]
                self.use_gnu_grep = True
            else:
                command = ["grep", "-n", "-r", "-l", query, self.path() + "/"]
            if not use_archive:
                command.append("--exclude-dir=archive")
            command.append('--exclude=.*')
            command.append("--exclude-dir=.git")
            command.append("--max-count=1")
        elif search_backend == "ack":
            if vim.eval("executable('ack')") == "1":
                ack_path = "ack"
            else:
                ack_path = "/usr/bin/vendor_perl/ack"
            command = [ack_path, query, self.path(), "--noheading", "-l"]
            if not use_archive:
                command.append("--ignore-dir=archive")
            command.append('--ignore-file=match:/\./')
        elif search_backend == "ag":
            if vim.eval("executable('ag')") == "1":
                command = ["ag", query, self.path(), "--noheading", "-l"]
                if not use_archive:
                    command.append("--ignore-dir=archive")
        elif search_backend == "pt":
            if vim.eval("executable('pt')") == "1":
                command = ["pt", "-l", "--nogroup"]
                if not use_archive:
                    command.append("--ignore=archive")
                command.append(query)
                command.append(self.path())

        if get_setting('search_ignorecase', bool):
            command.append("-i")

        cmd_output = Popen(command, stdout=PIPE, stderr=PIPE).communicate()[0].decode('utf-8').split('\n')

        return list(filter(lambda i: i != "", cmd_output))

    def query(self, query=None, use_archive=False):
        exclude_dirnames = get_setting('exclude_dirnames').split(',')
        if not query or query == "":
            files = self.__list_recursive_nohidden(use_archive, exclude_dirnames)
        else:
            query_filenames = get_setting('query_filenames', bool)
            query_dirnames = get_setting('query_dirnames', bool)

            files = self.__list_external(use_archive, query)

            if query_filenames:
                matches = filter(lambda i: \
                        not isdir(i) and \
                        i not in files, glob(join(self.path(), "*"+query+"*")))
                files.extend(matches)

            if query_dirnames:
                # first, filter out things which are not directories, and then the archive if needed
                matching_dirs = filter(lambda x: basename(x) != 'archive' if not use_archive else True,\
                        filter(isdir, glob(join(self.path(), "*"+ query+"*"))))
                for mdir in matching_dirs:
                    files.extend(filter(lambda x: x not in files, \
                            self.__list_recursive_nohidden(use_archive,
                                                           exclude_dirnames, mdir)))

        if version_info.major == 2:
            return map(lambda x: x.encode('utf-8') if isinstance(x, unicode) else x, files)
        return files

class LocalNotesSource(NotesSource):
    """
    A source of notes located in a path relative to the current working directory.
    """
    def path(self):
        return join(vim.eval("getcwd()"), self.path_init)

class DirNotesSource(NotesSource):
    """
    A source of notes located at a static path.
    """
    def path(self):
        return self.path_init

class NotesCollator(object):
    def __init__(self, sources):
        self.cache = CollatorCache()
        self.sources = []
        for source in sources:
            source_init = re.split(':', source)
            if re.match('dir', source):
                if len(source_init) == 1:
                    self.sources.append(DirNotesSource(get_save_dir()))
                else:
                    self.sources.append(DirNotesSource(source_init[1]))
            elif re.match('local', source):
                if len(source_init) == 1:
                    self.sources.append(LocalNotesSource(get_setting('local_dir')))
                else:
                    self.sources.append(LocalNotesSource(source_init[1]))

    def get_filelist(self, query=None, use_archive=False):
        files = []
        for source in self.sources:
            files.extend(source.query(query, use_archive))
        ie = ['.' + e for e in get_setting('ignored_extensions')]
        files = list(filter(lambda x: splitext(x)[1] not in ie, set(files)))
        return files
