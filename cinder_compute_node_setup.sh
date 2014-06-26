# cinder_compute_node_setup.sh

# FILE /etc/nova/nova.conf
volume_driver=nova.volume.driver.ISCSIDriver
enabled_apis=ec2,osapi_compute,metadata
volume_api_class=nova.volume.cinder.API
iscsi_helper=tgtadm
# END FILE

ls /etc/init/nova-* | cut -d '/' -f4 | cut -d '.' -f1 | while read S; do sudo stop $S; sudo start $S; done
