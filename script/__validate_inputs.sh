#!/bin/bash

if ! [[ "$instances" =~ ^[0-9]+$ ]]; then
    msg_error "Invalid number of instances: $instances"
    exit 1
fi