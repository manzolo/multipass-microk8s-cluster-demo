# Function to display the menu
display_menu() {
    local title=$1
    local options=("${!2}")
    whiptail --title "$title" --menu "Select an option:" 25 80 15 "${options[@]}" 3>&1 1>&2 2>&3
}

uninstall_all(){
    if whiptail --yesno "Are you sure you want to uninstall everything? This will destroy the Kubernetes cluster, Nginx LB, and Rancher." 10 60; then
        ./destroy_kube_vms.sh && msg_info "Kubernetes cluster destruction done." || msg_error "Error during Kubernetes cluster destruction."
        destroy_nginx_lb && msg_info "Nginx LB destruction done." || msg_error "Error during Nginx LB destruction."
        destroy_rancher && msg_info "Rancher destruction done." || msg_error "Error during Rancher destruction."
        press_any_key
    else
        echo "Uninstall All cancelled."
    fi
}

# Main menu
main_menu() {
    local options=(
        "Cluster Management" "Manage Kubernetes cluster"
        "DNS Management" "Manage local cluster DNS server"
        "Load Balancer Management" "Manage Nginx Load Balancer"
        "Rancher Management" "Manage Rancher"
        "Stack Management" "Manage all stacks (MariaDB, ELK, MongoDB, etc.)"
        "Client Management" "Ubuntu client for test"
        "Show Cluster" "Show Cluster information"
        "Uninstall All" "Destroy Kubernetes cluster, Nginx LB, and Rancher"
        "Exit" "Exit the program"
    )
    while true; do
        choice=$(display_menu "Kubernetes Cluster Management" options[@])
        case "$choice" in
            "Cluster Management")
                cluster_management
                ;;
            "DNS Management")
                dns_management
                ;;
            "Load Balancer Management")
                load_balancer_management
                ;;
            "Rancher Management")
                rancher_management
                ;;
            "Client Management")
                client_management
                ;;
            "Stack Management")
                stack_and_env_management
                ;;
            "Show Cluster")
                show_cluster_info
                press_any_key
                echo
                ;;
            "Uninstall All")
                uninstall_all
                ;;
            "Exit")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}