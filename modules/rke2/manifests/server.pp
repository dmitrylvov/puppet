class rke2::server (
  String $vip,
  String $server1_ip,
  String $server2_ip,
  String $server3_ip,
  String $token_content,
) {
  file { '/etc/systemd/system/rke2-server.service':
    ensure  => 'file',
    content => template('rke2/rke2-server.service.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { '/etc/rancher/rke2/config.yaml':
    ensure  => 'file',
    content => template('rke2/server-config.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { '/var/lib/rancher/rke2/server':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    before => File['/var/lib/rancher/rke2/server/token'],
  }

  # Ensure the token is also placed in the bootstrap location
  file { '/var/lib/rancher/rke2/server/token':
    ensure  => 'file',
    content => $token_content,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    before  => Service['rke2-server'],
  }

  exec { 'systemd-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/etc/systemd/system/rke2-server.service'],
  }

  service { 'rke2-server':
    ensure    => 'running',
    enable    => true,
    provider  => 'systemd',
    subscribe => File['/etc/rancher/rke2/config.yaml'],
  }
}
