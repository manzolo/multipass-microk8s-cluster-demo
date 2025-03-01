# RabbitMQ on Kubernetes

This README provides instructions on how to install RabbitMQ on a Kubernetes cluster and access its management interface.

## Installation

1.  **Apply the RabbitMQ manifest:**

    ```bash
    kubectl apply -f microk8s_demo_config/rabbitmq.yaml
    ```

    This command will create the necessary Kubernetes resources for RabbitMQ.

2.  **Verify the RabbitMQ pod is running:**

    ```bash
    kubectl get pods -n rabbitmq
    ```

    Ensure the RabbitMQ pod is in the `Running` state.

## Accessing RabbitMQ

1.  **Access the management interface via browser:**

    * `http://<your-node-ip>:31567` (if using NodePort)
    * `http://rabbitmq.loc` (if using Ingress, ensure your DNS is configured)

2.  **Enter the default credentials:**

    * Username: `guest`
    * Password: `guest`
