import sys
import ConfigParser

ip = sys.argv[1]

file_name = "/etc/keystone/keystone.conf"
#file_name = "UnitTest/keystone.conf"

config = ConfigParser.ConfigParser(allow_no_value=True)
config.read(file_name)

if 'database' not in config.sections():
	config.add_section('database')
config.set("database","connection","mysql+pymysql://keystone:KEYSTONE_DBPASS@"+ip+"/keystone")

if 'token' not in config.sections():
	config.add_section('token')
config.set('token','provider','fernet')

with open(file_name, 'wb') as configfile:
    config.write(configfile)