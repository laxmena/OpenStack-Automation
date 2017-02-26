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


#Install MySQL Server here
apt install mysql-server


echo "MySQL username: "
read mysql_username
echo "MySQL Password"
read mysql_pass



#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#***********************Environment***********************
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#******************Network Setup******************
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

#******************Network Setup ENd******************


#******************Chrony******************
#Install Chrony
apt install chrony

#Setup chrony
if [ $choice == 1 ]
then
	python environment/chrony_setup.py controller $management_ip
elif [ $choice == 2 ]
then=
	python environment/chrony_setup.py compute $management_ip
fi

#Restart chrony
service chrony restart

#Verification of Chrony
echo "Verification Operation - Chrony"
chronyc sources

if [ $? == 0 ]
then
	echo "chrony successfully setup"
else
then
	echo "Some error occured during chrony installation"	
fi
#******************Chrony End******************



#******************Open Stack Packages******************
apt install software-properties-common
add-apt-repository cloud-archive:newton
apt update
apt install python-openstackclient
#******************Open Stack Packages End******************




#******************SQL Database******************

#Setup SQL Database for OpenStack
apt install mariadb-server python-pymysql
#Call Python Script to modify changes in 50-server.cnf
python environment/mysql_setup.py $management_ip
#Restart MySQL service
service mysql restart
echo "Securing MySQL Database"
mysql_secure_installation
#******************SQL Database End******************



#******************Message Queue Service******************
apt install rabbitmq-server
echo "Creating openstack User for RabbitMQ"
rabbitmqctl add_user openstack RABBIT_PASS
#Set permissions for openstack user
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
#******************Message Queue Service End******************


#******************Memcached Service******************
apt install memcached python-memcache
#Python Script to setup Memcache service
python environment/memcached_setup.py $management_ip
#Restart Service
service memcached restart
#******************Memcached Service End******************



#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#*********************Identity Service********************
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

if [ $choice == 1 ]
then
	mysql -u $mysql_username -p$mysql_pass -e "CREATE DATABASE keystone;"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$management_ip' IDENTIFIED BY 'KEYSTONE_DBPASS';"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"

	apt install keystone

	#Call Python Script
	python Identity/identity_setup.py $management_ip

	su -s /bin/sh -c "keystone-manage db_sync" keystone
	keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
	keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

	keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
	  --bootstrap-admin-url http://$management_ip:35357/v3/ \
	  --bootstrap-internal-url http://$management_ip:35357/v3/ \
	  --bootstrap-public-url http://$management_ip:5000/v3/ \
	  --bootstrap-region-id RegionOne

	rm -f /var/lib/keystone/keystone.db
	export OS_USERNAME=admin
	export OS_PASSWORD=ADMIN_PASS
	export OS_PROJECT_NAME=admin
	export OS_USER_DOMAIN_NAME=Default
	export OS_PROJECT_DOMAIN_NAME=Default
	export OS_AUTH_URL=http://$management_ip:35357/v3
	export OS_IDENTITY_API_VERSION=3

	#Create a domain, projects, users, and roles
	openstack project create --domain default \
	  --description "Service Project" service
	openstack project create --domain default \
	  --description "Demo Project" demo
	openstack user create --domain default \
	  --password-prompt demo
	openstack role create user
	openstack role add --project demo --user demo user

	unset OS_AUTH_URL OS_PASSWORD

	openstack --os-auth-url http://$management_ip:35357/v3 \
	  --os-project-domain-name Default --os-user-domain-name Default \
	  --os-project-name admin --os-username admin token issue

	openstack --os-auth-url http://$management_ip:5000/v3 \
	  --os-project-domain-name Default --os-user-domain-name Default \
	  --os-project-name demo --os-username demo token issue

	echo "
	export OS_PROJECT_DOMAIN_NAME=Default
	export OS_USER_DOMAIN_NAME=Default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=ADMIN_PASS
	export OS_AUTH_URL=http://$management_ip:35357/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2" > admin-openrc

	echo "
	export OS_PROJECT_DOMAIN_NAME=Default
	export OS_USER_DOMAIN_NAME=Default
	export OS_PROJECT_NAME=demo
	export OS_USERNAME=demo
	export OS_PASSWORD=DEMO_PASS
	export OS_AUTH_URL=http://$management_ip:5000/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2" > demo-openrc

	. admin-openrc

	openstack token issue
fi

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#***********************Image Service*********************
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
if [ $choice == 1 ]
then
	mysql -u $mysql_username -p$mysql_pass -e "CREATE DATABASE glance;"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$management_ip' IDENTIFIED BY 'GLANCE_DBPASS';"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"

	. admin-openrc

	echo "


	Glance installation! 
	Prefered Password: GLANCE_PASS
	"
	openstack user create --domain default --password-prompt glance
	openstack role add --project service --user glance admin
	#Create Glance Service
	openstack service create --name glance --description "OpenStack Image" image

	#Create EndPoints
	openstack endpoint create --region RegionOne image public http://$management_ip:9292
	openstack endpoint create --region RegionOne image internal http://$management_ip:9292
	openstack endpoint create --region RegionOne image admin http://$management_ip:9292

	#Install and configure components
	apt install glance

	#Call Python Script
	python Image/glance_setup.py $management_ip

	su -s /bin/sh -c "glance-manage db_sync" glance
	service glance-registry restart
	service glance-api restart

	#-------------------------------------------------------------
	#******************Verification Operation*********************
	#-------------------------------------------------------------
	. admin-openrc
	wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
	openstack image create "cirros" \
	  --file cirros-0.3.4-x86_64-disk.img \
	  --disk-format qcow2 --container-format bare \
	  --public
	openstack image list
fi

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#**********************Compute Service********************
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

mysql -u $mysql_username -p$mysql_pass -e "CREATE DATABASE nova_api;"
mysql -u $mysql_username -p$mysql_pass -e "CREATE DATABASE nova;"
mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'$management_ip'IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$management_ip' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'  IDENTIFIED BY 'NOVA_DBPASS';"

. admin-openrc

openstack user create --domain default \
	--password-prompt nova
	openstack role add --project service --user nova admin

	#Create Nova Service Entity
	openstack service create --name nova \
	--description "OpenStack Compute" compute

	#Create Compute service endpoints
	openstack endpoint create --region RegionOne \
compute public http://$management_ip:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
compute internal http://$management_ip:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
compute admin http://$management_ip:8774/v2.1/%\(tenant_id\)s

#Install Packages
if [ $choice == 1 ]
then
	apt install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
else
	apt install nova-compute
fi

#Call Python Script
if [ $choice == 1 ]
then
	python Compute/compute_setup.py controller $management_ip
	su -s /bin/sh -c "nova-manage api_db sync" nova
	su -s /bin/sh -c "nova-manage db sync" nova
	service nova-api restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart
else
	python Compute/compute_setup.py compute $management_ip
	service nova-compute restart
fi 

#Verification Process
. admin-openrc
openstack compute service list
if [ $? == 0 ]
then
	echo "Nova successfully setup"
else
then
	echo "Some error occured during Nova installation"	
fi