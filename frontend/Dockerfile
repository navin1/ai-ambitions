# Frontend-only image — builds the React SPA and serves it via nginx.
# /api/* routing to the backend is handled by the GKE Ingress (path-based
# rule), so the frontend's existing relative-path API calls (baseURL: '/api')
# work unchanged with no frontend code or CORS changes needed.
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
# nginx-unprivileged runs as a non-root user (uid 101) out of the box and
# listens on 8080 instead of 80, since binding <1024 requires root.
FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
