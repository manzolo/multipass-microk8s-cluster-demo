#!/bin/bash

# Function to generate MOTD
generate_main_vm_motd() {
    VM_IP=$(get_vm_ip "$VM_MAIN_NAME")
    # Primo blocco: comandi per la gestione del cluster
    local MOTD_K8S_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Kubernetes Cluster Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Apply new configuration:$(tput sgr0)
$(tput setaf 2)kubectl apply -f microk8s_demo_config/demo-go.yaml$(tput sgr0)

$(tput setaf 3)$(tput bold)📈 Scale up to 20 demo-go pods:$(tput sgr0)
$(tput setaf 3)kubectl scale deployment demo-go --replicas=20 -n demo-go$(tput sgr0)

$(tput setaf 4)$(tput bold)📈 Scale up to 5 demo-php pods:$(tput sgr0)
$(tput setaf 4)kubectl scale deployment demo-php --replicas=5 -n demo-php$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄 Show demo-go pods rollout status:$(tput sgr0)
$(tput setaf 5)kubectl rollout status deployment/demo-go -n demo-go$(tput sgr0)

$(tput setaf 6)$(tput bold)🔄 Show demo-php pods rollout status:$(tput sgr0)
$(tput setaf 6)kubectl rollout status deployment/demo-php -n demo-php$(tput sgr0)

$(tput setaf 7)$(tput bold)👀 Show demo-php pods:$(tput sgr0)
$(tput setaf 7)kubectl get all -o wide -n demo-php$(tput sgr0)

$(tput setaf 8)$(tput bold)👀 Show demo-go pods:$(tput sgr0)
$(tput setaf 8)kubectl get all -o wide -n demo-go$(tput sgr0)

$(tput setaf 8)$(tput bold)👀 Inspect mariadb pods:$(tput sgr0)
$(tput setaf 8)kubectl get all -o wide -n mariadb$(tput sgr0)
$(tput setaf 8)kubectl describe pod mariadb-0 -n mariadb$(tput sgr0)
$(tput setaf 8)watch kubectl get all -o wide -n mariadb$(tput sgr0)
$(tput setaf 8)kubectl logs pod/mariadb-0 -n mariadb$(tput sgr0)
$(tput setaf 8)kubectl exec -it pod/mariadb-0 -n mariadb -- bash$(tput sgr0)
$(tput setaf 8)kubectl get pvc -n mariadb$(tput sgr0)

$(tput setaf 9)$(tput bold)🖥️ Show all namespaces:$(tput sgr0)
$(tput setaf 9)kubectl get all --all-namespaces$(tput sgr0)

$(tput setaf 1)$(tput bold)🖥️ Delete a namespace:$(tput sgr0)
$(tput setaf 1)kubectl delete namespace mariadb$(tput sgr0)

$(tput setaf 9)$(tput bold)🖥️ Show node details:$(tput sgr0)
$(tput setaf 9)kubectl get node$(tput sgr0)



EOF
    )

    # Secondo blocco: informazioni e comandi per il dashboard di Microk8s
    local MOTD_DASHBOARD=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Microk8s Dashboard
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)
$(tput setaf 9)$(tput bold)🖥️ Enable dashboard:$(tput sgr0)

$(tput setaf 8)microk8s enable community$(tput sgr0)
$(tput setaf 8)microk8s enable dashboard-ingress --hostname ${VM_MAIN_NAME}.${DNS_SUFFIX} --allow 0.0.0.0/0$(tput sgr0)

$(tput setaf 1)$(tput bold)🔑 Show MicroK8s Dashboard Token:$(tput sgr0)
$(tput setaf 1)kubectl describe secret -n kube-system microk8s-dashboard-token | grep "token:" | awk '{print "'\$2'"}'$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Start dashboard:$(tput sgr0)
$(tput setaf 8)microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0$(tput sgr0)

$(tput setaf 5)https://${VM_IP}:10443/#/login$(tput sgr0)
$(tput setaf 5)https://${VM_MAIN_NAME}.${DNS_SUFFIX}:10443/#/login$(tput sgr0)
$(tput sgr0)


EOF
    )

    msg_warn "Adding MOTD to ${VM_MAIN_NAME} in /etc/update-motd.d/"

    # Creazione del primo script: 10-k8s-commands
    multipass exec "${VM_MAIN_NAME}" -- sudo tee /etc/update-motd.d/992-k8s-commands > /dev/null <<EOF
#!/bin/bash
echo ""
echo "${MOTD_K8S_COMMANDS}"

EOF

    # Creazione del secondo script: 20-microk8s-dashboard
    multipass exec "${VM_MAIN_NAME}" -- sudo tee /etc/update-motd.d/991-microk8s-dashboard > /dev/null <<EOF
