#!/bin/bash

# Default values (fallback if not in .env)
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
DEFAULT_INSTANCES="${INSTANCES:-2}"
DEFAULT_MAIN_CPU="${MAIN_CPU:-2}"
DEFAULT_MAIN_RAM="${MAIN_RAM:-2Gb}"
DEFAULT_MAIN_HDD_GB="${MAIN_HDD_GB:-10Gb}"
DEFAULT_NODE_CPU="${NODE_CPU:-1}"
DEFAULT_NODE_RAM="${NODE_RAM:-2Gb}"
DEFAULT_NODE_HDD_GB="${NODE_HDD_GB:-10Gb}"

# Load .env file if it exists
if [ -f .env ]; then
    source .env
fi

# Set variables
instances="${1:-$DEFAULT_INSTANCES}"
mainCpu="${2:-$DEFAULT_MAIN_CPU}"
mainRam="${3:-$DEFAULT_MAIN_RAM}"
mainHddGb="${4:-$DEFAULT_MAIN_HDD_GB}"
nodeCpu="${5:-$DEFAULT_NODE_CPU}"
nodeRam="${6:-$DEFAULT_NODE_RAM}"
nodeHddGb="${7:-$DEFAULT_NODE_HDD_GB}"

INSTALL_DIR=$(dirname $0)
CONFIG_DIR=${INSTALL_DIR}/config

