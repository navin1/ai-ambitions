# ── Stage 1: Build React frontend ─────────────────────────────────────────────
FROM node:20-alpine AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
# VITE_ENABLE_AI_FEATURES=false hides the chat panel at build time.
# Set to 'true' in cloudbuild.yaml substitutions to surface AI features.
ARG VITE_ENABLE_AI_FEATURES="false"
ENV VITE_ENABLE_AI_FEATURES=$VITE_ENABLE_AI_FEATURES
RUN npm run build

# ── Stage 2: Python + Playwright runtime ──────────────────────────────────────
FROM python:3.12-slim
WORKDIR /app

# Chromium system dependencies (required by Playwright for PDF export)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 libnspr4 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
    libasound2 libx11-6 libx11-xcb1 libxcb1 libxext6 libxi6 \
    libxrender1 libxtst6 fonts-liberation fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Playwright bundled Chromium
RUN playwright install chromium

# Backend source
COPY backend/ ./

# Built React app → served as static files by FastAPI
COPY --from=frontend-build /app/dist ./static

ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Run as non-root
RUN useradd -m -u 1000 appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
