#chrony_setup.py

import sys

filename = "/etc/chrony/chrony.conf"
#filename = "UnitTest/chrony.conf"

print(sys.argv)
node = sys.argv[1]
ip = sys.argv[2]

with open(filename,'a') as f:
 	f.write("\n")
 	f.write("server %s iburst\n"%ip) 
 	if node=="controller":
 		f.write("allow %s/24"%ip)