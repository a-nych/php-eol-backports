# php-eol-backports

Official `php` Docker images for EOL PHP versions, rebuilt with upstream security fixes that no release ships.

Each `<version>/` holds a Dockerfile and `php-cve.patch`. The patched source is also repacked into `/usr/src/php.tar.xz`, so `docker-php-ext-install` in child images builds from patched code.

Use it as a drop-in `FROM` replacement:

```dockerfile
FROM ghcr.io/a-nych/php-eol-backports:8.1-fpm-bookworm
```

Images are multi-arch (`linux/amd64`, `linux/arm64`). Tags: `<version>-<variant>` (moving) and `<version>-<variant>-<sha>` (pinned).

| Version | Base | Patch |
|---|---|---|
| 8.1 | `php:8.1-fpm-bookworm` (8.1.34) | php/php-src@1d7dec1: CVE-2026-109618, CVE-2026-109619 |
| 8.0 | `php:8.0-fpm-bullseye` (8.0.30) | php/php-src@82f8f31: CVE-2026-109618, CVE-2026-109619 |
| 7.4 | `php:7.4-fpm-bullseye` (7.4.33) | php/php-src@712e60f: CVE-2026-109618, CVE-2026-109619 |

The bullseye images point apt at `archive.debian.org`, since Debian no longer serves bullseye from `deb.debian.org`.
