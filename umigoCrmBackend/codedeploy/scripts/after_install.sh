#!/bin/bash
set -euo pipefail

APP_ROOT="/opt/umigo/backend"
DEPLOY_USER="ec2-user"
SERVICE_SOURCE="codedeploy/systemd/umigo-backend.service"
SERVICE_FILE="/etc/systemd/system/umigo-backend.service"

if [ -f "$SERVICE_SOURCE" ]; then
  echo "Updating systemd unit"
  cp "$SERVICE_SOURCE" "$SERVICE_FILE"
  chmod 644 "$SERVICE_FILE"
  systemctl daemon-reload
  systemctl enable umigo-backend.service
fi

if [ -f "$APP_ROOT/backend.jar" ]; then
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$APP_ROOT/backend.jar"
  chmod 640 "$APP_ROOT/backend.jar"
fi
