# Default node definition
node default {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::master':
    vip        => '10.0.0.7',        # Virtual IP for the cluster
    server1_ip => '10.0.0.2',        # IP of the main server node
    server2_ip => '10.0.0.3',        # The actual IP of the server
    server3_ip => '10.0.0.4',
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }
}

# Main RKE2 Server Node (10.0.0.2)
#node '10.0.0.2' {
#  class { 'sysctl': }

#  class { 'rke2::install':
#    require   => Class['sysctl'],
#  }

#  class { 'rke2::master':
#    vip        => '10.0.0.7',        # Virtual IP for the cluster
#    server1_ip => '10.0.0.2',        # IP of the main server node
#    server2_ip => '10.0.0.3',        # The actual IP of the server
#    server3_ip => '10.0.0.4',
#    require    => Class['rke2::install'],
#  }

#  class { 'fleet::install': }
#}

# Additional RKE2 Servers (10.0.0.3, 10.0.0.4)
node '10.0.0.3', '10.0.0.4' {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::server':
    vip        => '10.0.0.7',        # Same VIP as the main server
    server1_ip => '10.0.0.2',  # Automatically detect the node's IP
    server2_ip => '10.0.0.3',
    server3_ip => '10.0.0.4',
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }
}

# RKE2 Agents (10.0.0.5, 10.0.0.6)
node '10.0.0.5' {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::agent':
    server1_ip => '10.0.0.2',  # IP of the main RKE2 server
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }
}
