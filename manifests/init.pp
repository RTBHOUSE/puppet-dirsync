class dirsync_test {

  # class for synchronization of directories with git

  define copyrepo ($git_url,                                                                     # url of server with git repos
                   $git_repo                 = $title,                                           # name of the repo
                   $git_work_tree,                                                               # destination directory
                   $git_dir_parent                                                               # parent of the directories with git repos on destination machine
                   $git_clean                = false,                                            # sets removal of untracked files
                   $git_ssl_cainfo           = '/var/lib/puppet/ssl/certs/ca.pem',               # full path to ca certificate
                   $git_ssl_cert             = "/var/lib/puppet/ssl/certs/'$fqdn'.pem",          # full path of node certificate
                   $git_ssl_key              = "/var/lib/puppet/ssl/private_keys/'$fqdn'.pem") { # full path of node private key

    $git_work_tree_underscore = regsubst($git_work_tree, '/', '_', 'G')
    $git_dir                  = "${git_dir_parent}${git_work_tree_underscore}"

    if ! defined ( Package["git"] ) {
        package { 'git':
          ensure => installed,
        }
    }
 
    if ! defined ( File["$git_work_tree"] ) {
      file { "$git_work_tree":
        ensure => directory,
        mode   => 755,
      }
    }
 
    if ! defined ( File["$git_dir_parent"] ) {
      file { "$git_dir_parent":
        ensure => directory,
        mode   => 755,
      }
    }

    # Ugly fail safe. Path has to have at least 8 characters.
    if $git_dir =~ /.{8,}/ and $git_work_tree =~ /.{8,}/ {
  
      # clones bare repo to some directory
      exec { "git_clone_dirsync-$git_repo": 
        command     => "bash -c 'GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git clone --bare $git_url/$git_repo $git_dir'",
        path        => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin"],
        onlyif      => "bash -c '! git --git-dir=$git_dir  rev-parse --is-bare-repository'",
        require     => Package['git'],
      }
  
      # fetches changes to our created bare repo
      exec { "git_fetch_dirsync-$git_repo":
        command     => "bash -c 'GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git --git-dir=$git_dir --work-tree=$git_work_tree fetch origin master'",
        path        => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin"],
        environment => ["GIT_SSL_CAINFO=$git_ssl_cainfo", "GIT_SSL_CERT=$git_ssl_cert", "GIT_SSL_KEY=$git_ssl_key"],
        provider    => shell,
        onlyif      => "bash -c '[[ `GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git --git-dir=$git_dir --work-tree=$git_work_tree ls-remote origin -h refs/heads/master | cut -f 1` != `GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git --git-dir=$git_dir --work-tree=$git_work_tree log --date-order -n 1 --pretty=%H` ]]'",
        require     => [Package['git'], File["$git_work_tree"]],
        notify      => [Exec["git_reset_hard_dirsync-$git_repo"]],
      }
  
      # resets working tree to the last fetched change
      exec { "git_reset_hard_dirsync-$git_repo":
        command     => "bash -c 'GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git --git-dir=$git_dir --work-tree=$git_work_tree reset --hard FETCH_HEAD'",
        path        => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin"],
        refreshonly => true,
        require     => [Package['git'], Exec["git_fetch_dirsync-$git_repo"]]
      }
  
      # RISKY, removes every file or directory from working tree that is not in the repo
      if $git_clean == true {
        exec { "git_clean_dirsync-$git_repo":
          command => "bash -c 'GIT_SSL_CAINFO=$git_ssl_cainfo GIT_SSL_CERT=$git_ssl_cert GIT_SSL_KEY=$git_ssl_key git --git-dir=$git_dir --work-tree=$git_work_tree clean -fd'",
          path    => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin"],
          onlyif  => ["git --git-dir=$git_dir --work-tree=$git_work_tree status --short", "test -d $git_work_tree"],
          require => [Package['git'], Exec["git_reset_hard_dirsync-$git_repo"]]
        }
      }
    }
    else {
      notify {"Path has less than 8 characters. Are you sure that You want to use $git_work_tree as git work tree?": }
    }

  }

}
