#!/bin/bash
source $(dirname $0)/__functions.sh

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

IP="$(hostname)"

NODE_TYPE=${2:-worker} # If not specified, node type will default to 'worker'

# Check if NODE_TYPE value is valid
if [[ "$NODE_TYPE" != "worker" && "$NODE_TYPE" != "controlplane" ]]; then
    echo "Error: NODE_TYPE value must be 'worker' or 'controlplane'."
    exit 1
fi

# Remove any previous scripts
rm -rf script/_join_node.sh

# Get the join command and replace the IP address and port with the cluster name
#JOINCMD=$(sudo microk8s add-node | sed '/microk8s/p' | sed '3!d' | sed -r 's|microk8s join (\b[0-9]{1,3}\.){3}[0-9]{1,3}\b:|microk8s join ${VM_MAIN_NAME}.loc:|')
JOINCMD=$(sudo microk8s add-node | sed '/microk8s/p' | sed '3!d')

# Add the flag for the node type
JOINCMD+=" --${NODE_TYPE}"

# Write the join command to the _join_node.sh file
echo "${JOINCMD##Join node with: }" > script/_join_node.sh

# Add execute permissions to the script
chmod a+x script/_join_node.sh
