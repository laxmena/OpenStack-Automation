cd ..

	echo "MySQL username: "
	read mysql_username
	echo "MySQL Password"
	read mysql_pass
	mysql -u $mysql_username -p$mysql_pass -e "CREATE DATABASE keystone;"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$management_ip' IDENTIFIED BY 'KEYSTONE_DBPASS';"
	mysql -u $mysql_username -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"

	apt install keystone

	#Call Python Script
	python environment/identity_setup.py $management_ip

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