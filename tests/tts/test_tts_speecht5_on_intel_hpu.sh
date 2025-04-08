#!/bin/bash
# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -x

WORKPATH=$(dirname "$PWD")
ip_address=$(hostname -I | awk '{print $1}')
export TAG=comps
export SPEECHT5_PORT=11802
export TTS_PORT=11803

function build_docker_images() {
    cd $WORKPATH
    echo $(pwd)
    docker build --no-cache --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy -t opea/speecht5-gaudi:$TAG -f comps/third_parties/speecht5/src/Dockerfile.intel_hpu .
    if [ $? -ne 0 ]; then
        echo "opea/speecht5-gaudi built fail"
        exit 1
    else
        echo "opea/speecht5-gaudi built successful"
    fi
    docker build --no-cache --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy -t opea/tts:$TAG -f comps/tts/src/Dockerfile .
    if [ $? -ne 0 ]; then
        echo "opea/tts built fail"
        exit 1
    else
        echo "opea/tts built successful"
    fi
}

function start_service() {
    unset http_proxy
    export TTS_ENDPOINT=http://$ip_address:$SPEECHT5_PORT

    export TTS_COMPONENT_NAME=OPEA_SPEECHT5_TTS

    docker compose -f comps/tts/deployment/docker_compose/compose.yaml up speecht5-gaudi-service tts-speecht5-gaudi -d
    sleep 15
}

function validate_microservice() {
    http_proxy="" curl localhost:$TTS_PORT/v1/audio/speech -XPOST -d '{"input":"Hello, who are you?"}' -H 'Content-Type: application/json' --output speech.mp3

    if [[ $(file speech.mp3) == *"RIFF"* ]]; then
        echo "Result correct."
    else
        echo "Result wrong."
        docker logs speecht5-gaudi-service
        docker logs tts-speecht5-gaudi-service
        exit 1
    fi

}

function stop_docker() {
    docker ps -a --filter "name=speecht5-gaudi-service" --filter "name=tts-speecht5-gaudi-service" --format "{{.Names}}" | xargs -r docker stop
}

function main() {

    stop_docker

    build_docker_images
    start_service

    validate_microservice

    stop_docker
    echo y | docker system prune

}

main
