#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

install -m 755 "$REPO_DIR/scripts/db-backup.sh" /usr/local/bin/anyrem-db-backup.sh
install -m 644 "$REPO_DIR/cron/anyrem-db-backup.cron" /etc/cron.d/anyrem-db-backup

echo "Installed: /usr/local/bin/anyrem-db-backup.sh"
echo "Installed: /etc/cron.d/anyrem-db-backup"
