#!/bin/bash
# cc.sh - 简易系统管理脚本

gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'

# 自动赋予执行权限（解决上传后权限丢失问题）
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
chmod +x "$SCRIPT_PATH" 2>/dev/null

# 检测并切换到 root 用户
if [ "$EUID" -ne 0 ]; then
    TMPFILE=$(mktemp /tmp/cc.XXXXXX)
    curl -sL https://raw.githubusercontent.com/lqz8802/VPS-Maintenance-Script/main/cc.sh -o "$TMPFILE"
    chmod +x "$TMPFILE"
    exec sudo -p '' bash --norc --noprofile -i "$TMPFILE"
fi
back_menu() {
    echo ""
    echo -e "${gl_huang}输入 q 返回上级，回车继续...${gl_bai}"
    read -p "" any
    if [ "$any" = "q" ]; then
        return 1
    fi
    return 0
}

# 通用输入处理（支持 q 返回）
read_input() {
    local var_name="$1"
    local prompt="$2"
    local input
    read -p "$prompt" input
    if [ "$input" = "q" ]; then
        return 1
    fi
    eval "$var_name=\"$input\""
    return 0
}

# 通用确认函数
confirm() {
    local prompt="$1"
    local choice
    read -p "$(echo -e "${gl_huang}${prompt} (Y/N): ${gl_bai}")" choice
    case "$choice" in
        q) return 2 ;;  # q 返回
        [Yy]) return 0 ;;
        *)    return 1 ;;
    esac
}

# ------------------------------
# 1. 系统更新
# ------------------------------
do_update() {
    clear
    echo -e "${gl_lv}>> 系统更新${gl_bai}"
    echo "------------------------"

    if command -v apt-get >/dev/null 2>&1; then
        echo "检测到 APT 系统（Debian/Ubuntu）"
        echo "更新软件包列表..."
        apt-get update -qq
        echo "升级所有可更新软件包..."
        apt-get upgrade -y -qq 2>&1 | tail -5
        echo -e "${gl_lv}系统更新完成${gl_bai}"

    elif command -v dnf >/dev/null 2>&1; then
        echo "检测到 DNF 系统（CentOS/RHEL/Fedora）"
        dnf check-update -q
        dnf upgrade -y -q
        echo -e "${gl_lv}系统更新完成${gl_bai}"

    elif command -v yum >/dev/null 2>&1; then
        echo "检测到 YUM 系统（CentOS/RHEL）"
        yum update -y -q
        echo -e "${gl_lv}系统更新完成${gl_bai}"

    elif command -v pacman >/dev/null 2>&1; then
        echo "检测到 Pacman 系统（Arch Linux）"
        pacman -Syu --noconfirm
        echo -e "${gl_lv}系统更新完成${gl_bai}"

    elif command -v apk >/dev/null 2>&1; then
        echo "检测到 APK 系统（Alpine）"
        apk update && apk upgrade -U -a
        echo -e "${gl_lv}系统更新完成${gl_bai}"

    else
        echo -e "${gl_hong}未检测到支持的包管理器${gl_bai}"
    fi
    back_menu
}

# ------------------------------
# 2. 系统清理
# ------------------------------
do_cleanup() {
    clear
    echo -e "${gl_lv}>> 系统清理${gl_bai}"
    echo "------------------------"

    if command -v apt-get >/dev/null 2>&1; then
        echo "清理 apt 缓存..."
        apt-get clean -qq
        apt-get autoclean -qq
        echo "删除不再需要的依赖..."
        apt-get autoremove -y -qq
        echo -e "${gl_lv}APT 缓存清理完成${gl_bai}"

    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all -q
        dnf autoremove -y -q
        echo -e "${gl_lv}DNF 缓存清理完成${gl_bai}"

    elif command -v yum >/dev/null 2>&1; then
        yum clean all -q
        echo -e "${gl_lv}YUM 缓存清理完成${gl_bai}"

    elif command -v pacman >/dev/null 2>&1; then
        pacman -Scc --noconfirm
        echo -e "${gl_lv}Pacman 缓存清理完成${gl_bai}"

    elif command -v apk >/dev/null 2>&1; then
        apk cache clean
        echo -e "${gl_lv}APK 缓存清理完成${gl_bai}"
    fi

    # 清理日志（保留系统日志目录）
    echo ""
    echo "清理旧日志..."
    find /var/log -name "*.gz" -delete 2>/dev/null
    find /var/log -name "*.[0-9]" -delete 2>/dev/null
    find /tmp -type f -atime +7 -delete 2>/dev/null
    echo -e "${gl_lv}日志清理完成${gl_bai}"

    back_menu
}

