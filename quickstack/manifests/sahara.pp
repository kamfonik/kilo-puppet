class quickstack::sahara (
  $sahara_password       = $quickstack::params::sahara_password,
  $sahara_db_password    = $quickstack::params::sahara_db_password,
  $sahara_debug          = $quickstack::params::sahara_debug,
  $heat_domain_password  = $quickstack::params::heat_domain_password,
  $sahara_plugins        = $quickstack::params::sahara_plugins,
  $keystone_auth_uri     = "${quickstack::params::auth_uri}v2.0/",
  $keystone_identity_uri = $quickstack::params::identity_uri,
  $keystone_tenant_name  = 'services',
  $keystone_region_name  = $openstack::keystone::region,
  $rabbit_userid         = $quickstack::params::amqp_username,
  $rabbit_password       = $quickstack::params::amqp_password,
  $hostname              = $quickstack::params::controller_admin_host,
  $sahara_use_ssl        = $quickstack::params::use_ssl_endpoints,
  $sahara_key            = $quickstack::params::sahara_key,
  $sahara_cert           = $quickstack::params::sahara_cert,
  $sahara_manage_policy  = $quickstack::params::sahara_manage_policy,
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
    'DEFAULT/plugins':                    value => $sahara_plugins;
    'DEFAULT/use_namespaces':             value => false;
    'DEFAULT/proxy_command':              value => "\'ip netns exec qdhcp-{network_id} nc {host} {port}\'";
    'DEFAULT/use_rootwrap':               value => true;
  }
  
  if str2bool_i($sahara_use_ssl) { 
    sahara_config {
      'ssl/key_file': value => $sahara_key;
      'ssl/cert_file': value => $sahara_cert;
    }
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

  if str2bool_i($sahara_manage_policy) {
    keystone_role { ['sahara_user', 'sahara_admin']:
      ensure => present,
    }
    file { '/etc/sahara/policy.json':
      notify => Service['openstack-sahara-all'], # only restarts if change
      ensure => file,
      owner  => 'root',
      group  => 'sahara',
      mode   => '0640',
      source => 'puppet:///modules/quickstack/sahara_policy.json',
    }
    $base_dir = '/usr/share/openstack-dashboard/openstack_dashboard/contrib/sahara/content/data_processing/'
    file_line { 'cluster':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}clusters/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after => "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'cluster_template':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}cluster_templates/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'data_plugin':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}data_plugins/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'data_source':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}data_sources/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'job_binary':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}job_binaries/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'job_execution':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}job_executions/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'job':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}jobs/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after =>  "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'nodegroup_template':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}nodegroup_templates/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after => "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'wizard':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}wizard/panel.py",
      line => "    permissions = (('openstack.roles.sahara_user','openstack.roles.sahara_admin'),)",
      after => "                    'openstack.services.data_processing'\u0029,\u0029"
    }
    file_line { 'data_image_registry':
      notify  => Service['httpd'], # only restarts if change
      path => "${base_dir}data_image_registry/panel.py",
      line => "    permissions = (('openstack.roles.sahara_admin',),)",
      after => "                    'openstack.services.data_processing'\u0029,\u0029"
    }
  }
  
  $m = '/usr/lib/python2.7/site-packages/sahara/plugins/mapr/versions'
  $mapr_dirs = [ "${m}/mapr_spark", "${m}/v3_1_1", "${m}/v4_0_1_mrv1", "${m}/v4_0_1_mrv2",
                 "${m}/v4_0_2_mrv1", "${m}/v4_0_2_mrv2", "${m}/v5_0_0_mrv1" ]

  file { $mapr_dirs :
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    ensure  => absent,
    recurse => true,
    purge   => true,
    force   => true,
  }

  file { 'old_vanilla':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    ensure  => absent,
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/vanilla/v2_6_0',
    recurse => true,
    purge   => true,
    force   => true,
  }
  
  file_line { 'spark_cleanup':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/spark/plugin.py',
    line    => '        return ["1.3.1"]',
    after   => "    def get_versions\u0028self\u0029:"
  }

  file_line { 'ambari_cleanup':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/ambari/plugin.py',
    line    => '        return ["2.2"]',
    after   => "    def get_versions\u0028self\u0029:"
  }

  file_line { 'mapr_hue_fix':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/mapr/services/hue/hue.py',
    line    => 'HueV381 = HueV370'
  }

  file_line { 'sencha_mapr':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/mapr/services/oozie/oozie.py',
    line    => "        extjs_url = 'http://sahara-files.mirantis.com/ext-2.2.zip'",
    after   => "        extjs_url = 'http://dev.sencha.com/deploy/ext-2.2.zip'"
  }

  file_line { 'sencha_cdh':
    notify  => Service['openstack-sahara-all'], # only restarts Sahara if a file changes
    path    => '/usr/lib/python2.7/site-packages/sahara/plugins/cdh/v5_4_0/config_helper.py',
    line    => "DEFAULT_EXTJS_LIB_URL = 'http://sahara-files.mirantis.com/ext-2.2.zip'",
    after   => "DEFAULT_EXTJS_LIB_URL = 'http://dev.sencha.com/deploy/ext-2.2.zip'"
  }

  #file_line { 'disable_floating':
  #  notify  => Service['httpd'], # only restarts if a file changes
  #  path    => '/etc/openstack-dashboard/local_settings',
  #  line    => 'SAHARA_AUTO_IP_ALLOCATION_ENABLED=True'
  #}

  file_line { 'keystone_dns':
    notify => Service['openstack-sahara-all'], # only restarts if change
    path   => '/usr/lib/python2.7/site-packages/sahara/utils/cluster.py',
    line   => "    for service in [\"object-store\"]:",
    match  => "(    for service in).*"
  }

  file { '/usr/lib/python2.7/site-packages/sahara/service/heat/templates.py':
    notify => Service['openstack-sahara-all'], # only restarts if change
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/quickstack/sahara_templates.py',
  }

  file { '/etc/sudoers.d/sahara-rootwrap':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    source => 'puppet:///modules/quickstack/sahara-rootwrap.fix'
  }

  class { '::heat::keystone::domain':
    auth_url          => $keystone_auth_uri,
    keystone_admin    => 'admin',
    keystone_password => $quickstack::params::admin_password,
    keystone_tenant   => 'admin',
    domain_password   => $heat_domain_password
  }


}
