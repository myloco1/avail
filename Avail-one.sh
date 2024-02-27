#!/bin/bash

# 函数：检查命令是否存在
exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装依赖项（如果不存在）
install_dependency() {
  exists "$1" || sudo apt update && sudo apt install "$1" -y < "/dev/null"
}

# 安装必要的依赖项
install_dependency curl
install_dependency make
install_dependency clang
install_dependency pkg-config
install_dependency libssl-dev
install_dependency build-essential

# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/avail-light"
RELEASE_URL="https://github.com/availproject/avail-light/releases/download/v1.7.9/avail-light-linux-amd64.tar.gz"

# 创建安装目录并进入
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# 下载并解压发布包
wget "$RELEASE_URL"
tar -xvzf avail-light-linux-amd64.tar.gz
cp avail-light-linux-amd64 avail-light

# 创建identity.toml文件
read -p "请输入您的12位钱包助记词：" SECRET_SEED_PHRASE
cat > identity.toml <<EOF
avail_secret_seed_phrase = "$SECRET_SEED_PHRASE"
EOF

# 配置 systemd 服务文件
tee /etc/systemd/system/availd.service > /dev/null << EOF
[Unit]
Description=Avail Light Client
After=network.target
StartLimitIntervalSec=0
[Service]
User=root
ExecStart=/root/avail-light/avail-light --network goldberg --identity /root/avail-light/identity.toml
Restart=always
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable availd
sudo systemctl start availd.service

# 完成安装提示
echo '====================================== 安装完成 ========================================='
echo -e "\e[1;32m 检查状态: \e[0m\e[1;36m${CYAN} systemctl status availd.service ${NC}\e[0m"
echo -e "\e[1;32m 检查日志  : \e[0m\e[1;36m${CYAN} journalctl -f -u availd ${NC}\e[0m"
echo -e "\e[1;32m 检查Avail运行钱包地址  : \e[0m\e[1;36m${CYAN} journalctl -u availd | grep address ${NC}\e[0m"
