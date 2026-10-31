#!/bin/bash
set -e

OWNER_UID=$(stat -c '%u' /mnt/outputs)
OWNER_GID=$(stat -c '%g' /mnt/outputs)
echo "Detected volume owner: UID=$OWNER_UID GID=$OWNER_GID"

if [ "$OWNER_UID" != "0" ]; then
    getent group "$OWNER_GID" >/dev/null || groupadd -g "$OWNER_GID" hostgroup
    getent passwd "$OWNER_UID" >/dev/null || useradd -m -u "$OWNER_UID" -g "$OWNER_GID" hostuser
    # chown -R по всему дереву на каждый старт долгий: делаем только если владелец не совпал
    if [ "$(stat -c '%u' /app/forge)" != "$OWNER_UID" ]; then
        chown -R "$OWNER_UID:$OWNER_GID" /app/forge
    fi
fi

cd /app/forge
echo "Starting Forge WebUI as UID=$OWNER_UID..."
exec gosu "$OWNER_UID:$OWNER_GID" python launch.py \
    --listen --port 7860 \
    --xformers --opt-sdp-attention --no-half-vae \
    --enable-insecure-extension-access --api \
    "$@"
