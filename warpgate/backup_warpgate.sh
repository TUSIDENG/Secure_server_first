#!/bin/bash

# Warpgate 备份脚本
# 功能：打包压缩并设置密码备份指定文件，使用 sqlite3 命令备份数据库

# 设置备份目录
WARPGATE_DIR="/home/wwdengd/warpgate"
BACKUP_DIR="$WARPGATE_DIR/backup"
# sqlite3 or copy
DB_BACKUP_METHOD="copy"

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：请使用 root 权限或 sudo 运行此脚本"
    exit 1
fi

# 创建备份目录（如果不存在）
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "错误：无法创建备份目录 $BACKUP_DIR"
    exit 1
fi

# 生成随机密码（16位）
PASSWORD=$(openssl rand -base64 16)

# 生成备份文件名
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/warpgate_backup_$TIMESTAMP.tar.gz"

# 备份 SQLite 数据库
DB_FILE="$WARPGATE_DIR/data/db/db.sqlite3"
DB_BACKUP_TEMP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sqlite3_db"

echo "正在备份数据库..."
if [ "$DB_BACKUP_METHOD" = "sqlite3" ]; then
    sqlite3 "$DB_FILE" ".backup '$DB_BACKUP_TEMP_FILE'"
    if [ $? -ne 0 ]; then
        echo "错误：数据库备份失败 (sqlite3 命令)"
        exit 1
    fi
elif [ "$DB_BACKUP_METHOD" = "copy" ]; then
    cp "$DB_FILE" "$DB_BACKUP_TEMP_FILE"
    if [ $? -ne 0 ]; then
        echo "错误：数据库备份失败 (直接复制文件)"
        exit 1
    fi
else
    echo "错误：无效的数据库备份方法: $DB_BACKUP_METHOD"
    exit 1
fi

echo "正在打包备份文件..."
# 打包压缩并设置密码
tar -czf - -C "$WARPGATE_DIR" \
    "data/recordings" \
    "data/ssh-keys" \
    "data/tls.certificate.pem" \
    "data/tls.key.pem" \
    "data/warpgate.yaml" \
    "backup/db_backup_$TIMESTAMP.sqlite3_db" \
    | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSWORD" -out "$BACKUP_FILE"

# 检查打包是否成功
if [ $? -ne 0 ]; then
    echo "错误：打包备份失败"
    # 清理临时文件
    rm -f "$DB_BACKUP_TEMP_FILE"
    exit 1
fi

# 清理临时数据库备份文件
rm -f "$DB_BACKUP_TEMP_FILE"

# 显示备份结果
echo "========================================"
echo "备份完成！"
echo "备份文件: $BACKUP_FILE"
echo "备份密码: $PASSWORD"
echo "========================================"
echo "请妥善保存备份密码，恢复时需要使用"
echo "========================================"
