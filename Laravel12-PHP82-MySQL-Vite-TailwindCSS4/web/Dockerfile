FROM alpine:3.19

# Install Nginx, PHP 8.2, Supervisor, dan tools lainnya
# Kita tambahkan php82-session, php82-fileinfo, php82-tokenizer, dan php82-dom
RUN apk add --no-cache \
    nginx supervisor \
    php82-fpm php82-cli php82-mbstring php82-xml php82-bcmath php82-curl \
    php82-pdo_mysql php82-zip php82-gd php82-intl \
    php82-session php82-fileinfo php82-tokenizer php82-dom \
    composer nodejs npm bash git mariadb-client

# Symlink binary php
RUN ln -sf /usr/bin/php82 /usr/bin/php

# Di Alpine, paket nginx otomatis bikin user 'nginx'. Kita pakai itu aja biar nggak ribet.
# Set PHP-FPM jalan sebagai user nginx
RUN sed -i 's/user = nobody/user = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/group = nobody/group = nginx/g' /etc/php82/php-fpm.d/www.conf

WORKDIR /var/www/html

# Copy konfigurasi supervisor dan entrypoint
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
