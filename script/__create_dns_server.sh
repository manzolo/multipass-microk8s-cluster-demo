#!/bin/bash

msg_info "Creating DNS VM: $DNS_VM_NAME"
multipass launch $DEFAULT_UBUNTU_VERSION --name "$DNS_VM_NAME" --cpus 1 -m 1G --disk 5G

msg_info "Installing dnsmasq on $DNS_VM_NAME"

multipass exec "$DNS_VM_NAME" -- bash -c '
    sudo apt -qq update > /dev/null 2>&1
    sudo apt -yq install dnsmasq > /dev/null 2>&1

    # Disabilita systemd-resolved per evitare conflitti
    sudo systemctl stop systemd-resolved > /dev/null 2>&1
    sudo systemctl disable systemd-resolved > /dev/null 2>&1
    sudo mv /etc/resolv.conf /etc/resolv.conf.backup > /dev/null 2>&1

    # Configura dnsmasq
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
'

msg_info "DNS VM $DNS_VM_NAME is ready!"