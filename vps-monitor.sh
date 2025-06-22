#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/1386193648353284166/JOa8uBH0-6bdQZF_00gHPU4W_UCq9IwSZ599MPWcbA3iN0QGOt4r-_6jotPyJ3CsKcxg"
HOSTNAME=$(hostname)
OS=$(uname -o)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
UPTIME_FULL=$(uptime -s)
CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
CPU_USAGE_NOW=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_USAGE="${CPU_USAGE_NOW}%"
CPU_CORES=$(nproc)
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USAGE_PERCENT=$(( RAM_USED * 100 / RAM_TOTAL ))
DISK_USAGE=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
TX=$(cat /proc/net/dev | grep eth0 | awk '{print $10}')
RX=$(cat /proc/net/dev | grep eth0 | awk '{print $2}')
TX_MB=$(echo "scale=2; $TX / 1024 / 1024" | bc)
RX_MB=$(echo "scale=2; $RX / 1024 / 1024" | bc)
PUBLIC_IP=$(curl -s https://api.ipify.org)

# === Bandingkan dengan data sebelumnya ===
PREV_FILE="/tmp/.prev_monitor"
CPU_DIFF="N/A"
RAM_DIFF="N/A"

if [ -f "$PREV_FILE" ]; then
  PREV_CPU=$(awk -F= '/CPU_USAGE/ {print $2}' "$PREV_FILE")
  PREV_RAM=$(awk -F= '/RAM_USED/ {print $2}' "$PREV_FILE")
  
  CPU_CHANGE=$(echo "scale=1; $CPU_USAGE_NOW - $PREV_CPU" | bc)
  if [[ $CPU_CHANGE == -* ]]; then
    CPU_DIFF="↓ ${CPU_CHANGE#-}%"
  else
    CPU_DIFF="↑ $CPU_CHANGE%"
  fi

  RAM_CHANGE=$(( RAM_USED - PREV_RAM ))
  if (( RAM_CHANGE < 0 )); then
    RAM_DIFF="↓ $(( -1 * RAM_CHANGE )) MB"
  else
    RAM_DIFF="↑ $RAM_CHANGE MB"
  fi
fi

# Simpan data sekarang
echo "CPU_USAGE=$CPU_USAGE_NOW" > "$PREV_FILE"
echo "RAM_USED=$RAM_USED" >> "$PREV_FILE"

# === Kirim ke Discord ===
read -r -d '' PAYLOAD <<EOF
{
  "embeds": [{
    "title": "📡 Server Uptime - $HOSTNAME",
    "color": 3066993,
    "fields": [
      { "name": "🖥️ OS", "value": "$OS ($KERNEL)", "inline": true },
      { "name": "🌐 Public IP", "value": "$PUBLIC_IP", "inline": true },
      { "name": "⏱️ Uptime", "value": "$UPTIME\n(since $UPTIME_FULL)", "inline": false },
      { "name": "💾 RAM Usage", "value": "$RAM_USED MB / $RAM_TOTAL MB (${RAM_USAGE_PERCENT}%)\n($RAM_DIFF)", "inline": true },
      { "name": "📁 Disk Usage", "value": "$DISK_USAGE", "inline": true },
      { "name": "📡 Bandwidth", "value": "Upload: ${TX_MB} MB\nDownload: ${RX_MB} MB", "inline": false },
      { "name": "⚙️ CPU", "value": "$CPU_MODEL\nUsage: $CPU_USAGE ($CPU_DIFF)\nCores: $CPU_CORES", "inline": false }
    ],
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }]
}
EOF

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL"