# ------------------------------
# 端口管理（二级菜单）
# ------------------------------
do_port_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}>> 端口管理${gl_bai}"
        echo "------------------------"
        echo -e "  ${gl_lan}1.${gl_bai} 查看已开放端口"
        echo -e "  ${gl_lan}2.${gl_bai} 开放指定端口"
        echo -e "  ${gl_lan}3.${gl_bai} 关闭指定端口"
        echo "------------------------"
        echo -e "  ${gl_hong}0.${gl_bai} 返回主菜单"
        echo "------------------------"
        echo ""
        echo -e "${gl_huang}输入 q 可随时返回上级菜单${gl_bai}"
        read -p "请输入你的选择: " port_choice
        
        if [ "$port_choice" = "q" ]; then
            echo -e "${gl_huang}已返回${gl_bai}"
            return
        fi
        
        case "$port_choice" in
            1) do_list_ports ;;
            2) do_open_port ;;
            3) do_close_port ;;
            0)
                echo -e "${gl_huang}已返回主菜单${gl_bai}"
                return
                ;;
            *)
                echo -e "${gl_hong}无效选择${gl_bai}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------
# 查看已开放端口
# ------------------------------
do_list_ports() {
    clear
    echo -e "${gl_lv}>> 查看已开放端口${gl_bai}"
    echo "------------------------"
    echo ""
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${gl_huang}防火墙工具: firewalld${gl_bai}"
        echo ""
        local ports=$(firewall-cmd --list-ports 2>/dev/null)
        if [ -z "$ports" ]; then
            echo -e "  ${gl_huang}暂无已开放的端口${gl_bai}"
        else
            echo "已开放的端口："
            echo ""
            echo "$ports" | tr ' ' '\n' | while read p; do
                port_num=$(echo "$p" | cut -d'/' -f1)
                port_proto=$(echo "$p" | cut -d'/' -f2)
                printf "  %-10s %s\n" "$port_num" "$port_proto"
            done
        fi
        echo ""
        echo -e "${gl_huang}防火墙状态: $(firewall-cmd --state 2>/dev/null || echo '未知')${gl_bai}"
        
    elif command -v ufw >/dev/null 2>&1; then
        echo -e "${gl_huang}防火墙工具: ufw${gl_bai}"
        echo ""
        local status=$(ufw status 2>/dev/null)
        echo "$status"
        echo ""
        local ports=$(ufw status | grep -E "^[0-9]+" | awk '{print $1}')
        if [ -z "$ports" ]; then
            echo -e "  ${gl_huang}暂无已开放的端口${gl_bai}"
        else
            echo "已开放的端口："
            echo "$ports" | while read p; do
                echo "  $p"
            done
        fi
        
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${gl_huang}防火墙工具: iptables${gl_bai}"
        echo ""
        local ports=$(iptables -L INPUT -n 2>/dev/null | grep ACCEPT | grep dpt | awk '{for(i=1;i<=NF;i++) if($i ~ /dpt:/) print $i}' | sed 's/dpt://' | sort -u)
        if [ -z "$ports" ]; then
            echo -e "  ${gl_huang}暂无已开放的端口${gl_bai}"
        else
            echo "已开放的端口："
            echo ""
            echo "$ports" | while read p; do
                echo "  $p"
            done
        fi
    else
        echo -e "${gl_hong}未检测到防火墙工具${gl_bai}"
    fi
    
    echo ""
    back_menu
}

