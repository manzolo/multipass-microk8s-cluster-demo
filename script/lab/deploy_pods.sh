
#!/bin/bash
multipass shell "k8s-main" > /dev/null 2>&1 <<EOF
#!/bin/bash
num_pods=0

while true; do
    num_pods=$((num_pods + 10))
    kubectl scale deployment demo-go --replicas=$num_pods -n demo-go
    kubectl rollout status deployment/demo-go -n demo-go
    kubectl get all -o wide -n demo-go

    if [ $num_pods -gt 10 ]; then
        exit 0
    fi
done
EOF