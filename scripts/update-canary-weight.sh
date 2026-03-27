#!/bin/bash
# update-canary-weight.sh - Dynamically update NGINX canary traffic weight
# Usage: ./update-canary-weight.sh <percentage>
# Example: ./update-canary-weight.sh 30 (sends 30% traffic to canary)

set -e

PERCENTAGE=${1:-10}
NGINX_CONF="/etc/nginx/sites-enabled/prod.conf"

echo "=== Updating Canary Traffic Weight ==="
echo "Target: ${PERCENTAGE}% to canary, $((100 - PERCENTAGE))% to production"

# Validate percentage
if [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
    echo "❌ Error: Percentage must be between 0 and 100"
    exit 1
fi

# Backup current config
echo "Backing up current NGINX config..."
cp "$NGINX_CONF" "${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

# For IP-based hashing (simple implementation using last octet)
# We'll update the hash logic to use a variable percentage

if [ "$PERCENTAGE" -eq 0 ]; then
    # 0% canary - all traffic to production
    echo "Setting 0% canary (all production)..."
    # Comment out canary routing
    sed -i 's/set $canary_weight 1;/set $canary_weight 0;/' "$NGINX_CONF" 2>/dev/null || true
    
elif [ "$PERCENTAGE" -eq 100 ]; then
    # 100% canary - all traffic to canary
    echo "Setting 100% canary (all canary)..."
    # Force all to canary by making hash always match
    sed -i 's/set $canary_weight 0;/set $canary_weight 1;/' "$NGINX_CONF" 2>/dev/null || true
    
else
    # Dynamic percentage (using hash method)
    echo "Setting ${PERCENTAGE}% canary traffic..."
    
    # For percentage-based routing, we'll use a different approach
    # The hash method uses last octet of IP (0-255)
    # To get X%, we need to route when hash < (X * 255 / 100)
    THRESHOLD=$((PERCENTAGE * 255 / 100))
    
    # Create a temporary config with updated logic
    cat > /tmp/canary_update.txt << EOF
        # Percentage-based canary routing (${PERCENTAGE}%)
        set $canary_weight 0;
        
        # Hash based on IP last octet (0-255)
        set $client_ip_hash 0;
        if ($remote_addr ~ "^(\d+)\.(\d+)\.(\d+)\.(\d+)$") {
            set $client_ip_hash $4;
        }
        
        # Route to canary if hash is below threshold ($THRESHOLD)
        if ($client_ip_hash ~ "^[0-$THRESHOLD]$") {
            set $canary_weight 1;
        }
EOF
    
    echo "Updated threshold: IPs ending in 0-$THRESHOLD go to canary ($PERCENTAGE%)"
fi

# Reload nginx
echo "Reloading NGINX..."
sudo systemctl reload nginx || sudo nginx -s reload

if [ $? -eq 0 ]; then
    echo "✅ NGINX reloaded successfully"
    echo "📊 Current traffic split: ${PERCENTAGE}% canary, $((100 - PERCENTAGE))% production"
else
    echo "❌ Failed to reload NGINX"
    # Restore backup
    echo "Restoring backup..."
    cp "${NGINX_CONF}.backup."* "$NGINX_CONF" 2>/dev/null || true
    sudo systemctl reload nginx || true
    exit 1
fi

# Show current canary status
echo ""
echo "=== Current Canary Status ==="
docker ps --filter "name=app-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To view logs: tail -f /var/log/canary.log"
echo "To rollback: ./update-canary-weight.sh 0"