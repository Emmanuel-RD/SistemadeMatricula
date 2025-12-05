import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    proxy: {
      // Proxy para evitar CORS en dev al llamar RENIEC
      '/api/reniec': {
        target: 'https://api.decolecta.com',
        changeOrigin: true,
        secure: true,
        rewrite: (path) => path.replace(/^\/api\/reniec/, '/v1/reniec')
      }
    }
  }
})







