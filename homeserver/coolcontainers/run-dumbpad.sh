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
echo "🚀 Starting Dumbpad container..."

# Create Docker volume if it doesn't exist
if ! docker volume inspect dumbpad &> /dev/null; then
    echo "📦 Creating Docker volume 'dumbpad'..."
    docker volume create dumbpad
fi

# Run Dumbpad container
docker run -p 3000:3000 \
  -v dumbpad:/app/data \
  dumbwareio/dumbpad:latest
