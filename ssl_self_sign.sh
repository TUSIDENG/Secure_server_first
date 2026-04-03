#!/bin/bash

# 自签名 SSL 证书生成脚本
# 功能：生成自签名 SSL 证书和私钥

# 设置默认输出目录
OUTPUT_DIR="/etc/ssl/self_signed"
DAYS_VALID=365
KEY_SIZE=2048
GENERATE_CA=false
CA_PATH=""

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

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项] [域名]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  --ca             使用根证书签名模式（默认：自签名）"
    echo "  --ca-path PATH   指定根证书存储路径（默认：$OUTPUT_DIR）"
    echo ""
    echo "示例:"
    echo "  $0 example.com                    # 生成自签名证书"
    echo "  $0 --ca example.com               # 生成根证书并使用它签名"
    echo "  $0 --ca --ca-path /path/to/ca example.com  # 指定根证书路径"
    echo ""
    echo "说明:"
    echo "  - 如果不指定域名，脚本会交互式提示输入"
    echo "  - 使用 --ca 模式时，如果指定路径已存在根证书，会直接复用"
    echo "  - 生成的证书默认保存在 $OUTPUT_DIR 目录"
    exit 0
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --ca)
            GENERATE_CA=true
            shift
            ;;
        --ca-path)
            CA_PATH="$2"
            shift 2
            ;;
        *)
            DOMAIN="$1"
            shift
            ;;
    esac
done

# 如果没有通过参数传入域名，则交互式输入
if [ -z "$DOMAIN" ]; then
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
echo "正在生成 SSL 证书..."
echo "域名: $DOMAIN"
echo "有效期: $DAYS_VALID 天"
echo "密钥大小: $KEY_SIZE 位"
if [ "$GENERATE_CA" = true ]; then
    echo "模式: 使用根证书签名"
else
    echo "模式: 自签名证书"
fi
echo "========================================"

if [ "$GENERATE_CA" = true ]; then
    # 确定根证书路径
    if [ -n "$CA_PATH" ]; then
        # 使用指定的根证书路径
        CA_KEY_FILE="$CA_PATH/ca.key"
        CA_CERT_FILE="$CA_PATH/ca.crt"
    else
        # 使用默认路径
        CA_KEY_FILE="$OUTPUT_DIR/ca.key"
        CA_CERT_FILE="$OUTPUT_DIR/ca.crt"
    fi
    
    # 检查根证书是否已存在
    if [ -f "$CA_KEY_FILE" ] && [ -f "$CA_CERT_FILE" ]; then
        echo "检测到现有根证书，将直接使用："
        echo "  根证书私钥: $CA_KEY_FILE"
        echo "  根证书文件: $CA_CERT_FILE"
    else
        echo "正在生成根证书..."
        
        # 确保根证书目录存在
        CA_DIR=$(dirname "$CA_KEY_FILE")
        if [ ! -d "$CA_DIR" ]; then
            mkdir -p "$CA_DIR"
            if [ $? -ne 0 ]; then
                echo "错误：无法创建根证书目录 $CA_DIR"
                exit 1
            fi
        fi
        
        openssl genrsa -out "$CA_KEY_FILE" $KEY_SIZE
        if [ $? -ne 0 ]; then
            echo "错误：生成根证书私钥失败"
            exit 1
        fi
        
        openssl req -x509 -new -nodes -key "$CA_KEY_FILE" -sha256 -days $DAYS_VALID \
            -out "$CA_CERT_FILE" \
            -subj "/C=CN/ST=State/L=City/O=Organization/CN=My CA"
        if [ $? -ne 0 ]; then
            echo "错误：生成根证书失败"
            exit 1
        fi
        
        # 设置根证书权限
        chmod 600 "$CA_KEY_FILE"
        chmod 644 "$CA_CERT_FILE"
        
        echo "根证书生成成功："
        echo "  根证书私钥: $CA_KEY_FILE"
        echo "  根证书文件: $CA_CERT_FILE"
    fi
    
    # 生成域名私钥和证书签名请求
    openssl genrsa -out "$KEY_FILE" $KEY_SIZE
    if [ $? -ne 0 ]; then
        echo "错误：生成域名私钥失败"
        exit 1
    fi
    
    CSR_FILE="$OUTPUT_DIR/${DOMAIN}.csr"
    openssl req -new -key "$KEY_FILE" \
        -out "$CSR_FILE" \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"
    if [ $? -ne 0 ]; then
        echo "错误：生成证书签名请求失败"
        exit 1
    fi
    
    # 使用根证书签名
    openssl x509 -req -in "$CSR_FILE" -CA "$CA_CERT_FILE" -CAkey "$CA_KEY_FILE" \
        -CAcreateserial -out "$CERT_FILE" -days $DAYS_VALID -sha256
    if [ $? -ne 0 ]; then
        echo "错误：使用根证书签名失败"
        exit 1
    fi
    
    # 删除CSR文件
    rm -f "$CSR_FILE"
else
    # 生成自签名证书
    openssl req -x509 -nodes -days $DAYS_VALID -newkey rsa:$KEY_SIZE \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"
fi

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
echo "域名证书私钥: $KEY_FILE"
echo "域名证书文件: $CERT_FILE"
if [ "$GENERATE_CA" = true ]; then
    echo ""
    echo "根证书信息："
    echo "根证书私钥: $CA_KEY_FILE"
    echo "根证书文件: $CA_CERT_FILE"
fi
echo "========================================"
echo ""
echo "使用说明："
echo "1. 在 Nginx/Apache 配置中引用域名证书文件路径"
if [ "$GENERATE_CA" = true ]; then
    echo "2. 客户端只需导入根证书即可信任所有由此根证书签名的证书"
    echo "   根证书路径: $CA_CERT_FILE"
    echo "3. 可以将根证书分发到客户端设备上进行安装"
else
    echo "2. 客户端需要导入证书文件以信任此自签名证书"
fi
echo "3. 证书有效期为 $DAYS_VALID 天，到期后需要重新生成"
echo "========================================"
