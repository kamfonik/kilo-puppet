class quickstack::sahara (
  $sahara_password = $quickstack::params::sahara_password,
  $sahara_db_password = $quickstack::params::sahara_db_password,
  $sahara_debug = $quickstack::params::sahara_debug,
  $heat_domain_password = $quickstack::params::heat_domain_password,
  $sahara_plugins = $quickstack::params::sahara_plugins,
  $keystone_auth_uri = "${quickstack::params::auth_uri}v2.0/",
  $keystone_identity_uri = $quickstack::params::identity_uri,
  $keystone_tenant_name = 'services',
  $keystone_region_name = $openstack::keystone::region,
  $rabbit_userid = $quickstack::params::amqp_username,
  $rabbit_password = $quickstack::params::amqp_password,
  $hostname = $quickstack::params::controller_admin_host,
  $sahara_use_ssl = $quickstack::params::use_ssl_endpoints,
  $sahara_key = $quickstack::params::sahara_key,
  $sahara_cert = $quickstack::params::sahara_cert,
) {
  
  if str2bool_i($sahara_use_ssl) {
      class {'moc_openstack::ssl::add_sahara_cert':
      }
    }

  class { '::sahara':
    debug               => $sahara_debug,
    log_dir             => '/var/log/sahara',
    use_neutron         => true,
    keystone_username   => 'sahara',
    keystone_password   => $sahara_password,
    keystone_tenant     => $keystone_tenant_name,
    keystone_url        => $keystone_auth_uri,
    identity_url        => $keystone_identity_uri,
    service_host        => '0.0.0.0',
    service_port        => 8386,
    use_floating_ips    => false,
  }

  sahara_config {
    'DEFAULT/heat_enable_wait_condition': value => false;
    'DEFAULT/plugins': value => $sahara_plugins;
    'DEFAULT/use_namespaces': value => true;
    'DEFAULT/use_rootwrap': value => true;
  }
  
  sahara_config {
    'ssl/key_file': value => $sahara_key;
    'ssl/cert_file': value => $sahara_cert;
  }

  if str2bool_i($sahara_use_ssl) {
    $endpoint_url = "https://${hostname}:8386/v1.1/%(tenant_id)s"
  } else {
    $endpoint_url = "http://${hostname}:8386/v1.1/%(tenant_id)s"
  }

  class { '::sahara::keystone::auth':
    password     => $sahara_password,
    auth_name    => 'sahara',
    tenant       => $keystone_tenant_name,
    region       => $keystone_region_name,
    public_url   => $endpoint_url, 
    admin_url    => $endpoint_url, 
    internal_url => $endpoint_url,
  }

  class { '::sahara::notify::rabbitmq':
    rabbit_userid   => $rabbit_userid,
    rabbit_password => $rabbit_password,
  }

  class { '::heat::keystone::domain':
    auth_url          => $keystone_auth_uri,
    keystone_admin    => 'admin',
    keystone_password => $quickstack::params::admin_password,
    keystone_tenant   => 'admin',
    domain_password   => $heat_domain_password
  }


}
