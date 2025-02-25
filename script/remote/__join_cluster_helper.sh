#!/bin/bash
IP="$(hostname)"

NODE_TYPE=${2:-worker} # If not specified, node type will default to 'worker'

# Check if NODE_TYPE value is valid
if [[ "$NODE_TYPE" != "worker" && "$NODE_TYPE" != "controlplane" ]]; then
    echo "Error: NODE_TYPE value must be 'worker' or 'controlplane'."
    exit 1
fi

# Get the join command and replace the IP address and port with the cluster name
#JOINCMD=$(sudo microk8s add-node | sed '/microk8s/p' | sed '3!d' | sed -r 's|microk8s join (\b[0-9]{1,3}\.){3}[0-9]{1,3}\b:|microk8s join ${VM_MAIN_NAME}.loc:|')
JOINCMD=$(microk8s add-node | sed '/microk8s/p' | sed '3!d')

# Add the flag for the node type
JOINCMD+=" --${NODE_TYPE}"

echo "${JOINCMD##Join node with: }"