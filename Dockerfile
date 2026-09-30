FROM gitea.okami101.io/okami101/frankenphp:8.5

ARG USER=www-data

RUN \
    useradd ${USER}; \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
    chown -R ${USER}:${USER} /config/caddy /data/caddy; \
    chown -R ${USER}:${USER} /app

USER ${USER}

ENV APP_ENV=prod

WORKDIR /app

COPY --chown=${USER}:${USER} app app/
COPY --chown=${USER}:${USER} config config/
COPY --chown=${USER}:${USER} database database/
COPY --chown=${USER}:${USER} resources resources/
COPY --chown=${USER}:${USER} public public/
COPY --chown=${USER}:${USER} bootstrap bootstrap/
COPY --chown=${USER}:${USER} storage storage/
COPY --chown=${USER}:${USER} artisan composer.json composer.lock ./

RUN \
    composer install --no-dev --optimize-autoloader && \
    php artisan storage:link && \
    php artisan route:cache && \
    php artisan view:cache

CMD ["frankenphp", "php-server", "-r", "public/", "--listen=:8000"]