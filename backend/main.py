import os
import logging
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from dotenv import load_dotenv

load_dotenv()

_log_level = (os.getenv("LOG_LEVEL") or "INFO").upper()
logging.basicConfig(
    level=_log_level,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    force=True,
)

from routes import overview, query, chat, pdf

app = FastAPI(title="AI Ambitions Dashboard", version="1.0.0")

# CORS — dev only; in prod all traffic goes through the GKE Ingress / IAP
_cors_origins = ["http://localhost:5173", "http://localhost:3000"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(overview.router)
app.include_router(query.router)
app.include_router(chat.router)
app.include_router(pdf.router)

_logger = logging.getLogger("main")


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    _logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


@app.get("/api/health")
async def health():
    import gemini_client
    return {
        "status": "ok",
        "ai_ready": gemini_client._model is not None,
        "model": os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        "vertex_project": os.getenv("VERTEX_AI_PROJECT", ""),
        "bigquery_project": os.getenv("BIGQUERY_PROJECT_ID", ""),
        "dataset": os.getenv("BIGQUERY_DATASET", "ai_ambitions"),
    }


@app.get("/api/me")
async def me(
    x_goog_authenticated_user_email: str | None = None,
    x_goog_authenticated_user_id: str | None = None,
):
    """Returns the IAP-authenticated user identity (or dev fallback)."""
    from fastapi import Header as FHeader
    email = (x_goog_authenticated_user_email or "").removeprefix("accounts.google.com:") or "dev@local"
    return {"email": email}


# ── Serve built React SPA in production ───────────────────────────────────────
_static = Path(__file__).parent / "static"
if _static.exists():
    _assets = _static / "assets"
    if _assets.exists():
        app.mount("/assets", StaticFiles(directory=str(_assets)), name="static-assets")

    @app.get("/{full_path:path}", include_in_schema=False)
    async def _spa(full_path: str):
        return FileResponse(str(_static / "index.html"))
