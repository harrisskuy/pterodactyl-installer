# 🐉 Pterodactyl Auto Installer (Tanpa Domain)

Script bash ini memungkinkan kamu menginstal **Pterodactyl Panel + Wings** secara **100% otomatis** di VPS (tanpa perlu domain). Hanya perlu satu perintah — tinggal duduk dan tunggu.

---

## 🚀 Fitur

✅ 100% otomatis (1 klik)  
✅ Tanpa input manual  
✅ Gaya log kekinian dan berwarna  
✅ Tanpa domain (akses via IP langsung)  
✅ Install panel + wings sekaligus  
✅ Include NGINX, MySQL, PHP, Docker  
✅ Buat akun admin otomatis

---

## ⚙️ Persyaratan VPS

- Ubuntu 20.04 / 22.04
- Akses root
- Minimal 1 vCPU & 1.5 GB RAM
- Port 80, 8080, 2022 terbuka

---

## 🛠 Cara Menggunakan

### 1. Masuk sebagai root

```bash
sudo -i
```

### 2. Unduh dan jalankan script

```bash
wget https://raw.githubusercontent.com/username/ptero-autoinstall/main/pterodactyl-autoinstall.sh
chmod +x pterodactyl-autoinstall.sh
./pterodactyl-autoinstall.sh
```

Gantilah `username` dengan akun GitHub kamu.

---

## 🌐 Akses Panel

Setelah selesai, buka browser dan akses:

```
http://IP-VPS-KAMU
```

Login admin:

- Email: `admin@pterodactyl.local`
- Password: `admin123`

> 📌 Kamu bisa mengubah email/password default di dalam script sebelum menjalankan.

---

## 📂 Struktur Direktori

| Path | Keterangan |
|------|------------|
| `/var/www/pterodactyl` | Panel Pterodactyl |
| `/etc/pterodactyl` | Konfigurasi Wings |
| `/usr/local/bin/wings` | Binary Wings |

---

## 📦 Service yang Digunakan

| Service | Port | Keterangan |
|---------|------|------------|
| NGINX (panel) | 80 | Untuk akses web panel |
| Wings (daemon) | 8080 | Untuk menjalankan server |
| SFTP | 2022 | Untuk upload file ke node |

---

## ❓ FAQ

### Q: Saya tidak punya domain, apakah bisa pakai script ini?
**A:** Bisa. Script ini memang dirancang untuk akses via IP.

### Q: Bagaimana jika ingin mengganti email/password admin?
**A:** Ubah variabel di bagian atas script:
```bash
ADMIN_EMAIL="..."
ADMIN_PASSWORD="..."
```

### Q: Apakah script ini bisa dijalankan di VPS RAM kecil?
**A:** Disarankan minimal 1.5 GB agar proses lancar.

---

## 🧑‍💻 Kontribusi

Pull Request sangat diterima untuk:
- Dukungan distro selain Ubuntu
- SSL otomatis
- Menu interaktif
- Versi self-hosted `.deb`

---

## 📜 Lisensi

Script ini open-source dan bebas digunakan untuk proyek pribadi maupun komersial.