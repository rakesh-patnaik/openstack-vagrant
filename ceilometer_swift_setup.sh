# ceilometer_swift_setup.sh
# FILE /etc/swift/swift-proxy.conf
[pipeline:main]
pipeline = catch_errors healthcheck cache authtoken keystoneauth proxy-logging proxy-server ceilometer

[filter:ceilometer]
use = egg:ceilometer#swift

# END FILE
