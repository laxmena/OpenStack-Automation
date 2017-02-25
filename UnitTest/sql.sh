cd ..

echo "Management IP:"
read management_ip

echo $management_ip
python environment/mysql_setup.py $management_ip