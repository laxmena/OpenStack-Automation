import ConfigParser
import sys

file_name = "/etc/mysql/mariadb.conf.d/50-server.cnf"
#file_name = "UnitTest/50-server.cnf"
ip = sys.argv[1]

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.read(file_name)

config.set('mysqld','bind-address',ip)
config.set('mysqld','default-storage-engine','innodb')
config.set('mysqld','innodb_file_per_table')
config.set('mysqld','max_connections','4096')
config.set('mysqld','collation-server','utf8_general_ci')
config.set('mysqld','character-set-server','utf8')

# Writing our configuration file to 'example.cfg'
with open(file_name, 'wb') as configfile:
    config.write(configfile)