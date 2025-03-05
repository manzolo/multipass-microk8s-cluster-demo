# Function to handle client management
client_management() {
    local options=(
        "Install" "Install client VM"
        "Start" "Start client VM"
        "RDP" "Enter via RDP on client VM"
        "Stop" "Stop client VM"
        "Remove" "Uninstall client VM"
        "Back" "Return to the main menu"
    )

    while true; do
        choice=$(display_menu "Client Management" options[@])
        case "$choice" in
            "Install")
                client_vm_setup
                ;;
            "Start")
                client_vm_start
                ;;
            "RDP")
                client_vm_rdp
                ;;
            "Stop")
                client_vm_stop
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