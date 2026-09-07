#!/usr/bin/env bash

# Auto-Deployment Daemon Script
# Polling repositories for changes every minute, building, and restarting services.

LOG_FILE="/home/ubuntu/oracle-app-server/auto-deploy.log"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $1" | tee -a "$LOG_FILE"
}

check_and_deploy_repo() {
  local REPO_DIR="$1"
  local REPO_NAME="$2"
  local BUILD_CMD="$3"
  local SERVICE_NAMES="$4"

  if [ ! -d "$REPO_DIR" ]; then
    return 0
  fi

  cd "$REPO_DIR" || return 1

  git fetch origin main >/dev/null 2>&1
  LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
  REMOTE_HASH=$(git rev-parse origin/main 2>/dev/null)

  if [ -n "$LOCAL_HASH" ] && [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    log "New commit detected for $REPO_NAME ($LOCAL_HASH -> $REMOTE_HASH). Pulling and deploying..."
    git pull origin main >> "$LOG_FILE" 2>&1

    if [ -n "$BUILD_CMD" ]; then
      log "Running build for $REPO_NAME..."
      eval "$BUILD_CMD" >> "$LOG_FILE" 2>&1
    fi

    if [ -n "$SERVICE_NAMES" ]; then
      for SVC in $SERVICE_NAMES; do
        log "Restarting systemd service: $SVC..."
        sudo systemctl restart "$SVC" >> "$LOG_FILE" 2>&1
      done
    fi

    log "Deployment completed successfully for $REPO_NAME!"
  fi
}

run_check() {
  # 1. Thai Unified Toll Map
  check_and_deploy_repo "/var/www/thai_unified_toll_map" "Toll Map" \
    "npm install && npm run build" \
    "toll-map.service"

  # 2. Shabu Nub Nub
  check_and_deploy_repo "/var/www/shabu_nub_nub" "Shabu Nub Nub" \
    "npm install && npm run build" \
    "shabu.service"

  # 3. Alpha Trader v2 Frontend & Backend
  check_and_deploy_repo "/var/www/alpha-trader-v2" "Alpha Trader v2" \
    "cd frontend && npm install && npm run build && cd .. && ./venv/bin/pip install -r requirements.txt" \
    "alpha-trader-api.service alpha-trader-web.service"

  # 4. Infrastructure Repo (oracle-app-server)
  check_and_deploy_repo "/home/ubuntu/oracle-app-server" "Oracle App Server Infrastructure" \
    "sudo cp systemd/*.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo cp nginx/*.conf /etc/nginx/sites-available/ && sudo nginx -t && sudo systemctl reload nginx" \
    ""
}

if [ "$1" = "daemon" ]; then
  log "Starting Auto-Deployment Daemon loop (interval: 60s)..."
  while true; do
    run_check
    sleep 60
  done
else
  run_check
fi
