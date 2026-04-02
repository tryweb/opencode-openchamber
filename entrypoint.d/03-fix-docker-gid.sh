#!/usr/bin/env bash
set -euo pipefail

SOCKET_PATH="/var/run/docker.sock"

if [ -S "$SOCKET_PATH" ]; then
    SOCKET_GID=$(stat -c '%g' "$SOCKET_PATH" 2>/dev/null)
    
    if [ -n "$SOCKET_GID" ] && [ "$SOCKET_GID" != "0" ]; then
        if getent group docker > /dev/null 2>&1; then
            CURRENT_GID=$(getent group docker | cut -d: -f3)
            if [ "$CURRENT_GID" != "$SOCKET_GID" ]; then
                echo "[docker-gid] Modifying docker group GID: $CURRENT_GID -> $SOCKET_GID"
                groupmod -g "$SOCKET_GID" docker
                echo "[docker-gid] GID updated successfully"
            else
                echo "[docker-gid] Docker group GID matches socket: $SOCKET_GID"
            fi
        else
            echo "[docker-gid] Creating docker group with GID: $SOCKET_GID"
            groupadd -g "$SOCKET_GID" docker
            echo "[docker-gid] Docker group created"
        fi
        
        if ! id -nG devuser | grep -qw docker; then
            usermod -aG docker devuser
            echo "[docker-gid] Added devuser to docker group"
        fi
        
        SOCKET_PERMS=$(stat -c '%a' "$SOCKET_PATH" 2>/dev/null)
        if [ "$SOCKET_PERMS" != "660" ] && [ "$SOCKET_PERMS" != "666" ]; then
            echo "[docker-gid] Fixing socket permissions: $SOCKET_PERMS -> 660"
            chmod 660 "$SOCKET_PATH" 2>/dev/null || true
        fi
    fi
else
    echo "[docker-gid] Docker socket not found at $SOCKET_PATH, skipping GID fix"
fi