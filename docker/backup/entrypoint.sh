#!/bin/sh
# Write the cron schedule from the runtime env var, then start busybox crond
# in the foreground (so the container stays alive and logs go to docker logs).
set -eu

CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"
echo "${CRON_SCHEDULE} /usr/local/bin/backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root

echo "$(date '+%Y-%m-%d %H:%M:%S') Backup cron started. Schedule: ${CRON_SCHEDULE}"
exec crond -f -l 2
