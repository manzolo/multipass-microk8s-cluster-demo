#!/bin/bash
source $(dirname $0)/__functions.sh

rm -rf script/_join_node.sh
rm -rf script/_test.sh
rm -rf config/hosts

# Funzione per eseguire un comando con un numero massimo di tentativi
function retry_command {
    local command="$1"
    local max_attempts=3
    local attempt=1
    local wait_time=5

    while [ $attempt -le $max_attempts ]; do
        #echo "Attempt $attempt for: $command"
        eval $command

        if [ $? -eq 0 ]; then
            #echo "Deploy OK."
            return 0
        else
            echo "Error on deploy. Attempt $attempt of $max_attempts."
            sleep $wait_time
        fi

        attempt=$((attempt + 1))
    done

    echo "Command failed after $max_attempts attempts."
    return 1
}

# Applica la configurazione per demo-go e verifica lo stato del rollout
retry_command "kubectl apply -f config/demo-go.yaml"
retry_command "kubectl rollout status deployment/demo-go -n demo-go"

# Applica la configurazione per demo-php e verifica lo stato del rollout
retry_command "kubectl apply -f config/demo-php.yaml"
retry_command "kubectl rollout status deployment/demo-php -n demo-php"

# Applica la configurazione per static-site e verifica lo stato del rollout
retry_command "kubectl apply -f config/static-site.yaml"
retry_command "kubectl rollout status deployment/static-site -n static-site"


# Messaggio di avviso e attesa
msg_warn "Waiting for deploy complete..."
sleep 10