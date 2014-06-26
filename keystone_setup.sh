echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee /etc/apt/sources.list.d/folsom.list

sudo apt-get update
sudo apt-get install -y ubuntu-cloud-keyring

# install mysql

MYSQL_ROOT_PASS=openstack
MYSQL_HOST=172.16.0.200
# To enable non-interactive installations of MySQL, set the following
echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password seen true" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again seen true" | sudo debconf-set-selections

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get -q -y install mysql-server python-mysqldb
sudo sed -i "s/^bind\-address.*/bind-address = ${MYSQL_HOST}/g" /etc/mysql/my.cnf
sudo service mysql restart

mysqladmin -uroot password ${MYSQL_ROOT_PASS}
mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"${MYSQL_HOST}\" IDENTIFIED BY "${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"

mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysqladmin -uroot -p${MYSQL_ROOT_PASS} flush-privileges

sudo apt-get update
sudo apt-get -y install keystone python-keyring
MYSQL_ROOT_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE DATABASE keystone;"
MYSQL_KEYSTONE_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'keystone'@'%' = PASSWORD('$MYSQL_KEYSTONE_PASS');"
MYSQL_HOST=172.16.0.200
sudo sed -i "s#^connection.*#connection =  mysql://keystone:openstack@${MYSQL_HOST}/keystone#" /etc/keystone/keystone.conf
sudo sed -i "s/^# admin_token.*/admin_token = ADMIN/" /etc/keystone/keystone.conf
sudo sed -i "s/^# token_format.*/token_format = UUID/" /etc/keystone/keystone.conf
sudo stop keystone
sudo start keystone
sudo keystone-manage db_sync

sudo apt-get update
sudo apt-get -y install python-keystoneclient

export ENDPOINT=172.16.0.200
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0


keystone tenant-create --name cookbook --description "Default Cookbook Tenant" --enabled true
keystone tenant-create --name admin --description "Admin Tenant" --enabled true
keystone tenant-list

keystone role-create --name admin
keystone role-create --name Member

TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')
PASSWORD=openstack
keystone user-create --name admin --tenant_id $TENANT_ID --pass $PASSWORD --email root@localhost --enabled true
ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}')
USER_ID=$(keystone user-list | awk '/\ admin\ / {print $2}')
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID
ADMIN_TENANT_ID=$(keystone tenant-list | awk '/\ admin\ / {print $2}')
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $ADMIN_TENANT_ID

TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')
keystone user-create --name demo --tenant_id $TENANT_ID --pass $PASSWORD --email demo@localhost --enabled true
ROLE_ID=$(keystone role-list | awk '/\ Member\ / {print $2}')
USER_ID=$(keystone user-list | awk '/\ demo\ / {print $2}')
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID

# OpenStack Compute Nova API Endpoint
keystone service-create --name nova --type compute --description 'OpenStack Compute Service'
# OpenStack Compute EC2 API Endpoint
keystone service-create --name ec2 --type ec2 --description 'EC2 Service'
# Glance Image Service Endpoint
keystone service-create --name glance --type image --description 'OpenStack Image Service'
# Keystone Identity Service Endpoint
keystone service-create --name keystone --type identity --description 'OpenStack Identity Service'
#Cinder Block Storage Endpoint
keystone service-create --name volume --type volume --description 'Volume Service'

NOVA_SERVICE_ID=$(keystone service-list | awk '/\ nova\ / {print $2}')
PUBLIC="http://$ENDPOINT:8774/v2/\$(tenant_id)s"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $NOVA_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

EC2_SERVICE_ID=$(keystone service-list | awk '/\ ec2\ / {print $2}')
PUBLIC="http://$ENDPOINT:8773/services/Cloud"
ADMIN="http://$ENDPOINT:8773/services/Admin"
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $EC2_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

GLANCE_SERVICE_ID=$(keystone service-list | awk '/\ glance\ / {print $2}')
PUBLIC="http://$ENDPOINT:9292/v1"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $GLANCE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

KEYSTONE_SERVICE_ID=$(keystone service-list | awk '/\ keystone\ / {print $2}')
PUBLIC="http://$ENDPOINT:5000/v2.0"
ADMIN="http://$ENDPOINT:35357/v2.0"
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $KEYSTONE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

CINDER_SERVICE_ID=$(keystone service-list | awk '/\ volume\ / {print $2}')
PUBLIC="http://$ENDPOINT:8776/v1/%(tenant_id)s"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $CINDER_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# create service tenants 
keystone tenant-create --name service --description "Service Tenant" --enabled true
SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')
keystone user-create --name nova --pass nova --tenant_id $SERVICE_TENANT_ID --email nova@localhost --enabled true
keystone user-create --name glance --pass glance --tenant_id $SERVICE_TENANT_ID --email glance@localhost --enabled true
keystone user-create --name keystone --pass keystone --tenant_id $SERVICE_TENANT_ID --email keystone@localhost --enabled true
keystone user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true

NOVA_USER_ID=$(keystone user-list | awk '/\ nova\ / {print $2}')
ADMIN_ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}')
keystone user-role-add --user $NOVA_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
GLANCE_USER_ID=$(keystone user-list | awk '/\ glance\ / {print $2}')
keystone user-role-add --user $GLANCE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
KEYSTONE_USER_ID=$(keystone user-list | awk '/\ keystone\ / {print $2}')
keystone user-role-add --user $KEYSTONE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
CINDER_USER_ID=$(keystone user-list | awk '/\ cinder \ / {print $2}')
keystone user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID


# Monitoring from a nagios server at 172.16.80.100

sudo apt-get install -y nagios-nrpe-server
sudo sed -i “s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,172.16.80.100/” /etc/nagios/nrpe.cfg

sudo cat > /etc/nagios/checks.cfg <<EOF
command[check_keystone_proc]=/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C keystone-all
command[check_keystone_api]=/usr/lib/nagios/plugins/check_keystone --auth_url 'http://172.16.0.200:35357/v2.0' --username admin --tenant admin --password
EOF

sudo echo “include=/etc/nagios/checks.cfg” >> /etc/nagios/nrpe.cfg

sudo service nagios-nrpe-server stop
sudo service nagios-nrpe-server start

# test api failure
# keystone user-password-update --pass openstack1 admin
