# Create a new module for kubectl
# modules/kubectl/manifests/init.pp

class kubectl (
  String $version = 'v1.29.4',
  String $cluster_server = 'agent01.example.com',
  Boolean $is_cluster_node = true,
) {
  # Download kubectl
  exec { 'download_kubectl':
    command => "curl -LO https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl",
    cwd     => '/tmp',
    creates => '/tmp/kubectl',
    path    => ['/usr/bin', '/bin'],
  }

  # Make kubectl executable
  file { '/tmp/kubectl':
    mode    => '0755',
    require => Exec['download_kubectl'],
  }

  # Move kubectl to a directory in PATH
  file { '/usr/local/bin/kubectl':
    ensure  => 'file',
    source  => '/tmp/kubectl',
    mode    => '0755',
    require => File['/tmp/kubectl'],
  }

  # Create .kube directory
  file { '/root/.kube':
    ensure => 'directory',
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }

  # Copy RKE2 kubeconfig (if on a cluster node)
  if $is_cluster_node {
    # Wait for RKE2 kubeconfig to exist
    exec { 'wait_for_rke2_kubeconfig':
      command => 'test -f /etc/rancher/rke2/rke2.yaml || (sleep 10 && false)',
      path    => ['/usr/bin', '/bin'],
      tries   => 30,
      try_sleep => 10,
      unless  => 'test -f /etc/rancher/rke2/rke2.yaml',
      require => Service['rke2-server'],
    }

    # Copy the config
    file { '/root/.kube/config':
      ensure  => 'file',
      source  => '/etc/rancher/rke2/rke2.yaml',
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      require => [File['/root/.kube'], Exec['wait_for_rke2_kubeconfig']],
    }
  }
  else {
    # For non-cluster nodes, kubeconfig should be provided separately
    # This is just a placeholder
    file { '/root/.kube/config':
      ensure  => 'file',
      content => template('kubectl/kubeconfig.erb'),
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      require => File['/root/.kube'],
    }
  }

  # Update the server URL in kubeconfig if needed
  if $is_cluster_node {
    exec { 'update_kubeconfig_server':
      command => "sed -i 's/127.0.0.1/${cluster_server}/g' /root/.kube/config",
      path    => ['/usr/bin', '/bin'],
      onlyif  => "grep -q '127.0.0.1' /root/.kube/config",
      require => File['/root/.kube/config'],
    }
  }

  # Add kubectl bash completion
  file_line { 'kubectl_completion':
    path   => '/root/.bashrc',
    line   => 'source <(kubectl completion bash)',
    match  => '^source <\(kubectl completion bash\)',
    require => File['/usr/local/bin/kubectl'],
  }

  file_line { 'kubectl_alias':
    path   => '/root/.bashrc',
    line   => 'alias k=kubectl',
    match  => '^alias k=kubectl',
    require => File['/usr/local/bin/kubectl'],
  }

  file_line { 'kubectl_completion_alias':
    path   => '/root/.bashrc',
    line   => 'complete -o default -F __start_kubectl k',
    match  => '^complete -o default -F __start_kubectl k',
    require => File_line['kubectl_alias'],
  }
}
