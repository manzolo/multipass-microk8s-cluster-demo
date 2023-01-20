RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
NC='\033[0m' # No Color

check_command_exists() {
    if ! command -v $1 &> /dev/null
    then
        echo -e "${RED}$1 could not be found!${NC}"
        exit 1
    fi
}

run_command_on_node() {
    node_name=$1
    command=$2
    multipass exec -v ${node_name} -- ${command}
}
