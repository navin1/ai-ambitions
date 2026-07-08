import os
import logging
from pathlib import Path
from fastapi import Depends, FastAPI, Request
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

import auth
from routes import overview, query, chat, pdf, auth as auth_routes, admin as admin_routes

logging.getLogger("main").info(
    "auth mode: %s",
    f"ForgeRock AM ({auth.FORGEROCK_AM_URL})" if auth.FORGEROCK_AM_URL else "dev-fallback (FORGEROCK_AM_URL not set)",
)

app = FastAPI(title="AI Ambitions Dashboard", version="1.0.0")

# CORS — dev only; in prod all traffic goes through the GKE Ingress / ForgeRock IG
_cors_origins = ["http://localhost:5173", "http://localhost:3000"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# overview/query/chat/pdf require any authenticated user (+ FORGEROCK_ACCESS_GROUP
# membership if configured); admin.py's own require_role("admin") layers the
# admin-group check on top for /api/admin/*.
_data_router_deps = [Depends(auth.require_authenticated())]
app.include_router(overview.router, dependencies=_data_router_deps)
app.include_router(query.router, dependencies=_data_router_deps)
app.include_router(chat.router, dependencies=_data_router_deps)
app.include_router(pdf.router, dependencies=_data_router_deps)
app.include_router(auth_routes.router)
app.include_router(admin_routes.router)

_logger = logging.getLogger("main")


@app.api_route("/favicon.ico", methods=["GET", "HEAD"], include_in_schema=False)
async def favicon():
    return FileResponse(
        str(Path(__file__).parent / "assets" / "star.png"),
        media_type="image/png",
    )


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
async def me(request: Request):
    """Returns the current identity: IG-injected headers, else a dev-mode login
    cookie set by /api/auth/login, else unauthenticated."""
    from auth import resolve_user
    user = await resolve_user(request)
    return user


# ── Serve built React SPA in production ───────────────────────────────────────
_static = Path(__file__).parent / "static"
if _static.exists():
    _assets = _static / "assets"
    if _assets.exists():
        app.mount("/assets", StaticFiles(directory=str(_assets)), name="static-assets")

    @app.get("/{full_path:path}", include_in_schema=False)
    async def _spa(full_path: str):
        candidate = _static / full_path
        if candidate.is_file():
            return FileResponse(str(candidate))
        return FileResponse(str(_static / "index.html"))
