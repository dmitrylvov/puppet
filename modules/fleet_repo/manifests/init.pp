# modules/fleet_repo/manifests/init.pp
class fleet_repo (
  String $repo_url,
  String $repo_branch = 'main',
  String $repo_name,
  String $namespace = 'fleet-local',
  Array[String] $paths = [],
  String $target_namespace = '',
) {
  # Ensure kubectl is available
  require kubectl

  # Create the namespace if it doesn't exist
  exec { "create_namespace_${namespace}":
    command => "/usr/local/bin/kubectl create namespace ${namespace}",
    unless  => "/usr/local/bin/kubectl get namespace ${namespace}",
    path    => ['/usr/bin', '/bin', '/usr/local/bin'],
  }

  # Create a temp directory for the yaml file
  file { "/tmp/${repo_name}-gitrepo":
    ensure => 'directory',
    mode   => '0755',
  }

  # Create the GitRepo YAML
  file { "/tmp/${repo_name}-gitrepo/gitrepo.yaml":
    ensure  => 'file',
    content => template('fleet_repo/gitrepo.yaml.erb'),
    mode    => '0644',
    require => File["/tmp/${repo_name}-gitrepo"],
  }

  # Apply the GitRepo resource
  exec { "apply_gitrepo_${repo_name}":
    command => "/usr/local/bin/kubectl apply -f /tmp/${repo_name}-gitrepo/gitrepo.yaml",
    unless  => "/usr/local/bin/kubectl get -n ${namespace} gitrepo ${repo_name}",
    require => [
      File["/tmp/${repo_name}-gitrepo/gitrepo.yaml"],
      Exec["create_namespace_${namespace}"],
    ],
  }
}
