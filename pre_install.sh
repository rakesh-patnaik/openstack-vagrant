# pre_install.sh

sudo apt-get install virtualbox-4.2
wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.3_x86_64.deb
sudo dpkg -i vagrant_1.6.3_x86_64.deb
sudo apt-get install linux-headers-$(uname -r)
sudo dpkg-reconfigure virtualbox-dkms
sudo dpkg-reconfigure virtualbox
vagrant box add precise32 http://files.vagrantup.com/precise32.box
vagrant box add precise64 http://files.vagrantup.com/precise64.box

