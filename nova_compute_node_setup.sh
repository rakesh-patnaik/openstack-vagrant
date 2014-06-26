echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee /etc/apt/sources.list.d/folsom.list
sudo apt-get update
sudo apt-get install -y ubuntu-cloud-keyring

sudo apt-get -y install nova-compute nova-network nova-api-metadata nova-compute-qemu
sudo apt-get -y install ntp

# FILE /etc/ntp.conf
# Replace ntp.ubuntu.com with an NTP server on
# your network
server ntp.ubuntu.com
server 127.127.1.0
fudge 127.127.1.0 stratum 10

sudo service ntp restart

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
volumes_path=/var/lib/nova/volumes

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
keystone_ec2_url=http://172.16.0.200:5000/v2.0/ec2tokens
auth_strategy=keystone 

#######################
# END #
#######################

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
auth_version = v2.0


ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do sudo stop $S; sudo start $S; done

ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do sudo stop $S; done

ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do echo $S; done

sudo stop nova-compute
sudo stop nova-network
sudo stop libvirt-bin

sudo start nova-compute
sudo start nova-network
sudo start libvirt-bin