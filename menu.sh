#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# Include functions
# shellcheck source=script/functions/common.sh
source "${SCRIPT_DIR}/script/functions/common.sh"
# shellcheck source=script/functions/node.sh
source "${SCRIPT_DIR}/script/functions/node.sh"
# shellcheck source=script/functions/vm.sh
source "${SCRIPT_DIR}/script/functions/vm.sh"
# shellcheck source=script/functions/dns.sh
source "${SCRIPT_DIR}/script/functions/dns.sh"
# shellcheck source=script/functions/nginx.sh
source "${SCRIPT_DIR}/script/functions/nginx.sh"
# shellcheck source=script/functions/rancher.sh
source "${SCRIPT_DIR}/script/functions/rancher.sh"
# shellcheck source=script/functions/cluster.sh
source "${SCRIPT_DIR}/script/functions/cluster.sh"
# shellcheck source=script/functions/motd.sh
source "${SCRIPT_DIR}/script/functions/motd.sh"

# shellcheck source=script/menu/cluster.sh
source "${SCRIPT_DIR}/script/menu/cluster.sh"
# shellcheck source=script/menu/load_balancer.sh
source "${SCRIPT_DIR}/script/menu/load_balancer.sh"
# shellcheck source=script/menu/rancher.sh
source "${SCRIPT_DIR}/script/menu/rancher.sh"
# shellcheck source=script/menu/dns.sh
source "${SCRIPT_DIR}/script/menu/dns.sh"
# shellcheck source=script/menu/stack.sh
source "${SCRIPT_DIR}/script/menu/stack.sh"
# shellcheck source=script/menu/client.sh
source "${SCRIPT_DIR}/script/menu/client.sh"
# shellcheck source=script/menu/main.sh
source "${SCRIPT_DIR}/script/menu/main.sh"

# Load default values and environment variables
# shellcheck source=script/functions/load_env.sh
source "${SCRIPT_DIR}/script/functions/load_env.sh"

create_env_local
# Execute the main menu
main_menu