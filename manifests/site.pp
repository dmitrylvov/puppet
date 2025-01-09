node default {
  notify { 'Node not explicitly defined.': }
}

node '10.0.0.2' {
  include rke2::install
  include sysctl
  include rke2::server
  include fleet::install
}

node '10.0.0.3', '10.0.0.4' {
  include rke2::install
  include sysctl
  include rke2::server
}

node '10.0.0.5', '10.0.0.6' {
  include rke2::install
  include sysctl
  include rke2::agent
}