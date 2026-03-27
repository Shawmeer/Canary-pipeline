#!/bin/bash
# monitor-canary.sh - Background canary monitoring and promotion script
# Usage: ./monitor-canary.sh <ec2_ip> <image> <prod_container> <port> <env> <git_sha>
# This script runs in the background on EC2 and monitors canary health
# Logs go to /var/log/canary.log

set -e

EC2_IP=$1
IMAGE=$2
CONTAINER=$3
PORT=$4
ENV=$5
GIT_SHA=$6
SLACK_WEBHOOK=${7:-}  # Optional: Slack webhook URL

# Configuration
LOG_FILE="/var/log/canary.log"
CANARY_PORT=3003
CHECKS=10
MIN_PASSED=8
SLEEP_INTERVAL=30

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Slack notification function
send_slack() {
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$1\"}" \
            "$SLACK_WEBHOOK" || true
    fi
}

log "=== Starting Canary Monitor ==="
log "Image: $IMAGE"
log "Production Container: $CONTAINER"
log "Production Port: $PORT"
log "Canary Port: $CANARY_PORT"
log "Required passes: $MIN_PASSED/$CHECKS"
log "================================"

PASSED=0
FAILED=0

for i in $(seq 1 $CHECKS); do
    log "--- Check $i/$CHECKS ---"
    
    # Check canary health
    CANARY_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$CANARY_PORT/health" 2>/dev/null || echo "000")
    
    # Check production health
    PROD_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")
    
    log "Canary (port $CANARY_PORT): $CANARY_STATUS"
    log "Production (port $PORT): $PROD_STATUS"
    
    if [ "$CANARY_STATUS" = "200" ] && [ "$PROD_STATUS" = "200" ]; then
        log "✅ Both healthy"
        PASSED=$((PASSED + 1))
    else
        log "⚠️ Issues detected (canary=$CANARY_STATUS, prod=$PROD_STATUS)"
        FAILED=$((FAILED + 1))
    fi
    
    # Sleep between checks (except on last iteration)
    if [ $i -lt $CHECKS ]; then
        log "Waiting ${SLEEP_INTERVAL}s before next check..."
        sleep $SLEEP_INTERVAL
    fi
done

log "================================"
log "Health Check Results: $PASSED/$CHECKS passed"
log "================================"

if [ $PASSED -ge $MIN_PASSED ]; then
    log "✅ Auto-promoting to 100%..."
    
    # Stop old production
    log "Stopping old production container..."
    docker stop $CONTAINER || true
    docker rm $CONTAINER || true
    
    # Deploy new version to production using the reusable script
    log "Deploying new version to production..."
    docker run -d --restart always -p $PORT:3000 \
        -e ENVIRONMENT=$ENV \
        -e VERSION=$IMAGE \
        -e GIT_SHA=$GIT_SHA \
        --name $CONTAINER \
        $IMAGE
    
    # Wait for production to be ready
    sleep 5
    
    # Reload nginx to ensure traffic flows to new version
    log "Reloading nginx..."
    sudo systemctl reload nginx || true
    
    # Stop canary (traffic now 100% to production)
    log "Stopping canary container..."
    docker stop app-canary || true
    docker rm app-canary || true
    
    log "================================"
    log "🎉 PROMOTION COMPLETE!"
    log "   - Port $PORT: NEW version (100%)"
    log "   - Canary stopped"
    log "================================"
    
    # Send success notification
    send_slack "✅ Canary promoted to 100%! Version: $IMAGE ($GIT_SHA)"
    
else
    log "⚠️ Not enough checks passed ($PASSED/$CHECKS)"
    log "   Canary stays at 10% traffic"
    log "   Manual promotion required or automatic rollback"
    
    # Send failure notification
    send_slack "❌ Canary promotion FAILED! Only $PASSED/$CHECKS checks passed. Version: $IMAGE ($GIT_SHA)"
    
    # Optional: Stop canary if too many failures
    if [ $FAILED -gt 5 ]; then
        log "⚠️ Too many failures, stopping canary..."
        docker stop app-canary || true
        docker rm app-canary || true
        
        # Send rollback notification
        send_slack "🔄 Canary rolled back due to $FAILED failures. Version: $IMAGE ($GIT_SHA)"
    fi
fi

log "=== Canary Monitor Finished ==="