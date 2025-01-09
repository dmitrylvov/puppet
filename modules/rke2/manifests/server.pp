class rke2::server {
  file { '/etc/rancher/rke2/config.yaml':
    ensure  => 'file',
    content => template('rke2/server-config.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  service { 'rke2-server':
    ensure    => 'running',
    enable    => true,
    provider  => 'systemd',
    subscribe => File['/etc/rancher/rke2/config.yaml'],
  }
}