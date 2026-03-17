import { resolve } from 'path'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: resolve(__dirname, '../../Gitfluence/WebResources/RichEditor'),
    emptyOutDir: true,
  },
})
