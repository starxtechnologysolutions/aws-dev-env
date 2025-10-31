#!/bin/bash
set -euo pipefail

SERVICE_NAME="umigo-backend.service"
APP_ROOT="/opt/umigo/backend"
ENV_FILE="$APP_ROOT/.env"
ENVIRONMENT=""
REGION=""

if [ -f "$ENV_FILE" ]; then
  ENVIRONMENT=$(grep '^SPRING_PROFILES_ACTIVE=' "$ENV_FILE" | tail -n1 | cut -d '=' -f2- | tr -d '"' || true)
  REGION=$(grep '^AWS_REGION=' "$ENV_FILE" | tail -n1 | cut -d '=' -f2- | tr -d '"' || true)
fi

if [ -z "$REGION" ]; then
  REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("region",""))' || true)
fi

if [ -z "$ENVIRONMENT" ]; then
  ENVIRONMENT="dev"
fi

if [ ! -f "$APP_ROOT/backend.jar" ]; then
  echo "backend.jar not found in $APP_ROOT" >&2
  exit 1
fi

if [ -z "$REGION" ]; then
  echo "Region could not be determined" >&2
  exit 1
fi

RDS_SECRET_ID="${ENVIRONMENT}/rds/app"
DATASOURCE_PARAM="/${ENVIRONMENT}/backend/SPRING_DATASOURCE_URL"
REDIS_HOST_PARAM="/${ENVIRONMENT}/backend/SPRING_REDIS_HOST"
REDIS_PORT_PARAM="/${ENVIRONMENT}/backend/SPRING_REDIS_PORT"

DB_SECRET=$(aws secretsmanager get-secret-value --secret-id "$RDS_SECRET_ID" --query SecretString --output text --region "$REGION")
DB_USERNAME=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("username",""))' "$DB_SECRET")
DB_PASSWORD=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("password",""))' "$DB_SECRET")

DATASOURCE_URL=$(aws ssm get-parameter --name "$DATASOURCE_PARAM" --query Parameter.Value --output text --region "$REGION")
REDIS_HOST=$(aws ssm get-parameter --name "$REDIS_HOST_PARAM" --query Parameter.Value --output text --region "$REGION" 2>/dev/null || true)
REDIS_PORT=$(aws ssm get-parameter --name "$REDIS_PORT_PARAM" --query Parameter.Value --output text --region "$REGION" 2>/dev/null || true)

cat > "$ENV_FILE" <<EOF
SPRING_PROFILES_ACTIVE=${ENVIRONMENT}
AWS_REGION=${REGION}
SPRING_DATASOURCE_URL=${DATASOURCE_URL}
SPRING_DATASOURCE_USERNAME=${DB_USERNAME}
SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
SPRING_DATA_REDIS_HOST=${REDIS_HOST}
SPRING_DATA_REDIS_PORT=${REDIS_PORT}
JAVA_TOOL_OPTIONS=-XX:+ExitOnOutOfMemoryError
EOF
chown ec2-user:ec2-user "$ENV_FILE"
chmod 600 "$ENV_FILE"

systemctl restart "$SERVICE_NAME"
