# Rebuilds an official php:<version>-<variant>-<debian> image with patches/<version>/series applied.
# Build context is the repo root: --build-arg BASE=php:7.4-fpm-bullseye --build-arg PHP_VERSION=7.4
ARG BASE
FROM ${BASE}

# Debian releases before bookworm are only served from archive.debian.org.
# Left in place so apt-get works in child images.
RUN set -eux; \
    if grep -qsE '\b(buster|bullseye)\b' /etc/apt/sources.list; then \
        sed -i -e 's#//deb.debian.org#//archive.debian.org#; s#//security.debian.org#//archive.debian.org#' -e '/-updates/d' /etc/apt/sources.list; \
        echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive; \
    fi

ARG PHP_VERSION
COPY patches/${PHP_VERSION} /tmp/patches

RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    if php-config --configure-options | grep -q apxs2; then apache=apache2-dev; else apache=; fi; \
    apt-get install -y --no-install-recommends \
        $apache \
        libargon2-dev \
        libcurl4-openssl-dev \
        libedit-dev \
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
    while read -r p flags; do patch -p1 --batch -s $flags < "/tmp/patches/$p"; done < /tmp/patches/series; \
    rm .docker-extracted; \
    # docker-php-ext-install in child images extracts this tarball, so it must carry the patches too
    tar -cJf /usr/src/php.tar.xz -C /usr/src php; \
    rm -f /usr/src/php.tar.xz.asc; \
    # PEAR is already installed; --with-pear would re-download it from pear.php.net
    CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
        ./configure $(php-config --configure-options | sed 's/--with-pear//'); \
    make -j"$(nproc)"; \
    make install; \
    find /usr/local -type f -perm '/0111' -exec sh -euxc 'strip --strip-all "$@" || :' -- '{}' +; \
    cd /; \
    docker-php-source delete; \
    rm -rf /tmp/patches; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    php -v; \
    if command -v php-fpm; then php-fpm -t; fi; \
    # Running out of memory exits 1 with the fix, 255 without it
    rc=0; php -d memory_limit=2M -r 'str_repeat("a", 10485760);' > /dev/null 2>&1 || rc=$?; \
    test "$rc" -eq 1
