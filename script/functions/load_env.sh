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

DEFAULT_DEPLOY_DEMO_GO="${DEPLOY_DEMO_GO:-false}"
DEFAULT_DEPLOY_DEMO_PHP="${DEPLOY_DEMO_GO:-false}"
DEFAULT_DEPLOY_STATIC_SITE="${DEPLOY_DEMO_GO:-false}"
DEFAULT_DEPLOY_MARIADB="${DEPLOY_DEMO_GO:-false}"

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

deploy_demo_go="${8:-$DEFAULT_DEPLOY_DEMO_GO}"
deploy_demo_php="${9:-$DEFAULT_DEPLOY_DEMO_PHP}"
deploy_static_site="${10:-$DEFAULT_DEPLOY_STATIC_SITE}"
deploy_mariadb="${11:-$DEFAULT_DEPLOY_MARIADB}"

INSTALL_DIR=$(dirname $0)
CONFIG_DIR=${INSTALL_DIR}/config

