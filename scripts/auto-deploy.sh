#!/usr/bin/env bash

# Auto-Deployment Daemon Script with Compact Visual Heartbeats
# Polling repositories for changes every minute, building, and restarting services.

LOG_FILE="/home/ubuntu/oracle-app-server/auto-deploy.log"

log() {
  printf "\n[%s] %s\n" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$1" | tee -a "$LOG_FILE"
}

# Heartbeat state tracking
LAST_LOGGED_HOUR=""
LAST_LOGGED_DAY=""

log_heartbeat() {
  local CURRENT_TIME=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
  local CURRENT_DAY=$(date -u +'%Y-%m-%d')
  local CURRENT_HOUR=$(date -u +'%H')
  local CURRENT_MIN=$(date -u +'%M')

  # New Day marker (Midnight UTC)
  if [ "$CURRENT_DAY" != "$LAST_LOGGED_DAY" ] && [ -n "$LAST_LOGGED_DAY" ]; then
    printf "\n[%s] === NEW DAY: %s ===\n" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$CURRENT_DAY" | tee -a "$LOG_FILE"
    LAST_LOGGED_DAY="$CURRENT_DAY"
    LAST_LOGGED_HOUR="$CURRENT_HOUR"
    return
  fi
  LAST_LOGGED_DAY="$CURRENT_DAY"

  # Hourly or 6-Hourly marker (Top of the hour :00)
  if [ "$CURRENT_MIN" = "00" ] && [ "$CURRENT_HOUR" != "$LAST_LOGGED_HOUR" ]; then
    LAST_LOGGED_HOUR="$CURRENT_HOUR"
    local HOUR_INT=$((10#$CURRENT_HOUR))
    if [ $((HOUR_INT % 6)) -eq 0 ]; then
      printf "\n[%s] | " "$CURRENT_TIME" | tee -a "$LOG_FILE"
    else
      printf "\n[%s] : " "$CURRENT_TIME" | tee -a "$LOG_FILE"
    fi
  else
    # Minute heartbeat dot
    printf "." | tee -a "$LOG_FILE"
  fi
}

check_and_deploy_repo() {
  local REPO_DIR="$1"
  local REPO_NAME="$2"
  local BUILD_CMD="$3"
  local SERVICE_NAMES="$4"
  local DEPLOYED=1

  if [ ! -d "$REPO_DIR" ]; then
    return 1
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
    DEPLOYED=0
  fi

  return $DEPLOYED
}

run_check() {
  local CHANGED=1

  # 1. Thai Unified Toll Map
  check_and_deploy_repo "/var/www/thai_unified_toll_map" "Toll Map" \
    "npm install && npm run build" \
    "toll-map.service" && CHANGED=0

  # 2. Shabu Nub Nub
  check_and_deploy_repo "/var/www/shabu_nub_nub" "Shabu Nub Nub" \
    "npm install && npm run build" \
    "shabu.service" && CHANGED=0

  # 3. Alpha Trader v2 Frontend & Backend
  check_and_deploy_repo "/var/www/alpha-trader-v2" "Alpha Trader v2" \
    "cd frontend && npm install && npm run build && cd .. && ./venv/bin/pip install -r requirements.txt" \
    "alpha-trader-api.service alpha-trader-web.service" && CHANGED=0

  # 4. Longwarp Auth Service
  check_and_deploy_repo "/var/www/longwarp-auth" "Longwarp Auth" \
    "npm install && npm run build && npx prisma db push" \
    "auth.service" && CHANGED=0

  # 5. Infrastructure Repo (oracle-app-server)
  check_and_deploy_repo "/home/ubuntu/oracle-app-server" "Oracle App Server Infrastructure" \
    "sudo cp systemd/*.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo cp nginx/*.conf /etc/nginx/sites-available/ && sudo nginx -t && sudo systemctl reload nginx" \
    "" && CHANGED=0

  if [ $CHANGED -ne 0 ]; then
    log_heartbeat
  fi
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
