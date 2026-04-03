#!/bin/bash

# 自签名 SSL 证书生成脚本
# 功能：生成自签名 SSL 证书和私钥

# 设置默认输出目录
OUTPUT_DIR="/etc/ssl/self_signed"
DAYS_VALID=365
KEY_SIZE=2048

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：请使用 root 权限或 sudo 运行此脚本"
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo "错误：无法创建输出目录 $OUTPUT_DIR"
    exit 1
fi

# 获取域名参数或使用交互式输入
if [ -n "$1" ]; then
    DOMAIN="$1"
    echo "使用传入的域名: $DOMAIN"
else
    # 提示用户输入域名
    echo -n "请输入域名 (例如: example.com): "
    read DOMAIN
fi

# 检查域名是否为空
if [ -z "$DOMAIN" ]; then
    echo "错误：域名不能为空"
    exit 1
fi

# 设置文件名
KEY_FILE="$OUTPUT_DIR/${DOMAIN}.key"
CERT_FILE="$OUTPUT_DIR/${DOMAIN}.crt"

# 检查文件是否已存在
if [ -f "$KEY_FILE" ] || [ -f "$CERT_FILE" ]; then
    echo "警告：以下文件已存在："
    [ -f "$KEY_FILE" ] && echo "  - $KEY_FILE"
    [ -f "$CERT_FILE" ] && echo "  - $CERT_FILE"
    echo -n "是否覆盖？(y/n): "
    read overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
fi

echo "========================================"
echo "正在生成自签名 SSL 证书..."
echo "域名: $DOMAIN"
echo "有效期: $DAYS_VALID 天"
echo "密钥大小: $KEY_SIZE 位"
echo "========================================"

# 生成私钥和证书
openssl req -x509 -nodes -days $DAYS_VALID -newkey rsa:$KEY_SIZE \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"

# 检查生成是否成功
if [ $? -ne 0 ]; then
    echo "错误：证书生成失败"
    exit 1
fi

# 设置文件权限
chmod 600 "$KEY_FILE"
if [ $? -ne 0 ]; then
    echo "错误：无法设置私钥文件权限"
    exit 1
fi

chmod 644 "$CERT_FILE"
if [ $? -ne 0 ]; then
    echo "错误：无法设置证书文件权限"
    exit 1
fi

echo "========================================"
echo "证书生成成功！"
echo "私钥文件: $KEY_FILE"
echo "证书文件: $CERT_FILE"
echo "========================================"
echo ""
echo "使用说明："
echo "1. 在 Nginx/Apache 配置中引用上述文件路径"
echo "2. 客户端需要导入证书文件以信任此自签名证书"
echo "3. 证书有效期为 $DAYS_VALID 天，到期后需要重新生成"
echo "========================================"
