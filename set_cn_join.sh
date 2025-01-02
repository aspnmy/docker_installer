#! /bin/bash
# 单独运行的国内镜像-自定义CF加速源配置

DAEMON_JSON="/etc/docker/daemon.json"
BACKUP_FILE="/etc/docker/daemon.json.aspnmy_bak"

# 国内源使用写入模式
function create_cn_daemon_json(){
    log "是否创建新的国内源配置文件 ${DAEMON_JSON}? (y/n，默认跳过)"
    read -p "请输入y或回车键安装，输入no跳过: " choice
    case "$choice" in
        y|Y|"")
            log "创建新的国内源配置文件 ${DAEMON_JSON}..."
            mkdir -p /etc/docker
            cat > /etc/docker/daemon.json << EOF
{"bip":"172.17.0.1/24","log-level":"warn","iptables":true,"api-cors-header":"*","hosts":["unix:///var/run/docker.sock"],"registry-mirrors":["https://drrpull.shdrr.org","https://docker.shdrr.org"]} 
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
  configure_accelerator
  
}
main


