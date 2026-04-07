# Secure Server First
Server initialization security scripts.

[中文版本 (Chinese Version)](README-CN.md)

# Table of Contents
- [Features](#features)
  - [min_server.sh](#min_server.sh)
  - [secure_login](#secure_login)
  - [warpgate](#warpgate)

# Features
## min_server.sh
The entry point for all scripts, which can interactively call scripts to add users and delete users.

## secure_login
Scripts related to secure login, used to protect against brute force attacks.
* [secure_login\change_root_login.sh](secure_login/change_root_login.sh) Change root login method (disable direct login, disable password login, allow key login)

* [secure_login\create_user.sh](secure_login/create_user.sh) Create normal users (configure sudo permissions/passwordless sudo)

* [secure_login\delete_user.sh](secure_login/delete_user.sh) Delete non-root users

## warpgate
Warpgate management and maintenance scripts.
* [warpgate\backup_warpgate.sh](warpgate/backup_warpgate.sh) Backup warpgate database