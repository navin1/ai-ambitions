import logging

from fastapi import APIRouter, HTTPException, Request, Response
from pydantic import BaseModel

import auth

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["auth"])


class LoginRequest(BaseModel):
    username: str
    password: str


@router.post("/login")
async def login(body: LoginRequest, response: Response):
    username = body.username.strip()
    if not username or not body.password:
        raise HTTPException(status_code=400, detail="Username and password are required")

    if auth.FORGEROCK_AM_URL:
        try:
            token = await auth.am_authenticate(username, body.password)
        except auth.AMAuthError as exc:
            raise HTTPException(status_code=401, detail=str(exc))

        response.set_cookie(
            key=auth.FORGEROCK_AM_COOKIE_NAME,
            value=token,
            httponly=True,
            samesite="lax",
            secure=True,
        )
        return {"username": username}

    # Dev fallback — no AM configured locally. Accept any non-empty credentials
    # so the login/logout flow is fully demoable without a live ForgeRock stack.
    logger.info("login: FORGEROCK_AM_URL not configured, using dev-mode session")
    response.set_cookie(
        key=auth.DEV_SESSION_COOKIE,
        value=username,
        httponly=True,
        samesite="lax",
    )
    return {"username": username}


@router.post("/logout")
async def logout(request: Request, response: Response):
    token = request.cookies.get(auth.FORGEROCK_AM_COOKIE_NAME)
    if auth.FORGEROCK_AM_URL and token:
        await auth.am_logout(token)

    response.delete_cookie(auth.FORGEROCK_AM_COOKIE_NAME)
    response.delete_cookie(auth.DEV_SESSION_COOKIE)
    return {"ok": True}
