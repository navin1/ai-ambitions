# Backend-only image — FastAPI + Playwright (PDF export). No frontend build
# stage; the React SPA is built and served separately by frontend/Dockerfile.
# Build context must be the backend/ directory:
#   docker build -t <image>:<tag> backend/

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

# Virtual environment — all Python dependencies install here, isolated from
# system site-packages.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Playwright bundled Chromium — install to a fixed path so the non-root
# appuser can find it (default ~/.cache is root-only when installed as root).
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN playwright install chromium && chmod -R 755 /ms-playwright

# Backend source
COPY . ./

ENV PORT=8000
ENV PYTHONUNBUFFERED=1

# Run as non-root
RUN useradd -m -u 1000 appuser && chown -R appuser /app /opt/venv
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
