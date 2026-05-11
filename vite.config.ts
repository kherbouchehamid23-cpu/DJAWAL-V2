import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vuetify from 'vite-plugin-vuetify'
import { VitePWA } from 'vite-plugin-pwa'
import Components from 'unplugin-vue-components/vite'
import path from 'node:path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vuetify({ autoImport: true }),
    Components({ dirs: ['src/components'], dts: true }),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'robots.txt'],
      manifest: {
        name: 'Djawal — Voyager l\'Algérie',
        short_name: 'Djawal',
        description: 'Plateforme communautaire de voyages, hôtels, sites et restaurants en Algérie',
        theme_color: '#1B4965',
        background_color: '#FAF7F2',
        display: 'standalone',
        orientation: 'portrait-primary',
        scope: '/',
        start_url: '/',
        lang: 'fr',
        dir: 'ltr',
        icons: [
          { src: '/icons/pwa-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/pwa-512.png', sizes: '512x512', type: 'image/png' },
          { src: '/icons/pwa-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
        ]
      },
      workbox: {
        navigateFallback: '/index.html',
        runtimeCaching: [
          {
            // Assets statiques
            urlPattern: /\.(?:js|css|woff2?|svg)$/,
            handler: 'CacheFirst',
            options: { cacheName: 'djawal-static', expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 * 30 } }
          },
          {
            // Images
            urlPattern: /\.(?:png|jpg|jpeg|webp|avif)$/,
            handler: 'CacheFirst',
            options: { cacheName: 'djawal-images', expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 30 } }
          },
          {
            // API publique Supabase — stale-while-revalidate avec TTL court
            urlPattern: /^https:\/\/.*\.supabase\.co\/rest\/v1\/(destinations|hotels|sites|restaurants|trips).*/,
            handler: 'NetworkOnly',
            options: { cacheName: 'djawal-api-public', expiration: { maxAgeSeconds: 300 } }
          },
          {
            // Panoramas 360° — cache LRU 100 MB
            urlPattern: /\/storage\/v1\/object\/public\/panoramas\/.*/,
            handler: 'CacheFirst',
            options: { cacheName: 'djawal-360', expiration: { maxEntries: 30, maxAgeSeconds: 60 * 60 * 24 * 30 } }
          }
        ]
      }
    })
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  server: {
    port: 5173,
    host: true
  },
  build: {
    target: 'esnext',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-core': ['vue', 'vue-router', 'pinia'],
          'vuetify': ['vuetify'],
          'leaflet': ['leaflet'],
          'pannellum': ['pannellum']
        }
      }
    }
  }
})
