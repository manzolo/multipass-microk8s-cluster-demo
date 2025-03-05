#!/bin/bash

# Include functions
source $(dirname $0)/script/functions/common.sh
source $(dirname $0)/script/functions/node.sh
source $(dirname $0)/script/functions/vm.sh
source $(dirname $0)/script/functions/dns.sh
source $(dirname $0)/script/functions/nginx.sh
source $(dirname $0)/script/functions/rancher.sh
source $(dirname $0)/script/functions/cluster.sh
source $(dirname $0)/script/functions/motd.sh

source $(dirname $0)/script/menu/cluster.sh
source $(dirname $0)/script/menu/load_balancer.sh
source $(dirname $0)/script/menu/rancher.sh
source $(dirname $0)/script/menu/dns.sh
source $(dirname $0)/script/menu/stack.sh
source $(dirname $0)/script/menu/client.sh
source $(dirname $0)/script/menu/main.sh

# Load default values and environment variables
source $(dirname $0)/script/functions/load_env.sh

create_env_local
# Execute the main menu
main_menu