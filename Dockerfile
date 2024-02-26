FROM ubuntu:22.04

ARG PTERODACTYL_VERSION=v1.11.5
ARG S6_OVERLAY_VERSION=v3.1.6.2

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

RUN    apt-get update \
    && apt-get -y install software-properties-common curl apt-transport-https ca-certificates gnupg cron

RUN    add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get -y install php8.1 php8.1-cli php8.1-gd php8.1-mysql php8.1-pdo php8.1-mbstring php8.1-tokenizer php8.1-bcmath php8.1-xml php8.1-fpm php8.1-curl php8.1-zip nginx tar unzip git

RUN    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN    f="" \
    ;  case "$(uname -s).$(uname -m)" in \
        Linux.x86_64)  f="s6-overlay-x86_64"   ;; \
	Linux.aarch64) f="s6-overlay-aarch64" ;; \
	*) echo ">>> Unsupported plaform $(uname -s).$(uname -m)"; exit 1 ;; \
       esac \
    ;  curl -s -L -o /s6-overlay-arch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/${f}.tar.xz \
    && curl -s -L -o /s6-overlay-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /s6-overlay-arch.tar.xz \
    && rm /s6-overlay-noarch.tar.xz /s6-overlay-arch.tar.xz

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
RUN    sed -i '/^listen\s\+=/s#/run/php/#/tmp/php/#' /etc/php/8.1/fpm/pool.d/www.conf \
    && sed -i '/^pid\s\+=/s#/run/php/#/tmp/php/#' /etc/php/8.1/fpm/php-fpm.conf

COPY ./cron/ptero /etc/cron.d/ptero

COPY ./nginx/nginx.conf /etc/nginx/
COPY ./nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-enabled/
COPY ./cont-init.d/app-init /etc/cont-init.d/
COPY ./cont-init.d/tmpfiles /etc/cont-init.d/
COPY ./svc/crond-run /etc/services.d/crond/run
COPY ./svc/nginx-run /etc/services.d/nginx/run
COPY ./svc/php8.1-fpm-run /etc/services.d/php-fpm8.1/run
COPY ./svc/ptero-queue-worker-run /etc/services.d/ptero-queue-worker/run
COPY ./scripts/make_user /usr/local/bin/

VOLUME /config
VOLUME /data

ENV S6_READ_ONLY_ROOT=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/command"

ENTRYPOINT ["/init"]
