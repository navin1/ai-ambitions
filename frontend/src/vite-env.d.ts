/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_ENABLE_AI_FEATURES: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
