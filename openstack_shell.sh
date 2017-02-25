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


#Check Network connectivity
ping -c 4 openstack.org
if [ $? == 0 ]
then
	echo "Internet connection available"
fi

#Install Chrony

apt install chrony

#Setup chrony for compute node
if [ $choice == 1 ]
then
	#Edit /etc/chrony/chrony.conf file in controller
	#Python Script does the changes in the conf file
	python chrony_controller.py
elif[ $choice == 2]
then
	#Edit /etc/chrony/chrony.conf file in compute node
	#Python Script chrony_compute.py does the changes
	python chrony_compute.py
fi

service chrony restart

echo "Verification Operation - Chrony"

chronyc sources
if [ $? == 0 ]
then
	echo "chrony successfully setup"
else
then
	echo "Some error occured during chrony installation"	
fi

apt install software-properties-common
add-apt-repository cloud-archive:newton
apt update
apt install python-openstackclient

#Install MySQL Server here
apt install mysql-server

#Setup SQL Database for OpenStack
apt install mariadb-server python-pymysql

#Call Python Script to modify changes in 50-server.cnf
python mysql_setup.py

#Restart MySQL service
service mysql restart

echo "Securing MySQL Database"
mysql_secure_installation

#Message Queue Service
apt install rabbitmq-server

echo "Creating openstack User for RabbitMQ"
rabbitmqctl add_user openstack RABBIT_PASS

#Set permissions for openstack user
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#Memcached Service
apt install memcached python-memcache

#Python Script to setup Memcache service
python memcached_setup.py

#Restart Service
service memcached restart