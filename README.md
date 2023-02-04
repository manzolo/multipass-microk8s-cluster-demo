# Multipass microk8s cluster demo
This is a demonstration of creating a [microk8s](https://microk8s.io) cluster inside [multipass](https://multipass.run/) virtual machine

From an idea of [Olawepo Olayemi](https://sejuba.medium.com/installing-kubernetes-microk8-cluster-on-multipass-vms-59978830692d)

## Prerequisites
* [Ubuntu 22.04](https://ubuntu.com/download)
* [multipass](https://multipass.run/)
* Git

## Tested on
* Ubuntu 22.04 
* Microk8s (1.26/stable)

## Install
```bash
$ git clone https://github.com/manzolo/multipass-microk8s-cluster-demo.git
$ cd multipass-microk8s-cluster-demo
$ find ./ -type f -iname "*.sh" -exec chmod +x {} \;
$ ./create_kube_vms.sh
```

## Example of deploy:
![immagine](https://user-images.githubusercontent.com/7722346/213332709-7f2fb680-e859-4ed1-a456-e271701aa3a5.png)

![immagine](https://user-images.githubusercontent.com/7722346/213332976-0762af52-85b9-4aa7-bb3c-a298e52048e7.png)

![immagine](https://user-images.githubusercontent.com/7722346/213333132-b66f43e4-a3bb-4501-b06e-3b4395130847.png)

### Full log with 3 nodes
$ ./create_kube_vms.sh 3
<pre>
<span style="background-color:#12488B">
<font color="#A2734C">Check prerequisites...</font>
<font color="#A2734C">Creating vms cluster</font>
Launched: k8s-main                                                              
Launched: k8s-node1                                                             
Launched: k8s-node2                                                             
Launched: k8s-node3                                                             
<font color="#26A269">[Task 1]</font>                                                                        
<font color="#A2734C">Mount host drive with installation scripts</font>
<font color="#26A269">[Task 2]</font>                                                                        
<font color="#A2734C">Installing microk8s on k8s-main</font>
microk8s (1.26/stable) v1.26.0 from Canonical<font color="#26A269">✓</font> installed
Added:
  - microk8s.helm as helm
Added:
  - microk8s.helm3 as helm3
Added:
  - microk8s.kubectl as kubectl
Added:
  - microk8s.kubectl as k
Infer repository core for addon dns
Infer repository core for addon dashboard
Infer repository core for addon helm
Enabling DNS
Using host configuration from /run/systemd/resolve/resolv.conf
Applying manifest
serviceaccount/coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
clusterrole.rbac.authorization.k8s.io/coredns created
clusterrolebinding.rbac.authorization.k8s.io/coredns created
Restarting kubelet
DNS is enabled
Enabling Kubernetes Dashboard
Infer repository core for addon metrics-server
Enabling Metrics-Server
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
clusterrolebinding.rbac.authorization.k8s.io/microk8s-admin created
Metrics-Server is enabled
Applying manifest
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
secret/microk8s-dashboard-token created

If RBAC is not enabled access the dashboard using the token retrieved with:

microk8s kubectl describe secret -n kube-system microk8s-dashboard-token

Use this token in the https login UI of the kubernetes-dashboard service.

In an RBAC enabled setup (microk8s enable RBAC) you need to create a user with restricted
permissions as shown in:
https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md

Addon core/helm is already enabled
<font color="#26A269">[Task 3]</font>
<font color="#26A269">*** Installing kuberbetes on worker&apos;s node ***</font>
<font color="#A2734C">Generate join cluster command k8s-main</font>
<font color="#A2734C">installing microk8s k8s-node1</font>
microk8s (1.26/stable) v1.26.0 from Canonical<font color="#26A269">✓</font> installed
Added:
  - microk8s.helm as helm
Added:
  - microk8s.helm3 as helm3
Added:
  - microk8s.kubectl as kubectl
Added:
  - microk8s.kubectl as k
Infer repository core for addon dns
Enabling DNS
Using host configuration from /run/systemd/resolve/resolv.conf
Applying manifest
<font color="#A2734C">Still trying to join...</font>
Contacting cluster at k8s-main
<font color="#A2734C">Still trying to join...</font>
                       <font color="#A2734C">Still trying to join...</font>

The node has joined the cluster and will appear in the nodes list in a few seconds.

This worker node gets automatically configured with the API server endpoints.
If the API servers are behind a loadbalancer please set the &apos;--refresh-interval&apos; to &apos;0s&apos; in:
    /var/snap/microk8s/current/args/apiserver-proxy
and replace the API server endpoints with the one provided by the loadbalancer in:
    /var/snap/microk8s/current/args/traefik/provider.yaml

<font color="#A2734C">Generate join cluster command k8s-main</font>
<font color="#A2734C">installing microk8s k8s-node2</font>
microk8s (1.26/stable) v1.26.0 from Canonical<font color="#26A269">✓</font> installed
Added:
  - microk8s.helm as helm
Added:
  - microk8s.helm3 as helm3
Added:
  - microk8s.kubectl as kubectl
Added:
  - microk8s.kubectl as k
Infer repository core for addon dns
Enabling DNS
Using host configuration from /run/systemd/resolve/resolv.conf
Applying manifest
serviceaccount/coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
clusterrole.rbac.authorization.k8s.io/coredns created
clusterrolebinding.rbac.authorization.k8s.io/coredns created
Restarting kubelet
DNS is enabled
<font color="#A2734C">Still trying to join...</font>
Contacting cluster at k8s-main

The node has joined the cluster and will appear in the nodes list in a few seconds.

This worker node gets automatically configured with the API server endpoints.
If the API servers are behind a loadbalancer please set the &apos;--refresh-interval&apos; to &apos;0s&apos; in:
    /var/snap/microk8s/current/args/apiserver-proxy
and replace the API server endpoints with the one provided by the loadbalancer in:
    /var/snap/microk8s/current/args/traefik/provider.yaml

<font color="#A2734C">Generate join cluster command k8s-main</font>
<font color="#A2734C">installing microk8s k8s-node3</font>
microk8s (1.26/stable) v1.26.0 from Canonical<font color="#26A269">✓</font> installed
Added:
  - microk8s.helm as helm
Added:
  - microk8s.helm3 as helm3
Added:
  - microk8s.kubectl as kubectl
Added:
  - microk8s.kubectl as k
Infer repository core for addon dns
Enabling DNS
Using host configuration from /run/systemd/resolve/resolv.conf
Applying manifest
<font color="#A2734C">Still trying to join...</font>
Contacting cluster at k8s-main

The node has joined the cluster and will appear in the nodes list in a few seconds.

This worker node gets automatically configured with the API server endpoints.
If the API servers are behind a loadbalancer please set the &apos;--refresh-interval&apos; to &apos;0s&apos; in:
    /var/snap/microk8s/current/args/apiserver-proxy
and replace the API server endpoints with the one provided by the loadbalancer in:
    /var/snap/microk8s/current/args/traefik/provider.yaml

<font color="#A2734C">Ready for deployment...</font>
<font color="#26A269">[Task 4]</font>
<font color="#A2734C">Completing microk8s</font>
deployment.apps/demo-go created
service/demo-go created
Waiting for deployment &quot;demo-go&quot; rollout to finish: 0 out of 10 new replicas have been updated...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 0 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 1 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 2 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 3 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 4 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 5 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 6 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 7 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 8 of 10 updated replicas are available...
Waiting for deployment &quot;demo-go&quot; rollout to finish: 9 of 10 updated replicas are available...
deployment &quot;demo-go&quot; successfully rolled out
<font color="#A2734C">Waiting deploy start...</font>
<font color="#A2734C">kubectl get node</font>
NAME        STATUS   ROLES    AGE     VERSION
k8s-node1   Ready    &lt;none&gt;   8m19s   v1.26.0
k8s-node3   Ready    &lt;none&gt;   2m18s   v1.26.0
k8s-main    Ready    &lt;none&gt;   12m     v1.26.0
k8s-node2   Ready    &lt;none&gt;   4m41s   v1.26.0
<font color="#A2734C">kubectl get all -o wide</font>
NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
pod/demo-go-c769ff578-h86l5   1/1     Running   0          72s   10.1.36.65     k8s-node1   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-8fwx7   1/1     Running   0          72s   10.1.36.66     k8s-node1   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-f894v   1/1     Running   0          72s   10.1.194.198   k8s-main    &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-p6zqk   1/1     Running   0          72s   10.1.194.199   k8s-main    &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-km2xb   1/1     Running   0          72s   10.1.107.193   k8s-node3   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-62s5w   1/1     Running   0          72s   10.1.194.200   k8s-main    &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-wbf62   1/1     Running   0          72s   10.1.107.195   k8s-node3   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-7znjd   1/1     Running   0          72s   10.1.107.194   k8s-node3   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-6g9sv   1/1     Running   0          72s   10.1.169.129   k8s-node2   &lt;none&gt;           &lt;none&gt;
pod/demo-go-c769ff578-zcdfh   1/1     Running   0          72s   10.1.169.130   k8s-node2   &lt;none&gt;           &lt;none&gt;

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE   SELECTOR
service/kubernetes   ClusterIP   10.152.183.1     &lt;none&gt;        443/TCP        12m   &lt;none&gt;
service/demo-go      NodePort    10.152.183.214   &lt;none&gt;        80:31001/TCP   72s   app=demo-go

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                  SELECTOR
deployment.apps/demo-go   10/10   10           10          73s   demo-go      manzolo/demo-go:0.1.0   app=demo-go

NAME                                DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                  SELECTOR
replicaset.apps/demo-go-c769ff578   10        10        10      72s   demo-go      manzolo/demo-go:0.1.0   app=demo-go,pod-template-hash=c769ff578
Name                    State             IPv4             Image
k8s-main                Running           10.65.7.66       Ubuntu 22.04 LTS
                                          10.1.194.192
k8s-node1               Running           10.65.7.132      Ubuntu 22.04 LTS
                                          10.1.36.64
k8s-node2               Running           10.65.7.110      Ubuntu 22.04 LTS
                                          10.1.169.128
k8s-node3               Running           10.65.7.14       Ubuntu 22.04 LTS
                                          10.1.107.192
<font color="#A2734C">Try:</font>
curl -s http://10.65.7.66:31001
</pre>
$ curl -s http://10.65.7.66:31001
<pre>

{
    &quot;id&quot;: &quot;5577006791947779410&quot;,
    &quot;hostname&quot;: &quot;demo-go-c769ff578-8fwx7&quot;,
    &quot;ip&quot;: &quot;10.1.36.66&quot;,
    &quot;datetime&quot;: &quot;2023.01.21 00:38:32&quot;
}
{
    &quot;id&quot;: &quot;5577006791947779410&quot;,
    &quot;hostname&quot;: &quot;demo-go-c769ff578-p6zqk&quot;,
    &quot;ip&quot;: &quot;10.1.194.199&quot;,
    &quot;datetime&quot;: &quot;2023.01.21 00:38:34&quot;
}
{
    &quot;id&quot;: &quot;5577006791947779410&quot;,
    &quot;hostname&quot;: &quot;demo-go-c769ff578-zcdfh&quot;,
    &quot;ip&quot;: &quot;10.1.169.130&quot;,
    &quot;datetime&quot;: &quot;2023.01.21 00:38:35&quot;
}
{
    &quot;id&quot;: &quot;8674665223082153551&quot;,
    &quot;hostname&quot;: &quot;demo-go-c769ff578-8fwx7&quot;,
    &quot;ip&quot;: &quot;10.1.36.66&quot;,
    &quot;datetime&quot;: &quot;2023.01.21 00:38:35&quot;
}
{
    &quot;id&quot;: &quot;5577006791947779410&quot;,
    &quot;hostname&quot;: &quot;demo-go-c769ff578-7znjd&quot;,
    &quot;ip&quot;: &quot;10.1.107.194&quot;,
    &quot;datetime&quot;: &quot;2023.01.21 00:38:36&quot;
}
</pre>

## remove
```bash
$ cd multipass-microk8s-cluster-demo
./destroy_kube_vms.sh
```
## Demo video
[![Watch demo](http://img.youtube.com/vi/DgNdGkz17pI/0.jpg)](http://www.youtube.com/watch?v=DgNdGkz17pI "Demo video")
