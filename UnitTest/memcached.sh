cd ..
echo "Management IP"
read management_ip

python environment/memcached_setup.py $management_ip