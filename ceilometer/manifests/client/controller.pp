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
   auth_url         => $quickstack::params::ceilometer_auth_url,
   auth_password    => $quickstack::params::ceilometer_password,
   auth_user        => $quickstack::params::ceilometer_keystone_user,
   auth_tenant_name => $quickstack::params::ceilometer_keystone_tenant
  }


  class { 'ceilometer' :
   rabbit_host     => $quickstack::params::amqp_host,
   rabbit_port     => $quickstack::params::ceilometer_rabbit_port,
   rabbit_use_ssl  => "false",
   rabbit_hosts    => $quickstack::params::ceilometer_rabbit_hosts,
   rabbit_userid   => "openstack",
   rabbit_password => $quickstack::params::amqp_password,
   rpc_backend     => 'rabbit',
  }

  ceilometer_config {
     'keystone_authtoken/auth_uri': value          => $quickstack::params::keystone_pub_url;
     'keystone_authtoken/identity_uri': value      => $quickstack::params::keystone_admin_url;
     'keystone_authtoken/admin_user': value        => $quickstack::params::ceilometer_keystone_user;
     'keystone_authtoken/admin_password': value    => $quickstack::params::ceilometer_password;
     'keystone_authtoken/admin_tenant_name': value => $quickstack::params::ceilometer_keystone_tenant;
     'publisher/metering_secret': ensure => absent; 
  }

  service {'openstack-ceilometer-collector':
    ensure =>'running',
    require => Package ['openstack-ceilometer-collector'],

  }

  service {'openstack-ceilometer-notification':
    ensure =>'running',
    require => Package ['openstack-ceilometer-notification'],

  }

  service {'openstack-ceilometer-central':
    ensure =>'running',
    require => Package ['openstack-ceilometer-central'],
  }

  service {'openstack-ceilometer-alarm-notifier':
    ensure =>'running',
    require => Package ['openstack-ceilometer-alarm'],

  }



}
