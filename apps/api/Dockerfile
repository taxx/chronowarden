# syntax=docker/dockerfile:1
FROM oven/bun:1-alpine AS base
WORKDIR /app
# Install dependencies first for better layer caching. Fail closed if the
# lockfile and package.json disagree — never silently resolve new versions.
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile --production

# Application code + SQL migrations.
COPY tsconfig.json ./
COPY src ./src
COPY migrations ./migrations

ENV NODE_ENV=production
EXPOSE 8080

# Migrations run on startup inside src/index.ts, then the server boots.
CMD ["bun", "run", "src/index.ts"]
