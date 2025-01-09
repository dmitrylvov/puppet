class rke2::agent {
  file { '/etc/rancher/rke2/config.yaml':
    ensure  => 'file',
    content => template('rke2/agent-config.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  service { 'rke2-agent':
    ensure    => 'running',
    enable    => true,
    provider  => 'systemd',
    subscribe => File['/etc/rancher/rke2/config.yaml'],
  }
}