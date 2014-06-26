
# NOTHING WORKS HERE !!!

echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
curl http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | sudo apt-key add -
apt-get update


wget --no-check-certificate https://github.com/jamesc/nagios-plugins-rabbitmq/archive/master.zip
unzip nagios-plugins-rabbitmq-master.zip
mv nagios-plugins-rabbitmq-master nagios-plugins-rabbitmq
mv nagios-plugins-rabbitmq /usr/local/nagios/libexec

cd /usr/save
wget http://search.cpan.org/CPAN/authors/id/T/TO/TONVOON/Nagios-Plugin-0.36.tar.gz
tar xvfz Nagios-Plugin-0.36.tar.gz
cd Nagios-Plugin-0.36
perl Makefile.PL
make
make test
make install