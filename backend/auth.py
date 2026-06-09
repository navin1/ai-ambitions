import logging
import os
import json
import pathlib
import subprocess
from dotenv import load_dotenv
from fastapi import Header
from typing import Optional

logger = logging.getLogger(__name__)

load_dotenv()

SERVICE_ACCOUNT_FILE = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")

# ── IAP user identity ─────────────────────────────────────────────────────────
# In production GKE + IAP, the load balancer validates the user and injects:
#   X-Goog-Authenticated-User-Email: accounts.google.com:user@example.com
#   X-Goog-Authenticated-User-ID:   accounts.google.com:12345678
# In local dev (no IAP), both headers are absent and we fall back to anonymous.

async def resolve_user(
    x_goog_authenticated_user_email: Optional[str] = Header(default=None),
    x_goog_authenticated_user_id: Optional[str] = Header(default=None),
) -> dict:
    if x_goog_authenticated_user_email:
        # Header value format: "accounts.google.com:user@example.com"
        email = x_goog_authenticated_user_email.removeprefix("accounts.google.com:")
        uid = (x_goog_authenticated_user_id or "").removeprefix("accounts.google.com:")
        return {"id": uid or email, "email": email}
    return {"id": "dev-user", "email": "dev@local"}


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
    """Return BigQuery credentials.

    Priority (token param is ignored — all BQ access is server-side):
      1. GOOGLE_APPLICATION_CREDENTIALS service-account JSON  (explicit override)
      2. gcloud auth login credentials via legacy credential file (dev, auto-refresh)
      3. gcloud auth print-access-token (dev fallback)
      4. ADC — covers both Workload Identity (prod) and application-default (dev)
    """
    from google.oauth2 import credentials as oauth2_creds
    import google.auth

    quota_project = (
        os.getenv("BQ_JOB_PROJECT_ID")
        or os.getenv("GOOGLE_CLOUD_PROJECT")
        or os.getenv("GCP_PROJECT_ID")
        or os.getenv("BIGQUERY_PROJECT_ID")
    )

    def _with_quota(creds):
        if quota_project and hasattr(creds, "with_quota_project"):
            try:
                return creds.with_quota_project(quota_project)
            except Exception:
                pass
        return creds

    # 1. Explicit service-account JSON
    if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
        logger.info("get_bq_credentials: using GOOGLE_APPLICATION_CREDENTIALS file")
        with open(SERVICE_ACCOUNT_FILE) as f:
            cred_type = json.load(f).get("type", "")
        if cred_type == "service_account":
            creds, _ = google.auth.load_credentials_from_file(
                SERVICE_ACCOUNT_FILE,
                scopes=["https://www.googleapis.com/auth/bigquery"],
            )
        else:
            creds, _ = google.auth.load_credentials_from_file(SERVICE_ACCOUNT_FILE)
        return _with_quota(creds)

    # 2. gcloud auth login (dev — stored refresh token, auto-refreshes)
    gcloud_creds = _get_gcloud_login_credentials()
    if gcloud_creds is not None:
        logger.info("get_bq_credentials: using gcloud auth login credentials")
        return _with_quota(gcloud_creds)

    # 3. gcloud auth print-access-token (dev fallback)
    gcloud_token = _get_gcloud_print_token()
    if gcloud_token:
        logger.info("get_bq_credentials: using token from gcloud auth print-access-token")
        return oauth2_creds.Credentials(token=gcloud_token, quota_project_id=quota_project)

    # 4. ADC — Workload Identity in prod, application-default in dev
    try:
        creds, _ = google.auth.default()
        logger.info("get_bq_credentials: using Application Default Credentials")
        return _with_quota(creds)
    except Exception as e:
        logger.warning("get_bq_credentials: ADC failed: %s", e)

    raise ValueError(
        "No valid Google credentials found. In dev run:\n"
        "  gcloud auth application-default login\n"
        "In GKE production, ensure Workload Identity is configured."
    )
