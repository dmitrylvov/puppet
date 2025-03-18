# Default node definition
node 'agent01.example.com' {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::master':
    vip        => '10.0.0.7',        # Virtual IP for the cluster
    server1_ip => '10.0.0.3',        # IP of the main server node
    server2_ip => '10.0.0.4',        # The actual IP of the server
    server3_ip => '10.0.0.5',
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }

  class { 'kubectl':
    cluster_server => 'agent01.example.com',
    is_cluster_node => true,
    require => Class['rke2::master'],
  }

  class { 'fleet::install':
    require => Class['kubectl'],
  }

  class { 'metallb_fleet':
    git_repo_url => 'https://github.com/dmitrylvov/fleet.git', # Replace with your actual repo URL
    git_branch   => 'main',
    require      => Class['fleet::install'],
  }

  # Install Rancher
#  class { 'rancher::install':
#    rancher_hostname => 'rancher.example.com',
#    rancher_version => 'v2.9.3',
#    bootstrap_password => 'admin',  # Use a secure password
#    ingress_ip => '10.0.0.10',               # From your MetalLB pool
#    replicas => 1,
#    require => Class['metallb_fleet'],
#  }
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
node 'agent02.example.com', 'agent03.example.com' {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::server':
    vip        => '10.0.0.7',        # Same VIP as the main server
    server1_ip => '10.0.0.3',  # Automatically detect the node's IP
    server2_ip => '10.0.0.4',
    server3_ip => '10.0.0.5',
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }
}

# RKE2 Agents (10.0.0.5, 10.0.0.6)
node 'agent04.example.com' {
  class { 'sysctl': }

  class { 'rke2::install':
    token_content => file('rke2/pre_generated_token.txt'),
    require   => Class['sysctl'],
  }

  class { 'rke2::agent':
    server1_ip => '10.0.0.3',  # IP of the main RKE2 server
    token_content => file('rke2/pre_generated_token.txt'),
    require    => Class['rke2::install'],
  }
}

