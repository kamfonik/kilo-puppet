class moc_openstack::ha {


  $pckgs =['corosync','pcs','pacemaker',]
  package { $pckgs: ensure => installed }
  service { pcsd:
    require => Package[pcs],
    enable => true,
    ensure  => running,
  }

  service { pacemaker:
    require => Package[pacemaker],
    enable => true,
  }
  service { corosync:
    require => Package[corosync],
    enable => true,
  }
  file { 'clsetup':
    ensure => 'file',
    content => template('moc_openstack/clsetup.erb'),
    path => '/etc/scripts/clsetup',
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }

  exec {'createmanagepcs':
    command => "/etc/scripts/clsetup",
    before => Class ['mysql::server'],
    require => Class ['apache'],
  }
}
