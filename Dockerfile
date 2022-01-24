FROM ubuntu:20.04

ARG PTERODACTYL_VERSION=v1.7.0
ARG S6_OVERLAY_VERSION=v2.2.0.3

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

RUN    apt-get update \
    && apt-get -y install software-properties-common curl apt-transport-https ca-certificates gnupg cron

RUN    add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get -y install php8.0 php8.0-cli php8.0-gd php8.0-mysql php8.0-pdo php8.0-mbstring php8.0-tokenizer php8.0-bcmath php8.0-xml php8.0-fpm php8.0-curl php8.0-zip nginx tar unzip git

RUN    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN    f="" \
    ;  case "$(uname -s).$(uname -m)" in \
        Linux.x86_64)  f="s6-overlay-amd64-installer"   ;; \
	Linux.aarch64) f="s6-overlay-aarch64-installer" ;; \
	*) echo ">>> Unsupported plaform $(uname -s).$(uname -m)"; exit 1 ;; \
       esac \
    ;  curl -s -L -o /s6-overlay-installer https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/${f} \
    && chmod +x /s6-overlay-installer \
    && /s6-overlay-installer / \
    && rm /s6-overlay-installer

RUN    mkdir -p /var/www/pterodactyl \
    && cd /var/www/pterodactyl \
    && curl -s -L -o panel.tar.gz https://github.com/pterodactyl/panel/releases/download/${PTERODACTYL_VERSION}/panel.tar.gz \
    && tar -xzf panel.tar.gz \
    && chmod -R 755 storage/* bootstrap/cache/ \
    && rm panel.tar.gz \
    && composer install --no-dev --optimize-autoloader --no-interaction --quiet

RUN    cd /var/www/pterodactyl \
    && rm -rf storage \
    && rm -rf bootstrap/cache \
    && ln -s /data/storage storage \
    && ln -s /data/bootstrap/cache bootstrap/cache \
    && ln -s /config/env .env

RUN    rm /etc/nginx/nginx.conf /etc/nginx/sites-enabled/*
RUN    sed -i '/^listen\s\+=/s#/run/php/#/tmp/php/#' /etc/php/8.0/fpm/pool.d/www.conf \
    && sed -i '/^pid\s\+=/s#/run/php/#/tmp/php/#' /etc/php/8.0/fpm/php-fpm.conf

COPY ./cron/ptero /etc/cron.d/ptero

COPY ./nginx/nginx.conf /etc/nginx/
COPY ./nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-enabled/
COPY ./cont-init.d/app-init /etc/cont-init.d/
COPY ./cont-init.d/tmpfiles /etc/cont-init.d/
COPY ./svc/crond-run /etc/services.d/crond/run
COPY ./svc/nginx-run /etc/services.d/nginx/run
COPY ./svc/php8.0-fpm-run /etc/services.d/php-fpm8.0/run
COPY ./svc/ptero-queue-worker-run /etc/services.d/ptero-queue-worker/run
COPY ./scripts/make_user /usr/local/bin/

VOLUME /config
VOLUME /data

ENV S6_READ_ONLY_ROOT=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ENTRYPOINT ["/init"]
