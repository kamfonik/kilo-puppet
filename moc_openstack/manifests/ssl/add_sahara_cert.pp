class moc_openstack::ssl::add_sahara_cert (
  $sahara_crt      = "/etc/pki/tls/certs/sahara.crt",
  $sahara_key      = "/etc/pki/tls/private/sahara.key",
  $sahara_crt_path = "puppet:///modules/moc_openstack/certs/host.crt",
  $sahara_key_path = "puppet:///modules/moc_openstack/certs/host.key",
) {

  file { $sahara_crt:
    ensure => present,
    mode => '0600',
    owner => 'sahara',
    group => 'sahara',
    source => $sahara_crt_path,
  }

  file { $sahara_key:
    ensure => present,
    mode => '0600',
    owner => 'sahara',
    group => 'sahara',
    source => $sahara_key_path,
  }
}
