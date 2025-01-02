# docker_installer
- 快速安装docker与docker-compose脚本，方便快速在服务器中部署
- 国内源的业务，使用 快速安装docker及组件脚本以后，如果错误提示了国内源，可以先运行独立更新国内镜像源脚本，再重新运行快速加入portainer节点的脚本
- 如果不使用portainer来管理docker可以不运行此脚本

# 独立更新国内镜像源

```
curl -sSL https://raw.githubusercontent.com/aspnmy/docker_installer/refs/heads/master/set_cn_join.sh -o set_cn_join.sh  && bash set_cn_join.sh
```

# 快速安装命令-docker及docker-compose

```
curl -sSL https://raw.githubusercontent.com/aspnmy/docker_installer/refs/heads/master/quick_install_docker.sh -o quick_install_docker.sh  && bash quick_install_docker.sh
```
# 快速安装命令-快速加入portainer节点
```
curl -sSL https://raw.githubusercontent.com/aspnmy/docker_installer/refs/heads/master/join_node_portainer.sh -o join_node.sh  && bash join_node.sh
```

```
main(){

    get_SSL
    restart_web
    log "自动化脚本执行完毕。"
}


main
```
