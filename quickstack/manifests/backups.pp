class backups (
        $user		= $quickstack::params::backups_user,
	$script_src	= $quickstack::params::backups_script_src,
        $script_local   = $quickstack::params::backups_script_local_name,
	$backups_dir    = $quickstack::params::backups_directory,
        $log_file       = $quickstack::params::backups_log,
        $ssh_key        = $quickstack::params::backups_ssh_key,
        $sudoers_d      = $quickstack::params::backups_sudoers_d,
        $cron_email     = $quickstack::params::backups_email,
        $cron_hour	= $quickstack::params::backups_hour,
        $cron_min 	= $quickstack::params::backups_min,
        $keep_days      = $quickstack::params::backups_keep_days,
) {

    $script_dest = "${backups_dir}/scripts/${script_local}"

    package { 'rsync':
      ensure => installed,
    }

    user { "${user}":
      ensure     => present,
      comment    => 'backups user',
      home       => "/home/${user}",
      managehome => true,
      before     => File[ 'ssh_dir', 'backup_script', 'sudo-permissions' ],
     }

    file { 'ssh_dir' :
      ensure => directory,
      path   => "/home/${user}/.ssh",
      owner  => $user,
      group  => $user,
      mode   => '0700',
      before => File['authorized_keys'],
    }

    file { 'authorized_keys':
      ensure  => present,
      path    => "/home/${user}/.ssh/authorized_keys",
      owner   => $user,
      group   => $user,
      mode    => '0600',
      replace => true,
      source  => $ssh_key,
      require => Class['ssh::server::install'],
    }
    
   file { [ $backups_dir, "${backups_dir}/scripts" ] :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      before => File['backup_script'],
    }

    file { 'backup_script':
      path    => $script_dest,
      ensure  => file,
      source  => $script_src,
      owner   => 'root',
      group   => $user,
      mode    => '0740',
      replace => true,
    }

    #There *must* be a new line character at the end of the 'content' string, otherwise sudo breaks on the target.
    file { 'sudo-permissions':
      ensure  => file,
      path    => "/etc/sudoers.d/10-${user}",
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      replace => true,
      content => "#This file is managed by Puppet\nDefaults:${user}\t!requiretty\n\n${user}\tALL=(root)\t${sudoers_d}\n",
    }
     
    file { $log_file :
        ensure => present,
    }

    cron { 'backup_cron':
      command     => "${script_dest} -d ${backups_dir} -k ${keep_days} 2>&1 >>${log_file} | tee -a ${log_file}", 
      user        => 'root',
      environment => "MAILTO=${cron_email}",
      hour        => $cron_hour,
      minute      => $cron_min,
    }
}

















