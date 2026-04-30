# =============================================================================
# modules/webserver/manifests/init.pp
# Puppet class: webserver
# Manages Nginx installation, configuration, and service state
# Demonstrates Puppet's declarative, idempotent resource model
# =============================================================================

class webserver (
  Integer $nginx_port  = 80,
  String  $app_name    = 'cloud-automation-study',
  String  $environment = 'research',
) {

  # ── Step 2: Install Nginx package ──────────────────────────────────────────
  package { 'nginx':
    ensure => '1.24.*',
    before => File['/etc/nginx/nginx.conf'],
  }

  # ── Step 3: Deploy Nginx configuration from EPP template ──────────────────
  file { '/etc/nginx/nginx.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('webserver/nginx.conf.epp', {
      'nginx_port'  => $nginx_port,
      'app_name'    => $app_name,
      'environment' => $environment,
      'hostname'    => $trusted['certname'],
    }),
    notify  => Service['nginx'],
  }

  # Deploy virtual host config
  file { "/etc/nginx/sites-available/${app_name}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('webserver/nginx.conf.epp', {
      'nginx_port'  => $nginx_port,
      'app_name'    => $app_name,
      'environment' => $environment,
      'hostname'    => $trusted['certname'],
    }),
    notify  => Service['nginx'],
  }

  # Enable virtual host symlink
  file { "/etc/nginx/sites-enabled/${app_name}":
    ensure  => link,
    target  => "/etc/nginx/sites-available/${app_name}",
    require => File["/etc/nginx/sites-available/${app_name}"],
    notify  => Service['nginx'],
  }

  # Remove default site
  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
    notify => Service['nginx'],
  }

  # ── Step 4: Ensure Nginx service is running and enabled ───────────────────
  service { 'nginx':
    ensure    => running,
    enable    => true,
    require   => Package['nginx'],
    subscribe => File['/etc/nginx/nginx.conf'],
  }

  # ── Compliance reporting (Puppet-specific capability) ─────────────────────
  # Puppet automatically detects drift and corrects it on next agent run
  notify { 'deployment_complete':
    message => "Webserver class applied on ${trusted['certname']} - ${app_name} (${environment})",
    require => Service['nginx'],
  }
}
