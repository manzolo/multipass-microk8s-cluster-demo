#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

multipass stop --force ${RANCHER_HOSTNAME}
multipass delete --purge ${RANCHER_HOSTNAME}
multipass purge

remove_machine_from_dns $RANCHER_HOSTNAME

msg_warn "Remove ${RANCHER_HOSTNAME}.${DNS_SUFFIX} from /etc/hosts"

sudo sed -i -E "/${RANCHER_HOSTNAME}.${DNS_SUFFIX}/d" /etc/hosts