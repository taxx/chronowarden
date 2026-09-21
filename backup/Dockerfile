# Backup job container: runs pg_dump on a cron schedule.
# Alpine 3.22 + PostgreSQL 17 client (matches the Supabase PG 17 server) + busybox cron.
FROM alpine:3.22

RUN apk add --no-cache postgresql17-client

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
