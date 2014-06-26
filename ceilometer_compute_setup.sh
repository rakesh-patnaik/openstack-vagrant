# ceilometer_compute_setup.sh

sudo apt-get install ceilometer-agent-compute

# FILE /etc/nova/nova.conf
[DEFAULT]
instance_usage_audit=True
instance_usage_audit_period=hour
notify_on_state_change=vm_and_task_state
notification_driver=nova.openstack.common.notifier.rpc_notifier
notification_driver=ceilometer.compute.nova_notifier
compute_available_monitors=nova.compute.monitors.all_monitors
compute_monitors=ComputeDriverCPUMonitor

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

auth_host=172.16.0.200
auth_uri=http://172.16.0.200:5000/v2.0
auth_protocol=http
admin_tenant_name=service
admin_user=ceilometer
admin_password=openstack
auth_port=35357

os_auth_url=http://172.16.0.200:5000/v2.0
os_username=ceilometer
os_tenant_name=service
os_password=openstack


# END FILE

sudo service ceilometer-agent-compute restart
sudo service nova-compute restart

sudo /usr/bin/ceilometer-agent-compute --config-file /etc/ceilometer/ceilometer.conf --debug --os-auth-url http://172.16.0.200:5000/v2.0 --os-tenant-name service --os-username ceilometer --os-password openstack &

### alt EXTENDED ###

sudo apt-get install git
sudo apt-get install python-dev python-pip
git clone https://git.openstack.org/openstack/ceilometer.git
cd ceilometer
sudo python setup.py install
cp etc/ceilometer/*.json /etc/ceilometer
cp etc/ceilometer/*.yaml /etc/ceilometer
sudo pip install pbr