#!/bin/bash
set -euo pipefail

SERVICE_NAME="umigo-backend.service"
PORT=8080

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
  systemctl status "$SERVICE_NAME" || true
  echo "$SERVICE_NAME is not running" >&2
  exit 1
fi

for attempt in {1..12}; do
  if ss -tln | grep -q ":${PORT} "; then
    echo "Service healthy on port $PORT"
    exit 0
  fi
  sleep 5
done

echo "Service did not expose port $PORT in time" >&2
exit 1
