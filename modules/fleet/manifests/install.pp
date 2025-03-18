# modules/fleet/manifests/install.pp
class fleet::install (
  String $helm_version = 'latest',
  String $fleet_namespace = 'cattle-fleet-system'
) {
  # Install helm script
  file { '/opt/helm-install.sh':
    ensure => 'file',
    source => 'puppet:///modules/fleet/helm-install.sh',
    mode   => '0755',
  }

  # Install Helm if not already installed
  exec { 'install_helm':
    command => '/bin/bash /opt/helm-install.sh',
    creates => '/usr/local/bin/helm',
    require => File['/opt/helm-install.sh'],
  }

  # Add Fleet Helm repo
  exec { 'add_fleet_repo':
    command => '/usr/local/bin/helm repo add fleet https://rancher.github.io/fleet-helm-charts/',
    unless  => '/usr/local/bin/helm repo list | grep fleet',
    require => Exec['install_helm'],
  }

  # Update Helm repos
  exec { 'helm_repo_update':
    command => '/usr/local/bin/helm repo update',
    require => Exec['add_fleet_repo'],
  }

  # IMPORTANT: Check if Fleet is already installed by checking for deployments
  exec { 'check_fleet_installation':
    command => '/bin/true',  # No-op command
    onlyif  => "/usr/local/bin/kubectl get -n ${fleet_namespace} deployment fleet-controller 2>/dev/null",
    require => Exec['helm_repo_update'],
  }

  # Install Fleet CRDs only if Fleet isn't already installed
  exec { 'install_fleet_crds':
    command => "/usr/local/bin/helm -n ${fleet_namespace} install --create-namespace --wait fleet-crd fleet/fleet-crd",
    unless  => "/usr/local/bin/kubectl get -n ${fleet_namespace} deployment fleet-controller 2>/dev/null || /usr/local/bin/helm list -n ${fleet_namespace} | grep fleet-crd",
    require => Exec['helm_repo_update'],
  }

  # Install Fleet only if Fleet isn't already installed
  exec { 'install_fleet':
    command => "/usr/local/bin/helm -n ${fleet_namespace} install --create-namespace --wait fleet fleet/fleet",
    unless  => "/usr/local/bin/kubectl get -n ${fleet_namespace} deployment fleet-controller 2>/dev/null || /usr/local/bin/helm list -n ${fleet_namespace} | grep ' fleet '",
    require => Exec['install_fleet_crds'],
  }

  # Add this to ensure Rancher module can depend on something that always succeeds
  # This resource will succeed whether Fleet is installed manually or via Helm
  exec { 'fleet_ready':
    command => '/bin/true',
    require => [Exec['check_fleet_installation'], Exec['install_fleet']],
    onlyif  => "/usr/local/bin/kubectl get -n ${fleet_namespace} deployment fleet-controller 2>/dev/null",
  }
}
