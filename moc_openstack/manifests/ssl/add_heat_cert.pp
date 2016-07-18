class moc_openstack::ssl::add_heat_cert (
  $heat_crt      = "/etc/pki/tls/certs/heat.crt",
  $heat_key      = "/etc/pki/tls/private/heat.key",
  $heat_crt_path = "puppet:///modules/moc_openstack/certs/host.crt",
  $heat_key_path = "puppet:///modules/moc_openstack/certs/host.key",
) {

  file { $heat_crt:
    ensure => present,
    mode => '0600',
    owner => 'heat',
    group => 'heat',
    source => $heat_crt_path,
  }

  file { $heat_key:
    ensure => present,
    mode => '0600',
    owner => 'heat',
    group => 'heat',
    source => $heat_key_path,
  }
}
