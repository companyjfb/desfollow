import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  // Configuração para produção
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
  // Configuração do servidor apenas para desenvolvimento local
  server: {
    host: '0.0.0.0',
    port: 3000,
  },
})
