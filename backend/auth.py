import logging
import os
import json
import pathlib
import subprocess
from dotenv import load_dotenv
from fastapi import Header, HTTPException, Request
from typing import Optional

logger = logging.getLogger(__name__)

load_dotenv()

SERVICE_ACCOUNT_FILE = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")

# ── ForgeRock Identity Gateway user identity ──────────────────────────────────
# In production GKE, the ForgeRock IG sidecar validates the AM session cookie
# and injects identity headers before forwarding the request to this app.
# Header names must match the HeaderFilter configuration in the IG route.
# In local dev (no IG), headers are absent and we fall back to dev@local.
FORGEROCK_EMAIL_HEADER = os.getenv("FORGEROCK_EMAIL_HEADER", "x-fr-email")
FORGEROCK_USERNAME_HEADER = os.getenv("FORGEROCK_USERNAME_HEADER", "x-fr-username")

# ── ForgeRock AM — direct REST authentication ─────────────────────────────────
# The custom login page in this app authenticates the user against AM's REST
# API directly (rather than relying on IG's default hosted login page), then
# sets the resulting AM SSO cookie so that IG's SingleSignOnFilter recognizes
# the session on subsequent requests and injects the identity headers above.
# See kubernetes/backend-config.yaml for the IG route that excludes /login and
# /api/auth/* from the SSO filter so this handshake is reachable pre-auth.
FORGEROCK_AM_URL = os.getenv("FORGEROCK_AM_URL", "")
FORGEROCK_AM_REALM = os.getenv("FORGEROCK_AM_REALM", "/")
FORGEROCK_AM_COOKIE_NAME = os.getenv("FORGEROCK_AM_COOKIE_NAME", "iPlanetDirectoryPro")

DEV_SESSION_COOKIE = "dev_session"

# ── AD-group-based roles ──────────────────────────────────────────────────────
# Group membership rides along as a session attribute in AM (backed by AD),
# same mechanism as uid/mail. IG injects it as a header (comma-separated, since
# HTTP headers are flat strings) alongside the identity headers above; /api/me
# reads it straight from AM session info since that route bypasses IG's filter.
# FORGEROCK_ADMIN_GROUP is the AD group name that grants the "admin" role —
# leave empty until the group actually exists (everyone resolves to "user").
FORGEROCK_GROUPS_HEADER = os.getenv("FORGEROCK_GROUPS_HEADER", "x-fr-groups")
FORGEROCK_AM_GROUPS_ATTRIBUTE = os.getenv("FORGEROCK_AM_GROUPS_ATTRIBUTE", "memberOf")
FORGEROCK_ADMIN_GROUP = os.getenv("FORGEROCK_ADMIN_GROUP", "")


def _parse_groups_header(raw: str) -> list[str]:
    return [g.strip() for g in raw.split(",") if g.strip()]


def _resolve_role(groups: list[str]) -> str:
    if FORGEROCK_ADMIN_GROUP and FORGEROCK_ADMIN_GROUP in groups:
        return "admin"
    return "user"


async def resolve_user(request: Request) -> dict:
    email = request.headers.get(FORGEROCK_EMAIL_HEADER, "")
    username = request.headers.get(FORGEROCK_USERNAME_HEADER, "")
    if email:
        groups = _parse_groups_header(request.headers.get(FORGEROCK_GROUPS_HEADER, ""))
        return {"id": username or email, "email": email, "authenticated": True, "groups": groups, "role": _resolve_role(groups)}

    # /api/me is reachable pre-auth (see backend-config.yaml), so IG never gets
    # a chance to validate+inject headers for it. Validate the AM cookie
    # ourselves so the header shows the real user rather than a dev fallback.
    am_token = request.cookies.get(FORGEROCK_AM_COOKIE_NAME, "")
    if am_token and FORGEROCK_AM_URL:
        info = await am_session_info(am_token)
        if info:
            groups = info["groups"]
            return {"id": info["username"] or info["email"], "email": info["email"], "authenticated": True, "groups": groups, "role": _resolve_role(groups)}

    dev_user = request.cookies.get(DEV_SESSION_COOKIE, "")
    if dev_user:
        # Dev-only convenience: there's no real AD/AM locally, so let the typed
        # username signal role for testing (e.g. "jane.admin") until real AD
        # groups are created and FORGEROCK_ADMIN_GROUP is set.
        role = "admin" if "admin" in dev_user.lower() else "user"
        return {"id": dev_user, "email": dev_user, "authenticated": True, "groups": [], "role": role}

    return {"id": "dev-user", "email": "dev@local", "authenticated": False, "groups": [], "role": "user"}


