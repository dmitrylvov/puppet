class sysctl {
  augeas { 'enable_ipv4_forwarding':
    changes => "set /files/etc/sysctl.conf/net.ipv4.ip_forward 1",
    notify  => Exec['sysctl_reload'],
  }

  exec { 'sysctl_reload':
    command     => '/sbin/sysctl -p',
    refreshonly => true,
  }
}