# ceilometer_setup.sh

# install ceilometer
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee /etc/apt/sources.list.d/folsom.list
sudo apt-get install -y ubuntu-cloud-keyring
sudo apt-get update
sudo apt-get install ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier python-ceilometerclient

# Install Mongodb
sudo apt-get install mongodb-server

# THIS MONGO INSTALL WORKS
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install mongodb-org


# FILE /etc/mongodb.conf
smallfiles=true
# END FILE

sudo service mongodb stop
sudo rm /var/lib/mongodb/journal/prealloc.*
sudo service mongodb start

# create mongodb database
mongo --host 172.16.0.250
use ceilometer
db.addUser ( { "user": "ceilometer", "pwd": "openstack" , "roles": [ "readWrite", "dbAdmin" ] } )
db.addUser({user:"ceilometer", pwd:"openstack",  roles:[ "readWrite", "dbAdmin" ] } )
# FILE /etc/ceilometer/ceilometer.conf
[database]
connection=mongodb://ceilometer:openstack@172.16.0.250:27017/ceilometer

# END FILE

openssl rand -hex 10
b7abc337012381ea805d

# FILE /etc/ceilometer/ceilometer.conf
[publisher_rpc]
metering_secret=b7abc337012381ea805d
# END FILE

# FILE /etc/ceilometer/ceilometer.conf
[DEFAULT]
rabbit_host=172.16.0.200
log_dir = /var/log/ceilometer
# END FILE

export ENDPOINT=172.16.0.200
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0

keystone user-create --name=ceilometer --pass=openstack --email=ceilometer@email.com
keystone user-role-add --user=ceilometer --tenant=service --role=admin
keystone service-create --name=ceilometer --type=metering --description="Ceilometer Metering Service"
keystone endpoint-create --region RegionOne --service-id=9ac9c4fc4d9e467fa9438d229639e6a2 --publicurl=http://172.16.0.250:8777/  --internalurl=http://172.16.0.250:8777/  --adminurl=http://172.16.0.250:8777/

keystone role-create --name=ResellerAdmin
keystone user-role-add --user=ceilometer --tenant=service --role=ResellerAdmin

# FILE /etc/ceilometer/ceilometer.conf
[DEFAULT]
rabbit_host=172.16.0.200
log_dir=/var/log/ceilometer
auth_strategy=keystone
debug=true
verbose=true
connection = mongodb://ceilometer:openstack@172.16.0.200:27017/ceilometer
database_connection = mongodb://172.16.0.200:27017/ceilometer

metering_secret=b7abc337012381ea805d

[keystone_authtoken]
auth_host=172.16.0.200
auth_uri=http://172.16.0.200:5000/v2.0
auth_protocol=http
admin_tenant_name=service
admin_user=ceilometer
admin_password=openstack
auth_port=35357

[service_credentials]
os_auth_url=http://172.16.0.200:5000/v2.0
os_username=ceilometer
os_tenant_name=service
os_password=openstack


# END FILE

sudo service mongodb restart
sudo service ceilometer-agent-central restart
sudo service ceilometer-collector restart
sudo service ceilometer-api restart

export CEILO_SVCS='mongodb ceilometer-agent-central ceilometer-collector ceilometer-api'
for svc in $CEILO_SVCS ; do sudo service $svc status ; done


# using ceilometer
http://172.16.0.250:8777/v2/meters/cpu_util/statistics?q[0].field=project_id&q[0].op=eq&q[0].value=e282ed9867644c758495868bce2b333c&q[1].field=timestamp&q[1].op=gt&q[1].value=2014-06-11T16:00:00


http://172.16.0.250:8777/v2/meters/vcpus/statistics?q[0].field=project_id&q[0].op=eq&q[0].value=e282ed9867644c758495868bce2b333c&q[1].field=timestamp&q[1].op=gt&q[1].value=2014-06-11T16:00:00



http://172.16.0.250:8777/v2/meters/vcpus/statistics?q[0].field=project_id&q[0].op=eq&q[0].value=e282ed9867644c758495868bce2b333c&q[1].field=timestamp&q[1].op=gt&q[1].value=2014-06-01T16:00:00&q[2].field=timestamp&q[2].op=lt&q[2].value=2014-06-30T16:00:00&groupby=resource_id

http://172.16.0.250:8777/v2/meters/compute.node.cpu.frequency/statistics?q[0].field=project_id&q[0].op=eq&q[0].value=e282ed9867644c758495868bce2b333c&q[1].field=timestamp&q[1].op=gt&q[1].value=2014-06-01T16:00:00&q[2].field=timestamp&q[2].op=lt&q[2].value=2014-06-30T16:00:00&groupby=resource_id

http://172.16.0.250:8777/v2/meters/volume/statistics?q[0].field=project_id&q[0].op=eq&q[0].value=e282ed9867644c758495868bce2b333c&q[1].field=timestamp&q[1].op=gt&q[1].value=2014-06-01T16:00:00&q[2].field=timestamp&q[2].op=lt&q[2].value=2014-06-30T16:00:00&groupby=resource_id

ceilometer meter-list

https://ask.openstack.org/en/question/32182/not-getting-measurement-from-ceilometer-regarding-cpu_util/