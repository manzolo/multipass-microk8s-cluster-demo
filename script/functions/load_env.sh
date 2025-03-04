#!/bin/bash
#set -x

# Default values (fallback if not in .env and .env.local)
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
DEFAULT_INSTANCES="${INSTANCES:-2}"
DEFAULT_MAIN_CPU="${MAIN_CPU:-2}"
DEFAULT_MAIN_RAM="${MAIN_RAM:-2Gb}"
DEFAULT_MAIN_HDD_GB="${MAIN_HDD_GB:-10Gb}"
DEFAULT_NODE_TEMPLATE="${NODE_TEMPLATE:-template-node-cluster}"
DEFAULT_FORCE_STOP_VM="${FORCE_STOP_VM:-false}"

DEFAULT_DEPLOY_DEMO_GO="${DEPLOY_DEMO_GO:-false}"
DEFAULT_DEPLOY_DEMO_PHP="${DEPLOY_DEMO_PHP:-false}"
DEFAULT_DEPLOY_STATIC_SITE="${DEPLOY_STATIC_SITE:-false}"
DEFAULT_DEPLOY_MARIADB="${DEPLOY_MARIADB:-false}"
DEFAULT_DEPLOY_MONGODB="${DEPLOY_MONGODB:-false}"
DEFAULT_DEPLOY_POSTGRES="${DEPLOY_POSTGRES:-false}"
DEFAULT_DEPLOY_ELK="${DEPLOY_ELK:-false}"
DEFAULT_DEPLOY_REDIS="${DEPLOY_REDIS:-false}"
DEFAULT_DEPLOY_RABBITMQ="${DEPLOY_RABBITMQ:-false}"
DEFAULT_DEPLOY_JENKINS="${DEPLOY_JENKINS:-false}"

# Load .env file if it exists
if [ -f .env ]; then
    source .env
fi

# Load .env.local file if it exists
if [ -f .env.local ]; then
    source .env.local
fi

# Set variables from .env/.env.local or defaults
instances="${INSTANCES:-$DEFAULT_INSTANCES}"
mainCpu="${MAIN_CPU:-$DEFAULT_MAIN_CPU}"
mainRam="${MAIN_RAM:-$DEFAULT_MAIN_RAM}"
mainHddGb="${MAIN_HDD_GB:-$DEFAULT_MAIN_HDD_GB}"

# Set the other deploy variables directly from .env/.env.local or defaults
deploy_demo_go="${DEPLOY_DEMO_GO:-$DEFAULT_DEPLOY_DEMO_GO}"
deploy_demo_php="${DEPLOY_DEMO_PHP:-$DEFAULT_DEPLOY_DEMO_PHP}"
deploy_static_site="${DEPLOY_STATIC_SITE:-$DEFAULT_DEPLOY_STATIC_SITE}"
deploy_mariadb="${DEPLOY_MARIADB:-$DEFAULT_DEPLOY_MARIADB}"
deploy_mongodb="${DEPLOY_MONGODB:-$DEFAULT_DEPLOY_MONGODB}"
deploy_postgres="${DEPLOY_POSTGRES:-$DEFAULT_DEPLOY_POSTGRES}"
deploy_elk="${DEPLOY_ELK:-$DEFAULT_DEPLOY_ELK}"
deploy_redis="${DEPLOY_REDIS:-$DEFAULT_DEPLOY_REDIS}"
deploy_rabbitmq="${DEPLOY_RABBITMQ:-$DEFAULT_DEPLOY_RABBITMQ}"
deploy_jenkins="${DEPLOY_JENKINS:-$DEFAULT_DEPLOY_JENKINS}"
node_template="${NODE_TEMPLATE:-$DEFAULT_NODE_TEMPLATE}"
force_stop_vm="${FORCE_STOP_VM:-$DEFAULT_FORCE_STOP_VM}"

# echo "instances: $instances"
# echo "mainCpu: $mainCpu"
# echo "mainRam: $mainRam"
# echo "mainHddGb: $mainHddGb"
# echo "deploy_demo_go: $deploy_demo_go"
# echo "force_stop_vm: $force_stop_vm"

INSTALL_DIR=$(dirname $0)
CONFIG_DIR=${INSTALL_DIR}/config