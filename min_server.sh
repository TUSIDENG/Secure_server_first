#!/bin/bash

# 主面板脚本
# 功能：介绍并调用 secure_login 目录下的安全脚本

# 定义脚本路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SECURE_LOGIN_DIR="$SCRIPT_DIR/secure_login"

# 确保子脚本有执行权限
chmod +x "$SECURE_LOGIN_DIR"/*.sh
if [ $? -ne 0 ]; then
    echo "错误：无法为 secure_login 目录下的脚本设置执行权限。请检查权限。"
    exit 1
fi

# 主循环，用于显示菜单
while true; do
    # 清屏
    clear
    
    # 显示菜单
    echo "========================================"
    echo "      服务器安全管理面板"
    echo "========================================"
    echo "请选择要执行的操作："
    echo ""
    echo "1. 创建新用户 (create_user.sh)"
    echo "   - 交互式创建新用户，生成随机密码，并授予 sudo 免密权限。"
    echo ""
    echo "2. 删除用户 (delete_user.sh)"
    echo "   - 从列表中选择并删除一个现有用户及其主目录。"
    echo ""
    echo "3. 修改 Root 登录策略 (change_root_login.sh)"
    echo "   - 交互式设置 SSH 的 root 登录策略（允许密码/仅密钥/禁止登录）。"
    echo ""
    echo "4. 退出"
    echo "========================================"
    
    # 读取用户选择
    read -p "请输入选项 [1-4]: " choice
    
    # 根据选择执行操作
    case "$choice" in
        1)
            echo "正在调用 [创建新用户] 脚本..."
            sudo "$SECURE_LOGIN_DIR/create_user.sh"
            ;;
        2)
            echo "正在调用 [删除用户] 脚本..."
            sudo "$SECURE_LOGIN_DIR/delete_user.sh"
            ;;
        3)
            echo "正在调用 [修改 Root 登录策略] 脚本..."
            sudo "$SECURE_LOGIN_DIR/change_root_login.sh"
            ;;
        4)
            echo "退出面板。"
            exit 0
            ;;
        *)
            echo "无效的选项，请输入 1 到 4 之间的数字。"
            ;;
    esac
    
    # 等待用户按键后返回菜单
    echo ""
    read -p "按 Enter 键返回主菜单..."
done
