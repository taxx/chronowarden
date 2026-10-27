# Backup job container: runs pg_dump on a cron schedule.
# PostgreSQL 18 base image, so the client matches the server version exactly;
# busybox cron is included in the Alpine base.
FROM postgres:18-alpine

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
