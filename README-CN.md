# Secure Server First.
服务器初始化安全脚本。

[English Version](README.md)

# 目录
- [Features](#features)
  - [min_server.sh](#min_server.sh)
  - [secure_login](#secure_login)
  - [warpgate](#warpgate)

# Features
## min_server.sh
所有脚本的入口，可以交互时调用增加用户，删除用户的脚本。

## secure_login
安全登录相关脚本，用于防护暴力破解。
* [secure_login\change_root_login.sh](secure_login/change_root_login.sh) 改变 root 登录方式（禁止直接登录、关闭密码登录、允许密钥登录）

* [secure_login\create_user.sh](secure_login/create_user.sh) 创建普通用户（配置 sudo 权限/免密 sudo）

* [secure_login\delete_user.sh](secure_login/delete_user.sh) 删除非root用户

## warpgate
warpgate 管理维护脚本。
* [warpgate\backup_warpgate.sh](warpgate/backup_warpgate.sh) 备份 warpgate 数据库

