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

    environment=$2
    if [ -z "$environment" ]
    then
        echo "error: Not a correct value for environment" >&2; exit 1
    fi
}

function createDeploymentSpecs {
    local count=$1
    local environment=$2
    if [ "$2" == "prod" ]
    then
        for ((c=1; c<=$count; c++ ))
        do
            cat ./templates/es_deployment_template_with_storage.yaml | sed -e "s/\${nodenumber}/$c/" | sed -e "s/\${nodecount}/$count/" | sed -e "s/\${environment}/"$2"/" > .tmp/es_deployment_$c.yaml
        done
    else
        for ((c=1; c<=$count; c++ ))
        do
            cat ./templates/es_deployment_template_no_storage.yaml | sed -e "s/\${nodenumber}/$c/" | sed -e "s/\${nodecount}/$count/" | sed -e "s/\${environment}/"$2"/" > .tmp/es_deployment_$c.yaml
        done
    fi
}

function createEsServiceSpec {
    cat ./templates/es_service_template.yaml | sed -e "s/\${environment}/"$1"/" > .tmp/es_service.yaml
}

function createDeployments {
    local count=$1
    for ((c=1; c<=$count; c++ ))
    do
        kubectl apply -f .tmp/es_deployment_$c.yaml
    done
}

function createEsService {
    kubectl apply -f .tmp/es_service.yaml
}

function createDisks {
    local count=$1
    if [ "$2" == "prod" ]
    then
        for ((c=1; c<=$count; c++ ))
        do
            if ! gcloud compute disks list sku-eventstore-$2-disk-$c | grep sku-eventstore-$2-disk-$c; then
                echo "creating disk: sku-eventstore-$2-disk-$c" 
                gcloud compute disks create --size=80GB sku-eventstore-$2-disk-$c --zone europe-west2-a
            else
                echo "disk already exists: sku-eventstore-$2-disk-$c"
            fi
        done
    fi
}

function createEsCluster {
    createDeploymentSpecs $1 $2
    createDeployments $1 $2
    createEsServiceSpec $2
    createEsService $1 $2
}

init
validateInput $1 $2
createDisks $1 $2
createEsCluster $count $2