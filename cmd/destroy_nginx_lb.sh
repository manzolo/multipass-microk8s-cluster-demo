#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

multipass stop --force $LOAD_BALANCE_HOSTNAME
multipass delete --purge $LOAD_BALANCE_HOSTNAME
multipass purge

remove_machine_from_dns $LOAD_BALANCE_HOSTNAME

msg_warn "Remove $LOAD_BALANCE_HOSTNAME from /etc/hosts"

sudo sed -i -E "/$LOAD_BALANCE_HOSTNAME/d" /etc/hosts
