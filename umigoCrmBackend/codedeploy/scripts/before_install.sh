#!/bin/bash
set -euo pipefail

APP_ROOT="/opt/umigo/backend"
LOG_ROOT="/var/log/umigo/backend"
DEPLOY_USER="ec2-user"
SERVICE_NAME="umigo-backend.service"

# Ensure service is stopped before deploying new bits
if systemctl list-units --full --all "$SERVICE_NAME" >/dev/null 2>&1; then
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl stop "$SERVICE_NAME"
  fi
fi

mkdir -p "$APP_ROOT" "$LOG_ROOT"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$APP_ROOT" "$LOG_ROOT"
chmod 775 "$APP_ROOT" "$LOG_ROOT"
