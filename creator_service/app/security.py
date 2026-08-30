from __future__ import annotations

import hmac

from fastapi import Header, HTTPException, Query, WebSocketException, status

from .settings import settings


def _matches(candidate: str | None) -> bool:
    return bool(candidate) and hmac.compare_digest(candidate, settings.session_token)


def require_token(
    x_pixelrpg_token: str | None = Header(default=None),
    token: str | None = Query(default=None),
) -> None:
    if not (_matches(x_pixelrpg_token) or _matches(token)):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session token")


def require_websocket_token(token: str | None) -> None:
    if not _matches(token):
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid session token")
