#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

multipass stop nginx-cluster-balancer
multipass delete nginx-cluster-balancer
multipass purge

msg_warn "Remove nginx-cluster-balancer from /etc/hosts"

sudo sed -i -E "/nginx-cluster-balancer/d" /etc/hosts
