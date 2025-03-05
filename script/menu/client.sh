# Function to handle client management
client_management() {
    local options=(
        "Install" "Install client VM"
        "RDP" "Enter via RDP on client VM"
        "Remove" "Uninstall client VM"
        "Back" "Return to the main menu"
    )

    while true; do
        choice=$(display_menu "Client Management" options[@])
        case "$choice" in
            "Install")
                client_vm_setup
                ;;
            "RDP")
                client_vm_rdp
                ;;
            "Remove")
                client_vm_remove
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