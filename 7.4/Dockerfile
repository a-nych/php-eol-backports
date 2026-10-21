# php:7.4-fpm-bullseye with php/php-src@712e60f (CVE-2026-109618, CVE-2026-109619) applied.
# PHP 7.4 is EOL, so no upstream release or official image ships this fix.
FROM php:7.4-fpm-bullseye

# Debian bullseye is archived; deb.debian.org no longer serves it
RUN sed -i "s#deb.debian.org#archive.debian.org#g" /etc/apt/sources.list

COPY php-cve.patch /tmp/php-cve.patch

RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libargon2-dev \
        libcurl4-openssl-dev \
        libonig-dev \
        libreadline-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        patch \
        zlib1g-dev; \
    docker-php-source extract; \
    cd /usr/src/php; \
    patch -p1 < /tmp/php-cve.patch; \
    rm .docker-extracted; \
    # docker-php-ext-install in child images extracts this tarball, so it must carry the patch too
    tar -cJf /usr/src/php.tar.xz -C /usr/src php; \
    rm -f /usr/src/php.tar.xz.asc; \
    CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
        ./configure $(php-config --configure-options); \
    make -j"$(nproc)"; \
    make install; \
    find /usr/local -type f -perm '/0111' -exec sh -euxc 'strip --strip-all "$@" || :' -- '{}' +; \
    cd /; \
    docker-php-source delete; \
    rm /tmp/php-cve.patch; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    php -v; \
    php-fpm -t
