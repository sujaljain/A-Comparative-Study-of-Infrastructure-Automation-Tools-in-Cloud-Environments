# =============================================================================
# manifests/site.pp
# Research Paper: A Comparative Study of Infrastructure Automation Tools
# Tool: Puppet 8.x
# Task: Configure Nginx web server on managed nodes (agent-based pull model)
# Authors: Risham Goyal, Vaibhav Khanna, Sujal Jain — Chitkara University
#
# HOW IT WORKS (Puppet pull model):
#   1. Puppet master compiles this manifest into a catalog
#   2. Each Puppet agent (on managed nodes) contacts master periodically
#   3. Agent downloads and applies the catalog
#   4. Agent reports compliance status back to master
# =============================================================================

# Apply webserver class to all nodes in the 'webservers' node group
node /^webserver-.*/ {
  class { 'webserver':
    nginx_port  => 80,
    app_name    => 'cloud-automation-study',
    environment => 'research',
  }
}

# Default node (catches anything not explicitly matched)
node default {
  notify { 'default_node':
    message => "Node ${trusted['certname']} has no explicit classification.",
  }
}
