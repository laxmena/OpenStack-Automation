import sys

#file_name = "UnitTest/hosts"
file_name = "/etc/hosts"
ip = []
block_storage_ip = []

for i in sys.argv:
	ip.append(i)

print(ip)

management_ip_name = "controller"
if(raw_input("Change Controller Node name?(y/n)") == 'y'):
	management_ip_name = raw_input("Enter Name for Controller Node: ")

management_ip = ip[1]
if len(ip) == 3:
	compute_ip = ip[2]
	compute_ip_name = "compute"
	if(raw_input("Change compute Node name?(y/n)") == 'y'):
		compute_ip_name = raw_input("Enter Name for compute Node: ")

with open(file_name,'a') as f:
	f.write('\n\n')
	f.write('%s\t%s\n'%(management_ip,management_ip_name))
	if len(ip) == 3:
		f.write('%s\t%s\n'%(compute_ip,compute_ip_name))