def require_role(*allowed_roles: str):
    """FastAPI dependency factory gating a route by resolved role.

    Not wired to any route yet — no admin-only feature exists. Attach it once
    one does, e.g. dependencies=[Depends(require_role("admin"))].
    """
    async def _check(request: Request) -> dict:
        user = await resolve_user(request)
        if user["role"] not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return user
    return _check


class AMAuthError(Exception):
    """Raised when ForgeRock AM rejects credentials or is unreachable."""


async def am_authenticate(username: str, password: str) -> str:
    """Authenticate against ForgeRock AM's REST API. Returns the AM SSO tokenId.

    Uses the classic `/json/authenticate?realm=...` endpoint with credentials
    passed as X-OpenAM-* headers, per AM's documented REST auth API.
    """
    import httpx

    url = f"{FORGEROCK_AM_URL.rstrip('/')}/json/authenticate"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                url,
                params={"realm": FORGEROCK_AM_REALM},
                headers={
                    "X-OpenAM-Username": username,
                    "X-OpenAM-Password": password,
                    "Content-Type": "application/json",
                    "Accept-API-Version": "resource=2.0",
                },
                json={},
            )
    except httpx.HTTPError as exc:
        logger.warning("am_authenticate: request to AM failed: %s", exc)
        raise AMAuthError("Could not reach ForgeRock AM") from exc

    if resp.status_code != 200:
        raise AMAuthError("Invalid username or password")

    token = resp.json().get("tokenId")
    if not token:
        raise AMAuthError("AM response did not include a session token")
    return token


async def am_session_info(token: str) -> Optional[dict]:
    """Look up the identity behind an AM SSO token. Returns None if invalid.

    Property names (uid, mail, memberOf) match the AM user profile schema —
    adjust if yours differs, same as the attribute mapping in backend-config.yaml.
    """
    import httpx

    url = f"{FORGEROCK_AM_URL.rstrip('/')}/json/sessions"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                url,
                params={"_action": "getSessionInfo", "realm": FORGEROCK_AM_REALM},
                cookies={FORGEROCK_AM_COOKIE_NAME: token},
                headers={"Accept-API-Version": "resource=3.1"},
            )
    except httpx.HTTPError as exc:
        logger.warning("am_session_info: request to AM failed: %s", exc)
        return None

    if resp.status_code != 200:
        return None

    props = resp.json().get("properties", {})
    username = props.get("uid") or props.get("username") or ""
    email = props.get("mail") or props.get("email") or ""
    if not (username or email):
        return None

    raw_groups = props.get(FORGEROCK_AM_GROUPS_ATTRIBUTE, [])
    groups = raw_groups if isinstance(raw_groups, list) else ([raw_groups] if raw_groups else [])
    return {"username": username, "email": email, "groups": groups}


async def am_logout(token: str) -> None:
    """Invalidate an AM SSO token via AM's REST session logout API. Best-effort."""
    import httpx

    url = f"{FORGEROCK_AM_URL.rstrip('/')}/json/sessions"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            await client.post(
                url,
                params={"_action": "logout", "realm": FORGEROCK_AM_REALM},
                cookies={FORGEROCK_AM_COOKIE_NAME: token},
                headers={"Accept-API-Version": "resource=3.1"},
            )
    except httpx.HTTPError as exc:
        logger.warning("am_logout: request to AM failed: %s", exc)


def get_request_token(authorization: Optional[str] = Header(default=None)) -> Optional[str]:
    """Kept for compatibility with dormant query/chat routes.

    In production all BQ access uses Workload Identity (no per-request tokens).
    In dev, returning None causes get_bq_credentials to fall through to ADC.
    """
    return None


# ── BigQuery credentials ──────────────────────────────────────────────────────
# In production: Workload Identity — ADC resolves automatically, no config needed.
# In dev: gcloud auth application-default login  (or print-access-token fallback).

