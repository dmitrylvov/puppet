# modules/rancher/manifests/install.pp
class rancher::install (
  String $rancher_hostname = 'rancher.example.com',
  String $rancher_version = 'v2.9.3',
  String $cert_manager_version = 'v1.14.4',
  String $bootstrap_password = 'admin',
  String $ingress_ip = '10.0.0.10',  # Use an IP from your MetalLB pool
  Boolean $use_le = false,           # Whether to use Let's Encrypt
  String $le_email = '',             # Email for Let's Encrypt
  Integer $replicas = 1,
) {
  # Add required Helm repositories
  exec { 'add_rancher_repo':
    command => '/usr/local/bin/helm repo add rancher-latest https://releases.rancher.com/server-charts/latest',
    unless  => '/usr/local/bin/helm repo list | grep rancher-latest',
    require => Exec['fleet_ready'],
  }
  
  exec { 'add_jetstack_repo':
    command => '/usr/local/bin/helm repo add jetstack https://charts.jetstack.io',
    unless  => '/usr/local/bin/helm repo list | grep jetstack',
    require => Exec['fleet_ready'],
  }
  
  exec { 'helm_repo_update_rancher':
    command => '/usr/local/bin/helm repo update',
    require => [Exec['add_rancher_repo'], Exec['add_jetstack_repo']],
  }
  
  # Install cert-manager
  exec { 'create_cert_manager_namespace':
    command => '/usr/local/bin/kubectl create namespace cert-manager',
    unless  => '/usr/local/bin/kubectl get namespace cert-manager',
    require => Class['kubectl'],
  }
  
  exec { 'install_cert_manager_crds':
    command => "/usr/local/bin/kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${cert_manager_version}/cert-manager.crds.yaml",
    unless  => '/usr/local/bin/kubectl get crd certificaterequests.cert-manager.io',
    require => Exec['create_cert_manager_namespace'],
  }
  
  exec { 'install_cert_manager':
    command => "/usr/local/bin/helm install cert-manager jetstack/cert-manager --namespace cert-manager --version ${cert_manager_version}",
    unless  => '/usr/local/bin/helm list -n cert-manager | grep cert-manager',
    require => [Exec['install_cert_manager_crds'], Exec['helm_repo_update_rancher']],
  }
  
  # Wait for cert-manager to be ready
  exec { 'wait_for_cert_manager':
    command => '/bin/bash -c "kubectl -n cert-manager wait --for=condition=ready pod --selector=app.kubernetes.io/instance=cert-manager --timeout=300s"',
    require => Exec['install_cert_manager'],
  }
  
  # Create rancher namespace
  exec { 'create_cattle_system_namespace':
    command => '/usr/local/bin/kubectl create namespace cattle-system',
    unless  => '/usr/local/bin/kubectl get namespace cattle-system',
    require => Class['kubectl'],
  }
  
  # Set up Rancher installation values
  $cert_manager_args = $use_le ? {
    true    => "--set ingress.tls.source=letsEncrypt --set letsEncrypt.email=${le_email}",
    default => '--set ingress.tls.source=rancher',
  }
  
  # Install Rancher
  exec { 'install_rancher':
    command => "/usr/local/bin/helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=${rancher_hostname} --set bootstrapPassword=${bootstrap_password} --set replicas=${replicas} ${cert_manager_args} --version ${rancher_version}",
    unless  => '/usr/local/bin/helm list -n cattle-system | grep rancher',
    require => [Exec['wait_for_cert_manager'], Exec['create_cattle_system_namespace'], Exec['helm_repo_update_rancher']],
  }
  
  # Create a host entry for easier access
  host { $rancher_hostname:
    ensure => 'present',
    ip     => $ingress_ip,
  }
}
