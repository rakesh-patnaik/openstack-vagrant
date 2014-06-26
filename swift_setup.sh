sudo apt-get update
sudo apt-get install -y swift swift-proxy swift-account swift-container swift-object memcached xfsprogs curl python-webob ntp parted

# FILE /etc/ntp.conf, with the following contents:
# Replace ntp.ubuntu.com with an NTP server on your network
server ntp.ubuntu.com
server 127.127.1.0
fudge 127.127.1.0 stratum 10


sudo service ntp restart

sudo fdisk /dev/sdb
n
p
1
enter
enter
w

sudo fdisk /dev/sdb
p

sudo partprobe

sudo mkfs.xfs -i size=1024 /dev/sdb1
sudo mkdir /mnt/sdb1

# FILE /etc/fstab
/dev/sdb1 /mnt/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0


sudo mount /dev/sdb1

sudo mkdir /mnt/sdb1/{1..4}
sudo chown swift:swift /mnt/sdb1/*
sudo ln -s /mnt/sdb1/{1..4} /srv
sudo mkdir -p /etc/swift/{object-server,container-server,account-server}
for S in {1..4}; do sudo mkdir -p /srv/${S}/node/sdb${S};done
sudo mkdir -p /var/run/swift
sudo chown -R swift:swift /etc/swift /srv/{1..4}/

# FILE /etc/rc.local
mkdir -p /var/run/swift
chown swift:swift /var/run/swift

# FILE /etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 127.0.0.1

[account6012]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/account6012.lock

[account6022]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/account6022.lock

[account6032]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/account6032.lock

[account6042]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/account6042.lock

[container6011]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/container6011.lock

[container6021]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/container6021.lock

[container6031]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/container6031.lock

[container6041]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/container6041.lock

[object6010]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/object6010.lock

[object6020]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/object6020.lock

[object6030]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/object6030.lock

[object6040]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/object6040.lock

# FILE END /etc/rsyncd.conf

sudo sed -i 's/=false/=true/' /etc/default/rsync
sudo service rsync start

< /dev/urandom tr -dc A-Za-z0-9_ | head -c16; echo
zgY_Lt0Mu4T73ptK

# FILE /etc/swift/swift.conf
[swift-hash]
# Random unique string used on all nodes
swift_hash_path_suffix = zgY_Lt0Mu4T73ptK

# FILE /etc/swift/proxy-server.conf
[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift
[pipeline:main]
# Order of execution of modules defined below
pipeline = catch_errors healthcheck cache authtoken keystone proxy-server
[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = true
set log_name = swift-proxy
set log_facility = LOG_LOCAL0
set log_level = INFO
set access_log_name = swift-proxy
set access_log_facility = SYSLOG
set access_log_level = INFO
set log_headers = True
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:catch_errors]
use = egg:swift#catch_errors
[filter:cache]
use = egg:swift#memcache
set log_name = cache
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_protocol = http
auth_host = 172.16.0.200
auth_port = 35357
auth_token = ADMIN
service_protocol = http
service_host = 172.16.0.200
service_port = 5000
admin_token = ADMIN
admin_tenant_name = service
admin_user = swift
admin_password = openstack
delay_auth_decision = 0
signing_dir = /tmp/keystone-signing-swift
[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, swiftoperator

# FILE /etc/swift/account-server/1.conf
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6012
user = swift
log_facility = LOG_LOCAL2
[pipeline:main]
pipeline = account-server
[app:account-server]
use = egg:swift#account
[account-replicator]
vm_test_mode = yes
[account-auditor]
[account-reaper]

# END FILE 

cd /etc/swift/account-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf


# FILE /etc/swift/container-server/1.conf
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6011
user = swift
log_facility = LOG_LOCAL2
[pipeline:main]
pipeline = container-server
[app:container-server]
use = egg:swift#container
[account-replicator]
vm_test_mode = yes
[account-updater]
[account-auditor]
[account-sync]
[container-sync]
[container-auditor]
[container-replicator]
[container-updater]

# END FILE
cd /etc/swift/container-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf

# FILE /etc/swift/object-server/1.conf 
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6010
user = swift
log_facility = LOG_LOCAL2
[pipeline:main]
pipeline = object-server
[app:object-server]
use = egg:swift#object
[object-replicator]
vm_test_mode = yes
[object-updater]
[object-auditor]

# END FILE

cd /etc/swift/object-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf

# FILE /usr/local/bin/remakerings
#!/bin/bash

# swift-ring-builder builder_file create part_power replicas min_part_hours
# swift-ring-builder builder_file add zzone-ip:port device_name weight
# swift-ring-builder builder_file rebalance

cd /etc/swift
rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz
# Object Ring
swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add z1-127.0.0.1:6010/sdb1 1
swift-ring-builder object.builder add z2-127.0.0.1:6020/sdb2 1
swift-ring-builder object.builder add z3-127.0.0.1:6030/sdb3 1
swift-ring-builder object.builder add z4-127.0.0.1:6040/sdb4 1
swift-ring-builder object.builder rebalance
# Container Ring
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add z1-127.0.0.1:6011/sdb1 1
swift-ring-builder container.builder add z2-127.0.0.1:6021/sdb2 1
swift-ring-builder container.builder add z3-127.0.0.1:6031/sdb3 1
swift-ring-builder container.builder add z4-127.0.0.1:6041/sdb4 1
swift-ring-builder container.builder rebalance
# Account Ring
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add z1-127.0.0.1:6012/sdb1 1
swift-ring-builder account.builder add z2-127.0.0.1:6022/sdb2 1
swift-ring-builder account.builder add z3-127.0.0.1:6032/sdb3 1
swift-ring-builder account.builder add z4-127.0.0.1:6042/sdb4 1
swift-ring-builder account.builder rebalance

# END FILE

sudo chmod +x /usr/local/bin/remakerings
sudo /usr/local/bin/remakerings

sudo swift-init main start
sudo swift-init rest start

# sudo swift-init main {start, stop, restart}
# sudo swift-init rest {start, stop, restart}

# KEystone and swift integration

# Set up environment
export ENDPOINT=172.16.0.200
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0
# Swift Proxy Address
export SWIFT_PROXY_SERVER=172.16.0.210
# Configure the OpenStack Object Storage Endpoint
keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-create --name swift --type object-store --description 'OpenStack Storage Service'
# Service Endpoint URLs
ID=$(keystone service-list | awk '/\ swift\ / {print $2}')
# Note we're using SSL
PUBLIC_URL="http://$SWIFT_PROXY_SERVER:8080/v1/AUTH_\$(tenant_id)s"
ADMIN_URL="http://$SWIFT_PROXY_SERVER:8080/v1"
INTERNAL_URL=$PUBLIC_URL
keystone endpoint-create --region RegionOne --service_id $ID --publicurl $PUBLIC_URL --adminurl $ADMIN_URL --internalurl $INTERNAL_URL

# Get the service tenant ID
SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')

# Create the swift user
keystone user-create --name swift --pass swift --tenant_id $SERVICE_TENANT_ID --email swift@localhost --enabled true
# Get the swift user id
USER_ID=$(keystone user-list | awk '/\ swift\ /{print $2}')
# Get the admin role id
ROLE_ID=$(keystone role-list | awk '/\ admin\ /{print $2}')
# Assign the swift user admin role in service tenant
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $SERVICE_TENANT_ID

sudo apt-get update
sudo apt-get install python-keystone

 # FILE /etc/memcached.conf
 -l 172.16.0.210

 # END File
 sudo service memcached restart

# FILE etc/swift/proxy-server.conf
[DEFAULT]
bind_ip = 172.16.0.210
bind_port = 8080
backlog = 4096
user = swift
swift_dir = /etc/swift
workers = 8
log_name = swift
log_facility = LOG_LOCAL1
log_level = INFO

[pipeline:main]
pipeline = catch_errors healthcheck cache authtoken keystoneauth proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
account_autocreate = true
set log_level = DEBUG
set log_name = swift-proxy-server
set access_log_name = swift-proxy-server
set access_log_facility = LOG_LOCAL0
set access_log_level = DEBUG
set log_headers = True

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:cache]
use = egg:swift#memcache
memcache_servers = 172.16.0.210:11211

[filter:keystone]
paste.filter_factory = keystone.middleware.swift_auth:filter_factory
operator_roles = Member,admin

[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = Member,admin,swiftoperator

[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
service_port = 5000
service_host = 172.16.0.200
auth_port = 35357
auth_host = 172.16.0.200
auth_protocol = http
auth_uri = http://172.16.0.200:5000/
auth_token = ADMIN
admin_token = ADMIN
admin_tenant_name = service
admin_user = swift
admin_password = swift
cache = swift.cache
include_service_catalog = False

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:swift3]
use = egg:swift#swift3

[filter:proxy-logging]
use = egg:swift#proxy_logging

# END FILE

sudo swift-init main restart
sudo swift-init rest restart
sudo swift-init proxy-server restart

########################## SKIP DOESNOT WORK
# setup SSL
cd /etc/swift
sudo openssl req -new -x509 -nodes -out cert.crt -keyout cert.key

# UPDATE FILE /etc/swift/proxy-server.conf file:
bind_port = 443
cert_file = /etc/swift/cert.crt
key_file = /etc/swift/cert.key
# END UPDATE FILE

sudo swift-init proxy-server restart

########################## END SKIP DOESNOT WORK

sudo chown -R swift:swift /var/cache/swift
sudo chown -R swift:swift ~/keystone-signing

# TESTING
swift -A http://172.16.0.200:5000/v2.0 -U service:swift -K swift -V 2.0 stat

sudo apt-get update
sudo apt-get -y install python-swiftclient python-keystone

swift -V 2.0 -A http://172.16.0.200:5000/v2.0 -U cookbook:demo -K openstack stat

# Create a container called test 
swift -V 2.0 -A http://172.16.0.200:5000/v2.0 -U cookbook:demo -K openstack post test
# List containers 
swift -V 2.0 -A http://172.16.0.200:5000/v2.0 -U cookbook:demo -K openstack list

# swift -V 2.0 -A http://keystone_server:5000/v2.0 -U tenant:user -K password post containername

sudo swift-init all restrat
OR
sudo swift-init main stop;sudo swift-init rest stop; sudo swift-init proxy-server stop
sudo swift-init main restart;sudo swift-init rest restart; sudo swift-init proxy-server restart

swift -A http://172.16.0.200:35357/v2.0 -U admin:admin -K openstack -V 2.0 stat

#### Collect Usage stats ##
# FILE /etc/swift/object-server/*.conf
[DEFAULT]
bind_ip = 0.0.0.0
workers = 2

[pipeline:main]
pipeline = recon object-server

[app:object-server]
use = egg:swift#object

[object-replicator]

[object-updater]

[object-auditor]

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift

# END FILE

sudo swift-init object-server restart

# disk usage
swift-recon -d
# du in zone 5
swift-recon -d -z5
# avg
swift-recon -l

swift-recon --all

#### END collect usage stats ###

#### Cluster Health
# FILE /etc/swift/dispersion.conf
[dispersion]
auth_url = http://172.16.0.200:5000/v2.0/
auth_user = cookbook:demo
auth_key = openstack
auth_version = 2.0
# END FILE

sudo swift-dispersion-populate

sudo swift-dispersion-report
### END Cluster heath


# nrpe for monitoring
./check_swift -A http://172.16.0.200:5000/v2.0 -U cookbook:demo -K openstack -V 2.0
