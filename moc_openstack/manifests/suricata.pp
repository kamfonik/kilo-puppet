# This manifest manages Suricata IPS

class moc_openstack::suricata {

  package { 'suricata':
    ensure => 'installed',
  }
  service { 'suricata':
    ensure  => 'running',
    enable  => true,
    require => Package['suricata'],
  }

  file { '/etc/sysconfig/suricata':
    notify  => Service['suricata'],
    mode    => '0600',
    owner   => 'suricata',
    group   => 'root',
    require => Package['suricata'],
    source => 'puppet:///modules/moc_openstack/suricata',
  }

  file { '/etc/suricata/suricata.yaml':
    notify  => Service['suricata'],
    mode    => '0600',
    owner   => 'suricata',
    group   => 'root',
    require => Package['suricata'],
    source => 'puppet:///modules/moc_openstack/suricata.yaml',
  }
  file { '/etc/scripts':
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode  => '0750',
  }
  file { 'surnfq':
    ensure => 'file',
    content => template('moc_openstack/surnfq.erb'),
    path => '/etc/scripts/surnfq',
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }
  file { 'surupd':
    ensure => 'file',
    content => template('moc_openstack/surupd.erb'),
    path => '/etc/scripts/surupd',
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }

  file { '/etc/cron.daily/updaterules':
    ensure => 'link',
    target => '/etc/scripts/surupd',
  }

  file { '/etc/cron.d/surnfq.cron':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode  => '0640',
    content => "SHELL=/bin/bash\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\nMAILTO=root\n* * * * * root /etc/scripts/surnfq\n",
    require   => Package['suricata'],
   }
  exec {'updaterules':
    command => "/etc/scripts/surupd",
  }
}
