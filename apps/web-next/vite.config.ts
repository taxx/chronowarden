import { execSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
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
 * Writes `dist/version.json` so the running app can detect a newer deployment
 * (the Flutter client does the same via `web/version.json`).
 */
function versionPlugin() {
  return {
    name: 'chronowarden-version-json',
    closeBundle() {
      const pkg = JSON.parse(readFileSync('package.json', 'utf8')) as { version?: string };
      const info = {
        version: pkg.version ?? '0.0.0',
        commit: buildCommit(),
        built_at: new Date().toISOString(),
      };
      mkdirSync('dist', { recursive: true });
      writeFileSync('dist/version.json', `${JSON.stringify(info, null, 2)}\n`);
    },
  };
}

export default defineConfig({
  define: {
    __BUILD_COMMIT__: JSON.stringify(buildCommit()),
  },
  plugins: [
    react(),
    versionPlugin(),
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
