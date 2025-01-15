class fleet::install {
  file { '/opt/helm-install.sh':
    ensure => 'file',
    source => 'puppet:///modules/fleet/helm-install.sh',
    mode   => '0755',
  }

  exec { 'install_helm':
    command => '/bin/bash /opt/helm-install.sh',
    creates => '/usr/local/bin/helm',
    require => File['/opt/helm-install.sh'],
  }

  exec { 'add_fleet_repo':
    command => '/usr/local/bin/helm repo add fleet https://rancher.github.io/fleet-helm-charts/',
    unless  => '/usr/local/bin/helm repo list | grep fleet',
    require => Exec['install_helm'],
  }

  exec { 'helm_repo_update':
    command => '/usr/local/bin/helm repo update',
    require => Exec['add_fleet_repo'],
  }

  exec { 'install_fleet_crds':
    command => '/usr/local/bin/helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd',
    unless  => '/usr/local/bin/kubectl get crd fleetbundles.fleet.cattle.io',
    require => Exec['helm_repo_update'],
  }

  exec { 'install_fleet':
    command => '/usr/local/bin/helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet',
    unless  => '/usr/local/bin/kubectl get deployment -n cattle-fleet-system fleet-controller',
    require => Exec['install_fleet_crds'],
  }
}