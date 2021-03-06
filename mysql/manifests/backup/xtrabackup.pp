# See README.me for usage.
class mysql::backup::xtrabackup (
  $backupuser         = '',
  $backuppassword     = '',
  $backupdir          = '',
  $backupmethod       = 'mysqldump',
  $backupdirmode      = '0700',
  $backupdirowner     = 'root',
  $backupdirgroup     = $mysql::params::root_group,
  $backupcompress     = true,
  $backuprotate       = 30,
  $ignore_events      = true,
  $delete_before_dump = false,
  $backupdatabases    = [],
  $file_per_database  = false,
  $include_triggers   = true,
  $include_routines   = false,
  $ensure             = 'present',
  $time               = ['23', '5'],
  $postscript         = false,
  $execpath           = '/usr/bin:/usr/sbin:/bin:/sbin',
) {

  package{ 'percona-xtrabackup':
    ensure  => $ensure,
  }

  cron { 'xtrabackup-weekly':
    ensure  => $ensure,
    command => "innobackupex ${backupdir}",
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    weekday => 0,
    require => Package['percona-xtrabackup'],
  }

  cron { 'xtrabackup-daily':
    ensure  => $ensure,
    command => "innobackupex --incremental ${backupdir}",
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    weekday => 1-6,
    require => Package['percona-xtrabackup'],
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => $backupdirmode,
    owner  => $backupdirowner,
    group  => $backupdirgroup,
  }
}
