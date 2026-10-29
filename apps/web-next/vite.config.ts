import { execSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
import { defineConfig } from 'vitest/config';

function buildCommit(): string {
  try {
    return execSync('git rev-parse --short HEAD').toString().trim();
  } catch {
    return 'dev';
  }
}

/**
 * Writes `dist/version.json` (for the update prompt) and copies the generated
 * changelog (from the Flutter app, which owns the git-history generator) so the
 * What's New screen can render it.
 */
function metadataPlugin() {
  return {
    name: 'chronowarden-metadata',
    closeBundle() {
      const pkg = JSON.parse(readFileSync('package.json', 'utf8')) as { version?: string };
      const info = {
        version: pkg.version ?? '0.0.0',
        commit: buildCommit(),
        built_at: new Date().toISOString(),
      };
      mkdirSync('dist', { recursive: true });
      writeFileSync('dist/version.json', `${JSON.stringify(info, null, 2)}\n`);

      const changelog = '../web/CHANGELOG.md';
      if (existsSync(changelog)) copyFileSync(changelog, 'dist/CHANGELOG.md');
    },
  };
}

export default defineConfig({
  define: {
    __BUILD_COMMIT__: JSON.stringify(buildCommit()),
  },
  plugins: [
    react(),
    metadataPlugin(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['icons/*.png'],
      manifest: {
        name: 'ChronoWarden',
        short_name: 'ChronoWarden',
        description: 'Personal time-banking and overtime protection.',
        theme_color: '#0f172a',
        background_color: '#0f172a',
        display: 'standalone',
        start_url: '/',
        icons: [
          { src: 'icons/Icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icons/Icon-512.png', sizes: '512x512', type: 'image/png' },
          {
            src: 'icons/Icon-maskable-192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'maskable',
          },
          {
            src: 'icons/Icon-maskable-512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
      },
      workbox: {
        navigateFallback: '/index.html',
        // Never serve the app shell for API navigations.
        navigateFallbackDenylist: [/^\/api\//],
        runtimeCaching: [
          {
            // Data is live and encrypted per-session: never cache the API.
            urlPattern: ({ url }) => url.pathname.startsWith('/api/'),
            handler: 'NetworkOnly',
          },
        ],
      },
    }),
  ],
  server: {
    port: 5173,
    // Same-origin API during development, so cookie auth works exactly like
    // production (the proxy container does this for real deployments).
    proxy: {
      '/api': {
        target: process.env.API_URL ?? 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    rollupOptions: {
      output: {
        // Keep the vendor bundles stable so the service worker cache is reused.
        manualChunks: {
          react: ['react', 'react-dom'],
          router: ['@tanstack/react-router', '@tanstack/react-query'],
          charts: ['recharts'],
          crypto: ['@scure/bip39'],
        },
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
  },
});
