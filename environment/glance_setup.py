import sys
import ConfigParser

ip = sys.argv[1]

#file_name = "/etc/glance/glance-api.conf"
file_name = "UnitTest/glance-api.conf"

config = ConfigParser.ConfigParser(allow_no_value=True)
config.read(file_name)

if 'database' not in config.sections():
	config.add_section('database')
if 'keystone_authtoken' not in config.sections():
	config.add_section('keystone_authtoken')	
if 'paste_deploy' not in config.sections():
	config.add_section('paste_deploy')
if 'glance_store' not in config.sections():
	config.add_section('glance_store')

config.set('glance_store','stores','file,http')
config.set('glance_store','default_store','file')
config.set('glance_store','filesystem_store_datadir','/var/lib/glance/images/')

config.set('database','connection','mysql+pymysql://glance:GLANCE_DBPASS@'+ip+'/glance')

config['keystone_authtoken'] = {}
config.set('keystone_authtoken','auth_uri','http://'+ip+':5000')
config.set('keystone_authtoken','auth_url','http://'+ip+':35357')
config.set('keystone_authtoken','memcached_servers',''+ip+':11211')
config.set('keystone_authtoken','auth_type','password')
config.set('keystone_authtoken','project_domain_name','Default')
config.set('keystone_authtoken','user_domain_name','Default')
config.set('keystone_authtoken','project_name','service')
config.set('keystone_authtoken','username','glance')
config.set('keystone_authtoken','password','GLANCE_PASS')

config.set('paste_deploy','flavor','keystone')

with open(file_name, 'wb') as configfile:
    config.write(configfile)

#file_name = "/etc/glance/glance-registry.conf"
file_name = "UnitTest/glance-registry.conf"
if 'database' not in config.sections():
	config.add_section('database')
if 'keystone_authtoken' not in config.sections():
	config.add_section('keystone_authtoken')	
if 'paste_deploy' not in config.sections():
	config.add_section('paste_deploy')

config.set('database','connection','mysql+pymysql://glance:GLANCE_DBPASS@'+ip+'/glance')

config['keystone_authtoken'] = {}
config.set('keystone_authtoken','auth_uri','http://'+ip+':5000')
config.set('keystone_authtoken','auth_url','http://'+ip+':35357')
config.set('keystone_authtoken','memcached_servers',''+ip+':11211')
config.set('keystone_authtoken','auth_type','password')
config.set('keystone_authtoken','project_domain_name','Default')
config.set('keystone_authtoken','user_domain_name','Default')
config.set('keystone_authtoken','project_name','service')
config.set('keystone_authtoken','username','glance')
config.set('keystone_authtoken','password','GLANCE_PASS')

config.set('paste_deploy','flavor','keystone')

with open(file_name, 'wb') as configfile:
    config.write(configfile)