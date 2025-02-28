# Main Menu

## Clone repository
```bash
git clone https://github.com/manzolo/multipass-microk8s-cluster-demo.git
cd multipass-microk8s-cluster-demo
./main.sh
```

## Menu

![Main menu](images/menu.png)

# Documentation

This directory contains documentation for various stacks.

Choose your test stack

# Installation

![Install](images/install.png)
- ![Install log](INSTALL_LOG.md)

## Configure DNS 

* ![DNS](dns/README.md)

## Add nginx load balancer vm to test your stack (ex. using http://demo-go.loc)

* ![Nginx Load Balancer](nginx-lb/README.md)

## Enter on main vm cluster
![Shell on main vm menu](images/shell_main.png)
![Shell](images/shell_main_enter.png)


## Available Stacks
![Stack menu](images/stack_menu.png)
![Stack list](images/stack_list.png)

A stack can be added or removed after installation from cluster kubernetes

* [MariaDB Documentation](mariadb/README.md)
* [PostgreSQL Documentation](postgres/README.md)
