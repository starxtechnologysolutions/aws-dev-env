#!/bin/bash
set -euo pipefail

SERVICE_NAME="umigo-backend.service"

if systemctl list-units --full --all "$SERVICE_NAME" >/dev/null 2>&1; then
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping $SERVICE_NAME"
    systemctl stop "$SERVICE_NAME"
  else
    echo "$SERVICE_NAME not running"
  fi
fi
