import vim
import re
from padlib.timestamps import timestamp

class PadInfo(object):
	__slots__ = "id", "summary", "body", "isEmpty"

	def __init__(self, source):
		nchars = int(vim.eval("g:pad_read_nchars_from_files"))
		self.summary = ""
		self.body = ""
		self.isEmpty = True
		self.id = timestamp()

		if source is vim.current.buffer:
			source = source[:10]
		elif source.__class__ == file:
			source = source.read(nchars).split("\n")
		
		data = [line.strip() for line in source if line != ""]

		if data != []:
			# we discard modelines
			if re.match("^.* vim: set .*:.*$", data[0]):
				data = data[1:]
			
			self.summary = data[0].strip()
			if self.summary[0] in ("%", "#"): #pandoc and markdown titles
				self.summary = str(self.summary[1:]).strip()
			
			self.body = u'\u21b2'.encode('utf-8').join(data[1:]).strip()

		if self.summary != "":
			self.isEmpty = False
			self.id = "".join(i for i in self.summary \
					if i.isalnum() or i.isspace()).\
					replace(" ", "_").lower() 
