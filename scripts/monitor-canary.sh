#!/bin/bash
# monitor-canary.sh - Progressive Canary Deployment with Traffic Routing
# Usage: ./monitor-canary.sh <ec2_ip> <image> <prod_container> <port> <env> <git_sha>
#
# Progressive Rollout Stages:
#   Stage 1: 10% canary, 90% production (10-15 min)
#   Stage 2: 20% canary, 80% production (10-15 min)
#   Stage 3: 40% canary, 60% production (10-15 min)
#   Stage 4: 60% canary, 40% production (10-15 min)
#   Stage 5: 80% canary, 20% production (10-15 min)
#   Stage 6: 100% production (promotion) - keep old for testing
#
# Health checks at each stage - rollback if any fail

set -e

EC2_IP=$1
IMAGE=$2
CONTAINER=$3
PORT=$4
ENV=$5
GIT_SHA=$6
SLACK_WEBHOOK=${7:-}

# Configuration
LOG_FILE="/var/log/canary.log"
CANARY_PORT=3003
CHECK_INTERVAL=30  # 30 seconds between checks
STAGE_WAIT=300      # 5 minutes (300s) per stage for traffic observation

# Progressive rollout: (percentage, checks_passed)
# Each stage needs at least N checks to pass
STAGES=(
    "10:6"    # Stage 1: 10% canary, need 6 checks (6*30s = 3min minimum)
    "20:6"    # Stage 2: 20% canary
    "40:6"    # Stage 3: 40% canary
    "60:6"    # Stage 4: 60% canary
    "80:6"    # Stage 5: 80% canary
    "100:3"   # Stage 6: 100% promotion
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Send Slack notification
send_slack() {
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$1\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Update canary traffic percentage in nginx
set_canary_percentage() {
    local PERCENTAGE=$1
    log "Setting canary traffic to ${PERCENTAGE}%..."
    bash /home/ubuntu/update-canary-weight.sh $PERCENTAGE
}

log "=============================================="
log "=== Progressive Canary Deployment Started ==="
log "=============================================="
log "Image: $IMAGE"
log "Production: $CONTAINER:$PORT"
log "Canary: app-canary:$CANARY_PORT"
log "Progressive: 10% -> 20% -> 40% -> 60% -> 80% -> 100%"
log "=============================================="

# Start with 10% canary traffic
log "🚀 Stage 1: Starting with 10% canary, 90% production"
set_canary_percentage 10

# Progressive monitoring through stages
for STAGE in "${STAGES[@]}"; do
    PERCENTAGE=$(echo $STAGE | cut -d: -f1)
    REQUIRED_CHECKS=$(echo $STAGE | cut -d: -f2)
    
    log "=============================================="
    log "=== STAGE: ${PERCENTAGE}% canary traffic ==="
    log "=== Need ${REQUIRED_CHECKS} successful checks ==="
    log "=============================================="
    
    PASSED=0
    FAILED=0
    
    # Run health checks
    for i in $(seq 1 $REQUIRED_CHECKS); do
        log "--- Check $i/${REQUIRED_CHECKS} ---"
        
        # Check canary health (new version)
        CANARY_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$CANARY_PORT/health" 2>/dev/null || echo "000")
        
        # Check production health (old version)
        PROD_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")
        
        log "Canary (port $CANARY_PORT): HTTP $CANARY_STATUS"
        log "Production (port $PORT): HTTP $PROD_STATUS"
        
        if [ "$CANARY_STATUS" = "200" ] && [ "$PROD_STATUS" = "200" ]; then
            PASSED=$((PASSED + 1))
            log "✅ Check $i PASSED"
        else
            FAILED=$((FAILED + 1))
            log "❌ Check $i FAILED (Canary: $CANARY_STATUS, Prod: $PROD_STATUS)"
            
            # ROLLBACK on failure
            log "⚠️ ROLLING BACK due to health check failure!"
            log "Stopping canary traffic..."
            set_canary_percentage 0
            
            log "Stopping canary container..."
            docker stop app-canary 2>/dev/null || true
            docker rm app-canary 2>/dev/null || true
            
            sudo systemctl reload nginx 2>/dev/null || true
            
            send_slack "❌ CANARY FAILED at ${PERCENTAGE}%! Rolled back. Version: $IMAGE ($GIT_SHA)"
            
            log "=============================================="
            log "🚫 CANARY ROLLED BACK"
            log "=============================================="
            exit 1
        fi
        
        # Wait between checks
        if [ $i -lt $REQUIRED_CHECKS ]; then
            log "Waiting ${CHECK_INTERVAL}s before next check..."
            sleep $CHECK_INTERVAL
        fi
    done
    
    log "✅ Stage ${PERCENTAGE}% passed: $PASSED/$REQUIRED_CHECKS checks"
    
    # If not final stage (100%), wait longer before moving to next percentage
    if [ "$PERCENTAGE" -lt 100 ]; then
        log "Waiting ${STAGE_WAIT}s (${STAGE_WAIT}/60 = $((STAGE_WAIT/60)) min) for traffic observation..."
        log "This allows real user traffic to test the canary version"
        sleep $STAGE_WAIT
        
        # Move to next percentage
        case "$PERCENTAGE" in
            10) NEXT=20 ;;
            20) NEXT=40 ;;
            40) NEXT=60 ;;
            60) NEXT=80 ;;
            80) NEXT=100 ;;
        esac
        log "🚀 Promoting to ${NEXT}% canary traffic..."
        set_canary_percentage $NEXT
    fi
done

# ==================== PROMOTION ====================
log "=============================================="
log "=== FINAL PROMOTION: 100% NEW VERSION ==="
log "=============================================="

# Keep old production for rollback/testing
log "Renaming old production to app-backup..."
docker stop $CONTAINER 2>/dev/null || true
docker rm $CONTAINER 2>/dev/null || true
docker rename $CONTAINER app-backup 2>/dev/null || true

# Deploy new version to production
log "Deploying new version to production (port $PORT)..."
docker run -d --restart always -p $PORT:3000 \
    -e ENVIRONMENT=$ENV \
    -e VERSION=$IMAGE \
    -e GIT_SHA=$GIT_SHA \
    --name $CONTAINER \
    $IMAGE

# Wait for production to be ready
sleep 5

# Verify production is healthy
PROD_HEALTH=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")
if [ "$PROD_HEALTH" != "200" ]; then
    log "❌ Production health check failed! Rolling back..."
    # Rollback to old version
    docker stop $CONTAINER 2>/dev/null || true
    docker rm $CONTAINER 2>/dev/null || true
    docker rename app-backup $CONTAINER 2>/dev/null || true
    docker start $CONTAINER 2>/dev/null || true
    set_canary_percentage 0
    send_slack "❌ PROMOTION FAILED! Rolled back to previous version."
    exit 1
fi

# Stop canary (no longer needed)
log "Stopping canary container..."
docker stop app-canary 2>/dev/null || true
docker rm app-canary 2>/dev/null || true

# Set canary to 0% (all traffic to new production)
log "Setting canary to 0%..."
set_canary_percentage 0
sudo systemctl reload nginx

log "=============================================="
log "✅ PROMOTION COMPLETE!"
log "   - New version running on port $PORT (100%)"
log "   - Old version kept as app-backup for testing/rollback"
log "   - Run 'docker start app-backup' to rollback if needed"
log "=============================================="

send_slack "✅ Canary promoted to 100%! Version: $IMAGE ($GIT_SHA)"

log "=== Canary Monitor Finished ==="
