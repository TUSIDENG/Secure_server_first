#!/bin/bash

# 交互式用户删除脚本
# 功能：列出用户供选择删除，删除后可以继续或选择退出

echo "========================================"
echo "用户删除脚本"
echo "========================================"

# 获取所有除了root外可以登录的用户
get_users() {
    awk -F: '$1 != "root" && $7 !~ /(nologin|false)$/ {print $1}' /etc/passwd
}

while true; do
    # 获取用户列表
    users=($(get_users))
    
    # 检查是否有可删除的用户
    if [ ${#users[@]} -eq 0 ]; then
        echo "没有找到可删除的普通用户"
        exit 0
    fi
    
    # 显示用户列表
    echo "可删除的用户列表："
    for i in "${!users[@]}"; do
        echo "$((i+1)). ${users[$i]}"
    done
    
    # 提示用户选择
    echo -n "请选择要删除的用户编号（输入 'exit' 退出）: "
    read choice
    
    # 检查是否退出
    if [ "$choice" = "exit" ]; then
        echo "退出脚本..."
        exit 0
    fi
    
    # 检查输入是否为数字
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "错误：请输入有效的数字编号"
        continue
    fi
    
    # 检查编号是否在有效范围内
    if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#users[@]} ]; then
        echo "错误：请输入 1 到 ${#users[@]} 之间的数字"
        continue
    fi
    
    # 获取选择的用户名
    username=${users[$((choice-1))]}
    
    # 检查是否为root用户
    if [ "$username" = "root" ]; then
        echo "错误：不能删除root用户"
        continue
    fi
    
    # 删除用户及其主目录
    echo "正在删除用户 $username..."
    userdel -r "$username"
    
    # 检查删除是否成功
    if [ $? -ne 0 ]; then
        echo "错误：删除用户 $username 失败"
        exit 1
    fi
    
    echo "用户 $username 删除成功！"
    
    # 询问是否继续
    echo -n "是否继续删除其他用户？(y/n): "
    read choice
    
    # 转换为小写
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    
    # 检查用户选择
    if [ "$choice" != "y" ]; then
        echo "退出脚本..."
        exit 0
    fi
    
    echo ""
done
