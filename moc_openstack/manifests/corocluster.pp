class moc_openstack::corocluster {

#  package { 'httpd': ensure => present, }

  class { 'corosync':
    enable_secauth    => true,
    authkey           => '/var/lib/puppet/ssl/certs/ca.pem',
    bind_address      => hiera('corosync::params::bindip'),
    multicast_address => '239.1.1.2',
    debug             => true,
  }

#  file { '/usr/lib/ocf/resource.d/pacemaker/nginx_fixed':
#    ensure  => file,
#    source  => "puppet:///modules/${module_name}/nginx_fixed",
#    mode    => '0755',
#    owner   => 'root',
#    group   => 'root',
#    require => Package['pacemaker', 'corosync'],
#    before  => Service['corosync'],
#  }

  service { 'pacemaker':
    ensure  => stopped,
    enable  => false,
    require => Package['pacemaker'],
  }

  corosync::service { 'pacemaker':
    version => '0',
    notify  => Service['corosync'],
    require => Service['pacemaker'],
  }

  Cs_property { require => Corosync::Service['pacemaker'], }

  cs_property { 'no-quorum-policy':    value => 'ignore', }
  cs_property { 'stonith-enabled':     value => 'false', }
  cs_property { 'resource-stickiness': value => '100', }

  Cs_primitive {
    require    => [
#      Package['nginx'],
      Cs_property['no-quorum-policy'],
      Cs_property['stonith-enabled'],
      Cs_property['resource-stickiness']
    ],
  }

  cs_primitive { 'moc_vip':
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => { 'ip' => hiera('corosync::params::vip'), 'cidr_netmask' => hiera('corosync::params::vipmask') },
    operations      => { 'monitor' => { 'interval' => '10s' } },
  }

#  cs_primitive { 'nginx_service':
#    primitive_class => 'ocf',
#    primitive_type  => 'nginx_fixed',
#    provided_by     => 'pacemaker',
#    operations      => {
#      'monitor' => { 'interval' => '10s', 'timeout' => '30s' },
#      'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
#    },
#    require         => Cs_primitive['nginx_vip'],
#  }

#  cs_colocation { 'vip_with_service':
#    primitives => [ 'nginx_vip', 'nginx_service' ],
#  }
#  cs_order { 'vip_before_service':
#    first   => 'nginx_vip',
#    second  => 'nginx_service',
#    require => Cs_colocation['vip_with_service'],
#  }

  include corosync::reprobe
}

