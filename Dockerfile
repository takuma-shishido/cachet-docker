FROM php:8.4-fpm-bookworm

EXPOSE 8000
CMD ["/sbin/entrypoint.sh"]

ARG cachet_ver=3.x
ARG archive_url=https://github.com/cachethq/cachet/archive/${cachet_ver}.tar.gz
ARG DEBIAN_FRONTEND=noninteractive

ENV CACHET_VERSION=${cachet_ver}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    default-mysql-client \
    git \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libpng-dev \
    libpq-dev \
    libsqlite3-dev \
    libxml2-dev \
    libzip-dev \
    nginx \
    postfix \
    postgresql-client \
    sqlite3 \
    sudo \
    supervisor \
    unzip \
    wget \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        curl \
        dom \
        gd \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        simplexml \
        soap \
        zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN useradd --uid 1001 --gid 0 --home-dir /var/www/html --shell /bin/bash cachet \
    && echo "cachet ALL=(ALL:ALL) NOPASSWD:SETENV: /usr/sbin/postfix" >> /etc/sudoers

WORKDIR /var/www/html

RUN wget -O /tmp/cachet.tar.gz "${archive_url}" \
    && tar xzf /tmp/cachet.tar.gz --strip-components=1 \
    && rm /tmp/cachet.tar.gz \
    && cp .env.example .env \
    && composer install --no-dev --optimize-autoloader \
    && composer config --json repositories.cachet-core '{"type":"vcs","url":"https://github.com/cachethq/core.git","no-api":true}' \
    && composer update cachethq/core --no-dev --with-dependencies --optimize-autoloader \
    && php artisan vendor:publish --tag=cachet --force \
    && if ! find database/migrations -name '*_create_jobs_table.php' | grep -q .; then \
        php artisan queue:table \
        && mv database/migrations/*_create_jobs_table.php database/migrations/0001_01_01_000002_create_jobs_table.php; \
    fi \
    && rm -rf bootstrap/cache/*

COPY conf/php-fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx-site.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /sbin/entrypoint.sh

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx /run/nginx \
    && chown -R cachet:root /var/www/html /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx /run/nginx \
    && chmod -R g+rwX /var/www/html /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx /run/nginx /usr/local/etc/php-fpm.d \
    && chmod +x /sbin/entrypoint.sh

USER 1001
