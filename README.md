# php-eol-backports

Official `php` Docker images for EOL PHP versions, rebuilt with upstream security fixes that no release ships.

Each `<version>/` holds a Dockerfile and `php-cve.patch`. The patched source is also repacked into `/usr/src/php.tar.xz`, so `docker-php-ext-install` in child images builds from patched code.

Use it as a drop-in `FROM` replacement (exact registry path under Deploy > Container Registry):

```dockerfile
FROM <registry>/php/php-eol-backports:8.1-fpm-bookworm
```

Images are multi-arch (`linux/amd64`, `linux/arm64`). Tags: `<version>-<variant>` (moving) and `<version>-<variant>-<sha>` (pinned).

| Version | Base | Patch |
|---|---|---|
| 8.1 | `php:8.1-fpm-bookworm` (8.1.34) | php/php-src@1d7dec1: CVE-2026-109618, CVE-2026-109619 |
