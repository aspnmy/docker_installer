#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CURRENT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

function install_node_portainer($AGENT_PORT) {
    docker run -d \
  -p $AGENT_PORT:$AGENT_PORT \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.21.2
}

function Set_Firewall($AGENT_PORT){
    if which firewall-cmd >/dev/null 2>&1; then
        if systemctl status firewalld | grep -q "Active: active" >/dev/null 2>&1;then
            log "防火墙开放 $AGENT_PORT 端口"
            firewall-cmd --zone=public --add-port="$AGENT_PORT"/tcp --permanent
            firewall-cmd --reload
        else
            log "防火墙未开启，忽略端口开放"
        fi
    fi

    if which ufw >/dev/null 2>&1; then
        if systemctl status ufw | grep -q "Active: active" >/dev/null 2>&1;then
            log "防火墙开放 $AGENT_PORT 端口"
            ufw allow "$AGENT_PORT"/tcp
            ufw reload
        else
            log "防火墙未开启，忽略端口开放"
        fi
    fi
}


function main(){
  install_node_portainer("9001")
}
main