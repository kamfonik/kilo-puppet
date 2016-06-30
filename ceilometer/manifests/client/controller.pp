#
# Installs the ceilometer python library.
#
# == parameters
#  [*ensure*]
#    ensure state for pachage.
#
class ceilometer::client::controller (
  $ensure = 'present'
) {
 

  include ::ceilometer::params

  package { 'openstack-ceilometer-collector':
    ensure => $ensure,
  }

  package { 'openstack-ceilometer-notification':
    ensure => $ensure,
  }

  package { 'openstack-ceilometer-central':
    ensure => $ensure,
  }

  package { 'openstack-ceilometer-alarm':
    ensure => $ensure,
  }

  package { 'python-ceilometerclient':
    ensure => $ensure,
  }
 

  class { 'ceilometer::db' : 
   database_connection => $quickstack::params::ceilometer_db
  }


  class { 'ceilometer::agent::auth':
   auth_url => $quickstack::params::ceilometer_auth_url,
   auth_password => $quickstack::params::ceilometer_password,
   auth_user => $quickstack::params::ceilometer_keystone_user,
   auth_tenant_name     => $quickstack::params::ceilometer_keystone_tenant
  }


  class { 'ceilometer' :
   rabbit_host => $quickstack::params::amqp_host,
   rabbit_port => $quickstack::params::ceilometer_rabbit_port,
   rabbit_use_ssl => "false",
   rabbit_hosts => $quickstack::params::ceilometer_rabbit_hosts,
   rabbit_userid => "openstack",
   rabbit_password => $quickstack::params::amqp_password,
   rpc_backend => 'rabbit',
  }

  class { 'ceilometer::api':
    keystone_auth_uri => $quickstack::params::keystone_pub_url,
    keystone_identity_uri => $quickstack::params::keystone_admin_url,
    keystone_password     => $quickstack::params::ceilometer_password,
    keystone_user     => $quickstack::params::ceilometer_keystone_user,
    keystone_tenant     => $quickstack::params::ceilometer_keystone_tenant
  }

}
