#!/bin/bash

# root登录配置脚本
# 功能：交互式选择root登录方式，完全匹配PermitRootLogin开头的配置进行修改

echo "========================================"
echo "root登录配置脚本"
echo "========================================"

# 显示菜单
echo "请选择root登录方式："
echo "1. 允许root登录（密码方式）"
echo "2. 只允许root密钥登录"
echo "3. 禁止root登录"
echo -n "请输入选项（1-3）: "
read choice

# 根据选择设置配置值
case $choice in
    1)
        config_value="yes"
        echo "您选择了：允许root登录（密码方式）"
        ;;
    2)
        config_value="without-password"
        echo "您选择了：只允许root密钥登录"
        ;;
    3)
        config_value="no"
        echo "您选择了：禁止root登录"
        ;;
    *)
        echo "错误：无效的选项"
        exit 1
        ;;
esac

# 备份原始SSH配置文件
BACKUP_FILE="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
echo "正在备份SSH配置文件到 $BACKUP_FILE..."
cp /etc/ssh/sshd_config "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    echo "错误：备份SSH配置文件失败"
    exit 1
fi

# 修改SSH配置
echo "正在修改SSH配置..."
# 完全匹配PermitRootLogin开头的配置，替换为新的值
sed -i "s/^PermitRootLogin.*/PermitRootLogin $config_value/" /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
    echo "错误：修改SSH配置失败"
    exit 1
fi

# 如果没有PermitRootLogin配置，则添加
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin $config_value" >> /etc/ssh/sshd_config
    if [ $? -ne 0 ]; then
        echo "错误：添加SSH配置失败"
        exit 1
    fi
fi

# 重启SSH服务
echo "正在重启SSH服务..."
if [ -f /etc/redhat-release ]; then
    # CentOS/RHEL系统
    systemctl restart sshd
    if [ $? -ne 0 ]; then
        echo "错误：重启SSH服务失败"
        exit 1
    fi
else
    # Ubuntu/Debian系统
    systemctl restart ssh
    if [ $? -ne 0 ]; then
        echo "错误：重启SSH服务失败"
        exit 1
    fi
fi

# 验证配置
echo "正在验证配置..."
grep "^PermitRootLogin" /etc/ssh/sshd_config

echo "========================================"
echo "root登录配置完成！"
echo "已备份原始配置到: $BACKUP_FILE"
case $choice in
    1)
        echo "现在root用户可以通过密码方式登录"
        ;;
    2)
        echo "现在root用户只能通过密钥方式登录"
        ;;
    3)
        echo "现在root用户将无法直接通过SSH登录"
        echo "请使用普通用户登录后，通过sudo命令执行管理员操作"
        ;;
esac
echo "========================================"
