#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

multipass stop --force ${RANCHER_HOSTNAME} > /dev/null 2>&1
multipass delete --purge ${RANCHER_HOSTNAME} > /dev/null 2>&1
multipass purge > /dev/null 2>&1

remove_machine_from_dns $RANCHER_HOSTNAME

# msg_warn "Remove ${RANCHER_HOSTNAME}.${DNS_SUFFIX} from /etc/hosts"

# sudo sed -i -E "/${RANCHER_HOSTNAME}.${DNS_SUFFIX}/d" /etc/hosts

# Ottieni il PID del processo padre
PARENT_PID=$(ps -o ppid= -p $$)

# Ottieni il nome del processo padre
PARENT_NAME=$(ps -o comm= -p $PARENT_PID)

if [[ "$PARENT_NAME" != "menu.sh" ]]; then
    press_any_key
fi