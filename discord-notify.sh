#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/xxxxx/xxxxx"  # Ganti URL Webhook kamu

tail -n0 -F /var/log/audit/audit.log | \
while read line; do
    if echo "$line" | grep -q "EXECVE"; then
        time_now=$(date -Iseconds)
        user=$(whoami)
        hostname=$(hostname)
        ip_addr=$(hostname -I | awk '{print $1}')
        command=$(echo "$line" | grep -oP 'a0=".*?"' | cut -d'"' -f2)

        json=$(cat <<EOF
{
  "embeds": [
    {
      "title": "⚠️ Aktivitas VPS Terdeteksi",
      "color": 16711680,
      "fields": [
        { "name": "Hostname", "value": "$hostname", "inline": true },
        { "name": "IP", "value": "$ip_addr", "inline": true },
        { "name": "User", "value": "$user", "inline": true },
        { "name": "Command", "value": "\`$command\`", "inline": false }
      ],
      "footer": {
        "text": "Audit Log | VPS Monitor"
      },
      "timestamp": "$time_now"
    }
  ]
}
EOF
)

        curl -H "Content-Type: application/json" \
             -X POST \
             -d "$json" \
             "$WEBHOOK_URL"
    fi
done
