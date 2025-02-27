#!/bin/bash

set -e

function get_available_node_number() {
  local existing_nodes
  local available_num=1

  # Ottieni i numeri dei nodi esistenti e ordinali
  existing_nodes=$(multipass list | grep "$VM_NODE_PREFIX" | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n)

  # Trova il primo numero disponibile
  if [ -n "$existing_nodes" ]; then
    for num in $existing_nodes; do
      if [[ $num -eq $available_num ]]; then
        available_num=$((available_num + 1))
      else
        break
      fi
    done
  fi

  echo "$available_num"
}

function wait_for_microk8s_ready() {
  local vm_name="$1"

  msg_warn "Waiting for microk8s to be ready on $vm_name..."
  while ! multipass exec "$vm_name" -- microk8s status --wait-ready > /dev/null 2>&1; do
    sleep 10
  done

  msg_info "MicroK8s is ready on $vm_name."
}

function restart_microk8s_nodes() {
  local prefix="$VM_NODE_PREFIX"
  local retries=3  # Numero massimo di tentativi
  local node_name

  msg_info "Checking nodes status..."

  # Ottieni lo stato dei nodi
  local nodes_status=$(multipass exec "$VM_MAIN_NAME" -- kubectl get nodes)

  # Trova tutti i nodi NotReady
  local not_ready_nodes=$(echo "$nodes_status" | grep "NotReady" | awk '{print $1}')

  # Se ci sono nodi NotReady, riavviali
  if [[ -n "$not_ready_nodes" ]]; then
    for node_name in $not_ready_nodes; do
      msg_warn "Restarting MicroK8s on $node_name..."
      restart_node "$node_name" "$retries"
    done
  else
    msg_info "All nodes are ready. Skipping restart."
  fi

  msg_info "MicroK8s restart process completed."
}

function restart_node() {
  local node_name=$1
  local retries=$2
  local attempt
  local reached=false
  local inspected=false
  local restarted=false
  local ready=false

  # Verifica se il nodo è raggiungibile
  if ! multipass exec "$node_name" -- "true" > /dev/null 2>&1; then
    msg_error "Node $node_name is not reachable. Skipping restart."
    return
  fi

  # Esegue l'ispezione per identificare eventuali problemi (con tentativi)
  msg_warn "Running microk8s inspect on $node_name..."
  attempt=1
  while [[ $attempt -le $retries ]]; do
    if multipass exec "$node_name" -- sudo microk8s inspect > /dev/null 2>&1; then
      inspected=true
      break # Comando riuscito, esci dal ciclo
    else
      attempt=$((attempt + 1))
      sleep 2
    fi
  done

  #if ! $inspected; then
  #  msg_error "All attempts failed for microk8s inspect on $node_name. Skipping restart."
  #  return
  #fi

  # Riavvia MicroK8s (con tentativi)
  msg_warn "Restarting MicroK8s on $node_name..."
  attempt=1
  while [[ $attempt -le $retries ]]; do
    if multipass exec "$node_name" -- sudo snap restart microk8s > /dev/null 2>&1; then
      restarted=true
      break # Comando riuscito, esci dal ciclo
    else
      attempt=$((attempt + 1))
      sleep 2
    fi
  done

  if ! $restarted; then
    msg_error "All attempts failed to restart MicroK8s on $node_name. Skipping restart."
    return
  fi

  # Attende che MicroK8s sia pronto (con tentativi)
  msg_warn "Waiting for MicroK8s to be ready on $node_name..."
  attempt=1
  while [[ $attempt -le $retries ]]; do
    if wait_for_microk8s_ready "$node_name"; then
      ready=true
      msg_info "MicroK8s restarted and ready on $node_name."
      break # Comando riuscito, esci dal ciclo
    else
      attempt=$((attempt + 1))
      sleep 2
    fi
  done

  if ! $ready; then
    msg_error "All attempts failed for MicroK8s to become ready on $node_name. Skipping restart."
  fi
}

function get_max_node_instance() {
  local prefix="$VM_NODE_PREFIX"
  local existing_nodes
  local max_instance

  # Ottieni i numeri dei nodi esistenti e ordinali
  existing_nodes=$(multipass list | grep "$prefix" | awk '{print $1}' | sed "s/${prefix}//" | sort -n)

  # Trova il numero massimo di istanza
  if [ -n "$existing_nodes" ]; then
    max_instance=$(echo "$existing_nodes" | tail -n 1)
  else
    max_instance=0 # Se non ci sono nodi, il massimo è 0
  fi

  echo "$max_instance"
}

