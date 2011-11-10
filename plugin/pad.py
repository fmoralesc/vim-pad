# coding=utf-8

import vim
import time
import datetime
import re
from os import remove, listdir
from os.path import expanduser, exists, basename, join, getmtime
from shutil import move
from subprocess import Popen, PIPE

def pad_timestamp():
	"""pad_timestamp() -> timestamp_string
	
	Returns a string of digits representing the current time.
	"""
	return str(int(time.time() * 1000000))

def pad_natural_timestamp(timestamp):
	"""pad_natural_timestamp(timestamp) -> natural_timestamp
	
	Returns a string representing a datetime object.

	    timestamp: a string in the format returned by pad_timestamp.

	The output uses a natural format for timestamps within the previous
	24 hours, and the format %Y-%m-%d %H:%M:%S otherwise.
	"""
	timestamp = basename(timestamp)
	f_timestamp = float(int(timestamp)) / 1000000
	tmp_datetime = datetime.datetime.fromtimestamp(f_timestamp)
	diff = datetime.datetime.now() - tmp_datetime
	days = diff.days
	seconds = diff.seconds
	minutes = seconds/60
	hours = minutes/60
	
	if days > 0:
		return tmp_datetime.strftime("%Y-%m-%d %H:%M:%S")
	if hours < 1:
		if minutes < 1:
			return str(seconds) + "s ago"
		else:
			seconds_diff = seconds - (minutes * 60)
			if seconds_diff != 0:
				return str(minutes) + "m and " + str(seconds_diff) + "s ago"
			else:
				return str(minutes) + "m ago"
	else:
		minutes_diff = minutes - (hours * 60)
		if minutes_diff != 0:
			return str(hours) + "h and " + str(minutes_diff) + "m ago"
		else:
			return str(hours) + "h ago"

