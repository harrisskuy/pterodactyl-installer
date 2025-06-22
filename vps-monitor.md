
# 📡 VPS Monitor - Discord Webhook Reporter

Script ini memonitor status VPS dan mengirim laporan otomatis ke Discord setiap 10 menit via webhook.

## 📋 Fitur yang Dilaporkan:
- Hostname & OS
- CPU usage & Load average
- RAM usage
- Disk usage
- IP publik & lokasi
- Bandwidth RX/TX (via `vnstat`)
- Uptime
- Ping
- Timestamp

---

## ⚙️ Cara Install

### 1. Login ke VPS via SSH

```bash
ssh root@IP-VPS-ANDA
```

---

### 2. Install `curl`, `vnstat`, dan `net-tools`

```bash
apt update && apt install curl vnstat net-tools -y
```

---

### 3. Download script monitor

```bash
wget -O /root/vps-monitor.sh https://raw.githubusercontent.com/harrisskuy/pterodactyl-installer/main/vps-monitor.sh
```

---

### 4. Ubah izin eksekusi

```bash
chmod +x /root/vps-monitor.sh
```

---

### 5. Tambahkan cronjob agar jalan tiap 10 menit

```bash
crontab -e
```

Lalu tambahkan baris ini di akhir file:

```bash
*/10 * * * * /root/vps-monitor.sh
```

Tekan `CTRL+X`, lalu `Y` dan `Enter`.

---

## ⚠️ Penting: Edit Webhook URL
Sebelum menjalankan script, buka dan edit file:

```bash
nano /root/vps-monitor.sh
```

Lalu ubah bagian berikut:

```bash
WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

Ganti dengan webhook Discord kamu.

---

## ✅ Selesai!
Laporan akan dikirim otomatis setiap 10 menit ke Discord 🎉

---

## 🧪 Tes manual (opsional)

Untuk memastikan script jalan:

```bash
bash /root/vps-monitor.sh
```

---

Kalau butuh bantuan lebih lanjut, silakan buka issue atau DM.
