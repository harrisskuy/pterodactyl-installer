# 🛠️ Pterodactyl Panel Auto-Installer (Tanpa Domain)

Script ini secara otomatis menginstal **Pterodactyl Panel** di Ubuntu 22.04 atau 24.04 **tanpa memerlukan domain** — cukup gunakan IP publik server kamu!

Cocok untuk penggunaan pribadi, internal, testing, atau yang belum memiliki domain.

---

## 🚀 Fitur

- ✅ Tanpa domain (akses via IP address)
- ✅ Instalasi otomatis NGINX, PHP, MariaDB, Redis, Composer
- ✅ Setup database & konfigurasi Laravel
- ✅ Membuat admin default
- ✅ Mengatur queue worker via systemd
- ✅ Konfigurasi NGINX otomatis

---

## 📦 Persyaratan

- Ubuntu 22.04 / 24.04 (fresh install disarankan)
- Akses `root` atau `sudo`
- IP publik yang bisa diakses (misalnya VPS)
- Minimal 2 GB RAM

---

## 📥 Cara Menggunakan

Jalankan perintah-perintah berikut di terminal server Ubuntu kamu:

```bash
# 1. Clone repositori ini
git clone https://github.com/harrisskuy/pterodactyl-installer.git

# 2. Masuk ke direktori script
cd pterodactyl-installer

# 3. Jadikan script executable
chmod +x install_pterodactyl.sh

# 4. Jalankan script sebagai root
sudo ./install_pterodactyl.sh