# ------------------------------
# 3. 开放指定端口
# ------------------------------
do_open_port() {
    clear
    echo -e "${gl_lv}>> 开放指定端口${gl_bai}"
    echo "------------------------"
    echo "当前已开放的端口："
    echo ""
    if command -v firewall-cmd >/dev/null 2>&1; then
        local ports=$(firewall-cmd --list-ports 2>/dev/null)
        if [ -z "$ports" ]; then
            echo "  暂无"
        else
            echo "$ports" | tr ' ' '\n' | while read p; do
                [ -n "$p" ] && echo "  $p"
            done
        fi
    elif command -v ufw >/dev/null 2>&1; then
        ufw status numbered 2>/dev/null | grep -E "\[[0-9]+\]" | while read line; do
            echo "  $line"
        done
    elif command -v iptables >/dev/null 2>&1; then
        iptables -L INPUT -n 2>/dev/null | grep ACCEPT | grep dpt | awk '{for(i=1;i<=NF;i++) if($i ~ /dpt:/) print "  "$i}' | sed 's/dpt:/端口 /' | sort -u | head -20
    else
        echo "  暂无可识别的防火墙工具"
    fi
    echo ""
    read -p "请输入要开放的端口号（多个用空格分隔）: " ports
    if [ "$ports" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$ports" ]; then
        echo -e "${gl_huang}未输入端口，已取消${gl_bai}"
        back_menu
        return $?
    fi

    for port in $ports; do
        if ! echo "$port" | grep -qE '^[0-9]+$'; then
            echo -e "${gl_hong}无效端口号: $port，跳过${gl_bai}"
            continue
        fi
        if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "${gl_hong}端口超出范围: $port，跳过${gl_bai}"
            continue
        fi

        if command -v firewall-cmd >/dev/null 2>&1; then
            firewall-cmd --permanent --add-port=$port/tcp >/dev/null 2>&1
            firewall-cmd --permanent --add-port=$port/udp >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            echo -e "${gl_lv}端口 $port 已开放（firewalld）${gl_bai}"
        elif command -v ufw >/dev/null 2>&1; then
            ufw allow $port/tcp >/dev/null 2>&1
            echo -e "${gl_lv}端口 $port 已开放（ufw）${gl_bai}"
        elif command -v iptables >/dev/null 2>&1; then
            iptables -I INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
            iptables -I INPUT -p udp --dport $port -j ACCEPT 2>/dev/null
            echo -e "${gl_lv}端口 $port 已开放（iptables）${gl_bai}"
        else
            echo -e "${gl_hong}未检测到防火墙工具，尝试 iptables${gl_bai}"
            iptables -I INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null || \
                echo -e "${gl_hong}开放失败，请手动操作${gl_bai}"
        fi
    done
    back_menu
}

# ------------------------------
# 4. 关闭指定端口
# ------------------------------
do_close_port() {
    clear
    echo -e "${gl_hong}>> 关闭指定端口${gl_bai}"
    echo "------------------------"
    echo "当前已开放的端口："
    echo ""
    if command -v firewall-cmd >/dev/null 2>&1; then
        local ports=$(firewall-cmd --list-ports 2>/dev/null)
        if [ -z "$ports" ]; then
            echo "  暂无"
        else
            echo "$ports" | tr ' ' '\n' | while read p; do
                [ -n "$p" ] && echo "  $p"
            done
        fi
    elif command -v ufw >/dev/null 2>&1; then
        ufw status numbered 2>/dev/null | grep -E "\[[0-9]+\]" | while read line; do
            echo "  $line"
        done
    elif command -v iptables >/dev/null 2>&1; then
        iptables -L INPUT -n 2>/dev/null | grep ACCEPT | grep dpt | awk '{for(i=1;i<=NF;i++) if($i ~ /dpt:/) print "  "$i}' | sed 's/dpt:/端口 /' | sort -u | head -20
    else
        echo "  暂无可识别的防火墙工具"
    fi
    echo ""
    read -p "请输入要关闭的端口号（多个用空格分隔）: " ports
    if [ "$ports" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$ports" ]; then
        echo -e "${gl_huang}未输入端口，已取消${gl_bai}"
        back_menu
        return $?
    fi

    for port in $ports; do
        if ! echo "$port" | grep -qE '^[0-9]+$'; then
            echo -e "${gl_hong}无效端口号: $port，跳过${gl_bai}"
            continue
        fi
        if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "${gl_hong}端口超出范围: $port，跳过${gl_bai}"
            continue
        fi
        # 保护 SSH 端口
        if [ "$port" = "22" ]; then
            echo -e "${gl_hong}警告：禁止关闭 22 端口（SSH）！跳过${gl_bai}"
            continue
        fi

        if command -v firewall-cmd >/dev/null 2>&1; then
            firewall-cmd --permanent --remove-port=$port/tcp >/dev/null 2>&1
            firewall-cmd --permanent --remove-port=$port/udp >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            echo -e "${gl_hong}端口 $port 已关闭（firewalld）${gl_bai}"
        elif command -v ufw >/dev/null 2>&1; then
            ufw delete allow $port/tcp >/dev/null 2>&1
            echo -e "${gl_hong}端口 $port 已关闭（ufw）${gl_bai}"
        elif command -v iptables >/dev/null 2>&1; then
            iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
            iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null
            echo -e "${gl_hong}端口 $port 已关闭（iptables）${gl_bai}"
        else
            echo -e "${gl_hong}未检测到防火墙工具${gl_bai}"
        fi
    done
    back_menu
}

# ------------------------------
# 账户管理（二级菜单）
# ------------------------------
do_account_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}>> 账户管理${gl_bai}"
        echo "------------------------"
        echo -e "  ${gl_lan}1.${gl_bai} 修改普通用户名"
        echo -e "  ${gl_lan}2.${gl_bai} 修改普通用户密码"
        echo -e "  ${gl_lan}3.${gl_bai} 普通用户账户管理（添加/删除）"
        echo -e "  ${gl_lan}4.${gl_bai} Root 账户管理（创建/改密）"
        echo -e "  ${gl_lan}5.${gl_bai} 修改主机名"
        echo "------------------------"
        echo -e "  ${gl_hong}0.${gl_bai} 返回主菜单"
        echo "------------------------"
        echo ""
        echo -e "${gl_huang}输入 q 可随时返回上级菜单${gl_bai}"
        read -p "请输入你的选择: " acc_choice
        
        if [ "$acc_choice" = "q" ]; then
            echo -e "${gl_huang}已返回${gl_bai}"
            return
        fi
        
        case "$acc_choice" in
            1) do_change_username ;;
            2) do_change_password ;;
            3) do_user_manage ;;
            4) do_root_account ;;
            5) do_change_hostname ;;
            0)
                echo -e "${gl_huang}已返回主菜单${gl_bai}"
                return
                ;;
            *)
                echo -e "${gl_hong}无效选择${gl_bai}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------
