cd ..

echo "MySQL username: "
read mysql_username
echo "MySQL Password"
read mysql_pass

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
	#python environment/glance_setup.py $management_ip
	python environment/glance_setup.py 10.0.10.0
	su -s /bin/sh -c "glance-manage db_sync" glance
	service glance-registry restart
	service glance-api restart