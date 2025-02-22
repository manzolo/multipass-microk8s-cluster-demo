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
multipass delete --purge $node > /dev/null 2>&1
done

echo "remove ${VM_MAIN_NAME}"
multipass delete --purge ${VM_MAIN_NAME} > /dev/null 2>&1
multipass purge > /dev/null 2>&1

multipass delete --purge ${DNS_VM_NAME} > /dev/null 2>&1
multipass purge > /dev/null 2>&1

multipass list

rm -rf "./script/_test.sh"
rm -rf "./config/hosts"

msg_info "== Vms cluster clear"

# Ottieni il PID del processo padre
PARENT_PID=$(ps -o ppid= -p $$)

# Ottieni il nome del processo padre
PARENT_NAME=$(ps -o comm= -p $PARENT_PID)

if [[ "$PARENT_NAME" != "menu.sh" ]]; then
    press_any_key
fi