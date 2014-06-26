# cinder_setup.sh

echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee /etc/apt/sources.list.d/folsom.list
sudo apt-get update
sudo apt-get install -y ubuntu-cloud-keyring
sudo apt-get update

# sudo apt-get install -y linux-headers-'uname -r' build-essential python-mysqldb xfsprogs
sudo apt-get install -y linux-headers-3.2.0-23-generic build-essential python-mysqldb xfsprogs


# sudo apt-get install -y cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt iscsitarget iscsitarget-dkms
sudo apt-get install -y cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt 

sudo service open-iscsi restart

dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=5G
sudo losetup /dev/loop2 cinder-volumes
sudo pvcreate /dev/loop2
sudo vgcreate cinder-volumes /dev/loop2

# database on database host
MYSQL_ROOT_PASS=openstack
MYSQL_CINDER_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE cinder;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'cinder'@'%' = PASSWORD('$MYSQL_CINDER_PASS');"

# FILE /etc/cinder/api-paste.ini
sudo sed -i 's/127.0.0.1/'172.16.0.200'/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_USER%/cinder/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_PASSWORD%/cinder/g' /etc/cinder/api-paste.ini

# FILE /etc/cinder/cinder.conf

[DEFAULT]
rootwrap_config=/etc/cinder/rootwrap.conf
sql_connection = mysql://cinder:openstack@172.16.0.200/cinder
api_paste_config = /etc/cinder/api-paste.ini
iscsi_helper=tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
# osapi_volume_listen_port=5900
# Add these when not using the defaults.
rabbit_host = 172.16.0.200
rabbit_port = 5672
state_path = /var/lib/cinder/

# END FILE

sudo cinder-manage db sync

cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; done

cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i status; done

# Test the setup Create Volumes
sudo apt-get update
sudo apt-get install python-cinderclient

export OS_TENANT_NAME=cookbook
export OS_USERNAME=demo
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://172.16.0.200:5000/v2.0/

cinder create --display-name cookbook 1

cinder list

sudo lvdisplay cinder-volumes

# attach volume-
# on nova node
nova volume-attach <instance_id> <volume_id> /dev/vdc
# on instance 
sudo fdisk -l /dev/vdc
sudo mkfs.ext4 /dev/vdc
sudo mkdir /mnt1
sudo mount /dev/vdc /mnt1
df -h

# detach volume
# on instance
sudo unmount /mnt1
# on nova node
nova volume-detach <instance_id> <volume_id>

# additional setup
sudo apt-get install sysfsutils
