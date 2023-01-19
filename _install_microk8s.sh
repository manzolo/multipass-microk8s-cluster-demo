#!/bin/bash
HOST_DIR_NAME=$1
NET=10.0.0 # internal subnet of virtual machines
#IP="$(hostname | sed -e 's/[^0-9]*//')"
IP="$(hostname)"
IF="$(ip -o -4 route show to default | awk '{print $5}')"
OUT="$(ip -o -4 route show to default | awk '{print $9}')"
# configure static cd  - comment this if assigned automatically
#printf "network:\n version: 2\n renderer: networkd\n ethernets:\n  $IF:\n    addresses:\n     - $NET.$IP/24" | tee /etc/netplan/90-static.yaml
sudo netplan apply
sudo apt install nfs-common -y
sudo swapoff -a
sudo snap install microk8s --classic --stable
# add user to microk8s sudoers group
sudo usermod -a -G microk8s ubuntu
#sudo chown -f -R ubuntu ~/.kube
#newgrp microk8s
sudo microk8s status --wait-ready

(cd ~/.kube && sudo microk8s config > config) & disown
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed
sudo snap alias microk8s.helm helm
 # helm repo
helm repo add stable https://charts.helm.sh/stable
helm repo add jetstack https://charts.jetstack.io 
helm repo add bitnami https://charts.bitnami.com/bitnami
# add kubect as alias
sudo snap alias microk8s.kubectl kubectl
sudo snap alias microk8s.kubectl k
#echo "IP:"$IP

if test "$IP" = "k8s-main"
then sudo microk8s enable dns dashboard hostpath-storage helm
    sudo rm -rf ${HOST_DIR_NAME}/_join_node.sh
    #JOINCMD=$(microk8s add-node | sed '/microk8s/p' | head -1)
    JOINCMD=$(sudo microk8s add-node -l 300 | sed '/microk8s/p' | sed '6!d')
    
    echo "${JOINCMD##Join node with: }" >> ${HOST_DIR_NAME}/_join_node.sh 
    sudo chmod a+x ${HOST_DIR_NAME}/_join_node.sh
    #sudo microk8s config | sed -e "s|server: https://$NET.1:16443|server: https://$OUT:16443|" >/etc/kubeconfig
else 
    sudo microk8s enable dns dashboard hostpath-storage helm
    sudo ${HOST_DIR_NAME}/_join_node.sh &
    BACK_PID=$!
    while kill -0 $BACK_PID ; do
        echo "still trying to join..."
        sleep 10
    done
fi