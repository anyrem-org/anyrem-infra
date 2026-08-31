#!/bin/bash

set -euo pipefail

ENV_FILE="${ENV_FILE:-/opt/anyrem-be/.env.production}"
IMAGE="${IMAGE:-vunavu/anyrem-be:latest}"
NETWORK="${NETWORK:-anyrem_network}"
UPLOADS_VOLUME="${UPLOADS_VOLUME:-anyrem_uploads}"
LOG_PREFIX="[anyrem-uploads-backup]"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "$LOG_PREFIX: Error: Environment file not found: $ENV_FILE" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

DAY="$(date -u +%F)"
ARCHIVE="/tmp/anyrem-uploads-backup-$DAY.tar.gz"

echo "$LOG_PREFIX: archiving volume $UPLOADS_VOLUME to $ARCHIVE"

docker run --rm \
  -v "$UPLOADS_VOLUME:/data:ro" \
  -v "/tmp:/out" \
  alpine:3.21 \
  sh -c "tar -czf /out/anyrem-uploads-backup-$DAY.tar.gz -C /data ."

if [[ ! -s "$ARCHIVE" ]]; then
  echo "$LOG_PREFIX: Error: archive missing or empty: $ARCHIVE" >&2
  exit 1
fi

echo "$LOG_PREFIX: uploading to object storage (key uploads/$DAY.tar.gz)"

docker run --rm \
  --network "$NETWORK" \
  --add-host=host.docker.internal:172.19.0.1 \
  --env-file "$ENV_FILE" \
  -v "$ARCHIVE:/backup.tar.gz:ro" \
  "$IMAGE" \
  node dist/backup/backup.script.js \
    --type uploads \
    --file /backup.tar.gz

rm -f "$ARCHIVE"

echo "$LOG_PREFIX: Backup completed successfully"
