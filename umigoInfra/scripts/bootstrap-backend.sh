#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID=""
REGION="ap-southeast-2"
ENV_NAME="dev"
BACKEND_PATH=""
PROFILE=""
SKIP_PORT_FORWARD=0
SKIP_SEED=0
RUN_BACKEND=0
NO_ENV_FILE=0

usage() {
  cat <<'USAGE'
Usage: bootstrap-backend.sh [options]

Options:
  --instance-id ID         EC2 instance id (defaults to terraform output)
  --region REGION          AWS region (default ap-southeast-2)
  --env NAME               Environment prefix for secrets (default dev)
  --backend-path PATH      Path to umigoCrmBackend project
  --profile PROFILE        AWS CLI profile name
  --skip-port-forward      Do not launch SSM port-forward sessions
  --skip-seed              Skip applying schema.sql via psql
  --run-backend            Run ./mvnw spring-boot:run after setup
  --no-env-file            Do not write .env.bootstrap file
  -h, --help               Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance-id) INSTANCE_ID="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --env) ENV_NAME="$2"; shift 2;;
    --backend-path) BACKEND_PATH="$2"; shift 2;;
    --profile) PROFILE="$2"; shift 2;;
    --skip-port-forward) SKIP_PORT_FORWARD=1; shift;;
    --skip-seed) SKIP_SEED=1; shift;;
    --run-backend) RUN_BACKEND=1; shift;;
    --no-env-file) NO_ENV_FILE=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 1; }

TF_DIR="$ROOT_DIR/infra/terraform"

if [[ -z "$INSTANCE_ID" ]]; then
  if ! INSTANCE_ID=$(terraform -chdir="$TF_DIR" output -raw ec2_instance_id 2>/dev/null); then
    echo "Unable to determine ec2_instance_id from terraform outputs. Pass --instance-id." >&2
    exit 1
  fi
fi

if [[ -z "$BACKEND_PATH" ]]; then
  for candidate in "$ROOT_DIR/Umigo/umigoCrmBackend" "$ROOT_DIR/umigoCrmBackend"; do
    if [[ -d "$candidate" ]]; then
      BACKEND_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "$BACKEND_PATH" || ! -d "$BACKEND_PATH" ]]; then
  echo "[WARN] Backend path not found. Use --backend-path to point to umigoCrmBackend." >&2
fi

aws_args=("--region" "$REGION")
if [[ -n "$PROFILE" ]]; then
  aws_args+=("--profile" "$PROFILE")
fi

get_tf_output() {
  local name="$1"
  terraform -chdir="$TF_DIR" output -raw "$name" 2>/dev/null || true
}

postgres_host=$(get_tf_output postgres_host)
postgres_port=$(get_tf_output postgres_port)
redis_host=$(get_tf_output redis_host)
redis_port=$(get_tf_output redis_port)
rabbit_endpoint=$(get_tf_output rabbit_amqp_endpoint)
redis_host=${redis_host:-localhost}
redis_port=${redis_port:-6379}
postgres_port=${postgres_port:-5432}

if [[ -n "$rabbit_endpoint" ]]; then
  rabbit_host=$(python - <<'PY'
import sys
from urllib.parse import urlparse
uri = urlparse(sys.stdin.read().strip())
print(uri.hostname or '')
PY
<<<"$rabbit_endpoint")
  rabbit_remote_port=$(python - <<'PY'
import sys
from urllib.parse import urlparse
uri = urlparse(sys.stdin.read().strip())
print(uri.port or '')
PY
<<<"$rabbit_endpoint")
fi
rabbit_remote_port=${rabbit_remote_port:-5671}

local_db_port=15432
local_redis_port=16379
local_rabbit_port=15671

start_forward_cmd() {
  local host="$1" remote_port="$2" local_port="$3"
  printf 'aws %s ssm start-session --target %s --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters %s\n' "${aws_args[*]}" "$INSTANCE_ID" "{\"host\":[\"$host\"],\"portNumber\":[\"$remote_port\"],\"localPortNumber\":[\"$local_port\"]}"
}

db_cmd=$(start_forward_cmd "$postgres_host" "$postgres_port" "$local_db_port")
redis_cmd=$(start_forward_cmd "$redis_host" "$redis_port" "$local_redis_port")
rabbit_cmd=$(start_forward_cmd "$rabbit_host" "$rabbit_remote_port" "$local_rabbit_port")

if [[ $SKIP_PORT_FORWARD -eq 0 ]]; then
  if command -v tmux >/dev/null; then
    session_name="umigo-fwd"
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
      tmux new-session -d -s "$session_name" "$db_cmd"
    else
      tmux new-window -t "$session_name" "$db_cmd"
    fi
    tmux new-window -t "$session_name" "$redis_cmd"
    tmux new-window -t "$session_name" "$rabbit_cmd"
    echo "Started tmux session '$session_name' with port forwards. Attach using: tmux attach -t $session_name"
  else
    cat <<EOF
