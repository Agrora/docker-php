agrora/php
==========

An opinionated PHP development and production container with Nginx support.

## What does it contain?

- PHP 7.4.10
- PHP Extensions: imagick, amqp, gd, intl, pdo_mysql, zip, soap, bcmath
- Composer
- Dev Build contains pre-configured XDebug
- Nginx Build contains FPM-Nginx Chain via Supervisor (similar to php-apache, but with nginx)

## Configurations

Multiple tags are available that provide different feature sets.

### latest, cli, 7-cli

Contains only PHP and the extensions.
Good to run PHP-based processes in isolated containers.

```bash
$ docker run agrora/php php -i
# Prints the PHP Info of the container
```

### cli-dev, 7-cli-dev

Contains only PHP and the extensions including XDebug.
Good to develop PHP-based processes in isolated containers.

```bash
$ docker run agrora/php:cli-dev php -i | grep xdebug
/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini,
xdebug
xdebug support => enabled
...
```

### fpm, 7-fpm

Contains PHP, the extensions and PHP-FPM.
Good to run PHP applications behind a reverse proxy or any FastCGI.

```bash
$ docker run -p 9000:9000 agrora/php:fpm
```

### fpm-dev, 7-fpm-dev

Contains PHP, the extensions including XDebug and PHP-FPM on port 9000.
Good to develop PHP applications behind a reverse proxy or any FastCGI.

```bash
$ docker run -p 9000:9000 agrora/php:fpm-dev
```

### fpm-nginx, 7-fpm-nginx

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
    -e FALLBACK_ROUTER_PATH=route-404.php
    agrora/php:fpm-nginx
```

Environment-Variables:
- `DOCUMENT_ROOT`

   (Default: `/var/www/html`)

   The folder Nginx serves files from. If possible, don't point
   this directly to your PHP sources, but to a folder
   containing only the front-controller file.
   
   You can, however, also serve unusual PHP applications like WordPress.
- `CORS_ALLOWED_METHODS`
   
   (Default: `GET,POST,PUT,PATCH,DELETE`)

   The HTTP Methods to allow for CORS requests
- `CORS_ALLOWED_HEADERS`
   
   (Default: `DNT,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization`)
   
   The inbound allowed HTTP headers for CORS requests
- `FALLBACK_ROUTER_PATH`

   (Default: `index.php`)

   A PHP file path that will handle requests that couldn't be resolved to a file.
   
   By default, the index.php will always be the Front Router, similar
   to how most frameworks work.
   
   You can also turn the request into a query string with this
   by using `index.php?request=` as a value. That way
   you can retrieve the request uri info in a `request`-query value

As Nginx doesn't forward OPTIONS requests, it handles them itself and
always returns the request origin as an allowed origin.

**If you want true, custom CORS protection, use a reverse proxy in front of
the Nginx that handles CORS headers.**

Alternatively you could overwrite the Nginx Configuration file
or add an own one yourself. Either overwrite `/etc/nginx/nginx.conf`
or add a `/etc/nginx/conf.d/your-own.conf`.

Since Lua is enabled, you can also control CORS logic via Lua.

Good to deploy front-facing PHP web applications.

### fpm-nginx-dev, 7-fpm-nginx-dev

Same as the fpm-nginx container, but with enabled XDebug.
Good to develop front-facing PHP web applications.
