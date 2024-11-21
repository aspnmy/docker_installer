#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
AGENT_PORT="9001"

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
    if [ "$(id -u)" -eq 0 ]; then
        log "当前用户是 root,不需要 sudo"
        return 0
    else
        if command_exists sudo; then
            log "当前用户不是 root,但已安装 sudo"
            return 1
        else
            log "请使用 root 或 sudo 权限运行此脚本"
            exit 1
        fi
    fi
}

# 生成随机数函数
random_container_name() {
    tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8
}

function install_firewall() {
    check_root_or_sudo
    if [ $? -eq 0 ]; then
        # 如果是 root 用户,直接安装
        if is_ubuntu_or_debian; then
            log "正在安装 ufw..."
            apt-get update && apt-get install -y ufw
        elif is_centos_or_rhel_or_fedora_or_rockey; then
            log "正在安装 firewalld..."
            yum install -y firewalld
        fi
    else
        # 如果有 sudo 权限,使用 sudo 安装
        if is_ubuntu_or_debian; then
            log "正在使用 sudo 安装 ufw..."
            sudo apt-get update && sudo apt-get install -y ufw
        elif is_centos_or_rhel_or_fedora_or_rockey; then
            log "正在使用 sudo 安装 firewalld..."
            sudo yum install -y firewalld
        fi
    fi
}

function install_node_portainer() {
    # 检查是否为 root 用户或者是否有 sudo 权限
    check_root_or_sudo

    # 设置 docker-compose 文件
    set_docker_compose_file

    local FILE_NAME
    FILE_NAME="$CURRENT_DIR/portainer-agent.yml"

    # 检查 docker-compose 文件是否存在
    if [ -f "$FILE_NAME" ]; then
        # 使用 docker-compose 启动 Portainer 代理
        if [ "$(id -u)" -eq 0 ]; then
            docker-compose -f "$FILE_NAME" up -d
        else
            sudo docker-compose -f "$FILE_NAME" up -d
        fi
        log "文件 $FILE_NAME 存在,正在启动 Portainer 代理,请等待1-5分钟"
    else
        log "文件 $FILE_NAME 不存在,无法启动 Portainer 代理"
        exit 1
    fi
}

set_docker_compose_file(){
    # 文件名
    FILE_NAME="$CURRENT_DIR/portainer-agent.yml"
    if [ -f "$FILE_NAME" ]; then
        log "警告:文件 $FILE_NAME 已存在,将被覆盖,"
    fi
    contaInerName=$(random_container_name)
    # 创建并写入内容到文件
    cat <<EOF > "$FILE_NAME"
name: portainer_agent
services:
    agent:
        ports:
            - 9001:9001
        container_name: portainer_agent_"$contaInerName"
        restart: always
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - /var/lib/docker/volumes:/var/lib/docker/volumes
            - /:/host
        image: portainer/agent:2.21.2
EOF

    log "文件 $FILE_NAME 创建成功,"
}


# 检查 firewalld 和 ufw 是否都存在.如果两个都存在,我们根据系统的发行版选择一个默认的防火墙.
# 例如,如果是 Ubuntu 或 Debian 系统,我们选择 ufw 作为默认防火墙；
# 对于其他系统,我们选择 firewalld 作为默认防火墙.然后,我们根据选择的默认防火墙配置规则来开放端口.
function Set_Firewall() {
    # 检查是否为 root 用户或者是否有 sudo 权限
    check_root_or_sudo

    # 优先使用的防火墙
    local default_firewall=""

    # 检查并选择默认防火墙
    if which firewall-cmd >/dev/null 2>&1 && which ufw >/dev/null 2>&1; then
        if is_ubuntu_or_debian; then
            default_firewall="ufw"
        else
            default_firewall="firewalld"
        fi
    elif which firewall-cmd >/dev/null 2>&1; then
        default_firewall="firewalld"
    elif which ufw >/dev/null 2>&1; then
        default_firewall="ufw"
    else
        log "没有检测到支持的防火墙,端口开放已跳过"
        return
    fi

    # 根据默认防火墙配置规则
    if [ "$default_firewall" = "firewalld" ]; then
        if ! systemctl status firewalld | grep -q "Active: active" >/dev/null 2>&1; then
            log "启动 firewalld 并设置为开机启动"
            systemctl start firewalld
            systemctl enable firewalld
        fi
        log "防火墙开放 ${AGENT_PORT} 端口"
        firewall-cmd --zone=public --add-port="${AGENT_PORT}"/tcp --permanent
        firewall-cmd --reload
    elif [ "$default_firewall" = "ufw" ]; then
        if ! systemctl status ufw | grep -q "Active: active" >/dev/null 2>&1; then
            log "启动 ufw 并设置为开机启动"
            systemctl start ufw
            systemctl enable ufw
        fi
        log "防火墙开放 ${AGENT_PORT} 端口"
        ufw allow "${AGENT_PORT}"/tcp
        ufw reload
    fi
}

function is_ubuntu_or_debian() {
    grep -qs "ubuntu" /etc/issue || grep -qs "debian" /etc/issue
}

function is_centos_or_rhel_or_fedora_or_rockey() {
    grep -qs "centos" /etc/issue || grep -qs "rhel" /etc/issue || grep -qs "fedora" /etc/issue || grep -qs "rocky" /etc/issue
}

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function main(){
    install_node_portainer
    Set_Firewall
}
main