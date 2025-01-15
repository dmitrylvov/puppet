class rke2::agent (
  String $server1_ip,
  String $token_content,
) {
  file { '/etc/systemd/system/rke2-agent.service':
    ensure  => 'file',
    content => template('rke2/rke2-agent.service.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { '/etc/rancher/rke2/config.yaml':
    ensure  => 'file',
    content => template('rke2/agent-config.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  exec { 'systemd-reload-agent':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/etc/systemd/system/rke2-agent.service'],
  }

  service { 'rke2-agent':
    ensure    => 'running',
    enable    => true,
    provider  => 'systemd',
    subscribe => File['/etc/rancher/rke2/config.yaml'],
  }
}
