#!/bin/bash

# Create main VM
create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"

add_machine_to_dns $VM_MAIN_NAME
