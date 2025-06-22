#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/1386193648353284166/JOa8uBH0-6bdQZF_00gHPU4W_UCq9IwSZ599MPWcbA3iN0QGOt4r-_6jotPyJ3CsKcxg"  # GANTI DENGAN WEBHOOK KAMU

HOSTNAME=$(hostname)
OS=$(uname -o)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
UPTIME_FULL=$(uptime -s)
CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
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

read -r -d '' PAYLOAD <<EOF
{
  "embeds": [{
    "title": "📡 VPS Status Report - $HOSTNAME",
    "color": 3066993,
    "fields": [
      { "name": "🖥️ OS", "value": "$OS ($KERNEL)", "inline": true },
      { "name": "🌐 Public IP", "value": "$PUBLIC_IP", "inline": true },
      { "name": "⏱️ Uptime", "value": "$UPTIME\n(since $UPTIME_FULL)", "inline": false },
      { "name": "💾 RAM Usage", "value": "$RAM_USED MB / $RAM_TOTAL MB (${RAM_USAGE_PERCENT}%)", "inline": true },
      { "name": "📁 Disk Usage", "value": "$DISK_USAGE", "inline": true },
      { "name": "📡 Bandwidth", "value": "Upload: ${TX_MB} MB\nDownload: ${RX_MB} MB", "inline": false },
      { "name": "⚙️ CPU", "value": "$CPU_MODEL\nUsage: $CPU_USAGE\nCores: $CPU_CORES", "inline": false }
    ],
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }]
}
EOF

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL"
