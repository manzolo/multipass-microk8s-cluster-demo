# Rancher Setup and Management

## Menu

![Rancher Menu](menu.png)
![Rancher Installation](install.png)
![Rancher Initial Setup](setup.png)

**Accessing Rancher without DNS:**

If DNS is not configured, use the following IP address and setup token:

https://&lt;RANCHER_IP>/dashboard/?setup=&lt;SETUP_TOKEN>


Replace `<RANCHER_IP>` with the IP address of your Rancher VM:
```bash
$ multipass info rancher | grep IPv4 | awk '{print $2}'
```
Replace <SETUP_TOKEN> with the token like displayed in the setup.png screenshot.

Accept self-signed certificate


## Screenshots

![Rancher Login Interface](login.png)
![Rancher Main Interface](main.png)

**Importing an Existing Kubernetes Cluster:**

1.  Select "Import Existing Cluster."
2.  Choose "Generic" as the cluster type.
    ![Rancher Add Generic Cluster Interface](generic.png)
3.  Enter a name for your cluster.
    ![Rancher Set Cluster Name Interface](import.png)
4.  **Copy the generated command string (use the second option, signed by an unknown authority).**
    ![Rancher Waiting for Import Completion](waiting.png)
5.  Open a shell on your `k8s-main` node.
    ![Rancher Import Complete](import-complete.png)
6.  Paste the command string to initiate the import process.
    ![Rancher Setup Complete](setup-complete.png)

**Accessing Rancher in your Browser:**

* If a DNS server is configured, navigate to http://rancher.loc in your web browser.
