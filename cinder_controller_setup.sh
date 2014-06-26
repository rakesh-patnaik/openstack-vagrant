# cinder_controller_setup.sh
export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://172.16.0.200:5000/v2.0/

keystone service-create --name volume --type volume --description 'Volume Service'

SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')
CINDER_SERVICE_ID=$(keystone service-list | awk '/\ volume\ /{print $2}')
CINDER_ENDPOINT="172.16.0.211"
PUBLIC="http://$CINDER_ENDPOINT:8776/v1/%(tenant_id)s"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC
keystone endpoint-create --region RegionOne --service_id $CINDER_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL 
keystone user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true 
CINDER_USER_ID=$(keystone user-list | awk '/\ cinder \ / {print $2}')
keystone user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

MYSQL_ROOT_PASS=openstack
MYSQL_CINDER_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE cinder;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'cinder'@'%'= PASSWORD('$MYSQL_CINDER_PASS');"

# FILE /etc/nova/nova.conf

volume_driver=nova.volume.driver.ISCSIDriver
enabled_apis=ec2,osapi_compute,metadata
volume_api_class=nova.volume.cinder.API
iscsi_helper=tgtadm

# END FILE

ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do sudo stop $S; sudo start $S; done
