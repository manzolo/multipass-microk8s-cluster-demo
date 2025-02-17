#!/bin/bash

msg_info "Creating DNS VM: $DNS_VM_NAME"
multipass launch $DEFAULT_UBUNTU_VERSION --name "$DNS_VM_NAME" --cpus 1 -m 1G --disk 5G

_DNS_IP=$(multipass info ${DNS_VM_NAME} | grep IPv4 | awk '{print $2}')

msg_info "Installing dnsmasq on $DNS_VM_NAME"

multipass exec "$DNS_VM_NAME" -- bash -c '
    sudo apt -qq update > /dev/null 2>&1
    sudo apt -yq install dnsmasq > /dev/null 2>&1

    # Disabilita systemd-resolved per evitare conflitti
    sudo systemctl stop systemd-resolved > /dev/null 2>&1
    sudo systemctl disable systemd-resolved > /dev/null 2>&1
    sudo mv /etc/resolv.conf /etc/resolv.conf.backup > /dev/null 2>&1

    # Configura dnsmasq

    cat <<EOF | sudo tee /etc/resolv.conf >/dev/null
nameserver 127.0.0.1
EOF

    cat <<EOF | sudo tee /etc/dnsmasq.d/local.conf >/dev/null
address=/'${DNS_VM_NAME}'.'${DNS_SUFFIX}'/'${_DNS_IP}'
EOF

    cat <<EOF | sudo tee /etc/dnsmasq.d/dns-public.conf >/dev/null
# Non usare i nameserver dal file /etc/resolv.conf
no-resolv

# Imposta i nameserver upstream
server=1.1.1.1
server=8.8.8.8

# Abilita la risoluzione per il dominio locale .'${DNS_SUFFIX}'
domain="'${DNS_SUFFIX}'"
expand-hosts
local=/"'${DNS_SUFFIX}'"/

#Specifica un file addizionale per host locali personalizzati
addn-hosts=/etc/dnsmasq.d/local.conf
EOF

    sudo systemctl restart dnsmasq
    sudo dnsmasq --test
'

# MOTD generation with color codes
MOTD_COMMANDS=$(cat <<EOF
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
multipass exec ${DNS_VM_NAME} -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${DNS_VM_NAME}:"
echo "$MOTD_COMMANDS"
EOF

msg_info "DNS VM $DNS_VM_NAME is ready!"