# Function to check prerequisites
check_prerequisites() {
    msg_warn "Checking prerequisites..."
    check_command_exists "multipass" || { msg_error "Multipass is not installed or cannot be found. Exiting."; exit 1; }
}

# Function to generate join command
node_cluster_join() {
local node_name=$1
    local max_retries=3 # Numero massimo di tentativi
    local retry_count=0

    msg_warn "Generating join cluster command for $VM_MAIN_NAME"
    multipass transfer script/remote/__join_cluster_helper.sh "$VM_MAIN_NAME:/home/ubuntu/join_cluster_helper.sh"

    local CLUSTER_JOIN_COMMAND=$(multipass exec "$VM_MAIN_NAME" -- /home/ubuntu/join_cluster_helper.sh)
    multipass exec "$VM_MAIN_NAME" -- rm -rf /home/ubuntu/join_cluster_helper.sh

    msg_warn "Installing microk8s on $node_name"

    while [[ $retry_count -lt $max_retries ]]; do
        if multipass exec "$node_name" -- $CLUSTER_JOIN_COMMAND; then
            msg_info "MicroK8s joined successfully on $node_name."
            return # Comando riuscito, esci dalla funzione
        else
            retry_count=$((retry_count + 1))
            msg_warn "Join command failed on $node_name. Retry attempt $retry_count of $max_retries..."
            sleep 5 # Attendi 5 secondi prima di riprovare
        fi
    done

    msg_error "Failed to join MicroK8s on $node_name after $max_retries attempts."
}

function add_node() {
    # Main script execution
    check_prerequisites

    # Gestione del parametro opzionale
    if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
        NUM_VMS="$1"
    else
        NUM_VMS=1
    fi

    local max_node_before_clone=$(get_max_node_instance) # Ottieni il numero massimo di nodi prima della clonazione.
    local starting_index=$(get_available_node_number)

    # Controllo per evitare l'errore di indice negativo o zero
    if [[ $starting_index -eq 0 ]]; then
        starting_index=1
    fi

    # Fase di clonazione
    for ((i=1; i<=NUM_VMS; i++)); do
        clone_node_vm
    done

    msg_warn "Configuring VM nodes..."
    # Fase di configurazione
    for ((current_vm=starting_index; current_vm < starting_index + NUM_VMS; current_vm++)); do
        local node_name="${VM_NODE_PREFIX}${current_vm}"
        configure_node_vm "$node_name"
    done

    # Riavvia il nodo principale (VM_MAIN_NAME)
    if [[ "$NUM_VMS" -gt 0 ]]; then
        msg_warn "Restarting main node: $VM_MAIN_NAME"
        multipass start "$VM_MAIN_NAME"
        wait_for_microk8s_ready "$VM_MAIN_NAME"
    fi
}

# Function to clone node VM (solo clonazione)
function clone_node_vm() {
    local max_node=$(get_max_node_instance) # Ottieni il numero massimo di nodi esistenti
    local node_name="${VM_NODE_PREFIX}${max_node}" # Nodo da clonare
    local new_node_name="${VM_NODE_PREFIX}$(get_available_node_number)" # Nome del nuovo nodo

    msg_warn "Cloning VM: $new_node_name"
    clone_vm "$new_node_name" "$node_name" # Clona dall'ultimo nodo creato
}

# Function to configure node VM (configurazione e avvio)
function configure_node_vm() {
    local node_name=$1

    multipass start "$node_name" # Avvia la VM
    sleep 5 # Aggiungi una pausa per permettere a Multipass di aggiornare lo stato
    wait_for_microk8s_ready "$node_name"

    add_machine_to_dns "$node_name"
    restart_dns_service
    multipass info "$node_name"

    multipass start "$VM_MAIN_NAME"
    wait_for_microk8s_ready "$VM_MAIN_NAME"
    sleep 5

    node_cluster_join "$node_name"
}

function remove_node() {
    vm_name=$1
    #Check prerequisites
    check_command_exists "multipass"

    remove_machine_from_dns $vm_name
    restart_dns_service

    run_command_on_node $VM_MAIN_NAME "microk8s remove-node $vm_name"

    multipass stop --force $vm_name
    multipass delete --purge $vm_name
    multipass purge
}