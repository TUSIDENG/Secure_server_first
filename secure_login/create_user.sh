#!/bin/bash

# 交互式用户创建脚本
# 功能：手动输入用户名，随机生成密码，提升sudo免密权限

echo "========================================"
echo "用户创建与sudo权限配置脚本"
echo "========================================"

# 提示用户输入用户名
echo -n "请输入要创建的用户名: "
read username

# 检查用户名是否为空
if [ -z "$username" ]; then
    echo "错误：用户名为空，请重新运行脚本并输入有效的用户名"
    exit 1
fi

# 检查用户是否已存在
if id "$username" &>/dev/null; then
    echo "错误：用户 $username 已存在，请使用其他用户名"
    exit 1
fi

# 生成随机密码（12位，包含大小写字母、数字和特殊字符）
password=$(openssl rand -base64 12)

# 创建用户并设置密码
echo "正在创建用户 $username..."
useradd -m "$username"
echo "$username:$password" | chpasswd

# 检测系统类型
if [ -f /etc/redhat-release ]; then
    # CentOS/RHEL系统
    SUDO_GROUP="wheel"
else
    # Ubuntu/Debian系统
    SUDO_GROUP="sudo"
fi

# 将用户添加到sudo组
echo "正在添加用户到$SUDO_GROUP组..."
usermod -aG "$SUDO_GROUP" "$username"

# 配置sudo免密权限
echo "正在配置sudo免密权限..."
echo "$username ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$username"
chmod 0440 "/etc/sudoers.d/$username"

# 显示结果
echo "========================================"
echo "用户创建成功！"
echo "用户名: $username"
echo "密码: $password"
echo "已配置sudo免密权限"
echo "========================================"
echo "请妥善保存密码，后续登录时使用"
echo "========================================"
