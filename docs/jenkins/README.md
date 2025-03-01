# Jenkins Installation on Kubernetes

This guide provides instructions on how to install Jenkins on your Kubernetes cluster using `kubectl apply -f microk8s_demo_config/jenkins.yaml` and how to retrieve the initial administrator password.

## Installation

1.  **Apply the Jenkins manifest:**

    ```bash
    kubectl apply -f microk8s_demo_config/jenkins.yaml
    ```

    This command will create the necessary Kubernetes resources for Jenkins.

2.  **Verify the Jenkins pod is running:**

    ```bash
    kubectl get pods -n jenkins
    ```

    Ensure the Jenkins pod is in the `Running` state.

## Retrieving the Initial Administrator Password

1.  **Get the Jenkins pod name:**

    ```bash
    kubectl get pods -n jenkins -o name | grep jenkins
    ```

2.  **Retrieve the initial administrator password from the pod logs:**

    ```bash
    kubectl get pods -n jenkins -o name | xargs -I {} kubectl exec -n jenkins -t {} -- cat /var/jenkins_home/secrets/initialAdminPassword
    ```

    This command will extract and display the password.

3.  **Access Jenkins:**

    * Open your web browser and navigate to the Jenkins URL:
        * `http://<your-node-ip>:31080` (if using NodePort)
        * `http://jenkins.loc` (if using Ingress, ensure your DNS is configured)

    * Enter the password you retrieved in the previous step.
