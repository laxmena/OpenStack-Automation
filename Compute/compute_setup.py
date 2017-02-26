import sys
import ConfigParser

node = sys.argv[1]
ip = sys.argv[2]

file_name = "/etc/nova/nova.conf"
#file_name = "UnitTest/nova.conf"

config = ConfigParser.ConfigParser(allow_no_value=True)
config.read(file_name)

sections = config.sections()


if 'keystone_authtoken' not in sections:
	config.add_section('keystone_authtoken')
if 'vnc' not in sections:
	config.add_section('vnc')
if 'glance' not in sections:
	config.add_section('glance')
if 'oslo_concurrency' not in sections:
	config.add_section('oslo_concurrency')

config.set('DEFAULT','transport_url','rabbit://openstack:RABBIT_PASS@'+ip)
config.set('DEFAULT','auth_strategy','keystone')
config.set('DEFAULT','my_ip',ip)
config.set('DEFAULT','use_neutron','True')
config.set('DEFAULT','firewall_driver','nova.virt.firewall.NoopFirewallDriver')


config.set('keystone_authtoken','auth_uri','http://'+ip+':5000')
config.set('keystone_authtoken','auth_url','http://'+ip+':35357')
config.set('keystone_authtoken','memcached_servers',ip+':11211')
config.set('keystone_authtoken','auth_type','password')
config.set('keystone_authtoken','project_domain_name','Default')
config.set('keystone_authtoken','user_domain_name','Default')
config.set('keystone_authtoken','project_name','service')
config.set('keystone_authtoken','username','nova')
config.set('keystone_authtoken','password','NOVA_PASS')


config.set('vnc','vncserver_proxyclient_address',ip)

config.set('glance','api_servers','http://'+ip+':9292')

config.set('oslo_concurrency','lock_path','/var/lib/nova/tmp')

if node == 'controller':
	if 'api_database' not in sections:
		config.add_section('api_database')
	if 'database' not in sections:
		config.add_section('database')
	config.set('api_database','connection','mysql+pymysql://nova:NOVA_DBPASS@'+ip+'/nova_api')
	config.set('database','connection','mysql+pymysql://nova:NOVA_DBPASS@'+ip+'/nova_api')
	config.set('vnc','vncserver_listen',ip)
else:
	config.set('vnc','vncserver_listen','0.0.0.0')
	config.set('vnc','novncproxy_base_url','http://'+ip+':6080/vnc_auto.html')
	config.set('vnc','enabled','True')

with open(file_name, 'wb') as configfile:
    config.write(configfile)