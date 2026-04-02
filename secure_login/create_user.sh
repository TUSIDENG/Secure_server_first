#!/bin/bash

# 交互式用户创建脚本
# 功能：手动输入用户名，随机生成密码，提升sudo免密权限
# 支持传入用户名参数，如果传入则直接创建并退出

echo "========================================"
echo "用户创建与sudo权限配置脚本"
echo "========================================"

username=""

# 检查是否传入了用户名参数
if [ -n "$1" ]; then
    username="$1"
    echo "检测到参数，将直接创建用户: $username"
else
    # 提示用户输入用户名
    echo -n "请输入要创建的用户名: "
    read username
fi

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
useradd -m -s /bin/bash "$username"
if [ $? -ne 0 ]; then
    echo "错误：创建用户 $username 失败，请检查权限或用户名是否有效"
    exit 1
fi

echo "$username:$password" | chpasswd
if [ $? -ne 0 ]; then
    echo "错误：设置用户 $username 密码失败"
    exit 1
fi

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
if [ $? -ne 0 ]; then
    echo "错误：将用户 $username 添加到$SUDO_GROUP组失败"
    exit 1
fi

# 配置sudo免密权限
echo "正在配置sudo免密权限..."
echo "$username ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$username"
if [ $? -ne 0 ]; then
    echo "错误：创建sudo免密配置文件失败"
    exit 1
fi

chmod 0440 "/etc/sudoers.d/$username"
if [ $? -ne 0 ]; then
    echo "错误：设置sudo配置文件权限失败"
    exit 1
fi

# 显示结果
echo "========================================"
echo "用户创建成功！"
echo "用户名: $username"
echo "密码: $password"
echo "已配置sudo免密权限"
echo "========================================"
echo "请妥善保存密码，后续登录时使用"
echo "========================================"
