# Build Args (pass to docker build with --build-arg=ARG_NAME=arg_value)
ARG PHP_VERSION=7.4.10
ARG APP_ENV=dev
ARG SERVICE_TYPE=cli
ARG DOCUMENT_ROOT
ARG CORS_ALLOWED_METHODS
ARG CORS_ALLOWED_HEADERS

FROM scratch

MAINTAINER Torben Köhn <t.koehn@outlook.com>

# Stage 1: Select base images for SERVICE_TYPE
FROM php:${PHP_VERSION}-buster AS php-cli

FROM php:${PHP_VERSION}-fpm-buster AS php-fpm
ONBUILD COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf

FROM php-fpm AS php-fpm-nginx

# Stage 2: Install dependencies and configs for APP_ENV
FROM php-${SERVICE_TYPE} AS build-production
# - Install PHP and PHP Extension related dependencies
ONBUILD RUN apt-get update && apt-get install -y \
    gnupg curl sudo python git mariadb-client zip unzip p7zip \
    libmcrypt-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
    libmagickwand-dev imagemagick ghostscript libzip-dev \
    librabbitmq-dev libssh-dev libxml2-dev libonig-dev \
    zlib1g-dev libicu-dev g++ graphviz \
    --no-install-recommends
# - Install common PHP Extensions
ONBUILD RUN docker-php-ext-configure gd && \
    pecl install imagick amqp && \
    docker-php-ext-configure gd && \
    docker-php-ext-configure intl && \
    docker-php-ext-enable imagick amqp && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install intl pdo_mysql zip soap bcmath && \
    docker-php-source delete
# - Install Composer
ONBUILD RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer
# - Configure PHP and Imagick
ONBUILD COPY config/php.ini /usr/local/etc/php/conf.d/00-app.ini
ONBUILD COPY config/imagick-policy.xml /etc/ImageMagick-6/policy.xml

FROM build-production AS build-dev
# - Install XDebug Extension
ONBUILD RUN  pecl install xdebug && \
    docker-php-ext-enable xdebug
# - Configure XDebug
ONBUILD COPY config/php-dev.ini /usr/local/etc/php/conf.d/10-app-dev.ini

# Stage 3: Install and configure Nginx+Supervisor for SERVICE_TYPE
FROM build-${APP_ENV} AS service-cli

FROM build-${APP_ENV} AS service-fpm

FROM build-${APP_ENV} AS service-fpm-nginx
ENV DOCUMENT_ROOT ${DOCUMENT_ROOT:-/var/www/html}
ENV CORS_ALLOWED_METHODS ${CORS_ALLOWED_METHODS:-GET,POST,PUT,PATCH,DELETE,OPTIONS}
ENV CORS_ALLOWED_HEADERS ${CORS_ALLOWED_HEADERS:-DNT,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization}

# - Install Nginx and Supervisor
ONBUILD RUN apt-get install -y nginx libnginx-mod-http-ndk libnginx-mod-http-lua supervisor

# - Configure Nginx
ONBUILD COPY config/nginx.conf /etc/nginx/nginx.conf

# - Configure Supervisor
ONBUILD COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# - Let all services run as user www-data
ONBUILD RUN mkdir -p /var/www/html
ONBUILD RUN chown -R www-data:www-data /var/www/html && \
  chown -R www-data:www-data /run && \
  chown -R www-data:www-data /var/lib/nginx && \
  chown -R www-data:www-data /var/log/nginx

ONBUILD USER www-data

# - Expose Nginx
ONBUILD WORKDIR ${DOCUMENT_ROOT}
ONBUILD EXPOSE 8080
ONBUILD CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# - Configure health check
ONBUILD HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

# Stage 4: Buld the final image
FROM service-${SERVICE_TYPE}
