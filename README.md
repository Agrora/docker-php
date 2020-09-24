agrora/php
==========

An opinionated PHP development and production container with Nginx support.

## What does it contain?

- PHP 7.4.10 or 8.0-rc
- PHP Extensions: imagick, amqp, gd, intl, pdo_mysql, zip, soap, bcmath
- Composer
- Dev Build contains pre-configured XDebug
- Nginx Build contains FPM-Nginx Chain via Supervisor (similar to php-apache, but with nginx)

## Configurations

Multiple tags are available that provide different feature sets.

### latest, cli, 7-cli, 8-cli

Contains only PHP and the extensions.
Good to run PHP-based processes in isolated containers.

```bash
$ docker run agrora/php php -i
# Prints the PHP Info of the container
```

### cli-dev, 7-cli-dev, 8-cli-dev

Contains only PHP and the extensions including XDebug.
Good to develop PHP-based processes in isolated containers.

```bash
$ docker run agrora/php:cli-dev php -i | grep xdebug
/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini,
xdebug
xdebug support => enabled
...
```

### fpm, 7-fpm, 8-fpm

Contains PHP, the extensions and PHP-FPM.
Good to run PHP applications behind a reverse proxy or any FastCGI.

```bash
$ docker run -p 9000:9000 agrora/php:fpm
```

### fpm-dev, 7-fpm-dev, 8-fpm-dev

Contains PHP, the extensions including XDebug and PHP-FPM on port 9000.
Good to develop PHP applications behind a reverse proxy or any FastCGI.

```bash
$ docker run -p 9000:9000 agrora/php:fpm-dev
```

### fpm-nginx, 7-fpm-nginx, 8-fpm-nginx

Contains PHP, the extensions and Supervisor which manages
Nginx and PHP-FPM

```bash
$ docker run -p 8080:8080 -v .:/var/www/html agrora/php:fpm-nginx
```

The Nginx uses a Lua Plugin to make itself configurable
easily via environment variables

```bash
$ docker run \
    -p 8080:8080 \
    -v .:/your/own/root \
    -e DOCUMENT_ROOT=/your/own/root
    -e CORS_ALLOWED_METHODS=GET,POST
    -e CORS_ALLOWED_HEADERS=X-Custom-Header
    agrora/php:fpm-nginx
```

As Nginx doesn't forward OPTIONS requests, it handles them itself and
always returns the request origin as an allowed origin.

If you want true CORS protection, use a reverse proxy in front of
the Nginx that handles CORS headers.

Alternatively you could overwrite the Nginx Configuration file
or add an own one yourself. Either overwrite `/etc/nginx/nginx.conf`
or add a `/etc/nginx/conf.d/your-own.conf`.

Good to deploy front-facing PHP web applications.

### fpm-nginx-dev, 7-fpm-nginx-dev, 8-fpm-nginx-dev

Same as the fpm-nginx container, but with enabled XDebug.
Good to develop front-facing PHP web applications.
