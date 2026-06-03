# Cachet Docker Image

This repository builds a Docker image for [Cachet](https://github.com/cachethq/cachet), the open-source status page system.

The default image targets Cachet's `3.x` branch. Cachet 3.x is still under active development, and its migration path from 2.x is not complete. Back up existing data and review the [Cachet 3.x migration guide](https://docs.cachethq.io/v3.x/migration-guide) before upgrading an existing installation.

## Quickstart

1. Clone this repository.

   ```shell
   git clone https://github.com/CachetHQ/Docker.git
   cd Docker
   ```

2. Set an application key.

   ```shell
   export APP_KEY='base64:YOUR_UNIQUE_KEY'
   ```

   You can generate a key after building the image:

   ```shell
   docker compose build cachet
   docker compose run --rm cachet php artisan key:generate --show
   ```

3. Build and start Cachet.

   ```shell
   docker compose up --build -d
   ```

4. Create the first user.

   ```shell
   docker compose exec cachet php artisan cachet:make:user
   ```

Cachet is available on host port 80 and is served from container port 8000.

## Configuration

Configure Cachet with Laravel and Cachet 3.x environment variables. See [`conf/.env.docker`](conf/.env.docker) for a minimal example and the [Cachet 3.x installation guide](https://docs.cachethq.io/v3.x/installation) for the current upstream configuration.

The primary database variable is `DB_CONNECTION`. `DB_DRIVER` is accepted as a compatibility alias for existing Cachet 2.x Docker deployments, but new deployments should use `DB_CONNECTION`.

To build a different Cachet ref, set the `cachet_ver` build argument in [`docker-compose.yml`](docker-compose.yml). The default is `3.x`.

The image runs as UID `1001`. Existing bind mounts or named volumes mounted under `/var/www/html`, including `/var/www/html/storage`, must be writable by UID `1001` before the container starts.

## Runtime Processes

The image runs these processes under Supervisor:

- nginx
- PHP-FPM
- Laravel queue worker
- Laravel scheduler

Application, nginx, and PHP-FPM logs are written to Docker stdout and stderr.

## Development

To develop Cachet with this image, clone Cachet and install its dependencies:

```shell
git clone -b 3.x https://github.com/cachethq/cachet.git Cachet
cd Cachet
composer install
cp ../conf/.env.docker .env
cd ..
```

Bind mount the source directory into the `cachet` service:

```yaml
services:
  cachet:
    volumes:
      - ./Cachet:/var/www/html
```
