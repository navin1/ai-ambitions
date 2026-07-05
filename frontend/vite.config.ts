import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true, // bind to 0.0.0.0 so phones on the same Wi-Fi can reach it
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
      '/favicon.ico': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
