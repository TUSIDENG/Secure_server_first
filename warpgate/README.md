# Warpgate脚本使用说明

## 备份
```bash
sudo bash ./backup_warpgate.sh
```
备份后，还原：
* 先创建还原目录
```bash
mkdir -p /tmp/restore
```
* 解密并解压缩备份文件
```bash
# 替换为你的备份文件路径和密码
openssl enc -aes-256-cbc -salt -pbkdf2 -d -pass pass:你的密码 -in backup/warpgate_backup_20260407_172249.tar.gz | tar -xzf - -C /tmp/restore
```
