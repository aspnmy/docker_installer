#! /bin/bash
# 单独运行的国内镜像-自定义CF加速源配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
DAEMON_JSON="/etc/docker/daemon.json"
BACKUP_FILE="/etc/docker/daemon.json.aspnmy_bak"

log "======================= 开始安装 ======================="

function Check_Root() {
    if [[ $EUID -ne 0 ]]; then
        log "请使用 root 或 sudo 权限运行此脚本"
        exit 1
    fi
}

# 国内源使用写入模式
function create_cn_daemon_json(){
    log "是否创建新的国内源配置文件 ${DAEMON_JSON}? (y/n，默认跳过)"
    read -p "请输入y或回车键安装，输入no跳过: " choice
    case "$choice" in
        y|Y|"")
            log "创建新的国内源配置文件 ${DAEMON_JSON}..."
            mkdir -p /etc/docker
            cat > /etc/docker/daemon.json << EOF
{"bip":"172.17.0.1/24","log-level":"warn","iptables":true,"api-cors-header":"*","registry-mirrors":["https://drrpull.shdrr.org","https://docker.shdrr.org","https://docker.1panelproxy.com"]} 
EOF
            ;;
        no|NO|n|N)
            log "跳过创建国内源配置文件。"
            ;;
        *)
            log "无效输入，跳过创建国内源配置文件。"
            ;;
    esac
	
}




function configure_accelerator() {
    read -p "是否配置镜像加速?(y/n): " configure_accelerator
    if [[ "$configure_accelerator" == "y" ]]; then
        if [ -f "$DAEMON_JSON" ]; then
            log "配置文件已存在,我们将备份现有配置文件为 ${BACKUP_FILE} 并创建新的配置文件。"
            cp "$DAEMON_JSON" "$BACKUP_FILE"
            create_cn_daemon_json
        else
            create_cn_daemon_json
        fi

        log "正在重启 Docker 服务..."
        systemctl daemon-reload
        systemctl restart docker
        log "Docker 服务已成功重启。"
    else
        log "未配置镜像加速。"
    fi
}

main(){
  Check_Root
  configure_accelerator
  
}
main


