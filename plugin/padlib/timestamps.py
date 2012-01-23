import time
import datetime
from os.path import basename

def timestamp():
	"""timestamp() -> str:timestamp
	
	Returns a string of digits representing the current time.
	"""
	return str(int(time.time() * 1000000))

def natural_timestamp(timestamp):
	"""natural_timestamp(str:timestamp) -> str:natural_timestamp
	
	Returns a string representing a datetime object.

		timestamp: a string in the format returned by pad_timestamp.

	The output uses a natural format for timestamps within the previous
	24 hours, and the format %Y-%m-%d %H:%M:%S otherwise.
	"""
	timestamp = basename(timestamp)
	f_timestamp = float(timestamp) / 1000000
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

