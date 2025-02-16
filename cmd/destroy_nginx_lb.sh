#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

multipass stop --force $LOAD_BALANCE_HOSTNAME
multipass delete --purge $LOAD_BALANCE_HOSTNAME
multipass purge

remove_machine_from_dns $LOAD_BALANCE_HOSTNAME
remove_machine_from_dns demo-go
remove_machine_from_dns demo-php

# msg_warn "Remove $LOAD_BALANCE_HOSTNAME from /etc/hosts"

# sudo sed -i -E "/$LOAD_BALANCE_HOSTNAME/d" /etc/hosts

read -n 1 -s -r -p "Press any key to continue..."
echo