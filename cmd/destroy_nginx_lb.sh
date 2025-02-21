#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

multipass stop --force $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
multipass delete --purge $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
multipass purge > /dev/null 2>&1

remove_machine_from_dns $LOAD_BALANCE_HOSTNAME
remove_machine_from_dns demo-go
remove_machine_from_dns demo-php

# msg_warn "Remove $LOAD_BALANCE_HOSTNAME from /etc/hosts"

# sudo sed -i -E "/$LOAD_BALANCE_HOSTNAME/d" /etc/hosts

press_any_key
echo