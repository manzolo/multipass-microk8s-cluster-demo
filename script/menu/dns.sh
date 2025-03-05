# Function to handle DNS management
dns_management() {
    local options=(
        "Add DNS Configuration" "Add a custom local cluster DNS configuration"
        "Remove DNS Configuration" "Remove the custom local DNS configuration"
        "Start DNS server" "Start local cluster DNS server"
        "Stop DNS server" "Stop local cluster DNS server"
        "Shell on ${DNS_VM_NAME}" "Shell on ${DNS_VM_NAME}"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Rancher Management" options[@])
        case "$choice" in
            "Add DNS Configuration")
                echo "Adding DNS configuration..."
                add_dns_to_host
                ;;
            "Remove DNS Configuration")
                echo "Removing DNS configuration..."
                remove_dns_from_host
                ;;
            "Start DNS server")
                echo "Start local DNS server..."
                multipass start "${DNS_VM_NAME}" && msg_info "DNS server startup done." || msg_error "Error starting Nginx LB."
                press_any_key
                echo
                ;;
            "Stop DNS server")
                echo "Stop local DNS server..."
                multipass stop "${DNS_VM_NAME}" && msg_info "DNS server shutdown done." || msg_error "Error stopping Nginx LB."
                press_any_key
                echo
                ;;
            "Shell on ${DNS_VM_NAME}")
                multipass shell "${DNS_VM_NAME}" && msg_info "DNS server shell OK." || msg_error "Error DNS server shell."
                press_any_key
                echo
                ;;
            "Back")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}