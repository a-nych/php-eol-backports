# php-eol-docker-backports

Official `php` Docker images for EOL PHP versions (7.0–8.1), rebuilt with the fix for CVE-2026-109618 and CVE-2026-109619 ("Avoid state corruption via bailout"), which no official image ships.

Drop-in `FROM` replacement, same tag names as the official image:

```dockerfile
FROM ghcr.io/a-nych/php-eol-docker-backports:7.4-fpm-bullseye
```

Every image is multi-arch (`linux/amd64`, `linux/arm64`). Tags: `<version>-<variant>` (moving) and `<version>-<variant>-<sha>` (pinned). See [`images.txt`](images.txt) for the full list: Debian `fpm` and `apache`, Alpine `fpm` and `cli`, on the newest distro release each version was built for.

## Patches

`patches/<version>/series` is applied in order to the official image's PHP source.

| Version | Source |
|---|---|
| 8.1 | php/php-src@1d7dec1 |
| 8.0 | php/php-src@82f8f31 |
| 7.4 | php/php-src@712e60f |
| 7.0–7.3 | php-src has no fix for these; [Sury's](https://deb.sury.org/) backport of the 7.4 fix, plus his `backport-ZSTR_MAX_LEN` which it needs to compile |

The 7.4 upstream fix also adds the `max_multipart_body_parts` INI limit (CVE-2023-0662) where it was missing. The 7.0–7.3 backport leaves that out, as Sury's 7.0 and 7.1 packages do.

`patches/<version>/series.alpine`, where present, holds patches the official Alpine build applied at build time but which aren't in the image's source tarball (8.1: php/php-src@577b8ae, @a5df266 reverted, @67259e4 without its NEWS hunk, as in the official 8.1.34 Dockerfile). Rebuilding without them would silently drop them. A series line may carry `patch` flags after the file name, e.g. `-R`.

The patched source is also repacked into `/usr/src/php.tar.xz`, so `docker-php-ext-install` in child images builds from patched code. Each build fails unless running out of memory exits with 1 (fixed) rather than 255 (unfixed).

Debian buster and bullseye images point apt at `archive.debian.org`, since Debian no longer serves them from `deb.debian.org`.

7.0 is Alpine-only: its official Debian images are stretch-based, and the stretch archive's signing keys have expired, so its build dependencies can't be installed with signature verification.

## Verify

Images are built by the public workflow in this repo, which attaches a signed build provenance attestation to each tag. To check that an image came from this repo's workflow, and which commit it was built from:

```sh
gh attestation verify oci://ghcr.io/a-nych/php-eol-docker-backports:7.4-fpm-bullseye --owner a-nych
```

The builds are not bit-for-bit reproducible. If you'd rather not trust the CI at all, build it yourself:

## Local build

```sh
docker buildx build -f docker/debian.Dockerfile \
  --build-arg BASE=php:7.4-fpm-bullseye --build-arg PHP_VERSION=7.4 .
```
