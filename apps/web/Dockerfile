# Stage 1: Build
FROM dart:stable AS build

RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    fonts-liberation \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git \
    -b stable \
    /usr/local/flutter \
    && /usr/local/flutter/bin/flutter precache --web
ENV PATH="/usr/local/flutter/bin:$PATH"

# Build context is the repository root (see docker-compose.yaml) so this
# Dockerfile can be built from ./apps/web while the changelog/build-info
# assets live inside the app directory.
WORKDIR /app
COPY apps/web/pubspec.yaml apps/web/pubspec.lock ./
RUN flutter pub get

COPY apps/web/ ./

# CHANGELOG.md and build_info.json are generated on the host by tool/*.sh as
# part of the release routine, then committed — the Docker build consumes the
# committed copies (the build context has no .git history).
# The API base URL defaults to same-origin /api/v1 (see api_client.dart), so
# no secrets are baked into the web bundle anymore.
RUN flutter build web --release --dart-define=API_URL=

# Stage 2: Serve
FROM nginx:alpine AS runner

COPY --from=build /app/build/web /usr/share/nginx/html

RUN echo 'server { listen 80; server_name _; root /usr/share/nginx/html; index index.html; gzip on; gzip_types text/css application/javascript application/json image/svg+xml text/markdown text/plain; location / { try_files $uri $uri/ /index.html; } location ~ \.(js|dart|html|json|md|sql|txt|xml)$ { add_header Cache-Control "no-cache, no-store, must-revalidate"; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
