import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
import { defineConfig } from 'vitest/config';

/**
 * The commit this bundle was built from. Prefers the generated
 * `public/version.json` (so Docker builds need no git), falling back to git.
 */
function buildCommit(): string {
  try {
    const info = JSON.parse(readFileSync('public/version.json', 'utf8')) as { commit?: string };
    if (info.commit) return info.commit;
  } catch {
    // no generated metadata yet
  }
  try {
    return execSync('git rev-parse --short HEAD').toString().trim();
  } catch {
    return 'dev';
  }
}

export default defineConfig({
  define: {
    __BUILD_COMMIT__: JSON.stringify(buildCommit()),
  },
  plugins: [
    react(),
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
        // The changelog is regenerated per deploy; don't precache a stale copy.
        globIgnores: ['**/CHANGELOG.md'],
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
  resolve: {
    // shadcn/ui convention — the CLI and component imports use `@/…`.
    alias: { '@': path.resolve(import.meta.dirname, 'src') },
  },
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
    setupFiles: ['./src/test/setup.ts'],
  },
});
