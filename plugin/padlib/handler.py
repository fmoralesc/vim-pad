# coding=utf-8

import vim
import re
from os import listdir
from os.path import join, getmtime, basename
from subprocess import Popen, PIPE
from padlib.utils import get_save_dir
from padlib.timestamps import timestamp, natural_timestamp

cached_data = []
cached_timestamps = []
cached_filenames = []

def open_pad(path=None, first_line=None):
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


def get_filelist(query=None):
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
		
		search_results = [line.split(":")[0] 
				for line in Popen(command, stdout=PIPE, stderr=PIPE).communicate()[0].\
							replace(get_save_dir() + "/", "").\
							split("\n")	if line != '']	
		
		files = list(reversed(sorted(search_results)))
	
	# we are interested only on the files whose name is a digit, because it means they are created by us
	return filter(lambda p: basename(p).isdigit() == True, files)


def fill_list(files, queried=False):
	""" Writes the list of notes to the __pad__ buffer.

	files: a list of files to process.

	queried: whether files is the result of a query or not.

	Keeps a cache so we only read the notes when the files have been modified.
	"""
	global cached_filenames, cached_timestamps, cached_data
	timestamps = [getmtime(join(get_save_dir(), f)) for f in files]
	
	# we will have a new list only on the following cases
	if queried or files != cached_filenames or timestamps != cached_timestamps:
		lines = []
		for pad in files:
			with open(join(get_save_dir(), pad)) as pad_file:
				data = [line for line in pad_file.read(int(vim.eval("g:pad_read_nchars_from_files"))).\
						split("\n") if line != ""]
			if data != []:
				# we discard modelines
				if re.match("^.* vim: set .*:.*$", data[0]):
					data = data[1:]
				
				summary = data[0].strip()
				if summary[0] in ("%", "#"): #pandoc and markdown titles
					summary = "".join(summary[1:]).strip()
				
				body = "\n".join([line.strip() for line in data[1:]]).\
						replace("\n", u'\u21b2 '.encode('utf-8'))
				
				tail = ''
				if data[1:] not in ([''], []):
					tail = u'\u21b2'.encode('utf-8') + ' ' +  body

				lines.append(pad + " @ " + summary + tail)
			else:
				lines.append(pad + " @ " + "[EMPTY]")
		
		# we only update the cache if we are not queried, to preserve the global cache
		if not queried:
			cached_data = lines
			cached_timestamps = timestamps
			cached_filenames = files

	# update natural timestamps
	def add_natural_timestamp(matchobj):
		id_string = matchobj.group("id")
		return id_string + " @ " + natural_timestamp(id_string).ljust(19) + " │"
	
	if not queried: # we use the cache
		lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in cached_data]
	else: # we use the new values in lines
		lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in lines]

	# we now show the list
	del vim.current.buffer[:] # clear the buffer
	vim.current.buffer.append(list(reversed(sorted(lines))))
	vim.command("normal! dd")

def display(query):
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

def search_pads():
	""" Aks for a query and lists the matching notes.
	"""
	if get_save_dir() == "":
		vim.command('let tmp = confirm("IMPORTANT:\n'\
				'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
		return
	query = vim.eval('input(">>> ")')
	display(query)
	vim.command("redraw!")

