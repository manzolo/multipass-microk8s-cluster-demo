#!/bin/bash

# Create main VM
create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
mount_host_dir $VM_MAIN_NAME
