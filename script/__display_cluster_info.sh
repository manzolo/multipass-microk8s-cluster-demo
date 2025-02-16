#!/bin/bash

# Display cluster info
multipass list | grep -i "k8s-"

# Test services
IP=$(multipass info ${VM_MAIN_NAME} | grep IPv4 | awk '{print $2}')
NODEPORT_GO=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
NODEPORT_PHP=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)

# MOTD generation with color codes
MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Kubernetes Cluster Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Apply new configuration:$(tput sgr0)
$(tput setaf 2)kubectl apply -f config/demo-go.yaml$(tput sgr0)

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

$(tput setaf 1)$(tput bold)🔑 Get MicroK8s Dashboard Token:$(tput sgr0)
$(tput setaf 1)kubectl describe secret -n kube-system microk8s-dashboard-token$(tput sgr0)

$(tput setaf 9)$(tput bold)🖥️ Show node details:$(tput sgr0)
$(tput setaf 9)kubectl get node$(tput sgr0)

$(tput sgr0)
EOF
)

msg_warn "Add ${VM_MAIN_NAME} MOTD"
multipass exec ${VM_MAIN_NAME} -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${VM_MAIN_NAME}:"
echo "$MOTD_COMMANDS"
EOF

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-go --replicas=10 -n demo-go"
multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-go --replicas=10 -n demo-go

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-php --replicas=10 -n demo-php"
multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-php --replicas=10 -n demo-php

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-go"
multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-go
msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-php"
multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-php

msg_warn "Enter on ${VM_MAIN_NAME}:"
msg_info "multipass shell ${VM_MAIN_NAME}"

msg_warn "Testing Golang service:"
msg_info "curl -s http://$IP:$NODEPORT_GO"

# Clean temp files
temp_file="${HOST_DIR_NAME}/script/_test.sh"
trap "rm -f $temp_file" EXIT
echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
chmod +x "$temp_file"
"$temp_file"

echo

msg_warn "Testing PHP service:"
msg_info "http://$IP:$NODEPORT_PHP"