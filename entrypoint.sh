#!/bin/bash
set -e
OUT=/app/forge/outputs
OWNER_UID="${PUID:-$(stat -c '%u' "$OUT")}"
OWNER_GID="${PGID:-$(stat -c '%g' "$OUT")}"
echo "Forge will run as UID=$OWNER_UID GID=$OWNER_GID"
if [ "$OWNER_UID" = "0" ]; then
    echo "WARNING: running as root, files in outputs will be owned by root."
    echo "         Create ~/ai/Data/outputs as your user before the first start, or set PUID/PGID in compose."
else
    getent group "$OWNER_GID" >/dev/null || groupadd -g "$OWNER_GID" hostgroup
    getent passwd "$OWNER_UID" >/dev/null || useradd -m -u "$OWNER_UID" -g "$OWNER_GID" hostuser
    # chown -R долгий, делаем только если владелец /app/forge не совпал
    if [ "$(stat -c '%u' /app/forge)" != "$OWNER_UID" ]; then
        chown -R "$OWNER_UID:$OWNER_GID" /app/forge
    fi
fi
cd /app/forge
exec gosu "$OWNER_UID:$OWNER_GID" python launch.py \
    --listen --port 7860 \
    --xformers --opt-sdp-attention --no-half-vae \
    --enable-insecure-extension-access --api \
    "$@"
