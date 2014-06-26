# ceilometer_cinder.sh

# FILE /etc/cinder/cinder.conf
cinder_volume_usage_audit=True
cinder_volume_usage_audit_period=hour
notification_driver=cinder.openstack.common.notifier.rpc_notifier
control_exchange=cinder
