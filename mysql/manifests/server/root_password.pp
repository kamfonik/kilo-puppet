#
class mysql::server::root_password {

  $options = $mysql::server::options

    mysql_user { 'root@localhost':
      ensure        => present,
      password_hash => mysql_password($mysql::server::root_password),
    } ->
    file { "/root/.my.cnf":
      content => template('mysql/my.cnf.pass.erb'),
      owner   => 'root',
      mode    => '0600',
    }

 }
