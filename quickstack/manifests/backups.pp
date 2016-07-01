class backups (
        $enabled        = $quickstack::params::backups_enabled,
        $user		= $quickstack::params::backups_user,
	$script_src	= $quickstack::params::backups_script_src,
        $script_local   = $quickstack::params::backups_script_local_name,
	$backups_dir    = $quickstack::params::backups_directory,
        $log_file       = $quickstack::params::backups_log,
        $verbose        = $quickstack::params::backups_verbose,
        $ssh_key        = $quickstack::params::backups_ssh_key,
        $sudoers_d      = $quickstack::params::backups_sudoers_d,
        $cron_email     = $quickstack::params::backups_email,
        $cron_hour	= $quickstack::params::backups_hour,
        $cron_min 	= $quickstack::params::backups_min,
        $keep_days      = $quickstack::params::backups_keep_days,
) {

    $script_dest = "${backups_dir}/scripts/${script_local}"

#    package { 'rsync':
#      ensure => installed,
#    }

   if str2bool_i($verbose) { 
        $v_flag = "-v"
    }
    else {
        $v_flag = ""
    } 

    if str2bool_i($enabled) {
        $ens_dir = 'directory'
        $ens_file = 'file'
        $ens_user = 'present'
    } 
    else {
        $ens_dir = 'absent'
        $ens_file = 'absent'
        $ens_user = 'absent'
    }
   
    user { "${user}":
      ensure     => $ens_user,
      comment    => 'backups user',
      home       => "/home/${user}",
      managehome => true,
      before     => File[ 'ssh_dir', 'backup_script', 'sudo-permissions' ],
     }

    file { 'ssh_dir' :
      ensure => $ens_dir,
      path   => "/home/${user}/.ssh",
      owner  => $user,
      group  => $user,
      mode   => '0700',
      force  => true,
      before => File['authorized_keys'],
    }

    file { 'authorized_keys' :
      ensure  => $ens_file,
      path    => "/home/${user}/.ssh/authorized_keys",
      owner   => $user,
      group   => $user,
      mode    => '0600',
      replace => true,
      source  => $ssh_key,
      #require => File ['ssh_dir'],
      #require => Class['ssh::server::install'],
    }
    
   file { [ $backups_dir, "${backups_dir}/scripts" ] :
      #Don't set force=true here, that would delete existing backups
      ensure => $ens_dir,
      owner  => 'root',
      group  => 'root',
      before => File['backup_script'],
    }

    file { 'backup_script':
      path    => $script_dest,
      ensure  => $ens_file,
      source  => $script_src,
      owner   => 'root',
      group   => $user,
      mode    => '0740',
      replace => true,
    }

    #There *must* be a new line character at the end of the 'content' string, otherwise sudo breaks on the target.
    file { 'sudo-permissions':
      ensure  => $ens_file,
      path    => "/etc/sudoers.d/10-${user}",
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      replace => true,
      content => "#This file is managed by Puppet\nDefaults:${user}\t!requiretty\n\n${user}\tALL=(root)\t${sudoers_d}\n",
    }
     
    file { $log_file :
        ensure => $ens_file,
    }

    file { 'logrotate':
        ensure   => $ens_file,
        path     => '/etc/logrotate.d/backups',
        replace  => true,
        owner    => 'root',
        group    => 'root',
        content  => "${log_file} {\n\tsize 100K\n\tmissingok\n\trotate 6\n\tcompress\n}\n",
    } 

    file { 'backup_cron':
    	ensure     => $ens_file,
        path       => '/etc/cron.d/backups',
        replace    => true,
        owner      => 'root',
        group      => 'root',
        mode       => '600',
        content    => "#This file is managed by Puppet\n#run a daily backup script\nMAILTO=${cron_email}\n${cron_min} ${cron_hour} * * * root ${script_dest} -d ${backups_dir} -k ${keep_days} ${v_flag} 2>&1 >>${log_file} | tee -a ${log_file}\n", 
    }

    cron { 'backup_cron':
        ensure   => absent,
    }
}
