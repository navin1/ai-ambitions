import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { ThemeProvider, applyInitialTheme } from './utils/theme'
import './index.css'

applyInitialTheme()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider>
      <App />
    </ThemeProvider>
  </React.StrictMode>
)
