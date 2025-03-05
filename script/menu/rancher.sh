# Function to handle Rancher management
rancher_management() {
    local options=(
        "Create Rancher" "Create Rancher"
        "Start Rancher" "Start Rancher"
        "Stop Rancher" "Stop Rancher"
        "Destroy Rancher" "Destroy Rancher"
        "Shell on ${RANCHER_HOSTNAME}" "Shell on ${RANCHER_HOSTNAME}"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Rancher Management" options[@])
        case "$choice" in
            "Create Rancher")
                create_rancher && msg_info "Rancher creation done." || msg_error "Error during Rancher creation."; press_any_key; echo
                ;;
            "Start Rancher")
                multipass start "${RANCHER_HOSTNAME}" && msg_info "Rancher startup done." || msg_error "Error starting Rancher."
                press_any_key
                echo
                ;;
            "Stop Rancher")
                multipass stop "${RANCHER_HOSTNAME}" && msg_info "Rancher shutdown done." || msg_error "Error stopping Rancher."
                press_any_key
                echo
                ;;
            "Shell on ${RANCHER_HOSTNAME}")
                multipass shell "${RANCHER_HOSTNAME}" && msg_info "Rancher shell OK." || msg_error "Error shell Rancher."
                press_any_key
                echo
                ;;
            "Destroy Rancher")
                destroy_rancher && msg_info "Rancher destruction done." || msg_error "Error during Rancher destruction."; press_any_key; echo
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