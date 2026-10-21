# Rebuilds an official php:<version>-<variant>-alpine<release> image with patches/<version>/series applied.
# Build context is the repo root: --build-arg BASE=php:7.4-fpm-alpine3.16 --build-arg PHP_VERSION=7.4
ARG BASE
FROM ${BASE}

ARG PHP_VERSION
COPY patches/${PHP_VERSION} /tmp/patches

RUN set -eux; \
    apk update; \
    pick() { for p; do if apk search -e "$p" | grep -q .; then echo "$p"; return; fi; done; }; \
    # Older Alpine releases (e.g. 3.7) ship LibreSSL instead of OpenSSL
    if apk info | grep -q '^libressl'; then ssl=libressl-dev; else ssl=openssl-dev; fi; \
    # Alpine 3.13+ images build PHP against GNU libiconv instead of musl's iconv
    if apk info | grep -q '^gnu-libiconv'; then iconv=gnu-libiconv-dev; else iconv=; fi; \
    apk add --virtual .patch-build-deps \
        $PHPIZE_DEPS \
        $ssl \
        $iconv \
        $(pick argon2-dev) \
        $(pick oniguruma-dev) \
        $(pick libsodium-dev) \
        coreutils \
        curl-dev \
        libedit-dev \
        libxml2-dev \
        linux-headers \
        patch \
        readline-dev \
        sqlite-dev \
        zlib-dev; \
    # Same as the official Alpine build: hide musl's iconv.h so GNU libiconv's is used,
    # and for PHP < 8 (which doesn't look in /usr/include/gnu-libiconv) link its headers in
    if [ -n "$iconv" ]; then \
        rm -f /usr/include/iconv.h; \
        case "$PHP_VERSION" in 7.*) ln -sf /usr/include/gnu-libiconv/*.h /usr/include/ ;; esac; \
    fi; \
    docker-php-source extract; \
    cd /usr/src/php; \
    while read -r p flags; do patch -p1 --batch -s $flags < "/tmp/patches/$p"; done < /tmp/patches/series; \
    # Patches the official Alpine build applied at build time (not in the image's source tarball)
    if [ -f /tmp/patches/series.alpine ]; then \
        while read -r p flags; do patch -p1 --batch -s $flags < "/tmp/patches/$p"; done < /tmp/patches/series.alpine; \
    fi; \
    rm .docker-extracted; \
    # docker-php-ext-install in child images extracts this tarball, so it must carry the patches too
    tar -cJf /usr/src/php.tar.xz -C /usr/src php; \
    rm -f /usr/src/php.tar.xz.asc; \
    # PEAR is already installed; --with-pear would re-download it from pear.php.net
    CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
        ./configure $(php-config --configure-options | sed 's/--with-pear//'); \
    make -j"$(nproc)"; \
    make install; \
    strip --strip-all /usr/local/bin/php /usr/local/sbin/php-fpm 2> /dev/null || :; \
    find "$(php-config --extension-dir)" -name '*.so' -exec strip --strip-all '{}' +; \
    cd /; \
    docker-php-source delete; \
    rm -rf /tmp/patches; \
    for h in /usr/include/gnu-libiconv/*.h; do \
        if [ -L "/usr/include/${h##*/}" ]; then rm "/usr/include/${h##*/}"; fi; \
    done; \
    apk del .patch-build-deps; \
    rm -rf /var/cache/apk/*; \
    php -v; \
    if command -v php-fpm; then php-fpm -t; fi; \
    # Running out of memory exits 1 with the fix, 255 without it
    rc=0; php -d memory_limit=2M -r 'str_repeat("a", 10485760);' > /dev/null 2>&1 || rc=$?; \
    test "$rc" -eq 1
