import axios from 'axios'

// ForgeRock IG validates the session and injects identity headers server-side
// (see kubernetes/backend-config.yaml) — no Authorization header needed here.
// Cookies ride along automatically since the frontend and API share an origin
// in prod (single Ingress) and via the Vite dev proxy locally.
const client = axios.create({ baseURL: '/api' })

export default client
