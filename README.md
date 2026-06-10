# VPS 维护一键脚本

一个面向 Linux VPS 的交互式系统管理脚本，提供常用运维操作的一键式菜单界面，无需记忆复杂命令。

## 功能一览

| 序号 | 功能 | 说明 |
|------|------|------|
| 1 | 系统更新 | 自动检测包管理器（APT/DNF/YUM/Pacman/APK）并执行更新 |
| 2 | 系统清理 | 清理包缓存 + 删除旧日志和过期临时文件 |
| 3 | 端口管理 | 查看/开放/关闭端口，支持 firewalld、ufw、iptables |
| 4 | 账户管理 | 改用户名/密码、添加/删除用户、Root 账户管理、修改主机名 |
| 5 | 查看已安装软件 | 列出已安装包及版本（最多显示前 50 个） |
| 6 | 查看运行中的服务 | 列出当前运行的服务（systemd / SysVinit） |

## 支持的系统

- Debian / Ubuntu（APT）
- CentOS / RHEL / Fedora（DNF / YUM）
- Arch Linux（Pacman）
- Alpine（APK）

## 快速使用

```bash
# 下载并运行（需要 root 权限）
curl -O https://raw.githubusercontent.com/lqz8802/VPS-/main/cc.sh
chmod +x cc.sh
sudo ./cc.sh
```

或直接克隆仓库：

```bash
git clone https://github.com/lqz8802/VPS-.git
cd VPS-
sudo ./cc.sh
```

## 安全特性

- 🔒 必须以 root 运行，否则自动退出
- 🚫 关闭端口时禁止关闭 SSH 22 端口，防止断连
- 🚫 禁止删除 root 用户
- ✅ 所有危险操作（删除用户、修改密码）均有二次确认
- ↩️ 任何输入步骤输入 `q` 可随时返回上级菜单

## 交互设计

- 彩色终端输出，操作状态一目了然
- 多级菜单结构，端口管理和账户管理各有子菜单
- 输入 `q` 可在任何步骤返回上级，避免误操作

## 许可证

MIT License