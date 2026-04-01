#!/bin/bash

# 禁止root登录脚本
# 功能：修改SSH配置，禁止root用户直接登录

echo "========================================"
echo "禁止root登录配置脚本"
echo "========================================"

# 备份原始SSH配置文件
BACKUP_FILE="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
echo "正在备份SSH配置文件到 $BACKUP_FILE..."
cp /etc/ssh/sshd_config "$BACKUP_FILE"

# 修改SSH配置，禁止root登录
echo "正在修改SSH配置，禁止root登录..."
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# 确保PermitRootLogin配置存在
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

# 重启SSH服务
echo "正在重启SSH服务..."
if [ -f /etc/redhat-release ]; then
    # CentOS/RHEL系统
    systemctl restart sshd
else
    # Ubuntu/Debian系统
    systemctl restart ssh
fi

# 验证配置
echo "正在验证配置..."
grep "PermitRootLogin" /etc/ssh/sshd_config

echo "========================================"
echo "禁止root登录配置完成！"
echo "已备份原始配置到: $BACKUP_FILE"
echo "现在root用户将无法直接通过SSH登录"
echo "请使用普通用户登录后，通过sudo命令执行管理员操作"
echo "========================================"
