# Backup job container: runs pg_dump on a cron schedule.
# Lightweight Alpine + PostgreSQL client + busybox cron.
FROM alpine:3.20

RUN apk add --no-cache postgresql-client

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
