import sys
import fileinput

file_name = "/etc/memcached.conf"
#file_name = "UnitTest/memcached.conf"

ip = sys.argv[1]

for line in fileinput.input(file_name, inplace=1):
	print line.replace("-l 127.0.0.1","-l %s"%ip),