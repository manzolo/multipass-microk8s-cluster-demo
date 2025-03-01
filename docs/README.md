# MicroK8s Cluster Demo Setup

This repository demonstrates how to set up a MicroK8s cluster and deploy various application stacks.

## Getting Started

1.  **Clone the Repository:**

    ```bash
    git clone [https://github.com/manzolo/multipass-microk8s-cluster-demo.git](https://github.com/manzolo/multipass-microk8s-cluster-demo.git)
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
* [MongoDB Documentation](mongodb/README.md)
* [ELK Documentation](elk/README.md)

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

### Rancher (for simplified Kubernetes management and application deployment)

* [Rancher Configuration](rancher/README.md)

## Accessing the Main Cluster VM

1.  **Main VM Shell Menu:**

    ![Shell on main vm menu](images/shell_main.png)

2.  **Entering the Shell:**

    ![Shell](images/shell_main_enter.png)

3.  **Useful Shell Commands:**

    ```bash
    ================================================
      Kubernetes Cluster Management Commands
    ================================================

     Apply new configuration:
    kubectl apply -f microk8s_demo_config/demo-go.yaml

     Scale up to 20 demo-go pods:
    kubectl scale deployment demo-go --replicas=20 -n demo-go

     Scale up to 5 demo-php pods:
    kubectl scale deployment demo-php --replicas=5 -n demo-php

     Show demo-go pods rollout status:
    kubectl rollout status deployment/demo-go -n demo-go

     Show demo-php pods rollout status:
    kubectl rollout status deployment/demo-php -n demo-php

     Show demo-php pods:
    kubectl get all -o wide -n demo-php

     Show demo-go pods:
    kubectl get all -o wide -n demo-go

     Show mariadb pods:
    kubectl get all -o wide -n mariadb
    
     Show postgres pods:
    kubectl get all -o wide -n postgres 

     Show elk pods:
    kubectl get all -o wide -n elk

    ️ Show node details:
    kubectl get node

    ================================================
      Microk8s Dashboard
    ================================================

    ️ Enable dashboard:
    microk8s enable community
    microk8s enable dashboard-ingress --hostname ${VM_MAIN_NAME}.${DNS_SUFFIX} --allow 0.0.0.0/0

     Show MicroK8s Dashboard Token:
    kubectl describe secret -n kube-system microk8s-dashboard-token | grep "token:" | awk '{print $2}'

     Start dashboard:
    microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0

    https://${VM_MAIN_NAME}.${DNS_SUFFIX}:10443/#/login
    ```

## Available Application Stacks

1.  **Stack Selection Menu:**

    ![Stack menu](images/stack_menu.png)

2.  **List of Available Stacks:**

    ![Stack list](images/stack_list.png)

**Note:** Application stacks can be added or removed after the Kubernetes cluster installation.
