# Stage 1: build the static bundle
FROM node:26-alpine AS build
WORKDIR /app

# Node 26 LTS (see .nvmrc). Dependencies first for layer caching.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: serve with nginx
FROM nginx:alpine AS runner
COPY --from=build /app/dist /usr/share/nginx/html

# SPA fallback + no-cache for text assets (they change between builds).
RUN printf '%s' 'server { listen 80; server_name _; root /usr/share/nginx/html; index index.html; gzip on; gzip_types text/css application/javascript application/json image/svg+xml text/markdown text/plain application/manifest+json; location / { try_files $uri $uri/ /index.html; } location ~* \.(js|css|html|json|webmanifest|md|txt|xml|svg|png|ico)$ { add_header Cache-Control "no-cache, no-store, must-revalidate"; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
