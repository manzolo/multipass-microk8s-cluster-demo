#!/bin/bash

HOST_DIR_NAME=${PWD}
MULTIPASS_VM=$1

#Include functions
source $(dirname $0)/script/__functions.sh

msg_warn "Check prerequisites..."

#Check prerequisites
check_command_exists "multipass"

multipass stop $MULTIPASS_VM
multipass delete $MULTIPASS_VM
multipass purge
multipass list

