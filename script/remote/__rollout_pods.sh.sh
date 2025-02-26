#!/bin/bash

# Variabili d'ambiente
deploy_demo_go=true
deploy_demo_php=true
deploy_static_site=true
deploy_mariadb=true
deploy_mongodb=false

# Funzione per eseguire un comando con un numero massimo di tentativi
function retry_command {
    local command="$1"
    local max_attempts=3
    local attempt=1
    local wait_time=5

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt for: $command"
        eval $command

        if [ $? -eq 0 ]; then
            echo "Deploy OK."
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

function k8s_deploy() {
    # Applica la configurazione per demo-go se deploy_demo_go è true
    if [ "$deploy_demo_go" = true ]; then
        retry_command "kubectl apply -f microk8s_demo_config/demo-go.yaml"
        retry_command "kubectl rollout status deployment/demo-go -n demo-go"
    else
        echo "Skipping demo-go deployment."
    fi

    # Applica la configurazione per demo-php se deploy_demo_php è true
    if [ "$deploy_demo_php" = true ]; then
        retry_command "kubectl apply -f microk8s_demo_config/demo-php.yaml"
        retry_command "kubectl rollout status deployment/demo-php -n demo-php"
    else
        echo "Skipping demo-php deployment."
    fi

    # Applica la configurazione per static-site se deploy_static_site è true
    if [ "$deploy_static_site" = true ]; then
        retry_command "kubectl apply -f microk8s_demo_config/static-site.yaml"
        retry_command "kubectl rollout status deployment/static-site -n static-site"
    else
        echo "Skipping static-site deployment."
    fi

    # Applica la configurazione per mariadb + phpmyadmin se deploy_mariadb è true
    if [ "$deploy_mariadb" = true ]; then
        retry_command "kubectl apply -f microk8s_demo_config/mariadb.yaml"
        retry_command "kubectl rollout status deployment/phpmyadmin -n mariadb"
    else
        echo "Skipping mariadb + phpmyadmin deployment."
    fi

    # Applica la configurazione per mongodb se deploy_mongodb è true
    if [ "$deploy_mongodb" = true ]; then
        retry_command "kubectl apply -f microk8s_demo_config/mongodb.yaml"
        retry_command "kubectl rollout status deployment/mongodb-express -n mongodb"
    else
        echo "Skipping mongodb deployment."
    fi

    # Messaggio di avviso e attesa
    echo "Waiting for deploy complete..."
    sleep 10
}

k8s_deploy
