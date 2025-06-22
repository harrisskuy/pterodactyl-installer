#!/bin/bash

# --------------- Konfigurasi Awal ---------------
DB_NAME="panel"
DB_USER="ptero"
DB_PASS="StrongPassword123"
PANEL_PATH="/var/www/pterodactyl"
LOG_FILE="/root/ptero-install.log"
IP=$(curl -s ifconfig.me)
PANEL_URL="http://${IP}"

# --------------- Warna Terminal ---------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

log() {
    echo -e "${BLUE}[INFO]${RESET} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
    echo "[OK] $1" >> "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}[ERROR]${RESET} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "Harus dijalankan sebagai root."
    fi
}

# --------------- Start Install ---------------
check_root
touch "$LOG_FILE"

log "Memperbarui sistem dan menginstal dependensi..."
apt update && apt upgrade -y >> "$LOG_FILE" 2>&1
apt install -y curl wget zip unzip git nginx mariadb-server php php-cli php-mbstring php-xml php-bcmath php-curl php-mysql php-tokenizer php-common php-gd php-zip php-fpm php-pdo composer redis-server php-redis >> "$LOG_FILE" 2>&1 || error_exit "Gagal install dependensi."

success "Dependensi berhasil diinstal."

log "Menyiapkan database..."
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" >> "$LOG_FILE"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" >> "$LOG_FILE"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';" >> "$LOG_FILE"
mysql -e "FLUSH PRIVILEGES;" >> "$LOG_FILE"
success "Database ${DB_NAME} berhasil dibuat."

log "Mengunduh dan menyiapkan Pterodactyl Panel..."
mkdir -p "$PANEL_PATH" && cd "$PANEL_PATH"
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz >> "$LOG_FILE" 2>&1
tar -xzvf panel.tar.gz >> "$LOG_FILE" 2>&1
rm panel.tar.gz
cp .env.example .env
composer install --no-dev --optimize-autoloader >> "$LOG_FILE" 2>&1
php artisan key:generate --force >> "$LOG_FILE"
success "Panel berhasil diunduh dan dikonfigurasi awal."

log "Mengatur environment panel..."
php artisan p:environment:setup --author="admin@example.com" --url="${PANEL_URL}" --timezone="Asia/Jakarta" --cache="redis" --session="file" --queue="sync" --force >> "$LOG_FILE"
php artisan p:environment:database --host="127.0.0.1" --port=3306 --database="${DB_NAME}" --username="${DB_USER}" --password="${DB_PASS}" --force >> "$LOG_FILE"
php artisan p:environment:mail --driver="smtp" --host="mail.example.com" --port=587 --username="noreply@example.com" --password="password" --encryption="tls" --from="noreply@example.com" --name="Pterodactyl Panel" --force >> "$LOG_FILE"
php artisan migrate --seed --force >> "$LOG_FILE"
php artisan storage:link >> "$LOG_FILE"

chown -R www-data:www-data "$PANEL_PATH"
chmod -R 755 "$PANEL_PATH/storage" "$PANEL_PATH/bootstrap/cache"
success "Environment dan database panel siap."

log "Mengatur konfigurasi Nginx..."
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
nginx -t >> "$LOG_FILE" 2>&1 && systemctl reload nginx
success "Nginx berhasil dikonfigurasi."

# --------------- Selesai ---------------
echo -e "\n${GREEN}✅ INSTALASI SELESAI!${RESET}"
echo -e "🌐 Panel dapat diakses di: ${YELLOW}${PANEL_URL}${RESET}"
echo -e "👤 Setelah itu jalankan: ${YELLOW}php artisan p:user:make${RESET} untuk membuat akun admin."
echo -e "📝 Log lengkap: ${LOG_FILE}"
