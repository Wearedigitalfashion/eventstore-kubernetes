#!/bin/bash

function init {
    rm -rf .tmp
    mkdir -p .tmp
}

function validateInput {
    count=$1
    re='^[0-9]+$'
    if ! [[ $count =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
    fi
}

function createSpecs {
    local count=$1
    for ((c=1; c<=$count; c++ ))
    do
        cat ./templates/es_deployment_template.yaml | sed -e "s/\${nodenumber}/$c/" | sed -e "s/\${nodecount}/$count/" > .tmp/es_deployment_$c.yaml
    done
}

function createDeployments {
    local count=$1
    for ((c=1; c<=$count; c++ ))
    do
        kubectl apply -f .tmp/es_deployment_$c.yaml
    done
}

function createEsService {
    kubectl apply -f ./templates/eventstore.yaml
}

function createDisks {
    local count=$1
    for ((c=1; c<=$count; c++ ))
    do
        if ! gcloud compute disks list sku-eventstore-prod-disk-$c | grep sku-eventstore-prod-disk-$c; then
            echo "creating disk: sku-eventstore-prod-disk-$c" 
            gcloud compute disks create --size=80GB sku-eventstore-prod-disk-$c --zone europe-west2-a
        else
            echo "disk already exists: sku-eventstore-prod-disk-$c"
        fi
    done
}

function createEsCluster {
    local count=$1
    createSpecs $count
    createDeployments $count
    createEsService
}

init
validateInput $1 #sets the variable $count
createDisks $count
createEsCluster $count