[INFO] tmux not detected. Run these commands in separate terminals and keep them open:
$ $db_cmd
$ $redis_cmd
$ $rabbit_cmd
EOF
  fi
else
  echo "[INFO] Skipping port forwarding as requested."
fi

echo "[INFO] Fetching Secrets Manager values..."

get_secret_json() {
  local name="$1"
  aws "${aws_args[@]}" secretsmanager get-secret-value --secret-id "$name" --query SecretString --output text
}

if ! db_secret_json=$(get_secret_json "$ENV_NAME/rds/app"); then
  echo "Failed to fetch secret $ENV_NAME/rds/app" >&2
  exit 1
fi

if ! rabbit_secret_json=$(get_secret_json "$ENV_NAME/rabbitmq/app"); then
  echo "Failed to fetch secret $ENV_NAME/rabbitmq/app" >&2
  exit 1
fi

parse_secret() {
  local json="$1" key="$2"
  printf '%s' "$json" | python - "$key" <<'PY'
import json, sys
payload = json.load(sys.stdin)
key = sys.argv[1]
print(payload.get(key, ''))
PY
}

db_username=$(parse_secret "$db_secret_json" username)
db_password=$(parse_secret "$db_secret_json" password)
db_name=$(parse_secret "$db_secret_json" dbname)
if [[ -z "$db_name" ]]; then db_name="appdb"; fi

rabbit_username=$(parse_secret "$rabbit_secret_json" username)
rabbit_password=$(parse_secret "$rabbit_secret_json" password)

s3_bucket=$(get_tf_output s3_bucket_name)

if [[ $NO_ENV_FILE -eq 0 && -d "$BACKEND_PATH" ]]; then
  cat <<EOF >"$BACKEND_PATH/.env.bootstrap"
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:$local_db_port/$db_name
SPRING_DATASOURCE_USERNAME=$db_username
SPRING_DATASOURCE_PASSWORD=$db_password
SPRING_REDIS_HOST=localhost
SPRING_REDIS_PORT=$local_redis_port
SPRING_RABBITMQ_HOST=localhost
SPRING_RABBITMQ_PORT=$local_rabbit_port
SPRING_RABBITMQ_USERNAME=$rabbit_username
SPRING_RABBITMQ_PASSWORD=$rabbit_password
UMIGO_FIREBASE_CONFIG_PATH=./config/serviceAccountKey.json
AWS_REGION=$REGION
S3_BUCKET_NAME=$s3_bucket
EOF
  echo "[INFO] Wrote $BACKEND_PATH/.env.bootstrap"
else
  echo "[INFO] Skipping env file creation."
fi

if [[ $SKIP_SEED -eq 0 && -d "$BACKEND_PATH" ]]; then
  if command -v psql >/dev/null; then
    schema_path="$BACKEND_PATH/src/main/resources/schema.sql"
    if [[ -f "$schema_path" ]]; then
      echo "[INFO] Applying schema via psql..."
      PGPASSWORD="$db_password" psql -h localhost -p "$local_db_port" -U "$db_username" -d "$db_name" -f "$schema_path" || echo "[WARN] psql returned non-zero exit code"
    else
      echo "[WARN] Schema file not found at $schema_path"
    fi
  else
    echo "[WARN] psql not found; skipping schema seed"
  fi
else
  echo "[INFO] Skipping schema seed."
fi

if [[ $RUN_BACKEND -eq 1 && -d "$BACKEND_PATH" ]]; then
  echo "[INFO] Starting Spring Boot via ./mvnw spring-boot:run"
  (cd "$BACKEND_PATH" && SPRING_PROFILES_ACTIVE=dev SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:$local_db_port/$db_name" SPRING_DATASOURCE_USERNAME="$db_username" SPRING_DATASOURCE_PASSWORD="$db_password" SPRING_REDIS_HOST=localhost SPRING_REDIS_PORT="$local_redis_port" SPRING_RABBITMQ_HOST=localhost SPRING_RABBITMQ_PORT="$local_rabbit_port" SPRING_RABBITMQ_USERNAME="$rabbit_username" SPRING_RABBITMQ_PASSWORD="$rabbit_password" AWS_REGION="$REGION" S3_BUCKET_NAME="$s3_bucket" UMIGO_FIREBASE_CONFIG_PATH=./config/serviceAccountKey.json ./mvnw spring-boot:run)
else
  echo "[INFO] Backend not started (use --run-backend to launch)."
fi

echo "[INFO] Bootstrap complete. Keep your port-forward sessions running while developing."