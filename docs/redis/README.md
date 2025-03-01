# Redis with Redis Commander on Kubernetes

This README provides instructions on how to install Redis with Redis Commander on a Kubernetes cluster. Redis Commander is a web-based Redis management tool.

## Installation

1.  **Apply the Redis and Redis Commander manifest:**

    ```bash
    kubectl apply -f microk8s_demo_config/redis-commander.yaml
    ```

    This command will create the necessary Kubernetes resources, including:

    * Namespace `redis`
    * ConfigMap `redis-config`
    * Secret `redis-secret`
    * Deployment `redis`
    * PersistentVolumeClaim `redis-data-pvc`
    * Service `redis` (ClusterIP)
    * Deployment `redis-commander`
    * Service `redis-commander` (NodePort)
    * Ingress `redis-commander-ingress`

2.  **Verify the Redis and Redis Commander pods are running:**

    ```bash
    kubectl get pods -n redis
    ```

    Ensure both the Redis and Redis Commander pods are in the `Running` state.

## Accessing Redis Commander

1.  **Access the Redis Commander interface via browser:**

    * `http://<your-node-ip>:31090` (if using NodePort)
    * `http://redis-commander.loc` (if using Ingress, ensure your DNS is configured or add `redis-commander.loc <your-node-ip>` to your `/etc/hosts` file)

2.  **Connect to Redis:**

    * Redis Commander will connect automatically using the following connection details:
        * Host: `redis`
        * Port: `6379`
        * Password: The password stored in the `redis-secret` Kubernetes Secret.
