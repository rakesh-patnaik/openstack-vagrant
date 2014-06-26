# ceilometer_glance_setup.sh

# FILE /etc/glance/glance-api.conf
notifier_strategy = rabbit
# END FILE

sudo stop glance-registry
sudo start glance-registry
sudo stop glance-api
sudo start glance-api


keystone role-create --name=ResellerAdmin

keystone user-role-add --tenant_id 95bbb535e2ea4ced9521b4df1b516fcb --user_id d528de27444b4dac968bb3d762399033 --role_id 0c477c71fddc4c98a691930709e85545

