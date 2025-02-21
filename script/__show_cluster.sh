#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Intestazione della tabella
echo
echo
printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"
printf "${BLUE}%-20s | %-15s | %-30s${NC}\n" "VM Name" "IP" "Multipass Shell"
printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"

# Estrai le informazioni e formatta la tabella
multipass list | awk '/k8s-/ {
    name = $1
    state = $2
    ip = $3
    if (state == "Running") {
        printf "'${GREEN}'%-20s'${NC}' | '${YELLOW}'%-15s'${NC}' | multipass shell %s\n", name, ip, name
    } else {
        printf "'${RED}'%-20s'${NC}' | '${YELLOW}'%-15s'${NC}' | '${RED}'Stopped'${NC}'\n", name, "N/A"
    }
}'

printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"
echo