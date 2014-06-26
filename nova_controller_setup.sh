sudo apt-get update
sudo apt-get -y install rabbitmq-server nova-api nova-conductor nova-scheduler nova-objectstore dnsmasq
sudo apt-get -y install ntp

# FILE /etc/ntp.conf
# Replace ntp.ubuntu.com with an NTP server on
# your network
server ntp.ubuntu.com
server 127.127.1.0
fudge 127.127.1.0 stratum 10

sudo service ntp restart

MYSQL_ROOT_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE nova;'
MYSQL_NOVA_PASS=openstack
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${MYSQL_NOVA_PASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${MYSQL_NOVA_PASS}';"

# FILE /etc/nova/nova.conf
sql_connection=mysql://nova:openstack@172.16.0.200/nova

# FILE /etc/nova/nova.conf
#######################
# BEGIN #
#######################
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True

api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata

# Libvirt and Virtualization
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
libvirt_type=qemu

# Database
sql_connection=mysql://nova:openstack@172.16.0.200/nova
# Messaging
rabbit_host=172.16.0.200

# EC2 API Flags
ec2_host=172.16.0.200
ec2_dmz_host=172.16.0.200
ec2_private_dns_show_ip=True

# Networking
public_interface=eth1
force_dhcp_release=True
auto_assign_floating_ip=True

# Images
image_service=nova.image.glance.GlanceImageService
glance_api_servers=172.16.0.200:9292
# Scheduler
scheduler_default_filters=AllHostsFilter

# Object Storage
iscsi_helper=tgtadm
# Auth
auth_strategy=keystone 
keystone_ec2_url=http://172.16.0.200:5000/v2.0/ec2tokens

#######################
# END #
#######################

sudo nova-manage db sync

sudo nova-manage network create privateNet --fixed_range_v4=10.0.10.0/24 --network_size=64 --bridge_interface=eth2
sudo nova-manage floating create --ip_range=172.16.10.0/24

sudo apt-get update
sudo apt-get -y install python-keystone

# FILE /etc/nova/api-paste.ini
[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
service_protocol = http
service_host = 172.16.0.200
service_port = 5000
auth_host = 172.16.0.200
auth_port = 35357
auth_protocol = http
auth_uri = http://172.16.0.200:5000/
admin_tenant_name = service
admin_user = nova
admin_password = nova

# END file

ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do sudo stop $S; sudo start $S; done

sudo stop nova-api
sudo stop nova-scheduler
sudo stop nova-objectstore
sudo stop nova-conductor
sudo stop libvirt-bin

sudo start nova-api
sudo start nova-scheduler
sudo start nova-objectstore
sudo start nova-conductor
sudo start libvirt-bin

sudo nova-manage service list
ps -ef | grep glance
netstat -ant | grep 9292.*LISTEN
sudo rabbitmqctl status
ntpq -p
MYSQL_ROOT_PASS=openstack
mysqladmin -uroot –p$MYSQL_ROOT_PASS status

sudo apt-get -y install python-novaclient

# security groups
nova keypair-add demo > demo.pem
chmod 0600 *.pem
nova list
nova credentials

export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://172.16.0.200:5000/v2.0/
export OS_NO_CACHE=1

nova secgroup-create webserver "Web Server Access"
nova secgroup-add-rule webserver tcp 80 80 0.0.0.0/0
nova secgroup-add-rule webserver tcp 443 443 0.0.0.0/0

nova secgroup-delete-rule webserver tcp 443 443 0.0.0.0/0
nova secgroup-delete webserver

nova keypair-add myKey > myKey.pem
chmod 0600 myKey.pem

nova keypair-list
nova keypair-delete myKey

# spin a server
export OS_TENANT_NAME=cookbook
export OS_USERNAME=demo
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://172.16.0.200:5000/v2.0/
export OS_NO_CACHE=1
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

nova image-list
nova flavor-list
nova secgroup-list
nova secgroup-list-rules default

nova boot myInstance --image 64a34b54-d32f-4504-a82e-d90eb72367ea --flavor 2 --key_name myKey --security_groups default,webserver

nova list
nova show 67438c9f-4733-4fa5-92fc-7f6712da4fc5

nova delete myInstance
nova delete 6f41bb91-0f4f-41e5-90c3-7ee1f9c39e5a

# takes some time to get ping going then try the following

ssh -i myKey.pem root@172.16.10.1