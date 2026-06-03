#!/bin/bash
set -o errexit -o nounset -o pipefail

[ "${DEBUG:-false}" == true ] && set -x

check_database_connection() {
  echo "Attempting to connect to database ..."

  case "${DB_CONNECTION}" in
    mysql|mariadb)
      prog="mysqladmin -h ${DB_HOST} -u ${DB_USERNAME} ${DB_PASSWORD:+-p$DB_PASSWORD} -P ${DB_PORT} status"
      ;;
    pgsql)
      export PGPASSWORD="${DB_PASSWORD}"
      prog="pg_isready -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME} -d ${DB_DATABASE} -t 1"
      ;;
    sqlite)
      mkdir -p "$(dirname "${DB_DATABASE}")"
      prog="touch ${DB_DATABASE}"
      ;;
    *)
      echo "Unsupported DB_CONNECTION: ${DB_CONNECTION}"
      exit 1
      ;;
  esac

  timeout=60
  while ! ${prog} >/dev/null 2>&1; do
    timeout=$((timeout - 1))
    if [[ "${timeout}" -eq 0 ]]; then
      echo
      echo "Could not connect to database server! Aborting..."
      exit 1
    fi
    echo -n "."
    sleep 1
  done
  echo
}

initialize_system() {
  echo "Initializing Cachet container ..."

  export APP_ENV="${APP_ENV:-production}"
  export APP_DEBUG="${APP_DEBUG:-false}"
  export APP_URL="${APP_URL:-http://localhost}"
  export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"

  # DB_DRIVER is retained as a compatibility alias for Cachet 2.x deployments.
  export DB_CONNECTION="${DB_CONNECTION:-${DB_DRIVER:-pgsql}}"
  export DB_HOST="${DB_HOST:-postgres}"
  export DB_USERNAME="${DB_USERNAME:-postgres}"
  export DB_PASSWORD="${DB_PASSWORD:-postgres}"

  case "${DB_CONNECTION}" in
    pgsql)
      export DB_DATABASE="${DB_DATABASE:-cachet}"
      export DB_PORT="${DB_PORT:-5432}"
      ;;
    mysql|mariadb)
      export DB_DATABASE="${DB_DATABASE:-cachet}"
      export DB_PORT="${DB_PORT:-3306}"
      ;;
    sqlite)
      export DB_DATABASE="${DB_DATABASE:-/var/www/html/database/database.sqlite}"
      export DB_HOST=""
      export DB_PORT=""
      export DB_USERNAME=""
      export DB_PASSWORD=""
      ;;
  esac

  export CACHE_STORE="${CACHE_STORE:-database}"
  export SESSION_DRIVER="${SESSION_DRIVER:-database}"
  export QUEUE_CONNECTION="${QUEUE_CONNECTION:-database}"

  if [[ -z "${APP_KEY:-}" || "${APP_KEY}" == "null" ]]; then
    APP_KEY="$(php artisan key:generate --show --no-ansi)"
    echo "ERROR: Please set the 'APP_KEY=${APP_KEY}' environment variable and re-launch"
    exit 1
  fi

  sed "s/{{PHP_MAX_CHILDREN}}/${PHP_MAX_CHILDREN:-5}/g" -i /usr/local/etc/php-fpm.d/www.conf
  rm -rf bootstrap/cache/*
}

start_system() {
  initialize_system
  check_database_connection

  echo "Running Cachet database migrations ..."
  php artisan migrate --force --no-interaction

  echo "Starting Cachet! ..."
  php artisan config:cache
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

if [[ "${MAIL_MAILER:-}" == "sendmail" ]]; then
  sudo /usr/sbin/postfix start
fi

start_system
