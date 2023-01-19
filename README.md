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



## remove
```bash
$ cd multipass-microk8s-cluster-demo
./destroy_kube_vms.sh
```
