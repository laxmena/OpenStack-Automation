cd ..

echo "MySQL username: "
read mysql_username
echo "MySQL Password"
read mysql_pass

echo "CHoice: "
read choice

echo "Management IP"
read management_ip

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
