#file_name = "/etc/network/interfaces"
file_name =  "UnitTest/interfaces"

with open(file_name,'r') as f:
	for line in f:
		line = line.strip()
		if line.startswith("auto"):
			interface_card = line.split()[1]
			break

with open(file_name,'w') as f:
	f.write("# The provider network interface\n")
	f.write("auto "+interface_card+"\n")
	f.write("iface "+ interface_card +" inet manual\n")
	f.write("up ip link set dev $IFACE up\n")
	f.write("down ip link set dev $IFACE down\n")