def _find_gcloud_binary() -> str:
    try:
        result = subprocess.run(["which", "gcloud"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass
    candidates = [
        "/usr/lib/google-cloud-sdk/bin/gcloud",
        "/usr/local/bin/gcloud",
        "/opt/homebrew/bin/gcloud",
        str(pathlib.Path.home() / "google-cloud-sdk" / "bin" / "gcloud"),
        "/snap/bin/gcloud",
        "/usr/bin/gcloud",
    ]
    for path in candidates:
        if pathlib.Path(path).exists():
            return path
    return "gcloud"


def _get_gcloud_login_credentials():
    try:
        result = subprocess.run(
            ["gcloud", "config", "get-value", "account"],
            capture_output=True, text=True, timeout=5,
        )
        account = result.stdout.strip()
        if not account:
            return None
    except Exception:
        return None

    cred_file = (
        pathlib.Path.home()
        / ".config" / "gcloud" / "legacy_credentials" / account / "adc.json"
    )
    if not cred_file.exists():
        return None

    try:
        import google.auth
        creds, _ = google.auth.load_credentials_from_file(str(cred_file))
        return creds
    except Exception:
        return None


def _get_gcloud_print_token() -> str | None:
    gcloud = _find_gcloud_binary()
    try:
        result = subprocess.run(
            [gcloud, "auth", "print-access-token"],
            capture_output=True, text=True, timeout=10,
        )
        token = result.stdout.strip()
        if token and result.returncode == 0:
            return token
        return None
    except Exception:
        return None


def get_bq_credentials(token: Optional[str] = None):
    """Return BigQuery credentials. See get_gcp_credentials() for the shared
    resolution logic — this just pins the scope to BigQuery."""
    return get_gcp_credentials(scopes=["https://www.googleapis.com/auth/bigquery"])


def get_gcs_credentials():
    """Return Cloud Storage credentials (used by the admin file-upload route)."""
    return get_gcp_credentials(scopes=["https://www.googleapis.com/auth/devstorage.read_write"])


def get_gcp_credentials(scopes: list[str]):
    """Return Google Cloud credentials for the given scopes.

    Priority:
      1. GOOGLE_APPLICATION_CREDENTIALS service-account JSON  (explicit override)
      2. gcloud auth login credentials via legacy credential file (dev, auto-refresh)
      3. gcloud auth print-access-token (dev fallback)
      4. ADC — covers both Workload Identity (prod) and application-default (dev)

    quota_project_id is intentionally not set on user credentials — it requires
    serviceusage.services.use which user accounts often lack. Callers handle
    project billing via their own client's project= parameter.
    """
    from google.oauth2 import credentials as oauth2_creds
    import google.auth

    # 1. Explicit service-account JSON
    if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
        logger.info("get_gcp_credentials: using GOOGLE_APPLICATION_CREDENTIALS file")
        with open(SERVICE_ACCOUNT_FILE) as f:
            cred_type = json.load(f).get("type", "")
        if cred_type == "service_account":
            creds, _ = google.auth.load_credentials_from_file(
                SERVICE_ACCOUNT_FILE,
                scopes=scopes,
            )
        else:
            creds, _ = google.auth.load_credentials_from_file(SERVICE_ACCOUNT_FILE)
        return creds

    # 2. gcloud auth login (dev — stored refresh token, auto-refreshes)
    gcloud_creds = _get_gcloud_login_credentials()
    if gcloud_creds is not None:
        logger.info("get_gcp_credentials: using gcloud auth login credentials")
        return gcloud_creds

    # 3. gcloud auth print-access-token (dev fallback)
    gcloud_token = _get_gcloud_print_token()
    if gcloud_token:
        logger.info("get_gcp_credentials: using token from gcloud auth print-access-token")
        return oauth2_creds.Credentials(token=gcloud_token)

    # 4. ADC — Workload Identity in prod, application-default in dev
    try:
        creds, _ = google.auth.default(scopes=scopes)
        logger.info("get_gcp_credentials: using Application Default Credentials")
        return creds
    except Exception as e:
        logger.warning("get_gcp_credentials: ADC failed: %s", e)

    raise ValueError(
        "No valid Google credentials found. In dev run:\n"
        "  gcloud auth application-default login\n"
        "In GKE production, ensure Workload Identity is configured."
    )