# 修改普通用户名
# ------------------------------
do_change_username() {
    clear
    echo -e "${gl_lv}>> 修改普通用户名${gl_bai}"
    echo "------------------------"
    echo "当前系统上的普通用户："
    echo ""
    awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "nogroup" {print "  "$1}' /etc/passwd
    echo ""
    read -p "请输入要修改的用户名: " old_username
    if [ "$old_username" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$old_username" ]; then
        echo -e "${gl_huang}未输入用户名，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    # 检查用户是否存在
    if ! id "$old_username" &>/dev/null; then
        echo -e "${gl_hong}用户 $old_username 不存在${gl_bai}"
        back_menu
        return
    fi
    
    # 检查是否为 root 用户
    if [ "$old_username" = "root" ]; then
        echo -e "${gl_hong}请勿通过此选项修改 root 用户名${gl_bai}"
        back_menu
        return
    fi
    
    read -p "请输入新的用户名: " new_username
    if [ "$new_username" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$new_username" ]; then
        echo -e "${gl_huang}未输入新用户名，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    # 检查新用户名是否已存在
    if id "$new_username" &>/dev/null; then
        echo -e "${gl_hong}用户 $new_username 已存在${gl_bai}"
        back_menu
        return
    fi
    
    # 修改用户名
    usermod -l "$new_username" "$old_username" 2>/dev/null && \
        echo -e "${gl_lv}用户名已从 $old_username 修改为 $new_username${gl_bai}" || \
        echo -e "${gl_hong}修改失败，请手动执行: usermod -l $new_username $old_username${gl_bai}"
    
    back_menu
}

# ------------------------------
# 修改普通用户密码（原第5项）
# ------------------------------
do_change_password() {
    clear
    echo -e "${gl_lv}>> 修改普通用户密码${gl_bai}"
    echo "------------------------"
    echo "当前系统上的普通用户："
    echo ""
    # 列出 UID >= 1000 的用户（排除 nobody 等）
    awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "nogroup" {print "  "$1}' /etc/passwd
    echo ""
    read -p "请输入要修改密码的用户名: " username
    if [ "$username" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi

    if [ -z "$username" ]; then
        echo -e "${gl_huang}未输入用户名，已取消${gl_bai}"
        back_menu
        return $?
    fi

    # 检查用户是否存在
    if ! id "$username" &>/dev/null; then
        echo -e "${gl_hong}用户 $username 不存在${gl_bai}"
        back_menu
        return
    fi

    # 检查是否为 root 用户
    if [ "$username" = "root" ]; then
        echo -e "${gl_hong}请勿通过此选项修改 root 密码${gl_bai}"
        back_menu
        return
    fi

    # 提示输入新密码
    echo -e "${gl_huang}为用户 $username 设置新密码${gl_bai}"
    read -s -p "请输入新密码: " new_pass
    echo ""
    if [ "$new_pass" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$new_pass" ]; then
        echo -e "${gl_huang}密码不能为空，已取消${gl_bai}"
        back_menu
        return $?
    fi

    read -s -p "请再次输入新密码: " confirm_pass
    echo ""
    if [ "$confirm_pass" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi

    if [ "$new_pass" != "$confirm_pass" ]; then
        echo -e "${gl_hong}两次输入的密码不一致，已取消${gl_bai}"
        back_menu
        return
    fi

    # 修改密码
    echo "$new_pass" | passwd --stdin "$username" 2>/dev/null && \
        echo -e "${gl_lv}用户 $username 的密码已成功修改${gl_bai}" || \
        echo "$username:$new_pass" | chpasswd 2>/dev/null && \
        echo -e "${gl_lv}用户 $username 的密码已成功修改${gl_bai}" || \
        echo -e "${gl_hong}密码修改失败，请手动执行: passwd $username${gl_bai}"

    back_menu
}

# ------------------------------
# 普通用户账户管理（添加/删除）
# ------------------------------
do_user_manage() {
    while true; do
        clear
        echo -e "${gl_kjlan}>> 普通用户账户管理${gl_bai}"
        echo "------------------------"
        echo -e "  ${gl_lan}1.${gl_bai} 添加用户"
        echo -e "  ${gl_lan}2.${gl_bai} 删除用户"
        echo "------------------------"
        echo -e "  ${gl_hong}0.${gl_bai} 返回上级"
        echo "------------------------"
        echo ""
        echo -e "${gl_huang}输入 q 可随时返回上级菜单${gl_bai}"
        read -p "请输入你的选择: " um_choice
        
        if [ "$um_choice" = "q" ]; then
            echo -e "${gl_huang}已返回${gl_bai}"
            return
        fi
        
        case "$um_choice" in
            1) do_add_user ;;
            2) do_del_user ;;
            0)
                echo -e "${gl_huang}已返回${gl_bai}"
                return
                ;;
            *)
                echo -e "${gl_hong}无效选择${gl_bai}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------
# 添加用户
# ------------------------------
do_add_user() {
    clear
    echo -e "${gl_lv}>> 添加用户${gl_bai}"
    echo "------------------------"
    echo ""
    read -p "请输入新用户名: " new_user
    if [ "$new_user" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$new_user" ]; then
        echo -e "${gl_huang}未输入用户名，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    # 检查用户是否已存在
    if id "$new_user" &>/dev/null; then
        echo -e "${gl_hong}用户 $new_user 已存在${gl_bai}"
        back_menu
        return
    fi
    
    # 输入密码
    read -s -p "请输入用户密码: " new_pass
    echo ""
    if [ "$new_pass" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$new_pass" ]; then
        echo -e "${gl_huang}密码不能为空，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    read -s -p "请再次输入密码: " confirm_pass
    echo ""
    if [ "$confirm_pass" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ "$new_pass" != "$confirm_pass" ]; then
        echo -e "${gl_hong}两次输入的密码不一致，已取消${gl_bai}"
        back_menu
        return
    fi
    
    # 创建用户
    if command -v useradd &>/dev/null; then
        useradd -m -s /bin/bash "$new_user" 2>/dev/null
    elif command -v adduser &>/dev/null; then
        adduser --disabled-password --gecos "" "$new_user" 2>/dev/null
    else
        echo -e "${gl_hong}未找到可用的用户创建命令${gl_bai}"
        back_menu
        return
    fi
    
    # 设置密码
    if id "$new_user" &>/dev/null; then
        echo "$new_pass" | passwd --stdin "$new_user" 2>/dev/null || \
            echo "$new_user:$new_pass" | chpasswd 2>/dev/null
        echo -e "${gl_lv}用户 $new_user 已创建并设置密码${gl_bai}"
    else
        echo -e "${gl_hong}用户创建失败${gl_bai}"
    fi
    
    back_menu
}

# ------------------------------
# 删除用户
# ------------------------------
do_del_user() {
    clear
    echo -e "${gl_hong}>> 删除用户${gl_bai}"
    echo "------------------------"
    echo "当前系统上的普通用户："
    echo ""
    awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "nogroup" {print "  "$1}' /etc/passwd
    echo ""
    read -p "请输入要删除的用户名: " del_user
    if [ "$del_user" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    if [ -z "$del_user" ]; then
        echo -e "${gl_huang}未输入用户名，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    # 检查用户是否存在
    if ! id "$del_user" &>/dev/null; then
        echo -e "${gl_hong}用户 $del_user 不存在${gl_bai}"
        back_menu
        return
    fi
    
    # 禁止删除 root
    if [ "$del_user" = "root" ]; then
        echo -e "${gl_hong}禁止删除 root 用户！${gl_bai}"
        back_menu
        return
    fi
    
    # 确认删除
    confirm "确定删除用户 $del_user 及其家目录？"
    ret=$?
    if [ $ret -eq 2 ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    elif [ $ret -eq 0 ]; then
        userdel -r "$del_user" 2>/dev/null && \
            echo -e "${gl_lv}用户 $del_user 已删除${gl_bai}" || \
            echo -e "${gl_hong}删除失败，请手动执行: userdel -r $del_user${gl_bai}"
    else
        echo "已取消"
    fi
    
    back_menu
}

# ------------------------------
# 7. Root 账户管理（创建/修改密码）
# ------------------------------
do_root_account() {
    clear
    echo -e "${gl_kjlan}>> Root 账户管理${gl_bai}"
    echo "------------------------"

    # 检查 root 用户是否存在
    if id root &>/dev/null; then
        echo -e "${gl_lv}Root 用户已存在${gl_bai}"
        echo ""
        confirm "是否要修改 root 密码？"
        ret=$?
        if [ $ret -eq 2 ]; then
            echo -e "${gl_huang}已返回${gl_bai}"
            back_menu
            return $?
        elif [ $ret -eq 0 ]; then
            read -s -p "请输入 root 新密码: " new_pass
            echo ""
            if [ "$new_pass" = "q" ]; then
                echo -e "${gl_huang}已返回${gl_bai}"
                back_menu
                return $?
            fi
            if [ -z "$new_pass" ]; then
                echo -e "${gl_huang}密码不能为空，已取消${gl_bai}"
                back_menu
                return
            fi
            read -s -p "请再次输入 root 新密码: " confirm_pass
            echo ""
            if [ "$confirm_pass" = "q" ]; then
                echo -e "${gl_huang}已返回${gl_bai}"
                back_menu
                return $?
            fi
            if [ "$new_pass" != "$confirm_pass" ]; then
                echo -e "${gl_hong}两次输入的密码不一致，已取消${gl_bai}"
                back_menu
                return
            fi
            echo "$new_pass" | passwd --stdin root 2>/dev/null && \
                echo -e "${gl_lv}Root 密码已成功修改${gl_bai}" || \
                echo "root:$new_pass" | chpasswd 2>/dev/null && \
                echo -e "${gl_lv}Root 密码已成功修改${gl_bai}" || \
                echo -e "${gl_hong}密码修改失败，请手动执行: passwd root${gl_bai}"
        else
            echo "已取消"
        fi
    else
        echo -e "${gl_huang}Root 用户不存在${gl_bai}"
        echo ""
        confirm "是否创建 root 用户？"
        ret=$?
        if [ $ret -eq 2 ]; then
            echo -e "${gl_huang}已返回${gl_bai}"
            back_menu
            return $?
        elif [ $ret -eq 0 ]; then
            # 根据系统选择创建方式
            if command -v useradd &>/dev/null; then
                useradd -m -s /bin/bash root 2>/dev/null
            elif command -v adduser &>/dev/null; then
                adduser --disabled-password --gecos "" root 2>/dev/null
            else
                echo -e "${gl_hong}未找到可用的用户创建命令${gl_bai}"
                back_menu
                return
            fi

            if id root &>/dev/null; then
                echo -e "${gl_lv}Root 用户已创建${gl_bai}"
                echo ""
                read -s -p "请设置 root 密码: " new_pass
                echo ""
                if [ "$new_pass" = "q" ]; then
                    echo -e "${gl_huang}已返回${gl_bai}"
                    back_menu
                    return $?
                fi
                if [ -z "$new_pass" ]; then
                    echo -e "${gl_huang}密码不能为空${gl_bai}"
                else
                    read -s -p "请再次输入密码: " confirm_pass
                    echo ""
                    if [ "$confirm_pass" = "q" ]; then
                        echo -e "${gl_huang}已返回${gl_bai}"
                        back_menu
                        return $?
                    fi
                    if [ "$new_pass" != "$confirm_pass" ]; then
                        echo -e "${gl_hong}两次输入的密码不一致${gl_bai}"
                    else
                        echo "$new_pass" | passwd --stdin root 2>/dev/null && \
                            echo -e "${gl_lv}Root 密码设置成功${gl_bai}" || \
                            echo "root:$new_pass" | chpasswd 2>/dev/null && \
                            echo -e "${gl_lv}Root 密码设置成功${gl_bai}" || \
                            echo -e "${gl_hong}密码设置失败，请手动执行: passwd root${gl_bai}"
                    fi
                fi
            else
                echo -e "${gl_hong}Root 用户创建失败${gl_bai}"
            fi
        else
            echo "已取消"
        fi
    fi

    back_menu
}

# ------------------------------
# 修改主机名
# ------------------------------
do_change_hostname() {
    clear
    echo -e "${gl_lv}>> 修改主机名${gl_bai}"
    echo "============================================================"
    echo ""
    
    # 显示当前主机名
    local current_hostname=$(hostname)
    echo -e "${gl_lan}当前主机名:${gl_bai} $current_hostname"
    echo ""
    echo "------------------------------------------------------------"
    echo -e "${gl_huang}提示:${gl_bai}"
    echo "  - 主机名只能包含字母、数字、连字符(-)和点(.)"
    echo "  - 建议使用有意义的名称，如: web-server, db-master"
    echo "  - 修改后需要重新登录才能在提示符中看到新主机名"
    echo "------------------------------------------------------------"
    echo ""
    
    read -p "请输入新的主机名: " new_hostname
    if [ "$new_hostname" = "q" ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    fi
    
    if [ -z "$new_hostname" ]; then
        echo -e "${gl_huang}未输入主机名，已取消${gl_bai}"
        back_menu
        return $?
    fi
    
    # 验证主机名格式
    if ! echo "$new_hostname" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9.-]*$'; then
        echo -e "${gl_hong}主机名格式无效！${gl_bai}"
        echo -e "${gl_huang}主机名必须以字母或数字开头，只能包含字母、数字、连字符和点${gl_bai}"
        back_menu
        return
    fi
    
    # 确认修改
    echo ""
    confirm "确定将主机名从 '$current_hostname' 改为 '$new_hostname'？"
    ret=$?
    if [ $ret -eq 2 ]; then
        echo -e "${gl_huang}已返回${gl_bai}"
        back_menu
        return $?
    elif [ $ret -eq 0 ]; then
        # 使用 hostnamectl 修改（推荐）
        if command -v hostnamectl &>/dev/null; then
            hostnamectl set-hostname "$new_hostname" 2>/dev/null && \
                echo -e "${gl_lv}主机名已成功修改为: $new_hostname${gl_bai}" || \
                echo -e "${gl_hong}修改失败，请手动执行: hostnamectl set-hostname $new_hostname${gl_bai}"
        # 兼容没有 systemd 的系统
        elif [ -f /etc/hostname ]; then
            echo "$new_hostname" | tee /etc/hostname >/dev/null && \
                hostname "$new_hostname" 2>/dev/null && \
                echo -e "${gl_lv}主机名已成功修改为: $new_hostname${gl_bai}" || \
                echo -e "${gl_hong}修改失败，请手动编辑 /etc/hostname${gl_bai}"
        else
            hostname "$new_hostname" 2>/dev/null && \
                echo -e "${gl_lv}主机名已成功修改为: $new_hostname（重启后失效）${gl_bai}" || \
                echo -e "${gl_hong}修改失败${gl_bai}"
        fi
        
        echo ""
        echo -e "${gl_huang}注意: 重新登录 SSH 后提示符才会显示新主机名${gl_bai}"
    else
        echo "已取消"
    fi
    
    back_menu
}

# ------------------------------
# 8. 查看已安装的软件
# ------------------------------
do_list_software() {
    clear
    echo -e "${gl_lv}>> 查看已安装的软件${gl_bai}"
    echo "============================================================"
    echo ""
    
    local pkg_count=0
    local pkg_manager=""
    
    if command -v dpkg &>/dev/null; then
        pkg_manager="dpkg"
        pkg_count=$(dpkg -l 2>/dev/null | grep -c '^ii')
        echo -e "${gl_lan}包管理器:${gl_bai} dpkg (Debian/Ubuntu)"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
        pkg_count=$(dnf list installed --quiet 2>/dev/null | wc -l)
        pkg_count=$((pkg_count - 1))
        echo -e "${gl_lan}包管理器:${gl_bai} dnf (Fedora/RHEL)"
    elif command -v yum &>/dev/null; then
        pkg_manager="yum"
        pkg_count=$(yum list installed --quiet 2>/dev/null | wc -l)
        pkg_count=$((pkg_count - 1))
        echo -e "${gl_lan}包管理器:${gl_bai} yum (CentOS/RHEL)"
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"
        pkg_count=$(pacman -Q 2>/dev/null | wc -l)
        echo -e "${gl_lan}包管理器:${gl_bai} pacman (Arch)"
    elif command -v apk &>/dev/null; then
        pkg_manager="apk"
        pkg_count=$(apk info 2>/dev/null | wc -l)
        echo -e "${gl_lan}包管理器:${gl_bai} apk (Alpine)"
    else
        echo -e "${gl_hong}未检测到支持的包管理器${gl_bai}"
        back_menu
        return
    fi
    
    echo -e "${gl_lan}已安装软件:${gl_bai} $pkg_count 个"
    echo ""
    echo "------------------------------------------------------------"
    echo -e "  ${gl_huang}软件包名称                                    版本${gl_bai}"
    echo "------------------------------------------------------------"
    
    case "$pkg_manager" in
        dpkg)
            dpkg -l 2>/dev/null | grep '^ii' | awk '{printf "  %-42s %s\n", $2, $3}' | head -50
            ;;
        dnf)
            dnf list installed --quiet 2>/dev/null | awk 'NR>0{printf "  %-42s %s\n", $1, $2}' | head -50
            ;;
        yum)
            yum list installed --quiet 2>/dev/null | awk 'NR>0{printf "  %-42s %s\n", $1, $2}' | head -50
            ;;
        pacman)
            pacman -Q 2>/dev/null | awk '{printf "  %-42s %s\n", $1, $2}' | head -50
            ;;
        apk)
            apk info -v 2>/dev/null | awk '{printf "  %s\n", $0}' | head -50
            ;;
    esac
    
    if [ $pkg_count -gt 50 ]; then
        echo ""
        echo -e "${gl_huang}仅显示前 50 个软件包，共 $pkg_count 个${gl_bai}"
    fi
    
    echo "------------------------------------------------------------"
    echo ""
    echo -e "${gl_lv}查询完成${gl_bai}"
    back_menu
}

# ------------------------------
# 9. 查看正在运行的服务
# ------------------------------
do_list_services() {
    clear
    echo -e "${gl_lv}>> 查看正在运行的服务${gl_bai}"
    echo "============================================================"
    echo ""
    
    local svc_count=0
    
    if command -v systemctl &>/dev/null; then
        echo -e "${gl_lan}服务管理器:${gl_bai} systemd"
        svc_count=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c 'running')
        echo -e "${gl_lan}运行中服务:${gl_bai} $svc_count 个"
        echo ""
        echo "------------------------------------------------------------"
        echo -e "  ${gl_huang}服务名称                                      状态${gl_bai}"
        echo "------------------------------------------------------------"
        systemctl list-units --type=service --state=running --no-pager 2>/dev/null | \
            awk 'NR>0 && /running/{printf "  %-42s [运行中]\n", $1}' | head -30
        echo "------------------------------------------------------------"
        if [ $svc_count -gt 30 ]; then
            echo -e "${gl_huang}仅显示前 30 个服务，共 $svc_count 个正在运行${gl_bai}"
        fi
    elif command -v service &>/dev/null; then
        echo -e "${gl_lan}服务管理器:${gl_bai} SysVinit"
        local running=$(service --status-all 2>/dev/null | grep -c '+\]')
        svc_count=$running
        echo -e "${gl_lan}运行中服务:${gl_bai} $svc_count 个"
        echo ""
        echo "------------------------------------------------------------"
        echo -e "  ${gl_huang}服务名称                                      状态${gl_bai}"
        echo "------------------------------------------------------------"
        service --status-all 2>/dev/null | grep '+\]' | \
            sed 's/\[ \+\]//' | awk '{printf "  %-42s [运行中]\n", $1}' | head -30
        echo "------------------------------------------------------------"
        if [ $svc_count -gt 30 ]; then
            echo -e "${gl_huang}仅显示前 30 个服务，共 $svc_count 个正在运行${gl_bai}"
        fi
    else
        echo -e "${gl_hong}未检测到服务管理工具${gl_bai}"
        back_menu
        return
    fi
    
    echo ""
    echo -e "${gl_lv}查询完成${gl_bai}"
    back_menu
}

