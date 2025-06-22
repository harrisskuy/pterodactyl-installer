#!/bin/bash

# ============================
#  Pelican Panel PRO Installer
# ============================

set -euo pipefail

### ====[ COLOR LOGGING ]====
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

### ====[ CHECK ROOT & OS ]====
[ "$(id -u)" -ne 0 ] && log_err "Jalankan script ini sebagai root (sudo)."
[[ "$(lsb_release -is)" != "Ubuntu" ]] && log_err "Script hanya mendukung Ubuntu."

### ====[ VARIABEL DASAR ]====
INSTALL_DIR="/var/www/pelican"
DB_NAME="pelican"
DB_USER="pelicanuser"
DB_PASS="passwordku"
PHP_VERSION="8.1"

PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

### ====[ LANGKAH 1: Update & Dependencies ]====
log_info "Mengupdate sistem & menginstal dependencies..."
apt update && apt upgrade -y
apt install -y curl git unzip nginx mariadb-server php php-cli php-mbstring php-curl php-xml php-mysql php-zip php-bcmath php-gd php-tokenizer composer php-fpm docker.io docker-compose
log_ok "Dependencies lengkap."

### ====[ LANGKAH 2: Setup Database ]====
log_info "Menyiapkan database MariaDB..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
log_ok "Database siap digunakan."

### ====[ LANGKAH 3: Clone Project ]====
if [ -d "$INSTALL_DIR" ]; then
    log_warn "Direktori $INSTALL_DIR sudah ada, melewati clone."
else
    log_info "Meng-clone Pelican Panel..."
    git clone https://github.com/pelican-dev/panel.git "$INSTALL_DIR"
    log_ok "Clone selesai."
fi
cd "$INSTALL_DIR"

### ====[ LANGKAH 4: Setup Laravel Project ]====
log_info "Menyiapkan Laravel..."
composer install --no-interaction --prefer-dist
cp -n .env.example .env
php artisan key:generate

sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
sed -i "s|APP_URL=.*|APP_URL=http://$PUBLIC_IP|" .env

php artisan migrate --seed --force
log_ok "Laravel siap."

### ====[ LANGKAH 5: Auto Create Admin User ]====
log_info "Membuat akun admin default..."
php artisan tinker --execute="
use App\Models\User;
if (!User::where('email', 'admin@localhost.com')->exists()) {
    User::create([
        'name' => 'Admin',
        'email' => 'admin@localhost.com',
        'password' => bcrypt('admin123'),
        'email_verified_at' => now(),
        'admin' => true,
    ]);
}
"
log_ok "Akun admin dibuat: admin@localhost.com / admin123"

### ====[ LANGKAH 6: Konfigurasi NGINX ]====
log_info "Mengonfigurasi NGINX..."
cat > /etc/nginx/sites-available/pelican <<EOF
server {
    listen 80;
    server_name _;

    root $INSTALL_DIR/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pelican /etc/nginx/sites-enabled/pelican
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
log_ok "NGINX aktif di http://$PUBLIC_IP"

### ====[ DONE ]====
log_ok "Pelican Panel berhasil diinstal!"
echo -e "${YELLOW}Akses sekarang: ${NC}http://$PUBLIC_IP"
echo -e "${YELLOW}Login Admin: ${NC}admin@localhost.com / admin123"
