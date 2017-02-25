echo "************Welcome to Openstack installation************"
echo "
1. Controller Node
2. Compute Node
Your Choice:"
read choice

if [ $choice == 1 ]
then
	echo "************Setting up Controller Node************"
elif [ $choice == 2 ]
then
	echo "************Setting up Compute Node************"
	echo "Enter Compute node IP: "
	read compute_ip
fi

echo "Enter Management IP: "
read management_ip

cd ..

#Python Script to edit Network Card Configurations
python environment/interface_setup.py

#Python Script to edit hosts
if [ $choice == 1 ]
then
	python environment/hosts_setup.py $management_ip
elif [ $choice == 2 ]
then
 	#statements 
 	python environment/hosts_setup.py $management_ip $compute_ip
fi
