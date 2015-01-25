from os import rmdir
from os.path import split
from sys import version_info

def make_sure_dir_is_empty(path):
    try:
        rmdir(split(path)[0])
    except:
        pass

def U(string):
    if version_info.major == 2:
        return string.encode('utf-8')
    elif version_info.major == 3:
        return string


