#!/bin/bash

#Include functions
source $(dirname $0)/../script/__functions.sh

multipass stop rancher
multipass delete rancher
multipass purge

msg_warn "Remove rancher.loc from /etc/hosts"

sudo sed -i -E "/rancher.loc/d" /etc/hosts