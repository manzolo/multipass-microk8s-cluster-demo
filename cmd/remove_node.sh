#!/bin/bash

HOST_DIR_NAME=${PWD}
MULTIPASS_VM=$1

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

msg_warn "Check prerequisites..."

#Check prerequisites
check_command_exists "multipass"

remove_machine_from_dns $MULTIPASS_VM

multipass stop --force $MULTIPASS_VM
multipass delete --purge $MULTIPASS_VM
multipass purge
multipass list

press_any_key
echo