# ------------------------------
# 主菜单
# ------------------------------
main_menu() {
    clear
    echo -e "${gl_kjlan}========================${gl_bai}"
    echo -e "${gl_kjlan}   系统管理脚本${gl_bai}"
    echo -e "${gl_kjlan}========================${gl_bai}"
    echo ""
    echo -e "  ${gl_lan}1.${gl_bai} 系统更新"
    echo -e "  ${gl_lan}2.${gl_bai} 系统清理"
    echo -e "  ${gl_lan}3.${gl_bai} 端口管理"
    echo -e "  ${gl_lan}4.${gl_bai} 账户管理"
    echo -e "  ${gl_lan}5.${gl_bai} 查看已安装的软件"
    echo -e "  ${gl_lan}6.${gl_bai} 查看正在运行的服务"
    echo ""
    echo -e "${gl_kjlan}========================${gl_bai}"
    echo -e "  ${gl_hong}0.${gl_bai} 退出"
    echo -e "${gl_kjlan}========================${gl_bai}"
    echo ""
}

# ------------------------------
# 主循环
# ------------------------------
while true; do
    main_menu
    echo ""
    echo -e "${gl_huang}输入 q 可随时返回上级菜单${gl_bai}"
    # 清空 stdin 缓冲区，防止提权时残留字符导致无效输入
    read -t 0.1 -n 10000 2>/dev/null
    read -p "请输入你的选择: " choice

    case "$choice" in
        1) do_update ;;
        2) do_cleanup ;;
        3) do_port_menu ;;
        4) do_account_menu ;;
        5) do_list_software ;;
        6) do_list_services ;;
        0)
            clear
            echo -e "${gl_lv}再见！${gl_bai}"
            exit 0
            ;;
        q) ;;  # q 直接回到主菜单
        "") ;;  # 空输入直接回到主菜单，不提示
        *)
            echo -e "${gl_huang}无效选择，请重新输入${gl_bai}"
            sleep 1
            ;;
    esac
done
