#
# Installs the ceilometer python library.
#
# == parameters
#  [*ensure*]
#    ensure state for pachage.
#
class ceilometer::client::compute (
  $ensure = 'present'
) {

  include ::ceilometer::params

  package { 'python-ceilometerclient':
    ensure => $ensure
  }

  package { 'python-pecan':
    ensure => $ensure
  }
 
  class { 'ceilometer::db' : 
    database_connection => $quickstack::params::ceilometer_db
  }

  class { 'ceilometer::agent::auth':
     auth_url => $quickstack::params::ceilometer_auth_uri,
     auth_password => $quickstack::params::ceilometer_password,
     auth_user => $quickstack::params::ceilometer_keystone_user,
     auth_tenant_name     => $quickstack::params::ceilometer_keystone_tenant
  }

  class { 'ceilometer::api':
    keystone_auth_uri => $quickstack::params::ceilometer_auth_uri,
    keystone_identity_uri => $quickstack::params::ceilometer_identity_uri,
    keystone_password     => $quickstack::params::ceilometer_password,
    keystone_host     => $quickstack::params::ceilometer_auth_host,
    keystone_user     => $quickstack::params::ceilometer_keystone_user,
    keystone_tenant     => $quickstack::params::ceilometer_keystone_tenant
  }
}

