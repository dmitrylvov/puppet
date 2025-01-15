class rke2::install (
  String $token_content,  # Read the token content from the Puppet module
) {
  # Create /etc/rancher first
  file { '/etc/rancher':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  # Create /etc/rancher/rke2 after
  file { '/etc/rancher/rke2':
    ensure  => 'directory',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/rancher'],  # Ensure /etc/rancher exists
  }

  exec { 'download_rke2':
    command => "curl -L -o /usr/local/bin/rke2 https://github.com/rancher/rke2/releases/download/v1.29.4+rke2r1/rke2.linux-amd64",
    creates => '/usr/local/bin/rke2',
    path    => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
#    require => Package['curl'],
  }

  file { '/usr/local/bin/rke2':
    mode  => '0755',
    owner => 'root',
    group => 'root',
  }
}
