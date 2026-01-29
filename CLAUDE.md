# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bash-based automation project for creating a local MicroK8s Kubernetes cluster using Multipass VMs. It provides an interactive menu system for cluster management and deploys various application stacks.

## Common Commands

```bash
# Interactive menu (primary interface)
./menu.sh

# Automated cluster creation
./create_kube_vms.sh

# Automated cluster destruction
./destroy_kube_vms.sh

# Run tests
./script/_test.sh

# Git flow release (prompts for version)
./new_release
```

## Architecture

### Entry Points
- `menu.sh` - Interactive whiptail-based menu system
- `create_kube_vms.sh` - Orchestrates full cluster creation
- `destroy_kube_vms.sh` - Tears down all VMs

### Script Organization

**Function modules** (`script/functions/`):
- `common.sh` - Logging (`msg_info`, `msg_warn`, `msg_error`, `msg_fatal`), retry logic, VM utilities
- `load_env.sh` - Environment loading from `.env` and `.env.local`
- `vm.sh` - VM creation, cloning, removal
- `node.sh` - Node management, MicroK8s status checks
- `cluster.sh` - Cluster lifecycle (start/stop, scaling, health)
- `dns.sh` - DNS server setup with dnsmasq
- `nginx.sh` - NGINX load balancer configuration
- `rancher.sh` - Rancher container management

**Menu modules** (`script/menu/`):
- `main.sh`, `cluster.sh`, `dns.sh`, `load_balancer.sh`, `rancher.sh`, `stack.sh`, `client.sh`

**Remote scripts** (`script/remote/`):
- Scripts executed inside VMs via `multipass exec`

### Kubernetes Manifests (`config/`)

Each YAML file creates a namespace and deploys a service stack. Available stacks:
- Databases: mariadb, postgres, mongodb, redis
- Messaging: rabbitmq
- Monitoring: elk (Elasticsearch/Kibana), grafana
- Apps: demo-go, demo-php, static-site, ghost, gitea, jenkins, minio, nextcloud, node-red

## Configuration

**`.env`** - Default configuration (committed):
- `UBUNTU_VERSION` - VM Ubuntu version (18.04, 20.04, 22.04, 24.04)
- `VM_MAIN_NAME=k8s-main`, `VM_NODE_PREFIX=k8s-node`, `DNS_VM_NAME=k8s-dns-server`
- `MAIN_CPU`, `MAIN_RAM`, `MAIN_HDD_GB` - VM resources
- `INSTANCES` - Number of worker nodes

**`.env.local`** - Local overrides (not committed):
- `DEPLOY_*=true/false` - Enable/disable stack deployment during cluster creation

## VM Naming Convention

- Main node: `k8s-main`
- Worker nodes: `k8s-node1`, `k8s-node2`, ...
- DNS server: `k8s-dns-server`
- Client: `k8s-client`
- Load balancer: `nginx-lb`
- Rancher: `rancher`

## Multipass Commands Pattern

Scripts interact with VMs via:
```bash
multipass exec VM_NAME -- command    # Run command in VM
multipass shell VM_NAME              # Interactive shell
multipass info VM_NAME               # VM details
multipass list                       # List all VMs
```

## Logging Convention

Use these functions from `common.sh`:
```bash
msg_info "Success message"   # Green
msg_warn "Warning"           # Yellow/brown
msg_error "Error"            # Red
msg_fatal "Fatal error"      # Red, exits with code 1
```
