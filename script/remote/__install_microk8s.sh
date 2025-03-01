#!/bin/bash

# # Funzione per verificare lo stato dei Pods
# check_pods() {
#   kubectl get pods -n longhorn-system 2>/dev/null | grep -v 'Running\|Completed' >/dev/null
#   return $?
# }

# # Funzione per verificare lo stato dei Deployments
# check_deployments() {
#   kubectl get deployments -n longhorn-system 2>/dev/null | grep -v 'READY.*[0-9]/[0-9]' >/dev/null
#   return $?
# }

# # Funzione per verificare lo stato dei DaemonSets
# check_daemonsets() {
#   kubectl get daemonsets -n longhorn-system 2>/dev/null | grep -v 'READY.*[0-9]/[0-9]' >/dev/null
#   return $?
# }

# # Funzione per verificare lo stato dei Engine Images
# check_engineimages() {
#   kubectl get engineimages -n longhorn-system 2>/dev/null | grep -v 'ready' >/dev/null
#   return $?
# }

# # Funzione principale di attesa
# wait_for_longhorn() {
#   echo "Waiting for Longhorn to be ready..."
#   local timeout=300 # Timeout di 5 minuti (300 secondi)
#   local interval=10  # Intervallo di controllo di 10 secondi
#   local elapsed=0

#   while true; do
#     if check_pods && check_deployments && check_daemonsets && check_engineimages; then
#       echo "Longhorn is ready!"
#       return 0
#     elif [ $elapsed -ge $timeout ]; then
#       echo "Timeout: Longhorn is not ready after $timeout seconds."
#       return 1
#     else
#       sleep $interval
#       elapsed=$((elapsed + interval))
#     fi
#   done
# }

enable_microk8s_storage() {
  retry_count=3
  success=false
  for attempt in $(seq 1 $retry_count); do
    echo "Attempt $attempt: Enabling hostpath-storage..."
    sudo microk8s enable hostpath-storage
    if [ $? -eq 0 ]; then
      success=true
      break
    else
      echo "Attempt $attempt failed. Retrying..."
      sleep 5 # Attendi 5 secondi prima di riprovare
    fi
  done

  if [ "$success" = false ]; then
    echo "Failed to enable hostpath-storage after $retry_count attempts."
    exit 1 # Esci con un codice di errore
  else
    echo "hostpath-storage enabled successfully."
  fi
}

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
#sudo apt update -qq > /dev/null 2>&1
#sudo apt install -qqy nfs-common > /dev/null 2>&1
sudo snap install --stable snapd > /dev/null 2>&1
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

enable_microk8s_storage

#Longhorn storage
#helm repo add longhorn https://charts.longhorn.io
#sudo helm repo update
#sudo helm install longhorn longhorn/longhorn --namespace longhorn-system --set csi.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet" --create-namespace --version 1.5.1

echo "Waiting for microk8s to be ready..."
sudo microk8s status --wait-ready > /dev/null 2>&1

# Esegui la funzione di attesa
#wait_for_longhorn

#sudo cp config/hosts /etc/hosts
##sudo sh -c 'sudo microk8s config | sed -e "s|server: https://$OUT:16443|server: https://$NET.1:16443|" > /etc/kubeconfig'
