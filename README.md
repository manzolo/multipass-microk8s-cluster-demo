# Multipass MicroK8s Cluster Demo

[![CI](https://github.com/manzolo/multipass-microk8s-cluster-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/manzolo/multipass-microk8s-cluster-demo/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-18.04--24.04-E95420?logo=ubuntu)](https://ubuntu.com/)
[![MicroK8s](https://img.shields.io/badge/MicroK8s-1.28--1.35-326CE5?logo=kubernetes)](https://microk8s.io/)

A local Kubernetes playground using [MicroK8s](https://microk8s.io) on [Multipass](https://multipass.run/) VMs. Create a multi-node cluster with an interactive menu in minutes.

Inspired by [Olawepo Olayemi](https://sejuba.medium.com/installing-kubernetes-microk8-cluster-on-multipass-vms-59978830692d).

## Features

- Interactive menu for cluster management
- Multi-node Kubernetes cluster (1 main + N workers)
- Local DNS server for service discovery
- Pre-configured stacks: MariaDB, PostgreSQL, MongoDB, Redis, RabbitMQ, ELK, Jenkins
- Optional Nginx load balancer and Rancher

## Quick Start

```bash
git clone https://github.com/manzolo/multipass-microk8s-cluster-demo.git
cd multipass-microk8s-cluster-demo
./menu.sh
```

## Prerequisites

- Linux with [Multipass](https://multipass.run/) installed
- Git

## Compatibility

| Ubuntu | MicroK8s |
|--------|----------|
| 24.04  | 1.28 - 1.35+ |
| 22.04  | 1.25 - 1.35+ |
| 20.04  | 1.20 - 1.32 |
| 18.04  | 1.18 - 1.32 |

Configure versions in `.env`:
```bash
UBUNTU_VERSION=22.04
MICROK8S_VERSION=1.32
```

## Documentation

See [docs/README.md](docs/README.md) for detailed usage.

## Demo

[![Watch demo on YouTube](https://img.youtube.com/vi/60-j3D5CzHg/0.jpg)](https://www.youtube.com/watch?v=60-j3D5CzHg)

## Screenshots

![Shell](docs/images/shell_main_enter.png)
![MariaDB](docs/mariadb/html.png)
![Rancher](docs/rancher/setup-complete.png)
![MongoDB](docs/mongodb/html.png)
![ELK](docs/elk/kibana-dashboard.png)
![Postgres](docs/postgres/html.png)
![Kubernetes dashboard](docs/images/k8s-dashboard.png)
![Cluster info](docs/images/cluster-info.png)

