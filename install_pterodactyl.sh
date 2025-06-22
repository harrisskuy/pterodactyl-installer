#!/bin/bash

# ==================== PENGATURAN ====================
ADMIN_EMAIL="admin@pterodactyl.local"
ADMIN_PASSWORD="admin123"
ADMIN_NAME="Admin Ptero"
NODE_NAME="Node 1"
NODE_LOCATION="Indonesia"
NODE_FQDN=$(curl -s ipinfo.io/ip)
DB_PASS="passwordku"
# ===================================================

# Warna & log simbol
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

function info() {
  echo -e "${BLUE}===================={ 🔧 $1 }====================${RESET}"
}
function success() {
  echo -e "${GREEN}✅ $1${RESET}"
}
function error() {
  echo -e "${RED}❌ $1${RESET}"
}

info "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y
success "Sistem berhasil diperbarui."

info "Menginstal dependensi dasar..."
sudo apt install -y curl wget unzip tar git gnupg nginx mysql-server > /dev/null
success "Dependensi dasar terinstal."

info "Menambahkan PPA PHP dan menginstal PHP 8.1..."
sudo add-apt-repository ppa:ondrej/php -y && sudo apt update
sudo apt install -y php8.1-cli php8.1-fpm php8.1-mysql php8.1-zip php8.1-bcmath php8.1-curl php8.1-mbstring php8.1-xml php8.1-gd php8.1-intl php8.1-readline php8.1-soap php8.1-redis > /dev/null
success "PHP 8.1 dan ekstensi berhasil diinstal."

info "Menginstal Composer..."
curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
success "Composer berhasil diinstal."

info "Membuat database MySQL untuk Pterodactyl..."
sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';"
sudo mysql -e "FLUSH PRIVILEGES;"
success "Database dan user MySQL berhasil dibuat."

info "Mengunduh dan menyiapkan panel Pterodactyl..."
cd /var/www/
sudo mkdir -p pterodactyl && sudo chown -R $USER:$USER pterodactyl
cd pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
sed -i "s/DB_DATABASE=.*/DB_DATABASE=panel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
success "Panel berhasil disiapkan."

info "Migrasi dan seeding database..."
php artisan migrate --seed --force
success "Migrasi database selesai."

info "Membuat user admin panel..."
php artisan p:user:make --email="$ADMIN_EMAIL" --username="admin" --name="$ADMIN_NAME" --password="$ADMIN_PASSWORD" --admin=1 --no-interaction
success "Admin berhasil dibuat."

info "Menyiapkan konfigurasi NGINX (tanpa domain)..."
sudo tee /etc/nginx/sites-available/pterodactyl >/dev/null <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
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

sudo ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
sudo systemctl restart nginx php8.1-fpm
success "NGINX dikonfigurasi dan direstart."

info "Menginstal Docker dan Wings..."
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
sudo systemctl enable --now docker
sudo mkdir -p /etc/pterodactyl
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings
success "Docker & Wings terinstal."

info "Membuat konfigurasi Wings..."
cat <<EOF | sudo tee /etc/pterodactyl/config.yml >/dev/null
debug: false
uuid: "$(cat /proc/sys/kernel/random/uuid)"
token_id: "$(cat /proc/sys/kernel/random/uuid)"
token: "$(cat /proc/sys/kernel/random/uuid)"
api:
  host: 0.0.0.0
  port: 8080
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_address: 0.0.0.0
    port: 2022
  allow_offline_installations: true
  enable_unprivileged_userns_clone: true
EOF

info "Menambahkan service systemd untuk Wings..."
sudo tee /etc/systemd/system/wings.service >/dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now wings
success "Wings berhasil dijalankan."

# 🎉 Penutup
IP=$(curl -s ipinfo.io/ip)
echo -e "\n${GREEN}🎉 INSTALASI SELESAI!${RESET}"
echo -e "${YELLOW}🌐 Akses Panel: http://$IP"
echo -e "👤 Login Admin:"
echo -e "   Email: $ADMIN_EMAIL"
echo -e "   Password: $ADMIN_PASSWORD${RESET}"
echo -e "${YELLOW}📦 Wings aktif di port 8080, SFTP di port 2022${RESET}"
