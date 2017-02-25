echo "Enter Management IP: "
read management_ip

cd ..

echo "choice"
read choice

#Python Script to edit hosts
if [ $choice == 1 ]
then
	python environment/chrony_setup.py controller $management_ip
elif [ $choice == 2 ]
then=
	python environment/chrony_setup.py compute $management_ip
fi