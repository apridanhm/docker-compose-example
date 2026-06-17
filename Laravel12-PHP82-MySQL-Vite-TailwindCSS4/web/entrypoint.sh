#!/bin/bash
set -e

echo "Menunggu database MySQL siap..."
while ! mysqladmin ping -h"db" -u"example_user" -p"password_strong" --silent; do
    sleep 2
done

cd /var/www/html

# 1. Buat .env jika belum ada
if [ ! -f .env ]; then
    echo "Membuat file .env dari .env.example..."
    cp .env.example .env
fi

# 2. PASTIKAN konfigurasi database benar
echo "Memastikan konfigurasi .env sesuai dengan Docker..."
sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
sed -i 's/DB_HOST=.*/DB_HOST=db/' .env
sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE=db_example/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=example_user/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=password_strong/' .env

# 3. HAPUS CACHE LAMA (INI KUNCINYA!)
# Agar Laravel terpaksa membaca ulang file .env yang baru kita ubah
echo "Membersihkan cache konfigurasi lama..."
rm -f bootstrap/cache/config.php
rm -f bootstrap/cache/routes.php
rm -f bootstrap/cache/services.php

# 4. Install Composer
if [ ! -d "vendor" ]; then
    echo "Menginstall dependensi PHP..."
    composer install --no-dev --optimize-autoloader
fi

# 5. Generate APP_KEY
if ! grep -q "APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate
fi

# 6. Install NPM & Build Frontend
if [ ! -d "node_modules" ]; then
    echo "Menginstall dependensi Node.js..."
    npm install
fi

if [ ! -d "public/build" ]; then
    echo "Building frontend assets (Vite)..."
    npm run build
fi

# 7. Storage link & direktori upload
if [ ! -L "public/storage" ]; then
    php artisan storage:link
fi
mkdir -p public/uploads/profile public/storage/alat-lab public/temp-msds storage/app/templates storage/app/private

# 8. Fix permissions
chown -R nginx:nginx /var/www/html
chmod -R 775 storage bootstrap/cache public/uploads public/storage

# 9. Migrate & Seed (Hanya jalan sekali)
if [ ! -f ".migrated" ]; then
    echo "Menjalankan migrasi database dan seeder..."
    php artisan migrate --force
    php artisan db:seed --force
    touch .migrated
fi

# 10. Optimasi Production (Setelah semua beres)
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Setup selesai! Menjalankan Supervisor (Nginx + PHP-FPM)..."
exec "$@"
