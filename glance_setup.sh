sudo apt-get update
sudo apt-get -y install glance

# client
sudo apt-get update
sudo apt-get -y install glance-client


MYSQL_ROOT_PASSWORD=openstack
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e 'CREATE DATABASE glance;'

MYSQL_GLANCE_PASSWORD=openstack
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${MYSQL_GLANCE_PASSWORD}';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${MYSQL_GLANCE_PASSWORD}';"

sudo sed -i "s,^sql_connection.*,sql_connection = mysql://glance:${MYSQL_GLANCE_PASSWORD}@172.16.0.200/glance," /etc/glance/glance-{registry,api}.conf

sudo stop glance-registry
sudo start glance-registry
sudo stop glance-api
sudo start glance-api

glance-manage version_control 0
sudo glance-manage db_sync


# FILE: /etc/glance/glance-api-paste.ini

[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_tenant_name = service
admin_user = glance
admin_password = glance

# FILE: /etc/glance/glance-api.conf
[keystone_authtoken]
auth_host = 172.16.0.200
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = glance

[paste_deploy]
config_file = /etc/glance/glance-api-paste.ini
flavor = keystone

# FILE: /etc/glance/glance-registry-paste.ini
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_tenant_name = service
admin_user = glance
admin_password = glance

# FILE: /etc/glance/glance-registry.conf
[keystone_authtoken]
auth_host = 172.16.0.200
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = glance
[paste_deploy]
config_file = /etc/glance/glance-registry-paste.ini
flavor = keystone

sudo restart glance-api
sudo restart glance-registry


# CLIENT
sudo apt-get update
sudo apt-get -y install glance-client

export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://172.16.0.200:5000/v2.0/
export OS_NO_CACHE=1

wget http://uec-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img

glance image-create --name='Ubuntu 12.04 x86_64 Server' --disk-format=qcow2 --container-format=bare --public < precise-server-cloudimg-amd64-disk1.img
glance image-list
glance image-show 64a34b54-d32f-4504-a82e-d90eb72367ea
glance image-delete 64a34b54-d32f-4504-a82e-d90eb72367ea
glance image-update 64a34b54-d32f-4504-a82e-d90eb72367ea --is-public True

glance image-create --name='Ubuntu 12.04 x86_64 Server-May26' --disk-format=qcow2 --container-format=bare --public --location http://uec-images.ubuntu.com/precise/20140526/precise-server-cloudimg-amd64-disk1.img

# sharing images
keystone tenant-list
glance image-list

# glance member-create image-id –-tenant-id
glance member-create 64a34b54-d32f-4504-a82e-d90eb72367ea 0031e398a63844cd8aec31f6ca04a50f

glance member-list --image-id IMAGE_ID
glance member-list –-tenant-id TENANT_ID