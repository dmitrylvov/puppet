class rke2::install {
  file { '/usr/local/bin':
    ensure => 'directory',
    mode   => '0755',
  }

  file { '/etc/rancher/rke2':
    ensure => 'directory',
    mode   => '0755',
  }

  file { '/etc/rancher/rke2/token.txt':
    ensure => 'file',
    source => 'puppet:///modules/rke2/pre_generated_token.txt',
    mode   => '0600',
    owner  => 'root',
    group  => 'root',
  }

  exec { 'download_rke2':
    command => "curl -L -o /usr/local/bin/rke2 https://github.com/rancher/rke2/releases/download/${rke2::version}/rke2.${facts['os']['name']}-${facts['os']['architecture']}",
    creates => '/usr/local/bin/rke2',
  }

  file { '/usr/local/bin/rke2':
    mode  => '0755',
    owner => 'root',
    group => 'root',
  }
}