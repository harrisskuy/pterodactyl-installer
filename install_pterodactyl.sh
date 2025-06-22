#!/bin/bash

# ========== KONFIGURASI ==========
DB_PASSWORD="ptero123"
PANEL_ADMIN_EMAIL="admin@localhost.com"
PANEL_ADMIN_USER="admin"
PANEL_ADMIN_PASSWORD="admin123"
PTERO_VERSION="v1.11.4"
IP_ADDR=$(curl -s ifconfig.me)

# ========== PREPARE ==========
apt update && apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git

# ========== INSTALL PHP 8.1 & LOCK ==========
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.1 php8.1-{cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} nginx mariadb-server redis-server

# Lock PHP 8.1
apt-mark hold php8.1 php8.1-* 

# ========== DATABASE ==========
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE panel;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# ========== INSTALL PANEL ==========
cd /var/www/
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/${PTERO_VERSION}/panel.tar.gz
mkdir -p /var/www/pterodactyl
tar -xzvf panel.tar.gz -C /var/www/pterodactyl
cd /var/www/pterodactyl
cp .env.example .env

# ========== COMPOSER ==========
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
composer install --no-dev --optimize-autoloader

# ========== SETUP ENV ==========
sed -i "s|APP_URL=.*|APP_URL=http://${IP_ADDR}|g" .env

php artisan key:generate --force
php artisan migrate --seed --force
php artisan p:environment:setup -n
php artisan p:environment:database -n

php artisan p:user:make \
  --email="${PANEL_ADMIN_EMAIL}" \
  --username="${PANEL_ADMIN_USER}" \
  --name="Admin" \
  --password="${PANEL_ADMIN_PASSWORD}" \
  --admin=1

# ========== PERMISSIONS ==========
chown -R www-data:www-data /var/www/pterodactyl/*
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache

# ========== NGINX CONFIG ==========
cat <<EOF > /etc/nginx/sites-available/pterodactyl
server {
    listen 80;
    server_name ${IP_ADDR};

    root /var/www/pterodactyl/public;
    index index.php index.html;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log /var/log/nginx/pterodactyl.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# ========== DONE ==========
clear
echo "==============================================="
echo "✅ Pterodactyl Panel v${PTERO_VERSION} Installed"
echo "🌐 Akses via: http://${IP_ADDR}"
echo "👤 Username: ${PANEL_ADMIN_USER}"
echo "📧 Email: ${PANEL_ADMIN_EMAIL}"
echo "🔐 Password: ${PANEL_ADMIN_PASSWORD}"
echo "📌 Credit: t.me/harrisskuy"
echo "==============================================="
