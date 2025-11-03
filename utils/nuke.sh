#!/bin/bash

# Exit on error
set -e

echo "🚨 WARNING: This script will remove ALL Docker containers, images, volumes, and networks!"
echo "            This action cannot be undone!"
echo ""
echo "The following items will be removed:"
echo "- All stopped and running containers"
echo "- All unused images, not just dangling ones"
echo "- All unused volumes"
echo "- All unused networks"
echo "- All unused build cache"
echo ""

read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if Docker is running
echo "🔍 Checking Docker status..."
check_docker

# Stop all running containers
echo -n "🛑 Stopping all running containers... "
docker stop $(docker ps -q) 2>/dev/null || echo "No running containers to stop"

# Remove all containers
echo -n "🗑️  Removing all containers... "
docker rm -f $(docker ps -a -q) 2>/dev/null || echo "No containers to remove"

# Remove all images
echo -n "🖼️  Removing all images... "
docker rmi -f $(docker images -q) 2>/dev/null || echo "No images to remove"

# Remove all volumes
echo -n "💾 Removing all volumes... "
docker volume rm $(docker volume ls -q) 2>/dev/null || echo "No volumes to remove"

# Remove all networks (except the default ones)
echo -n "🌐 Removing all networks... "
for network in $(docker network ls --format '{{.Name}}' | grep -vE '^(bridge|host|none)$'); do
    docker network rm $network 2>/dev/null || true
done

# Remove build cache
echo -n "🧹 Cleaning up build cache... "
docker builder prune -af 2>/dev/null || echo "No build cache to remove"

echo ""
echo "✅ Docker environment has been completely cleaned!"
echo ""
docker system df  # Show disk usage after cleanup
