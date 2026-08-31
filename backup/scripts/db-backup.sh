#!/bin/bash

set -euo pipefail

ENV_FILE="${ENV_FILE:-/opt/anyrem-be/.env.production}"
IMAGE="${IMAGE:-vunavu/anyrem-be:latest}"
NETWORK="${NETWORK:-anyrem_network}"
LOG_PREFIX="[anyrem-db-backup]"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "$LOG_PREFIX: Error: Environment file not found: $ENV_FILE" >&2
    exit 1
fi

set -a

source "$ENV_FILE"

set +a

BACKUP_DATABASE_URL="${BACKUP_DATABASE_URL:-${DATABASE_URL/host.docker.internal/127.0.0.1}}"

if [[ -z "${BACKUP_DATABASE_URL:-}" ]]; then
  echo "$LOG_PREFIX Error: BACKUP_DATABASE_URL or DATABASE_URL required" >&2
  exit 1
fi

DAY="$(date -u +%F)"
DUMP="/tmp/anyrem-db-backup-$DAY.sql.gz"

echo "$LOG_PREFIX: dumping to $DUMP"

pg_dump "$BACKUP_DATABASE_URL" \
    --no-owner \
    --no-acl \
    | gzip -6 > "$DUMP"

docker run --rm \
    --network "$NETWORK" \
    --add-host=host.docker.internal:172.19.0.1 \
    --env-file "$ENV_FILE" \
    -v "$DUMP:/backup.sql.gz:ro" \
    "$IMAGE" \
    node dist/backup/backup.script.js \
    --type db-daily \
    --file /backup.sql.gz

rm -f "$DUMP"

echo "$LOG_PREFIX: Backup completed successfully"
exit 0