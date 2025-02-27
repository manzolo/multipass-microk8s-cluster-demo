#!/bin/bash

#NET=10.0.0 # internal subnet of virtual machines
#OWN_IP="$(hostname | sed -e 's/k8s-[^0-9]*//')"
#OWN_IP="$(hostname | sed -e 's/k8s-[^0-9]*//')"
#OWN_IP="${OWN_IP:-250}"
#IP="$(hostname)"
#IF="$(ip -o -4 route show to default | awk '{print $5}')"
#OUT="$(ip -o -4 route show to default | awk '{print $9}')"
#echo "IP:"$NET.$OWN_IP
#echo "IF:"$IF
#echo "OUT:"$OUT
# configure static cd  - comment this if assigned automatically
#sudo tee /etc/netplan/90-static.yaml > /dev/null << EOF
#network:
# version: 2
# renderer: networkd
# ethernets:
#    $IF:
#        addresses: [$NET.$OWN_IP/24] 
#EOF

#sudo netplan apply
#sudo apt install nfs-common -y
sudo swapoff -a
#sudo apt update -qq
#sudo apt upgrade -qqy
#sudo snap refresh
sudo apt update -qq
sudo apt install -qqy nfs-common
sudo snap install --stable snapd
sudo snap install microk8s --classic --stable
#sudo snap install microk8s --channel=latest/stable --classic
#https://github.com/canonical/microk8s/issues/4361
#sudo touch /var/snap/microk8s/7661/var/kubernetes/backend/localnode.yaml > /dev/null
#sudo microk8s stop
#sudo microk8s start
# add user to microk8s sudoers group
sudo usermod -a -G microk8s ubuntu

group=microk8s

if [ $(id -gn) != $group ]; then
exec sg $group "$0 $*"
fi

#sudo chown -f -R ubuntu ~/.kube
#newgrp microk8s

#(cd ~/.kube && sudo microk8s config > config) & disown
#sudo ufw allow in on cni0 && sudo ufw allow out on cni0
#sudo ufw default allow routed
sudo snap alias microk8s.helm helm
sudo snap alias microk8s.helm3 helm3
# helm repo
#helm repo add stable https://charts.helm.sh/stable
#helm repo add jetstack https://charts.jetstack.io 
#helm repo add bitnami https://charts.bitnami.com/bitnami
# add kubect as alias
sudo snap alias microk8s.kubectl kubectl
sudo snap alias microk8s.kubectl k
#microk8s enable dns
#microk8s enable dashboard
#microk8s enable helm

#Longhorn storage
helm repo add longhorn https://charts.longhorn.io
sudo helm repo update
sudo helm install longhorn longhorn/longhorn --namespace longhorn-system --set csi.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet" --create-namespace

echo "Waiting for microk8s to be ready..."
sudo microk8s status --wait-ready > /dev/null 2>&1
#sudo cp config/hosts /etc/hosts
##sudo sh -c 'sudo microk8s config | sed -e "s|server: https://$OUT:16443|server: https://$NET.1:16443|" > /etc/kubeconfig'
