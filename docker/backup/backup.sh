#!/bin/sh
# Dump the database with pg_dump, gzip it, then prune old backups.
# Credentials come from the standard PG* environment variables (PGHOST,
# PGPORT, PGDATABASE, PGUSER, PGPASSWORD), set by docker-compose from .env.
set -u

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-62}"
BACKUP_PREFIX="${BACKUP_PREFIX:-chronowarden_backup}"

echo "$(date '+%Y-%m-%d %H:%M:%S') Starting pg_dump backup..."
TS=$(date +%Y%m%d_%H%M%S)
FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_${TS}.tar"

if pg_dump --format=tar --file="${FILE}" --no-owner; then
  gzip -9 "${FILE}"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Backup written: ${FILE}.gz"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') Backup FAILED; skipping compression."
  rm -f "${FILE}"
fi

# Retention cleanup always runs, independent of backup success.
if [ "${RETENTION_DAYS}" -gt 0 ]; then
  find "${BACKUP_DIR}" -type f -name "${BACKUP_PREFIX}_*.tar.gz" -mtime +"${RETENTION_DAYS}" -delete
  echo "$(date '+%Y-%m-%d %H:%M:%S') Cleanup: removed backups older than ${RETENTION_DAYS} days."
fi
