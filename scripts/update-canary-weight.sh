#!/bin/bash
# update-canary-weight.sh - Dynamically update NGINX canary traffic weight
# Usage: ./update-canary-weight.sh <percentage>
# Example: ./update-canary-weight.sh 30 (sends 30% traffic to canary)

set -e

PERCENTAGE=${1:-10}
CANARY_WEIGHT_FILE="/home/ubuntu/canary-weight.conf"

echo "=== Updating Canary Traffic Weight ==="
echo "Target: ${PERCENTAGE}% to canary, $((100 - PERCENTAGE))% to production"

# Validate percentage
if [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
    echo "❌ Error: Percentage must be between 0 and 100"
    exit 1
fi

# Check if canary container is running
if ! docker ps | grep -q app-canary; then
    echo "⚠️ Warning: Canary container not running!"
    PERCENTAGE=0
fi

# Create the canary weight configuration file
cat > "$CANARY_WEIGHT_FILE" << EOF
# Dynamic canary weight configuration
# Generated at $(date)
# $PERCENTAGE% traffic to canary
set \$canary_percentage $PERCENTAGE;
EOF

echo "✅ Updated canary-weight.conf: $PERCENTAGE% to canary"

# Reload nginx to apply changes
echo "Reloading NGINX..."
sudo nginx -s reload 2>/dev/null || sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ NGINX reloaded successfully"
    echo "📊 Current traffic split: ${PERCENTAGE}% canary, $((100 - PERCENTAGE))% production"
else
    echo "❌ Failed to reload NGINX"
    exit 1
fi

# Show current canary status
echo ""
echo "=== Current Container Status ==="
docker ps --filter "name=app-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To check canary logs: docker logs app-canary"
echo "To view canary traffic: curl http://localhost:3003/metrics"
echo "To rollback: ./update-canary-weight.sh 0"
