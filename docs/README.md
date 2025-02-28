# MicroK8s Cluster Demo Setup

This repository demonstrates how to set up a MicroK8s cluster and deploy various application stacks.

## Getting Started

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/manzolo/multipass-microk8s-cluster-demo.git
    cd multipass-microk8s-cluster-demo
    ./main.sh
    ```

2.  **Main Menu:**

    ![Main menu](images/menu.png)

## Documentation

This directory contains documentation for deploying and managing different application stacks.

**Select a stack to test:**

* [MariaDB Documentation](mariadb/README.md)
* [PostgreSQL Documentation](postgres/README.md)

## Cluster Installation

1.  **Initiate Installation:**

    ![Install](images/install.png)

2.  **Installation Log:**

    * [Installation Log](INSTALL_LOG.md)

3.  **Cluster Information:**

    ![Cluster info](images/cluster-info.png)

## Optional Configurations

### DNS Configuration (for example, to use http://demo-go.loc on nodes)

* [DNS Setup](dns/README.md)

### Nginx Load Balancer VM (for testing application stacks)

* [Nginx Load Balancer Configuration](nginx-lb/README.md)

## Accessing the Main Cluster VM

1.  **Main VM Shell Menu:**

    ![Shell on main vm menu](images/shell_main.png)

2.  **Entering the Shell:**

    ![Shell](images/shell_main_enter.png)

## Available Application Stacks

1.  **Stack Selection Menu:**

    ![Stack menu](images/stack_menu.png)

2.  **List of Available Stacks:**

    ![Stack list](images/stack_list.png)

**Note:** Application stacks can be added or removed after the Kubernetes cluster installation.
