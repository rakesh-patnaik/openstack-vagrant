#!/bin/bash
sudo apt-get update
sudo apt-get install -y nagios-nrpe-server
sudo sed -i “s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,172.16.80.100/” /etc/nagios/nrpe.cfg
sudo cat > /etc/nagios/checks.cfg <<EOF
command[check_nagios_nrpe_proc]=/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C nrpe
EOF