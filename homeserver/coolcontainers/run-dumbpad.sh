#!/bin/bash

# Script to run Dumbpad container
# Checks if Docker is installed before running

set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "Please start Docker service: sudo systemctl start docker"
    exit 1
fi

echo "✅ Docker is installed and running"

# Check if dumbpad container exists and is running
if docker ps -a --format '{{.Names}}' | grep -q '^dumbpad$'; then
    echo "🛑 Stopping existing Dumbpad container..."
    docker stop dumbpad 2>/dev/null || true
    echo "🗑️  Removing existing Dumbpad container..."
    docker rm dumbpad 2>/dev/null || true
fi

# Pull the latest image
echo "📥 Pulling latest Dumbpad image..."
docker pull dumbwareio/dumbpad:latest

echo "🚀 Starting Dumbpad container..."

# Create Docker volume if it doesn't exist
if ! docker volume inspect dumbpad &> /dev/null; then
    echo "📦 Creating Docker volume 'dumbpad'..."
    docker volume create dumbpad
fi

# Run Dumbpad container
docker run -d -p 3000:3000 \
  -v dumbpad:/app/data \
  --name dumbpad \
  --restart unless-stopped \
  -e BASE_URL="${BASE_URL:-http://localhost:3000}" \
  dumbwareio/dumbpad:latest

echo "✅ Dumbpad container started successfully"
echo "📍 Access it at: http://localhost:3000"
echo ""
echo "💡 To use with nginx reverse proxy at /dp/, set BASE_URL:"
echo "   BASE_URL=http://10.0.0.85/dp ./run-dumbpad.sh"
echo ""
echo "Useful commands:"
echo "  - View logs: docker logs -f dumbpad"
echo "  - Stop container: docker stop dumbpad"
echo "  - Remove container: docker rm dumbpad"