#!/bin/bash
echo "${MOTD_DASHBOARD}"
EOF

    # Imposta i permessi eseguibili per entrambi gli script
    multipass exec "${VM_MAIN_NAME}" -- sudo chmod +x /etc/update-motd.d/992-k8s-commands /etc/update-motd.d/991-microk8s-dashboard
}

# Function to generate MOTD
generate_dns_server_motd() {
    local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  DNS Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🖥️  Check /etc/dnsmasq.d/local.conf:$(tput sgr0)
$(tput setaf 2)cat /etc/dnsmasq.d/local.conf$(tput sgr0)

$(tput setaf 3)$(tput bold)🖥️  Check /etc/dnsmasq.d/dns-public.conf:$(tput sgr0)
$(tput setaf 3)cat /etc/dnsmasq.d/dns-public.conf$(tput sgr0)

$(tput setaf 3)$(tput bold)📈  Check dnsmasq:$(tput sgr0)
$(tput setaf 3)sudo dnsmasq --test$(tput sgr0)

$(tput setaf 6)$(tput bold)👀  Check dnsmasq status:$(tput sgr0)
$(tput setaf 6)sudo systemctl status dnsmasq$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄  Restart dnsmasq service:$(tput sgr0)
$(tput setaf 5)sudo systemctl restart dnsmasq$(tput sgr0)

$(tput sgr0)
EOF
    )

    msg_warn "Add ${DNS_VM_NAME} MOTD"
    multipass exec "$DNS_VM_NAME" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${DNS_VM_NAME}:"
echo "$MOTD_COMMANDS"
EOF
}

# Function to add MOTD for Rancher
add_motd_rancher() {
    local VM_NAME=$1
    local VM_IP=$(get_vm_ip "$VM_NAME")
    local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Rancher Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 3)$(tput bold)🔄 Restart Rancher:$(tput sgr0)
$(tput setaf 3)docker compose down && docker compose rm -f && docker compose up -d$(tput sgr0)

$(tput setaf 6)$(tput bold)👀 Check Rancher logs:$(tput sgr0)
$(tput setaf 6)docker logs rancher -f $(tput sgr0)

$(tput setaf 5)$(tput bold)🔑 Show rancher bootstrap password:$(tput sgr0)
$(tput setaf 5)docker logs rancher 2>&1 | grep "Bootstrap Password:"$(tput sgr0)

Rancher homepage:

https://${VM_IP}
https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}

Use the following link to complete the Rancher setup:
https://${VM_IP}/dashboard/?setup=BOOTSTRAP_PASSWORD_HERE
https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}/dashboard/?setup=BOOTSTRAP_PASSWORD_HERE
EOF
    )

    msg_warn "Add ${VM_NAME} MOTD"
    multipass exec "$VM_NAME" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${VM_NAME}:"
echo "$MOTD_COMMANDS"
EOF
}


# Function to generate MOTD
generate_nginx_motd() {
  local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Load Balancer Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 3)$(tput bold)️👀 Check nginx configuration:$(tput sgr0)
$(tput setaf 3)sudo nginx -t$(tput sgr0)

$(tput setaf 6)$(tput bold)👀 Check Nginx file configuration:$(tput sgr0)
$(tput setaf 6)sudo cat /etc/nginx/sites-available/cluster-balancer$(tput sgr0)

$(tput setaf 7)$(tput bold)👀 Check Nginx Service status:$(tput sgr0)
$(tput setaf 7)sudo systemctl status nginx.service$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄 Restart Nginx Service:$(tput sgr0)
$(tput setaf 5)sudo systemctl restart nginx.service$(tput sgr0)

$(tput setaf 8)$(tput bold)👀 Check systemd resolved configuration:$(tput sgr0)
$(tput setaf 8)cat /etc/systemd/resolved.conf.d/dns-loc.conf$(tput sgr0)

$(tput sgr0)

http://demo-go.${DNS_SUFFIX}
http://demo-php.${DNS_SUFFIX}
http://static-site.${DNS_SUFFIX}
http://phpmyadmin.${DNS_SUFFIX}

ping ${DNS_VM_NAME}.${DNS_SUFFIX}
ping ${VM_MAIN_NAME}.${DNS_SUFFIX}
ping ${VM_NODE_PREFIX}1.${DNS_SUFFIX}

ping demo-php.${DNS_SUFFIX}
ping demo-go.${DNS_SUFFIX}
ping static-site.${DNS_SUFFIX}
ping phpmyadmin.${DNS_SUFFIX}

EOF
)
  msg_warn "Add ${LOAD_BALANCE_HOSTNAME} MOTD"
  multipass exec "$LOAD_BALANCE_HOSTNAME" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
    echo ""
    echo "Commands to run on ${LOAD_BALANCE_HOSTNAME}:"
    echo "$MOTD_COMMANDS"
EOF
}
