#!/bin/sh
# Dump the Supabase database with pg_dump, gzip it, then prune old backups.
# Credentials come from env vars (DB_CONNECTION_STRING, DB_PASSWORD).
set -u

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-62}"

echo "$(date '+%Y-%m-%d %H:%M:%S') Starting pg_dump backup..."
TS=$(date +%Y%m%d_%H%M%S)
FILE="${BACKUP_DIR}/chronowarden_backup_${TS}.tar"

if PGPASSWORD="${DB_PASSWORD}" pg_dump \
    --dbname="${DB_CONNECTION_STRING}" \
    --format=tar \
    --file="${FILE}" \
    --no-owner; then
  gzip -9 "${FILE}"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Backup written: ${FILE}.gz"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') Backup FAILED; skipping compression."
  rm -f "${FILE}"
fi

# Retention cleanup always runs, independent of backup success.
if [ "${RETENTION_DAYS}" -gt 0 ]; then
  find "${BACKUP_DIR}" -type f -name 'chronowarden_backup_*.tar.gz' -mtime +"${RETENTION_DAYS}" -delete
  echo "$(date '+%Y-%m-%d %H:%M:%S') Cleanup: removed backups older than ${RETENTION_DAYS} days."
fi
