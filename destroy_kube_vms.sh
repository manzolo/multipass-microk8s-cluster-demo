#!/bin/bash
# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi
#Include functions
source $(dirname $0)/script/__functions.sh

msg_warn "== Clean vms cluster"

multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}' | while read node; do
msg_warn "remove $node"
multipass delete --purge $node
done

echo "remove ${VM_MAIN_NAME}"
multipass delete --purge ${VM_MAIN_NAME}
multipass purge

multipass delete --purge ${DNS_VM_NAME}
multipass purge

multipass list



rm -rf "./script/_test.sh"
rm -rf "./config/hosts"

msg_info "== Vms cluster clear"
