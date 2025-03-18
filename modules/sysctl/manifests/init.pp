class sysctl {
  package { 'procps':
    ensure => 'installed',
  }

  file_line { 'enable_ipv4_forwarding':
    path  => '/etc/sysctl.conf',
    line  => 'net.ipv4.ip_forward = 1',
    match => '^net.ipv4.ip_forward',
  }

  file_line { 'enable_ipv6_forwarding':
    path  => '/etc/sysctl.conf',
    line  => 'net.ipv6.conf.all.forwarding = 1',
    match => '^net.ipv6.conf.all.forwarding',
  }

  exec { 'reload_sysctl':
    command     => '/sbin/sysctl -p',
    refreshonly => true,
    subscribe   => File_line['enable_ipv4_forwarding'],
  }
}