class Pad(object):
	"""This handles all the operations of the plugin. 
	It works as a namespace of sorts."""

	def __init__(self):
		"""
		Updates the internal variables and initializes the caches.

		Adjusts some external options.
		"""
		self.save_dir = vim.eval("g:pad_dir")
		self.save_dir_set = self.save_dir != ""
		self.filetype = vim.eval("g:pad_format")
		self.window_height = str(vim.eval("g:pad_window_height"))
		self.search_backend = vim.eval("g:pad_search_backend")
		self.ignore_case = bool(int(vim.eval("g:pad_search_ignorecase")))
		self.read_chars = int(vim.eval("g:pad_read_nchars_from_files"))

		# vim-pad pollutes the MRU.vim list quite a lot, if let alone.
		# This should fix that.
		if vim.eval('exists(":MRU")') == "2":
			mru_exclude_files = vim.eval("MRU_Exclude_Files")
			if mru_exclude_files != '':
				tail = "\|" + mru_exclude_files
			else:
				tail = ''
			vim.command("let MRU_Exclude_Files = '^" + 
					self.save_dir.replace("~", expanduser("~")) + "/*" + tail + "'")

		# we forbid writing backups of the notes
		orig_backupskip = vim.eval("&backupskip")
		vim.command("set backupskip=" + 
				",".join([orig_backupskip, self.save_dir.replace("~", expanduser("~")) + "/*"]))

		self.cached_data = []
		self.cached_timestamps = []
		self.cached_filenames = []

	# Pads

	def pad_open(self, path=None, first_line=None):
		"""Creates or opens a note.

		path: a valid path for a note.

		first_line: a string to insert to a new note, if given.
		"""
		# we require self.save_dir_set to be set to a valid path
		if not self.save_dir_set:
			vim.command('let tmp = confirm("IMPORTANT:\n'\
					'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
			return
		
		# if no path is provided, we create one using the current time
		if not path:
			path = join(self.save_dir, pad_timestamp())

		vim.command("silent! botright" + self.window_height + "split " + path)
		
		# set the filetype to our default
		if vim.eval('&filetype') in ('', 'conf'):
			vim.command("set filetype=" + self.filetype)
		
		# map the local commands
		if vim.eval('has("gui_running")') == "1":
			vim.command("noremap <silent> <buffer> <localleader><delete> :py pad.pad_delete()<cr>")
		else:
			vim.command("noremap <silent> <buffer> <localleader>dd :py pad.pad_delete()<cr>")

		vim.command("noremap <silent> <buffer> <localleader>+m :py pad.pad_add_modeline()<cr>")
		
		# insert the text in first_line to the buffer, if provided
		if first_line:
			vim.current.buffer.append(first_line,0)
			vim.command("normal! j")

	def pad_update(self):
		""" Moves a note to a new location if its contents are modified.

		Called on the BufLeave event for the notes.

		"""
		modified = bool(int(vim.eval("b:pad_modified")))
		if modified:
			old_path = expanduser(vim.current.buffer.name)
			new_path = expanduser(join(self.save_dir, pad_timestamp()))
			vim.command("bw")
			move(old_path, new_path)

	def pad_delete(self):
		""" (Local command) Deletes the current note.
		"""
		path = vim.current.buffer.name
		if exists(path):
			confirm = vim.eval('input("really delete? (y/n): ")')
			if confirm in ("y", "Y"):
				remove(path)
				vim.command("bd!")
				vim.command("redraw!")

	def pad_add_modeline(self):
		""" (Local command) Add a modeline to the current note.
		"""
		mode = vim.eval('input("filetype: ", "", "filetype")')
		if mode:
			vim.current.buffer.append("<!-- vim: set ft=" + mode + ": -->", 0)
			vim.command("set filetype=" + mode)
			vim.command("set nomodified")

	# Pad List:

	def __get_filelist(self, query=None):
		""" __get_filelist(query) -> list_of_notes

		Returns a list of notes. If no query is provided, all the valid filenames in
		self.save_dir are returned in a list, otherwise, return the results of grep
		or ack search for query in self.save_dir.
		"""
		if not query or query == "":
			files = listdir(expanduser(self.save_dir))
		else:
			if self.search_backend == "grep":
				# we use Perl mode for grep (-P), because it is really fast
				command = ["grep", "-P", "-n", "-r", query, expanduser(self.save_dir) + "/"]
			elif self.search_backend == "ack":
				if vim.eval("executable('ack')") == "1":
					ack_path = "ack"
				else:
					ack_path = "/usr/bin/vendor_perl/ack"
				command = [ack_path, query, expanduser(self.save_dir) + "/", "--type=text"]
			
			if self.ignore_case:
				command.append("-i")
			command.append("--max-count=1")
			
			search_results = [line.split(":")[0] 
					for line in Popen(command, stdout=PIPE, stderr=PIPE).communicate()[0].\
								replace(expanduser(self.save_dir) + "/", "").\
								split("\n")	if line != '']	
			
			files = list(reversed(sorted(search_results)))
		
		# we are interested only on the files whose name is a digit, because it means they are created by us
		return filter(lambda p: basename(p).isdigit() == True, files)

	
	def __fill_list(self, files, queried=False):
		""" Writes the list of notes to the __pad__ buffer.

		files: a list of files to process.

		queried: whether files is the result of a query or not.

		Keeps a cache so we only read the notes when the files have been modified.
		"""
		timestamps = [getmtime(expanduser(self.save_dir) + "/" + f) for f in files]
		
		# we will have a new list only on the following cases
		if queried or files != self.cached_filenames or timestamps != self.cached_timestamps:
			lines = []
			for pad in files:
				with open(join(expanduser(self.save_dir), pad)) as pad_file:
					data = [line for line in pad_file.read(self.read_chars).split("\n") if line != ""]
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
				self.cached_data = lines
				self.cached_timestamps = timestamps
				self.cached_filenames = files

		# update natural timestamps
		def add_natural_timestamp(matchobj):
			id_string = matchobj.group("id")
			return id_string + " @ " + pad_natural_timestamp(id_string).ljust(19) + " │"
		
		if not queried: # we use the cache
			lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in self.cached_data]
		else: # we use the new values in lines
			lines = [re.sub("(?P<id>^.*?) @", add_natural_timestamp, line) for line in lines]

		# we now show the list
		del vim.current.buffer[:] # clear the buffer
		vim.current.buffer.append(list(reversed(sorted(lines))))
		vim.command("normal! dd")
		vim.command("setlocal nomodifiable")
	
	def list_pads(self, query):
		""" Shows a list of notes.

		query: a string representing a regex search. Can be "".

		Builds a list of files for query and then processes it to show the list in the pad format.
		"""
		if not self.save_dir_set:
			vim.command('let tmp = confirm("IMPORTANT:\n'\
					'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
			return
		pad_files = self.__get_filelist(query)
		if len(pad_files) > 0:
			if vim.eval("bufexists('__pad__')") == "1":
				vim.command("bw __pad__")
			vim.command("silent! botright " + self.window_height + "new __pad__")
			self.__fill_list(pad_files, query != "")
			vim.command("set filetype=pad")
		else:
			print "no pads"

	def search_pads(self):
		""" Aks for a query and lists the matching notes.
		"""
		if not self.save_dir_set:
			vim.command('let tmp = confirm("IMPORTANT:\n'\
					'Please set g:pad_dir to a valid path in your vimrc.", "OK", 1, "Error")')
			return
		query = vim.eval('input(">>> ")')
		self.list_pads(query)
		vim.command("redraw!")

	def incremental_search(self):
		""" Provides incremental search within the __pad__ buffer.
		"""
		query = ""
		should_create_on_enter = False
		
		vim.command("echohl None")
		vim.command('echo ">> "')
		while True:
			raw_char = vim.eval("getchar()")
			if raw_char in ("13", "27"):
				if raw_char == "13" and should_create_on_enter:
					vim.command("bw")
					self.pad_open(first_line=query)
					vim.command("echohl None")
				vim.command("redraw!")
				break
			else:
				try: # if we can convert to an int, we have a regular key
					int(raw_char) # we check this way so we bring up an error on nr2char
					last_char = vim.eval("nr2char(" + raw_char + ")")
					query = query + last_char
				except: # if we don't, we have some special key
					keycode = unicode(raw_char, errors="ignore")
					if keycode == "kb": # backspace
						query = query[:-len(last_char)]
			vim.command("setlocal modifiable")
			pad_files = self.__get_filelist(query)
			if pad_files != []:
				self.__fill_list(pad_files, query != "")
				info = ""
				vim.command("echohl None")
				should_create_on_enter = False
			else: # we will create a new pad
				del vim.current.buffer[:]
				info = "[NEW] "
				vim.command("echohl WarningMsg")
				should_create_on_enter = True
			vim.command("redraw")
			vim.command('echo ">> ' + info + query + '"')
	
	def edit_pad(self):
		""" Opens the currently selected note in the __pad__ buffer.
		"""
		path = join(self.save_dir, vim.current.line.split(" @")[0])
		vim.command("bd")
		self.pad_open(path=path)

	def delete_pad(self):
		""" Deletes the currently selected note in the __pad__ buffer.
		"""
		confirm = vim.eval('input("really delete? (y/n): ")')
		if confirm in ("y", "Y"):
			path = join(expanduser(self.save_dir), vim.current.line.split(" @")[0])
			remove(path)
			vim.command("bd")
			vim.command("redraw!")
