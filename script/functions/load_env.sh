#!/bin/bash

# Default values (fallback if not in .env)
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
DEFAULT_INSTANCES="${INSTANCES:-2}"
DEFAULT_MAIN_CPU="${MAIN_CPU:-2}"
DEFAULT_MAIN_RAM="${MAIN_RAM:-2Gb}"
DEFAULT_MAIN_HDD_GB="${MAIN_HDD_GB:-10Gb}"

DEFAULT_DEPLOY_DEMO_GO="${DEPLOY_DEMO_GO:-false}"
DEFAULT_DEPLOY_DEMO_PHP="${DEPLOY_DEMO_PHP:-false}"
DEFAULT_DEPLOY_STATIC_SITE="${DEPLOY_STATIC_SITE:-false}"
DEFAULT_DEPLOY_MARIADB="${DEPLOY_MARIADB:-false}"
DEFAULT_DEPLOY_MONGODB="${DEPLOY_MONGODB:-false}"
DEFAULT_DEPLOY_POSTGRES="${DEPLOY_POSTGRES:-false}"
DEFAULT_DEPLOY_ELK="${DEPLOY_ELK:-false}"

# Load .env file if it exists
if [ -f .env ]; then
    source .env
fi

# Set variables
instances="${1:-$DEFAULT_INSTANCES}"
mainCpu="${2:-$DEFAULT_MAIN_CPU}"
mainRam="${3:-$DEFAULT_MAIN_RAM}"
mainHddGb="${4:-$DEFAULT_MAIN_HDD_GB}"

deploy_demo_go=${5:-$DEFAULT_DEPLOY_DEMO_GO}
deploy_demo_php=${6:-$DEFAULT_DEPLOY_DEMO_PHP}
deploy_static_site=${7:-$DEFAULT_DEPLOY_STATIC_SITE}
deploy_mariadb=${8:-$DEFAULT_DEPLOY_MARIADB}
deploy_mongodb=${9:-$DEFAULT_DEPLOY_MONGODB}
deploy_postgres=${10-$DEFAULT_DEPLOY_POSTGRES}
deploy_elk=${11:-$DEFAULT_DEPLOY_ELK}

INSTALL_DIR=$(dirname $0)
CONFIG_DIR=${INSTALL_DIR}/config