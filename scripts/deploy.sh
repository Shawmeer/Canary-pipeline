#!/bin/bash
# deploy.sh - Reusable deployment script for EC2
# Usage: ./deploy.sh <container_name> <port> <image> <env> <git_sha>

set -e

CONTAINER=$1
PORT=$2
IMAGE=$3
ENV=$4
GIT_SHA=$5

echo "=== Deploying $CONTAINER ==="
echo "Image: $IMAGE"
echo "Port: $PORT"
echo "Environment: $ENV"
echo "Git SHA: $GIT_SHA"

# Create backup of current image (for rollback)
if [ "$CONTAINER" = "app-prod" ]; then
    CURRENT_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "devops-app-repo" | head -1 || true)
    if [ -n "$CURRENT_IMAGE" ]; then
        echo "Creating backup tag for rollback..."
        docker tag $CURRENT_IMAGE devops-app-repo:backup || true
        echo "Backup created: devops-app-repo:backup"
    fi
fi

# Stop and remove existing container
echo "Stopping existing container..."
docker stop $CONTAINER || true
docker rm $CONTAINER || true

# Run new container
echo "Starting new container..."
docker run -d --restart always -p $PORT:3000 \
  -e ENVIRONMENT=$ENV \
  -e VERSION=$IMAGE \
  -e GIT_SHA=$GIT_SHA \
  --name $CONTAINER \
  $IMAGE

# Cleanup old images (keep only last 5)
echo "Cleaning up old Docker images..."
docker image prune -af --filter "until=24h" || true

echo "=== Deployment complete ==="
docker ps | grep app-