# Frontend-only image — builds the React SPA and serves it via nginx.
# nginx also reverse-proxies /api/* and /favicon.ico to the backend Service,
# so the frontend's existing relative-path API calls (baseURL: '/api') work
# unchanged with no frontend code or CORS changes needed.
# Build context must be the frontend/ directory:
#   docker build -t <image>:<tag> frontend/

# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . ./
# VITE_ENABLE_AI_FEATURES=false hides the chat panel at build time.
ARG VITE_ENABLE_AI_FEATURES="false"
ENV VITE_ENABLE_AI_FEATURES=$VITE_ENABLE_AI_FEATURES
RUN npm run build

# ── Stage 2: Serve ──────────────────────────────────────────────────────────
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
