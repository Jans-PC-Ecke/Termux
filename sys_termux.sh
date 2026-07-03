#!/data/data/com.termux/files/usr/bin/bash

# Farben
R='\033[0;31m'
Y='\033[1;33m'
G='\033[0;32m'
O='\033[38;5;208m'
NC='\033[0m'

# Netzwerk initialisieren
iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')
if [[ -n "$iface" ]] && [[ -f /sys/class/net/"$iface"/statistics/rx_bytes ]]; then
    rx_prev=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null)
    tx_prev=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null)
else
    rx_prev=0; tx_prev=0
fi

cpu_load() {
    if [[ -f /proc/stat ]]; then
        read -r _ user nice system idle iowait irq softirq _ < /proc/stat 2>/dev/null
        prev_total=$((user + nice + system + idle + iowait + irq + softirq))
        prev_idle=$idle
        sleep 1
        read -r _ user nice system idle iowait irq softirq _ < /proc/stat 2>/dev/null
        total=$((user + nice + system + idle + iowait + irq + softirq))
        idle=$idle
        ((diff_idle = idle - prev_idle))
        ((diff_total = total - prev_total))
        if (( diff_total > 0 )); then
            echo $((100 * (diff_total - diff_idle) / diff_total))
        else
            echo "0"
        fi
    else
        echo "—"
    fi
}

ram_info() {
    if [[ -f /proc/meminfo ]]; then
        read -r _ total _ < <(grep '^MemTotal:' /proc/meminfo 2>/dev/null)
        read -r _ avail _ < <(grep '^MemAvailable:' /proc/meminfo 2>/dev/null)
        if [[ -n "$total" && -n "$avail" ]]; then
            mem_used=$(( (total - avail) / 1024 ))
            mem_total=$((total / 1024))
            echo "$mem_used $mem_total"
        else
            echo "0 0"
        fi
    else
        echo "0 0"
    fi
}

get_temp() {
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [[ -n "$temp" ]] && (( temp > 0 )); then
            (( temp > 1000 )) && temp=$((temp / 1000))
            echo "$temp"
            return
        fi
    fi
    if command -v termux-battery-status &>/dev/null; then
        temp=$(termux-battery-status 2>/dev/null | grep -o '"temperature":[0-9]*' | cut -d: -f2)
        if [[ -n "$temp" ]]; then
            echo $((temp / 10))
            return
        fi
    fi
    echo "—"
}

uptime_de() {
    if [[ -f /proc/uptime ]]; then
        local up=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
        if [[ -n "$up" ]]; then
            local hours=$((up / 3600))
            local minutes=$(((up % 3600) / 60))
            (( hours > 0 )) && echo "${hours}h ${minutes}m" || echo "${minutes}m"
        else
            echo "—"
        fi
    else
        echo "—"
    fi
}

tput civis 2>/dev/null
while true; do
    clear
    printf "${O}┌─ Sys-Mon ─ $(date '+%H:%M:%S') ─ $(uptime_de) ─┐${NC}\n"

    # CPU
    cpu=$(cpu_load)
    temp=$(get_temp)
    [[ "$temp" =~ ^[0-9]+$ ]] && { (( temp > 75 )) && tc=$R || (( temp > 55 )) && tc=$Y || tc=$G; } || { tc=$NC; temp="—"; }
    printf "${O}│ CPU${NC} %6s%% Temp: ${tc}%3s°C${NC} ${O}│${NC}\n" "$cpu" "$temp"

    # RAM
    read -r umem tmem <<< $(ram_info)
    if [[ "$umem" != "0" && "$tmem" != "0" ]]; then
        mem_percent=$(( umem * 100 / tmem ))
        printf "${O}│ RAM${NC} %5d/%-5d MiB (%2d%%) ${O}│${NC}\n" "$umem" "$tmem" "$mem_percent"
    else
        printf "${O}│ RAM${NC} %-20s ${O}│${NC}\n" "Nicht verfügbar"
    fi

    # Disk
    if command -v df &>/dev/null; then
        root=$(df -h /data/data/com.termux/files 2>/dev/null | awk 'NR==2 {printf "%s/%s (%s)", $3,$2,$5}')
        [[ -n "$root" ]] && printf "${O}│ Disk${NC} %-35s ${O}│${NC}\n" "$root"
    fi

    # Netzwerk
    if [[ -n "$iface" ]] && [[ -f /sys/class/net/"$iface"/statistics/rx_bytes ]]; then
        rx_now=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null)
        tx_now=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null)
        rx_kb=$(( (rx_now - rx_prev) / 1024 ))
        tx_kb=$(( (tx_now - tx_prev) / 1024 ))
        rx_prev=$rx_now; tx_prev=$tx_now
        printf "${O}│ Net ${NC}%s ↓%6d ↑%6d KB/s ${O}│${NC}\n" "$iface" "$rx_kb" "$tx_kb"
    else
        printf "${O}│ Net${NC} offline ${O}│${NC}\n"
    fi

    # Top-Prozess
    if command -v ps &>/dev/null; then
        top_proc=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null | awk 'NR==2 {print $1,$2,$3,$4}')
        if [[ -n "$top_proc" ]]; then
            read -r pid cmd cpuuse memuse <<< "$top_proc"
            printf "${O}│ Top${NC} PID %-5s %-12s CPU %4s%% RAM %4s%% ${O}│${NC}\n" "$pid" "$cmd" "$cpuuse" "$memuse"
        fi
    fi

    printf "${O}└──────────────────────────────────────────────────────────┘${NC}\n"
    echo -e "${Y}Drücke 'q' zum Beenden${NC}"

    read -t 2 -n 1 key
    [[ "$key" == "q" || "$key" == "Q" ]] && break
done
tput cnorm 2>/dev/null
clear
echo -e "${O}Sys-Mon beendet.${NC}"