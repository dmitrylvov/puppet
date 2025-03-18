# modules/metallb_fleet/manifests/init.pp
class metallb_fleet (
  String $git_repo_url = 'https://github.com/dmitrylvov/fleet.git',
  String $git_branch = 'main',
) {
  # Ensure Fleet is installed
  require fleet::install

  # Create GitRepo resource for MetalLB
  class { 'fleet_repo':
    repo_url  => $git_repo_url,
    repo_branch => $git_branch,
    repo_name => 'metallb-config',
    namespace => 'fleet-local',
    paths     => ['metallb', 'metallb-resources'],
  }
}
