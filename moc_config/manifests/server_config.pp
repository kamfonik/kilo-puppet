## This is the base server configuration for the Mass Open Cloud
class moc_config::server_config() {

  class { '::timezone':
    timezone => 'America/New_York',
  }

  class { '::ssh': }

  class { '::workarounds::disable_lro': }

  class { '::vim': 
    opt_misc => ['backspace=2','tabstop=4','shiftwidth=4','expandtab','nocp','relativenumber','number','ruler','hlsearch','showcmd','showmatch','ignorecase','smartcase','incsearch','autowrite','hidden']
  }
}
