#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
AGENT_PORT="9001 22 662"

CURRENT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

function log() {
    message="[Aspnmy Log]: $1 "
    case "$1" in
        *"失败"*|*"错误"*|*"请使用 root 或 sudo 权限运行此脚本"*)
            echo -e "${RED}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *"成功"*)
            echo -e "${GREEN}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *"忽略"*|*"跳过"*)
            echo -e "${YELLOW}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *)
            echo -e "${BLUE}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
    esac
}

function check_root_or_sudo() {
    if [ "$(id -u)" -ne 0 ] && ! command_exists sudo; then
        log "请使用 root 或 sudo 权限运行此脚本"
        exit 1
    fi
}

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function is_ubuntu_or_debian() {
    . /etc/os-release && [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]
}

function is_centos_or_rhel_or_fedora_or_rockey() {
    . /etc/os-release && [[ "$ID" == "centos" || "$ID_LIKE" == *"centos"* || "$ID" == "rhel" || "$ID_LIKE" == *"rhel"* || "$ID" == "fedora" || "$ID_LIKE" == *"fedora"* || "$ID" == "rocky" || "$ID_LIKE" == *"rocky"* ]]
}

function install_package() {
    local package=$1
    if is_ubuntu_or_debian; then
        apt-get update && apt-get install -y "$package"
    elif is_centos_or_rhel_or_fedora_or_rockey; then
        yum install -y "$package"
    else
        log "您的操作系统不受支持，无法自动安装 $package"
        exit 1
    fi
}

function random_container_name() {
    tr -dc 'a-z0-9' </dev/urandom | head -c 8
}

function set_docker_compose_file() {
    local FILE_NAME="$CURRENT_DIR/portainer-agent.yml"
    if [ -f "$FILE_NAME" ]; then
        log "警告:文件 $FILE_NAME 已存在,将被覆盖"
    fi
    local contaInerName=$(random_container_name)
    cat <<EOF > "$FILE_NAME"
name: portainer_agent
services:
    agent:
        ports:
            - 9001:9001
        container_name: portainer_agent_$contaInerName
        restart: always
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - /var/lib/docker/volumes:/var/lib/docker/volumes
            - /:/host
        image: portainer/agent:2.21.2
EOF
    log "文件 $FILE_NAME 创建成功"
}

function install_node_portainer() {
    check_root_or_sudo
    set_docker_compose_file
    local FILE_NAME="$CURRENT_DIR/portainer-agent.yml"
    if [ -f "$FILE_NAME" ]; then
        if command_exists docker-compose; then
            if [ "$(id -u)" -eq 0 ]; then
                docker-compose -f "$FILE_NAME" up -d
            else
                sudo docker-compose -f "$FILE_NAME" up -d
            fi
            log "文件 $FILE_NAME 存在,正在启动 Portainer 代理,请等待1-5分钟"
        else
            log "Docker Compose 未安装,无法启动 Portainer 代理"
            exit 1
        fi
    else
        log "文件 $FILE_NAME 不存在,无法启动 Portainer 代理"
        exit 1
    fi
}

function Set_Firewall() {
    check_root_or_sudo

    # 确定默认防火墙
    local default_firewall=""
    if which firewall-cmd >/dev/null 2>&1; then
        default_firewall="firewalld"
    elif which ufw >/dev/null 2>&1; then
        default_firewall="ufw"
    else
        log "没有检测到支持的防火墙，尝试安装"
        if is_ubuntu_or_debian; then
            install_package "ufw"
            default_firewall="ufw"
        elif is_centos_or_rhel_or_fedora_or_rockey; then
            install_package "firewalld"
            default_firewall="firewalld"
        else
            log "您的操作系统不受支持，无法自动安装防火墙"
            return
        fi
    fi

    # 根据默认防火墙配置规则
    if [ "$default_firewall" = "firewalld" ]; then
        configure_firewalld
    elif [ "$default_firewall" = "ufw" ]; then
        configure_ufw
    fi
}

function configure_firewalld() {
    if ! systemctl status firewalld | grep -q "Active: active" >/dev/null 2>&1; then
        log "启动 firewalld 并设置为开机启动"
        systemctl start firewalld
        systemctl enable firewalld
    fi
    log "防火墙开放 ${AGENT_PORT} 端口"
    firewall-cmd --zone=public --add-port="${AGENT_PORT}"/tcp --permanent
    firewall-cmd --reload
}

function configure_ufw() {
    if ! systemctl status ufw | grep -q "Active: active" >/dev/null 2>&1; then
        log "启动 ufw 并设置为开机启动"
        systemctl start ufw
        systemctl enable ufw
    fi
    log "防火墙开放 ${AGENT_PORT} 端口"
    ufw allow "${AGENT_PORT}"/tcp
    ufw reload
}

function main(){
    install_node_portainer
    Set_Firewall
}
main