#!/bin/bash

msg_info "Creating DNS VM: $DNS_VM_NAME"
multipass launch $DEFAULT_UBUNTU_VERSION --name "$DNS_VM_NAME" --cpus 1 -m 1G --disk 5G

msg_info "Installing dnsmasq on $DNS_VM_NAME"
multipass exec "$DNS_VM_NAME" -- sudo apt-get update
multipass exec "$DNS_VM_NAME" -- sudo apt-get install -y dnsmasq

multipass exec "$DNS_VM_NAME" -- sudo systemctl stop systemd-resolved
multipass exec "$DNS_VM_NAME" -- sudo systemctl disable systemd-resolved
multipass exec "$DNS_VM_NAME" -- sudo mv /etc/resolv.conf /etc/resolv.conf.backup
multipass exec "$DNS_VM_NAME" -- sudo bash -c 'echo "nameserver 8.8.8.8" | tee /etc/resolv.conf'

msg_info "Restarting dnsmasq service on $DNS_VM_NAME"
multipass exec "$DNS_VM_NAME" -- sudo systemctl restart dnsmasq

msg_info "DNS VM $DNS_VM_NAME is ready!"

