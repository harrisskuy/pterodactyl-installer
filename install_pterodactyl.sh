#!/bin/bash

# ==============================
# 🛠️  PTERODACTYL PANEL INSTALLER - PRO EDITION
# ==============================
# 📦 OS: Ubuntu 20.04 / 22.04 (root)
# 🔗 Akses: http://<IP_KAMU>
# 👤 Admin Otomatis: admin@example.com / Admin123!
# ==============================

# ====== 🔧 KONFIGURASI ======
DB_NAME="panel"
DB_USER="ptero"
DB_PASS="StrongPassword123"
ADMIN_EMAIL="admin@example.com"
ADMIN_USER="admin"
ADMIN_NAME="Admin"
ADMIN_PASS="Admin123!"
PANEL_PATH="/var/www/pterodactyl"
LOG_FILE="/root/ptero-install.log"
IP=$(curl -s ifconfig.me)
PANEL_URL="http://${IP}"

# ====== 🎨 WARNA ======
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

# ====== 🧠 FUNGSI BANTUAN ======
log() { echo -e "${BLUE}[INFO]${RESET} $1"; echo "[INFO] $1" >> "$LOG_FILE"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; echo "[OK] $1" >> "$LOG_FILE"; }
error_exit() { echo -e "${RED}[ERROR]${RESET} $1"; echo "[ERROR] $1" >> "$LOG_FILE"; exit 1; }

# ====== ⚠️ CEK ROOT ======
[[ $EUID -ne 0 ]] && error_exit "Script harus dijalankan sebagai root."

touch "$LOG_FILE"
clear
echo -e "${YELLOW}🚀 Memulai instalasi Pterodactyl Panel - PRO Edition...${RESET}"

# ====== 1. UPDATE DAN INSTALL DEPENDENSI ======
log "Update system & install paket..."
apt update && apt upgrade -y >> "$LOG_FILE"
apt install -y curl wget zip unzip git nginx mariadb-server php php-cli php-mbstring php-xml php-bcmath php-curl php-mysql php-tokenizer php-common php-gd php-zip php-fpm php-pdo composer redis-server php-redis >> "$LOG_FILE" || error_exit "Gagal install paket."
success "Semua dependensi terinstal."

# ====== 2. SETUP DATABASE ======
log "Menyiapkan database..."
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"
success "Database '${DB_NAME}' siap digunakan."

# ====== 3. INSTALL PANEL ======
log "Mengunduh dan menginstal Pterodactyl Panel..."
mkdir -p "$PANEL_PATH" && cd "$PANEL_PATH"
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz >> "$LOG_FILE"
tar -xzvf panel.tar.gz >> "$LOG_FILE"
rm panel.tar.gz
cp .env.example .env
composer install --no-dev --optimize-autoloader >> "$LOG_FILE"
php artisan key:generate --force >> "$LOG_FILE"
success "Panel berhasil diunduh dan dikonfigurasi awal."

# ====== 4. KONFIGURASI ENV ======
log "Mengatur konfigurasi environment..."
php artisan p:environment:setup --author="${ADMIN_EMAIL}" --url="${PANEL_URL}" --timezone="Asia/Jakarta" --cache="redis" --session="file" --queue="sync" --force >> "$LOG_FILE"
php artisan p:environment:database --host="127.0.0.1" --port=3306 --database="${DB_NAME}" --username="${DB_USER}" --password="${DB_PASS}" --force >> "$LOG_FILE"
php artisan p:environment:mail --driver="smtp" --host="mail.example.com" --port=587 --username="noreply@example.com" --password="password" --encryption="tls" --from="noreply@example.com" --name="Pterodactyl Panel" --force >> "$LOG_FILE"
php artisan migrate --seed --force >> "$LOG_FILE"
php artisan storage:link >> "$LOG_FILE"
success "Konfigurasi environment selesai."

# ====== 5. IZIN FILE ======
chown -R www-data:www-data "$PANEL_PATH"
chmod -R 755 "$PANEL_PATH/storage" "$PANEL_PATH/bootstrap/cache"
success "Permission file OK."

# ====== 6. KONFIGURASI NGINX ======
log "Membuat konfigurasi Nginx..."
cat > /etc/nginx/sites-available/pterodactyl <<EOF
server {
    listen 80;
    server_name _;

    root ${PANEL_PATH}/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log /var/log/nginx/pterodactyl.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/ || true
nginx -t >> "$LOG_FILE" && systemctl reload nginx
success "Nginx dikonfigurasi dan aktif."

# ====== 7. ADMIN AUTO CREATE ======
log "Membuat akun admin default..."
php artisan p:user:make --email="${ADMIN_EMAIL}" --username="${ADMIN_USER}" --name="${ADMIN_NAME}" --password="${ADMIN_PASS}" --admin=1 >> "$LOG_FILE"
success "Akun admin dibuat (${ADMIN_EMAIL} / ${ADMIN_PASS})."

# ====== ✅ DONE ======
echo -e "\n${GREEN}✅ INSTALASI SELESAI!${RESET}"
echo -e "🌐 Panel tersedia di: ${YELLOW}${PANEL_URL}${RESET}"
echo -e "👤 Login Admin: ${YELLOW}${ADMIN_EMAIL}${RESET} / ${YELLOW}${ADMIN_PASS}${RESET}"
echo -e "📝 Log lengkap: ${LOG_FILE}\n"
