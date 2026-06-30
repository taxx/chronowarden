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

ARG FLUTTER_VERSION=3.27.1
RUN git clone https://github.com/flutter/flutter.git \
    -b stable \
    /usr/local/flutter \
    && /usr/local/flutter/bin/flutter precache --web
ENV PATH="/usr/local/flutter/bin:$PATH"

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
RUN printf '{"SUPABASE_URL":"%s","SUPABASE_ANON_KEY":"%s"}' \
    "$SUPABASE_URL" "$SUPABASE_ANON_KEY" \
    > /tmp/secrets.json \
    && flutter build web --release --web-enable-semantics --dart-define-from-file=/tmp/secrets.json \
    && rm -f /tmp/secrets.json

# Stage 2: Serve
FROM nginx:alpine AS runner

COPY --from=build /app/build/web /usr/share/nginx/html

RUN echo 'server { listen 80; server_name _; root /usr/share/nginx/html; index index.html; gzip on; gzip_types text/css application/javascript application/json image/svg+xml; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
