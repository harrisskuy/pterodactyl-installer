#!/bin/bash

set -e

### KONFIGURASI
PANEL_DB="panel"
PANEL_DB_USER="ptero"
PANEL_DB_PASS="passwordku123"
PANEL_DIR="/var/www/pterodactyl"
PHP_VERSION="8.1"

echo "🔧 Memperbarui sistem..."
apt update && apt upgrade -y

echo "📦 Menginstall dependensi..."
apt install -y nginx mariadb-server redis-server unzip curl git tar \
    php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-gd php$PHP_VERSION-mysql \
    php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-bcmath \
    php$PHP_VERSION-zip php$PHP_VERSION-fpm php$PHP_VERSION-redis

echo "📦 Menginstall Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "🛠️ Mengkonfigurasi database..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $PANEL_DB;
CREATE USER '$PANEL_DB_USER'@'127.0.0.1' IDENTIFIED BY '$PANEL_DB_PASS';
GRANT ALL PRIVILEGES ON $PANEL_DB.* TO '$PANEL_DB_USER'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "📁 Mengunduh dan mengekstrak Pterodactyl Panel..."
mkdir -p $PANEL_DIR
cd $PANEL_DIR
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chown -R www-data:www-data $PANEL_DIR

echo "📦 Menginstall dependensi Laravel..."
composer install --no-dev --optimize-autoloader

cp .env.example .env

echo "⚙️ Mengatur environment file..."
php artisan key:generate --force

php artisan p:environment:setup <<EOF
http
$(hostname -I | awk '{print $1}')
EOF

php artisan p:environment:database <<EOF
127.0.0.1
3306
$PANEL_DB
$PANEL_DB_USER
$PANEL_DB_PASS
EOF

php artisan migrate --seed --force

echo "✅ Membuat user admin..."
php artisan p:user:make --email admin@example.com --username admin --name "Admin" --password "admin123" --admin=1

echo "🗂️ Mengatur izin file..."
chown -R www-data:www-data $PANEL_DIR/*
chmod -R 755 $PANEL_DIR/storage $PANEL_DIR/bootstrap/cache

echo "⚙️ Membuat konfigurasi NGINX..."
cat > /etc/nginx/sites-available/pterodactyl <<EOF
server {
    listen 80;
    server_name $(hostname -I | awk '{print $1}');

    root $PANEL_DIR/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log /var/log/nginx/pterodactyl.error.log error;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "🕒 Menambahkan cron untuk Laravel scheduler..."
(crontab -l ; echo "* * * * * cd $PANEL_DIR && php artisan schedule:run >> /dev/null 2>&1") | crontab -

echo "⚙️ Membuat systemd service untuk queue worker..."
cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php $PANEL_DIR/artisan queue:work --queue=high,default --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pteroq.service

echo "🎉 Instalasi selesai!"
echo "💻 Akses Panel di: http://$(hostname -I | awk '{print $1}')"
echo "🔐 Login sebagai: admin@example.com / admin123"
